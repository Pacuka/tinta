package app.zan1456.folio.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import app.zan1456.folio.MainActivity
import app.zan1456.folio.R
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.Locale

/**
 * Órarend-widget a kezdő- és a zárolási képernyőre: a mostani (vagy a
 * következő) óra, alatta az utána jövő. Az adatot a Tinta adja át minden
 * szinkron után (ugyanaz a kéthetes lista, amit az óra is kap), innen
 * AlarmManagerrel lépünk a következő óra elejére/végére.
 *
 * A visszaszámlálás a rendszer Chronometere, magától ketyeg (nem kell hozzá
 * se az app, se ébresztő). Egy órára koppintva az az óra nyílik meg az appban.
 */
class TimetableWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        refresh(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, id: Int, newOptions: Bundle
    ) {
        refresh(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_TICK, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED -> refresh(context)
            else -> super.onReceive(context, intent)
        }
    }

    override fun onDisabled(context: Context) {
        alarmManager(context).cancel(tickIntent(context))
    }

    data class Lesson(
        val subject: String,
        val room: String,
        val start: Long,
        val end: Long,
        val index: Int,
        val status: String,
        val teacher: String,
    )

    companion object {
        private const val PREFS = "tinta_widget"
        private const val KEY_LESSONS = "lessons"
        private const val KEY_COLORS = "colors"
        private const val ACTION_TICK = "app.zan1456.folio.widget.TICK"

        /** Mit nyisson meg az app: "timetable" vagy "lesson:<kezdés ms>". */
        const val EXTRA_OPEN = "tinta_widget_open"

        /** Ennyivel az óra előtt indul a "x perc múlva" visszaszámlálás. */
        private const val SOON_MS = 60 * 60 * 1000L

        /** A Tinta hívja: elmenti az órarendet és frissít. */
        fun save(context: Context, json: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString(KEY_LESSONS, json).apply()
            refresh(context)
        }

        /** A Tinta hívja témaváltáskor: a widget az app színeit veszi át. */
        fun saveColors(context: Context, json: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString(KEY_COLORS, json).apply()
            refresh(context)
        }

        /** Kijelentkezéskor: ne maradjon órarend a zárolási képernyőn. */
        fun clear(context: Context) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
            refresh(context)
        }

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TimetableWidget::class.java))
            val lessons = load(context)
            val now = System.currentTimeMillis()
            for (id in ids) {
                manager.updateAppWidget(id, build(context, lessons, now))
            }
            scheduleNext(context, lessons, now, ids.isNotEmpty())
        }

        private fun load(context: Context): List<Lesson> {
            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_LESSONS, null) ?: return emptyList()
            return try {
                val arr = JSONArray(raw)
                (0 until arr.length()).map {
                    val o = arr.getJSONObject(it)
                    Lesson(
                        subject = o.optString("subject"),
                        room = o.optString("room"),
                        start = o.optLong("start"),
                        end = o.optLong("end"),
                        index = o.optInt("lessonIndex"),
                        status = o.optString("status", "normal"),
                        teacher = o.optString("teacher"),
                    )
                }.sortedBy { it.start }
            } catch (e: Exception) {
                emptyList()
            }
        }

        /** Az app témájának színei; null = a res/values(-night) alapszínei (Kobalt). */
        private class Palette(
            val bg: Int, val card: Int, val text: Int,
            val dim: Int, val accent: Int, val container: Int,
        )

        private fun loadPalette(context: Context): Palette? {
            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_COLORS, null) ?: return null
            return try {
                val o = JSONObject(raw)
                Palette(
                    o.getInt("bg"), o.getInt("card"), o.getInt("text"),
                    o.getInt("dim"), o.getInt("accent"), o.getInt("container"),
                )
            } catch (e: Exception) {
                null
            }
        }

        /** Kártyák/chipek alakja megmarad, csak a színük cserélődik (Android 12+). */
        private fun tintBackground(views: RemoteViews, id: Int, color: Int) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
            views.setColorStateList(id, "setBackgroundTintList", ColorStateList.valueOf(color))
        }

        private fun paintFrame(views: RemoteViews, p: Palette?, small: Boolean) {
            if (p == null) return
            tintBackground(views, R.id.widget_root, p.bg)
            views.setInt(R.id.widget_logo, "setColorFilter", p.accent)
            views.setTextColor(R.id.widget_timer, p.accent)
            if (small) {
                views.setTextColor(R.id.widget_subject, p.text)
                views.setTextColor(R.id.widget_detail, p.accent)
            } else {
                views.setTextColor(R.id.widget_label, p.text)
                views.setTextColor(R.id.widget_time, p.dim)
                views.setTextColor(R.id.widget_empty, p.dim)
            }
        }

        private fun paintRow(row: RemoteViews, p: Palette?, kind: Int) {
            if (p == null) return
            val now = kind == R.layout.widget_row_now
            val past = kind == R.layout.widget_row_past
            tintBackground(row, R.id.row_card, if (now) p.container else p.card)
            tintBackground(row, R.id.row_room, p.container)
            row.setTextColor(R.id.row_index, when { now -> p.accent; past -> p.dim; else -> p.text })
            row.setTextColor(R.id.row_time, if (now) p.accent else p.dim)
            row.setTextColor(R.id.row_subject, if (past) p.dim else p.text)
            row.setTextColor(R.id.row_teacher, if (now) p.accent else p.dim)
            row.setTextColor(R.id.row_room, p.accent)
        }

        private fun build(context: Context, lessons: List<Lesson>, now: Long): RemoteViews {
            val palette = loadPalette(context)
            val small = RemoteViews(context.packageName, R.layout.widget_timetable_small)
            fillSmall(context, small, lessons, now)
            paintFrame(small, palette, small = true)
            val medium = RemoteViews(context.packageName, R.layout.widget_timetable_day)
            fillList(context, medium, lessons, now, wholeDay = false, palette)
            paintFrame(medium, palette, small = false)
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return medium
            val day = RemoteViews(context.packageName, R.layout.widget_timetable_day)
            fillList(context, day, lessons, now, wholeDay = true, palette)
            paintFrame(day, palette, small = false)
            return RemoteViews(
                mapOf(
                    SizeF(110f, 40f) to small,
                    SizeF(200f, 130f) to medium,
                    SizeF(200f, 250f) to day,
                )
            )
        }

        /** Legkisebb méret: logó + a mostani/következő óra egy sorban. */
        private fun fillSmall(context: Context, views: RemoteViews, lessons: List<Lesson>, now: Long) {
            views.setOnClickPendingIntent(R.id.widget_root, openIntent(context, "timetable"))
            val current = lessons.firstOrNull { now >= it.start && now < it.end }
            val main = current ?: lessons.firstOrNull { it.start > now }
            if (main == null) {
                views.setTextViewText(R.id.widget_subject, "Tinta")
                views.setTextViewText(R.id.widget_detail, "Még nincs órarend")
                showTimer(views, R.id.widget_timer, null, null)
                return
            }
            views.setOnClickPendingIntent(R.id.widget_root, openIntent(context, lessonTarget(main)))
            views.setTextViewText(R.id.widget_subject, title(main))
            val time = when {
                main === current -> "${clock(main.end)}-ig"
                sameDay(main.start, now) -> clock(main.start)
                else -> "${dayLabel(main.start, now).lowercase()} ${clock(main.start)}"
            }
            val room = if (main.room.isNotBlank()) "${main.room} · " else ""
            views.setTextViewText(R.id.widget_detail, room + time)
            val (target, format) = countdown(main, current, now)
            showTimer(views, R.id.widget_timer, target, format, now)
        }

        /**
         * Mire számoljunk vissza: óra közben a végére ("még 12:34"), szünetben
         * a következő mai óra elejére, ha egy órán belül kezdődik ("8:12 múlva").
         */
        private fun countdown(main: Lesson, current: Lesson?, now: Long): Pair<Long?, String?> = when {
            main === current -> main.end to "még %s"
            main.start - now in 1..SOON_MS -> main.start to "%s múlva"
            else -> null to null
        }

        private fun showTimer(
            views: RemoteViews, id: Int, target: Long?, format: String?, now: Long = 0
        ) {
            if (target == null) {
                views.setViewVisibility(id, View.GONE)
                return
            }
            val base = SystemClock.elapsedRealtime() + (target - now)
            views.setChronometer(id, base, format, true)
            views.setChronometerCountDown(id, true)
            views.setViewVisibility(id, View.VISIBLE)
        }

        /**
         * Közepes méret: a mostani/következő óra és ami utána jön.
         * Nagy méret ([wholeDay]): a mai (vagy a következő tanítási) nap minden órája.
         */
        private fun fillList(
            context: Context, views: RemoteViews, lessons: List<Lesson>, now: Long, wholeDay: Boolean,
            palette: Palette?,
        ) {
            views.setOnClickPendingIntent(R.id.widget_root, openIntent(context, "timetable"))
            views.removeAllViews(R.id.widget_rows)

            val current = lessons.firstOrNull { now >= it.start && now < it.end }
            val main = current ?: lessons.firstOrNull { it.start > now }
            if (main == null) {
                views.setTextViewText(R.id.widget_label, "Órarend")
                views.setTextViewText(R.id.widget_time, "")
                showTimer(views, R.id.widget_timer, null, null)
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                return
            }
            views.setViewVisibility(R.id.widget_empty, View.GONE)

            val dayLessons = lessons.filter { sameDay(it.start, main.start) }
            val shown = if (wholeDay) {
                dayLessons
            } else {
                listOfNotNull(main, dayLessons.firstOrNull { it.start >= main.end })
            }

            val label = when {
                wholeDay -> dayLabel(main.start, now)
                main === current -> "Most"
                sameDay(main.start, now) -> "Következő"
                else -> dayLabel(main.start, now)
            }
            views.setTextViewText(R.id.widget_label, label)
            val (target, format) = countdown(main, current, now)
            showTimer(views, R.id.widget_timer, target, format, now)
            views.setTextViewText(R.id.widget_time, date(main.start))
            views.setViewVisibility(R.id.widget_time, if (target == null) View.VISIBLE else View.GONE)

            for (l in shown) {
                val layout = when {
                    l === current -> R.layout.widget_row_now
                    l.end <= now -> R.layout.widget_row_past
                    else -> R.layout.widget_row_normal
                }
                val row = RemoteViews(context.packageName, layout)
                row.setOnClickPendingIntent(R.id.row_root, openIntent(context, lessonTarget(l)))
                row.setTextViewText(R.id.row_index, if (l.index > 0) "${l.index}." else "")
                row.setTextViewText(R.id.row_time, "${clock(l.start)}\n${clock(l.end)}")
                row.setTextViewText(
                    R.id.row_subject,
                    if (l.status == "cancelled") "${l.subject} (elmarad)" else l.subject
                )
                val teacher = when {
                    l.status == "substitution" -> "Helyettesítés: ${l.teacher}"
                    else -> l.teacher
                }
                row.setTextViewText(R.id.row_teacher, teacher)
                row.setViewVisibility(R.id.row_teacher, if (teacher.isBlank()) View.GONE else View.VISIBLE)
                row.setTextViewText(R.id.row_room, l.room)
                row.setViewVisibility(R.id.row_room, if (l.room.isBlank()) View.GONE else View.VISIBLE)
                paintRow(row, palette, layout)
                views.addView(R.id.widget_rows, row)
            }
        }

        private fun title(l: Lesson): String {
            val name = if (l.index > 0) "${l.index}. ${l.subject}" else l.subject
            return if (l.status == "cancelled") "$name (elmarad)" else name
        }

        private fun dayLabel(ms: Long, now: Long) = when {
            sameDay(ms, now) -> "Ma"
            sameDay(ms, now + DAY_MS) -> "Holnap"
            else -> dayName(ms)
        }

        /** Következő ébresztés: a legközelebbi óra eleje vagy vége. */
        private fun scheduleNext(context: Context, lessons: List<Lesson>, now: Long, active: Boolean) {
            val am = alarmManager(context)
            val pi = tickIntent(context)
            // Az óra előtti egy órában a "x perc múlva" visszaszámlálás is bekapcsol.
            val next = lessons.flatMap { listOf(it.start - SOON_MS, it.start, it.end) }
                .filter { it > now }.minOrNull()
            if (!active || next == null) {
                am.cancel(pi)
                return
            }
            // Egy kis ráhagyás, hogy a határon már az új állapotot rajzoljuk.
            val wakeAt = next + 1000
            val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
            if (exact) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC, wakeAt, pi)
            } else {
                am.setAndAllowWhileIdle(AlarmManager.RTC, wakeAt, pi)
            }
        }

        private const val DAY_MS = 24 * 60 * 60 * 1000L

        private fun sameDay(a: Long, b: Long): Boolean {
            val ca = Calendar.getInstance().apply { timeInMillis = a }
            val cb = Calendar.getInstance().apply { timeInMillis = b }
            return ca.get(Calendar.YEAR) == cb.get(Calendar.YEAR) &&
                ca.get(Calendar.DAY_OF_YEAR) == cb.get(Calendar.DAY_OF_YEAR)
        }

        private fun clock(ms: Long): String {
            val c = Calendar.getInstance().apply { timeInMillis = ms }
            return String.format(
                Locale.ROOT, "%d:%02d", c.get(Calendar.HOUR_OF_DAY), c.get(Calendar.MINUTE)
            )
        }

        private fun date(ms: Long): String {
            val c = Calendar.getInstance().apply { timeInMillis = ms }
            val months = arrayOf(
                "jan.", "febr.", "márc.", "ápr.", "máj.", "jún.",
                "júl.", "aug.", "szept.", "okt.", "nov.", "dec."
            )
            return "${months[c.get(Calendar.MONTH)]} ${c.get(Calendar.DAY_OF_MONTH)}."
        }

        private fun dayName(ms: Long): String {
            val c = Calendar.getInstance().apply { timeInMillis = ms }
            return when (c.get(Calendar.DAY_OF_WEEK)) {
                Calendar.MONDAY -> "Hétfő"
                Calendar.TUESDAY -> "Kedd"
                Calendar.WEDNESDAY -> "Szerda"
                Calendar.THURSDAY -> "Csütörtök"
                Calendar.FRIDAY -> "Péntek"
                Calendar.SATURDAY -> "Szombat"
                else -> "Vasárnap"
            }
        }

        private fun lessonTarget(l: Lesson) = "lesson:${l.start}"

        /** Minden célnak saját PendingIntent kell: ezt a data URI különbözteti meg. */
        private fun openIntent(context: Context, target: String): PendingIntent =
            PendingIntent.getActivity(
                context, 4343,
                Intent(context, MainActivity::class.java)
                    .setData(Uri.parse("tinta-widget://open/$target"))
                    .putExtra(EXTRA_OPEN, target)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

        private fun alarmManager(context: Context) =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        private fun tickIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
            context, 4344,
            Intent(context, TimetableWidget::class.java).setAction(ACTION_TICK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
