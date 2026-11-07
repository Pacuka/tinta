package app.zan1456.folio.wear.glance

import org.json.JSONArray
import org.json.JSONException
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.ceil

/**
 * The start page's logic for the tile and the complication, which run without
 * Flutter. Keep in step with lib/models/day_state.dart and home_ring.dart.
 */
data class GlanceLesson(
    val subject: String,
    val room: String,
    val startMs: Long,
    val endMs: Long,
    val index: Int,
    val cancelled: Boolean,
)

enum class GlancePhase { LESSON, BREAK, FIRST, DONE, NONE }

data class GlanceState(
    val phase: GlancePhase,
    val current: GlanceLesson? = null,
    val next: GlanceLesson? = null,
    val upcoming: GlanceLesson? = null,
    val progress: Float = 0f,
    val minutesLeft: Int = 0,
)

data class GlanceText(
    val top: String,
    val main: String,
    val value: String,
    val room: String,
    val countdownTo: Long?,
)

fun parseGlanceLessons(json: String?): List<GlanceLesson> {
    if (json == null) return emptyList()
    return try {
        val raw = JSONArray(json)
        List(raw.length()) { i ->
            val l = raw.getJSONObject(i)
            GlanceLesson(
                subject = l.getString("subject"),
                room = l.getString("room"),
                startMs = l.getLong("start"),
                endMs = l.getLong("end"),
                index = l.getInt("lessonIndex"),
                cancelled = l.getString("status") == "cancelled",
            )
        }
    } catch (e: JSONException) {
        emptyList()
    }
}

fun glanceStateAt(lessons: List<GlanceLesson>, nowMs: Long): GlanceState {
    val held = lessons.filter { !it.cancelled }.sortedBy { it.startMs }
    val dayEnd = startOfDay(nowMs, 1)
    val today = held.filter { sameDay(it.startMs, nowMs) }
    val upcoming = held.firstOrNull { it.startMs >= dayEnd }

    if (today.isEmpty()) return GlanceState(GlancePhase.NONE, upcoming = upcoming)

    val past = today.filter { it.endMs <= nowMs }
    val remaining = today.filter { it.endMs > nowMs }
    val soonest = remaining.firstOrNull()
        ?: return GlanceState(GlancePhase.DONE, upcoming = upcoming)

    if (soonest.startMs <= nowMs) {
        return GlanceState(
            GlancePhase.LESSON,
            current = soonest,
            next = remaining.getOrNull(1),
            progress = progress(soonest.startMs, soonest.endMs, nowMs),
            minutesLeft = minutesUntil(soonest.endMs, nowMs),
        )
    }
    val previous = past.lastOrNull()
        ?: return GlanceState(
            GlancePhase.FIRST,
            next = soonest,
            minutesLeft = minutesUntil(soonest.startMs, nowMs),
        )
    return GlanceState(
        GlancePhase.BREAK,
        next = soonest,
        progress = progress(previous.endMs, soonest.startMs, nowMs),
        minutesLeft = minutesUntil(soonest.startMs, nowMs),
    )
}

fun glanceText(state: GlanceState, nowMs: Long): GlanceText = when (state.phase) {
    GlancePhase.LESSON -> state.current!!.let {
        GlanceText("${it.index}. óra", it.subject, "${state.minutesLeft} perc", it.room, it.endMs)
    }
    GlancePhase.BREAK -> state.next!!.let {
        GlanceText("Szünet", it.subject, "${state.minutesLeft} perc", it.room, it.startMs)
    }
    GlancePhase.FIRST -> state.next!!.let {
        val value = if (state.minutesLeft <= 60) "${state.minutesLeft} perc" else time(it.startMs)
        GlanceText("Első óra", it.subject, value, it.room, it.startMs)
    }
    GlancePhase.DONE -> freeDayText("Mára végeztél", state.upcoming, nowMs)
    GlancePhase.NONE -> freeDayText("Ma nincs órád", state.upcoming, nowMs)
}

private fun freeDayText(main: String, upcoming: GlanceLesson?, nowMs: Long): GlanceText {
    if (upcoming == null) return GlanceText("", main, "", "", null)
    val tomorrow = sameDay(upcoming.startMs, startOfDay(nowMs, 1))
    val whenText = if (tomorrow) time(upcoming.startMs)
    else "${weekday(upcoming.startMs)} ${time(upcoming.startMs)}"
    return GlanceText(
        if (tomorrow) "Holnap első óra" else "Következő óra",
        main,
        "$whenText · ${upcoming.subject}",
        "",
        null,
    )
}

private val HU = Locale.forLanguageTag("hu")

private fun time(ms: Long) = SimpleDateFormat("H:mm", HU).format(Date(ms))

private fun weekday(ms: Long) = SimpleDateFormat("EEEE", HU).format(Date(ms))

private fun startOfDay(ms: Long, plusDays: Int): Long = Calendar.getInstance().run {
    timeInMillis = ms
    set(Calendar.HOUR_OF_DAY, 0)
    set(Calendar.MINUTE, 0)
    set(Calendar.SECOND, 0)
    set(Calendar.MILLISECOND, 0)
    add(Calendar.DAY_OF_YEAR, plusDays)
    timeInMillis
}

private fun sameDay(a: Long, b: Long) = startOfDay(a, 0) == startOfDay(b, 0)

private fun progress(from: Long, to: Long, now: Long): Float =
    if (to <= from) 0f else ((now - from).toFloat() / (to - from)).coerceIn(0f, 1f)

private fun minutesUntil(target: Long, now: Long): Int = ceil((target - now) / 60_000.0).toInt()
