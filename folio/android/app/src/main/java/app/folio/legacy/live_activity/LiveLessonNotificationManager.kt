package app.zan1456.folio.live_activity

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import app.zan1456.folio.MainActivity
import app.zan1456.folio.R
import io.github.d4viddf.hyperisland_kit.HyperIslandNotification
import kotlin.math.PI
import kotlin.math.sin

class LiveLessonNotificationManager(private val context: Context) {

    companion object {
        const val CHANNEL_ID = "live_lesson_activity"
        const val NOTIFICATION_ID = 1337
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Jelenlegi óra",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Az éppen folyó óra élő értesítése"
                enableVibration(false)
                setSound(null, null)
                setShowBadge(false)
            }
            notificationManager().createNotificationChannel(channel)
        }
    }

    /** Régi, csak szöveges változat (HyperOS-hiba esetén ez a tartalék). */
    fun showOrUpdateNative(title: String, body: String, subText: String?) {
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setAutoCancel(false)
            .setShowWhen(false)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openAppIntent())

        if (!subText.isNullOrBlank()) {
            builder.setSubText(subText)
        }

        notificationManager().notify(NOTIFICATION_ID, builder.build())
    }

    /**
     * Élő óra-értesítés: mi van most, hol, mennyi van hátra (rendszer által
     * ketyegtetett visszaszámlálás), alatta Material You-s hullámos csík a
     * telefon témaszíneivel. [startMs]/[endMs] epoch ms; ha a kezdet ismeretlen
     * (0), csík nincs, csak visszaszámlálás. [timerFormat] pl. "még %s".
     */
    fun showOrUpdateLive(
        title: String,
        compact: String,
        body: String,
        next: String,
        startMs: Long,
        endMs: Long,
        timerFormat: String,
        mode: String = "auto",
    ) {
        val now = System.currentTimeMillis()
        val remaining = endMs - now
        if (endMs <= 0 || remaining <= 0) {
            cancel()
            return
        }
        val progress = if (startMs in 1 until endMs) {
            ((now - startMs).toFloat() / (endMs - startMs)).coerceIn(0f, 1f)
        } else {
            -1f
        }
        // Android 16+: rendszer-stílusú élő frissítés (felső sávos chip),
        // ha az automatikus mód vagy kézzel ez van kiválasztva.
        val wantsPromoted = mode == "promoted" || mode == "auto"
        if (wantsPromoted && Build.VERSION.SDK_INT >= 36) {
            notificationManager().notify(
                NOTIFICATION_ID,
                buildPromoted(title, body, next, endMs, remaining, progress)
            )
            return
        }
        val bar = if (progress >= 0f) wavyBar(progress) else null
        val chronoBase = SystemClock.elapsedRealtime() + remaining

        // Összecsukva csak egy szövegsor + csík fér el, ott a [compact] sor megy.
        fun build(layout: Int, withNext: Boolean) =
            RemoteViews(context.packageName, layout).apply {
                if (withNext) {
                    setTextViewText(R.id.live_title, title)
                    setTextViewText(R.id.live_body, body)
                    setViewVisibility(R.id.live_body, if (body.isBlank()) View.GONE else View.VISIBLE)
                } else {
                    setTextViewText(R.id.live_title, compact.ifBlank { title })
                }
                setChronometer(R.id.live_timer, chronoBase, timerFormat, true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    setChronometerCountDown(R.id.live_timer, true)
                }
                if (bar != null) {
                    setImageViewBitmap(R.id.live_progress, bar)
                    setViewVisibility(R.id.live_progress, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.live_progress, View.GONE)
                }
                if (withNext) {
                    setTextViewText(R.id.live_next, next)
                    setViewVisibility(R.id.live_next, if (next.isBlank()) View.GONE else View.VISIBLE)
                }
            }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(accentColor())
            // Szöveges tartalék (zárolt képernyő, okosóra, régi launcherek).
            .setContentTitle(title)
            .setContentText(if (body.isBlank()) next else body)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(build(R.layout.notif_live_small, false))
            .setCustomBigContentView(build(R.layout.notif_live_big, true))
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setShowWhen(false)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            // Ha az app közben leáll, ne maradjon ott egy lejárt óra.
            .setTimeoutAfter(remaining + 5_000L)
            .setContentIntent(openAppIntent())
            .build()

        notificationManager().notify(NOTIFICATION_ID, notification)
    }

    /**
     * Android 16 „Live Update”: ProgressStyle + kiemelt (promoted) folyamatban
     * lévő értesítés. A rendszer a felső sávban chipként mutatja a
     * visszaszámlálást. Itt nem lehet saját rajzolású nézet, ezért a csík a
     * rendszeré.
     */
    @RequiresApi(36)
    private fun buildPromoted(
        title: String,
        body: String,
        next: String,
        endMs: Long,
        remaining: Long,
        progress: Float,
    ): Notification {
        val accent = accentColor()
        val text = listOf(body, next).filter { it.isNotBlank() }.joinToString("\n")
        val builder = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(accent)
            .setContentTitle(title)
            .setContentText(body.ifBlank { next })
            .setCategory(Notification.CATEGORY_PROGRESS)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(true)
            .setWhen(endMs)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setTimeoutAfter(remaining + 5_000L)
            .setContentIntent(openAppIntent())
            // = Notification.EXTRA_REQUEST_PROMOTED_ONGOING (a 36-os SDK-ban
            // még nincs hozzá builder-metódus).
            .addExtras(Bundle().apply { putBoolean("android.requestPromotedOngoing", true) })
        if (progress >= 0f) {
            builder.setStyle(
                Notification.ProgressStyle()
                    .setStyledByProgress(true)
                    .setProgressSegments(
                        listOf(Notification.ProgressStyle.Segment(1000).setColor(accent))
                    )
                    .setProgress((progress * 1000).toInt())
            )
        } else if (text.isNotBlank()) {
            builder.setStyle(Notification.BigTextStyle().bigText(text))
        }
        return builder.build()
    }

    private fun openAppIntent(): PendingIntent = PendingIntent.getActivity(
        context, 0,
        Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    private fun isNight(): Boolean =
        (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES

    /** A telefon Material You fő színe (Android 12+), különben Tinta-kobalt. */
    private fun accentColor(): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val res = if (isNight()) android.R.color.system_accent1_200
            else android.R.color.system_accent1_600
            return context.getColor(res)
        }
        return if (isNight()) 0xFF9DB4FF.toInt() else 0xFF2F55D4.toInt()
    }

    /**
     * Material 3 Expressive-stílusú hullámos csík bitmapként (RemoteViews-ba
     * nem lehet saját View-t tenni): a megtett rész szinuszhullám, utána kis
     * rés, majd egyenes, halványabb sáv a végén pöttyel.
     */
    private fun wavyBar(progress: Float): Bitmap {
        val dm = context.resources.displayMetrics
        val d = dm.density
        // Az ImageView szélessége kb. a kijelző mínusz az értesítés margói.
        val w = (dm.widthPixels - 64 * d).toInt().coerceAtLeast((120 * d).toInt())
        val h = (12 * d).toInt()
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)

        val stroke = 4 * d
        val amp = 2.5f * d
        val wave = 22 * d
        val gap = 6 * d
        val mid = h / 2f
        val left = stroke / 2
        val right = w - stroke / 2
        val accent = accentColor()

        val track = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = stroke
            strokeCap = Paint.Cap.ROUND
            color = accent
            alpha = 70
        }
        val active = Paint(track).apply { alpha = 255 }

        val split = left + (right - left) * progress
        if (progress > 0f && split > left + 1) {
            val path = Path()
            path.moveTo(left, mid)
            var x = left
            val step = d
            while (x < split) {
                x = (x + step).coerceAtMost(split)
                // A hullám a két végén elsimul, hogy szépen induljon/érkezzen.
                val ease = ((x - left) / wave).coerceAtMost(1f)
                val y = mid + amp * ease * sin(2 * PI * (x - left) / wave).toFloat()
                path.lineTo(x, y)
            }
            c.drawPath(path, active)
        }
        val trackStart = if (progress > 0f) split + gap else left
        if (trackStart < right - stroke) {
            c.drawLine(trackStart, mid, right - stroke, mid, track)
        }
        // Végpötty (M3 "stop indicator").
        c.drawPoint(right, mid, active)
        return bmp
    }

    fun showOrUpdateHyperOs(title: String, body: String, subText: String?, remainingSeconds: Int) {
        // HyperIsland-ToolKit requires API 26+; fall back on older devices
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            showOrUpdateNative(title, body, subText)
            return
        }
        try {
            val pendingIntent = PendingIntent.getActivity(
                context, 0,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val now = System.currentTimeMillis()
            val baseTime = now + (remainingSeconds * 1000L)

            val bigIslandText = if (body.isNotBlank()) "$title • $body" else title

            val hiBuilder = HyperIslandNotification.Builder(context, CHANNEL_ID, bigIslandText)
                .setEnableFloat(false)
                .setIslandFirstFloat(false)
                .setChatInfo(
                    title = bigIslandText,
                    content = "",
                    timer = io.github.d4viddf.hyperisland_kit.models.TimerInfo(-1, baseTime, remainingSeconds * 1000L, now),
                    pictureKey = "",
                    actionKeys = emptyList()
                )
                .setBigIslandCountdown(baseTime, bigIslandText)
                .setSmallIsland(title)

            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .setAutoCancel(false)
                .setShowWhen(true)
                .setWhen(baseTime)
                .setUsesChronometer(true)
                .apply { if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) setChronometerCountDown(true) }
                .setSilent(true)
                .setOnlyAlertOnce(true)
                .setContentIntent(pendingIntent)
                .apply { if (!subText.isNullOrBlank()) setSubText(subText) }
                .addExtras(hiBuilder.buildResourceBundle())
                .build()

            notification.extras.putString("miui.focus.param", hiBuilder.buildJsonParam())
            notificationManager().notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            // HyperOS not available – fall back to native notification
            showOrUpdateNative(title, body, subText)
        }
    }

    fun cancel() {
        notificationManager().cancel(NOTIFICATION_ID)
    }

    private fun notificationManager(): NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
}
