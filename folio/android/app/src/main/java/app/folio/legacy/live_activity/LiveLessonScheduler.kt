package app.zan1456.folio.live_activity

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

/**
 * Az élő óra-értesítés háttérbeli frissítése: a Tinta átadja a nap
 * szakaszait (első óra előtt, órák, szünetek), és innen AlarmManagerrel
 * magunk lépünk a következő szakaszra, akkor is, ha az app nem fut.
 * Szakaszon belül pár percenként újrarajzoljuk a csíkot.
 */
object LiveLessonScheduler {
    private const val PREFS = "live_lesson_schedule"
    private const val KEY_PLAN = "plan"
    private const val KEY_MODE = "mode"
    private const val REDRAW_MS = 3 * 60 * 1000L

    fun schedule(context: Context, plan: String, mode: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_PLAN, plan)
            .putString(KEY_MODE, mode)
            .apply()
        tick(context)
    }

    fun cancel(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
        alarmManager(context).cancel(alarmIntent(context))
    }

    /** Kirakja az épp aktuális szakaszt, és beállítja a következő ébresztést. */
    fun tick(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val plan = try {
            JSONArray(prefs.getString(KEY_PLAN, "[]"))
        } catch (e: Exception) {
            JSONArray()
        }
        val mode = prefs.getString(KEY_MODE, "auto") ?: "auto"
        val now = System.currentTimeMillis()

        var current: JSONObject? = null
        var nextStart = Long.MAX_VALUE
        for (i in 0 until plan.length()) {
            val seg = plan.getJSONObject(i)
            val from = seg.getLong("from")
            val to = seg.getLong("to")
            if (now in from until to) current = seg
            if (from > now && from < nextStart) nextStart = from
        }

        val wakeAt = if (current != null) {
            LiveLessonNotificationManager(context).showOrUpdateLive(
                title = current.optString("title"),
                compact = current.optString("compact"),
                body = current.optString("body"),
                next = current.optString("next"),
                startMs = current.optLong("startMs"),
                endMs = current.optLong("endMs"),
                timerFormat = current.optString("timerFormat", "%s"),
                mode = mode,
            )
            minOf(current.getLong("to"), now + REDRAW_MS)
        } else {
            nextStart
        }

        val am = alarmManager(context)
        val pi = alarmIntent(context)
        if (wakeAt == Long.MAX_VALUE) {
            am.cancel(pi)
            return
        }
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
        if (exact) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, wakeAt, pi)
        } else {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, wakeAt, pi)
        }
    }

    private fun alarmManager(context: Context) =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private fun alarmIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context, 4242,
        Intent(context, LiveLessonAlarmReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
}

class LiveLessonAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        LiveLessonScheduler.tick(context)
    }
}
