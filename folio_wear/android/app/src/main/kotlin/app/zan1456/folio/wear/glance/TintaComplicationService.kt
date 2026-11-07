package app.zan1456.folio.wear.glance

import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationText
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.CountDownTimeReference
import androidx.wear.watchface.complications.data.LongTextComplicationData
import androidx.wear.watchface.complications.data.NoDataComplicationData
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.RangedValueComplicationData
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.data.TimeDifferenceComplicationText
import androidx.wear.watchface.complications.data.TimeDifferenceStyle
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceService
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import java.time.Instant

/** Current or next lesson on any watch face. The face runs the countdown itself. */
class TintaComplicationService : ComplicationDataSourceService() {

    override fun onComplicationRequest(
        request: ComplicationRequest,
        listener: ComplicationRequestListener,
    ) {
        val now = System.currentTimeMillis()
        val state = GlanceData.stateNow(this, now)
        listener.onComplicationData(
            build(request.complicationType, state, glanceText(state, now)),
        )
    }

    override fun getPreviewData(type: ComplicationType): ComplicationData? = build(
        type,
        GlanceState(GlancePhase.LESSON, progress = 0.45f),
        GlanceText(
            top = "3. óra",
            main = "Történelem",
            value = "24 perc",
            room = "12",
            countdownTo = null,
        ),
    )

    private fun build(
        type: ComplicationType,
        state: GlanceState,
        text: GlanceText,
    ): ComplicationData? {
        val description = plain(listOf(text.top, text.main, text.value, text.room)
            .filter { it.isNotEmpty() }
            .joinToString(", "))
        val value = text.countdownTo?.let(::countdown) ?: plain(text.value)
        return when (type) {
            ComplicationType.SHORT_TEXT ->
                if (text.value.isEmpty() || text.room.isEmpty()) NoDataComplicationData()
                else ShortTextComplicationData.Builder(value, description)
                    .setTitle(plain(text.room))
                    .build()
            ComplicationType.LONG_TEXT -> LongTextComplicationData.Builder(
                plain(listOf(text.main, text.room).filter { it.isNotEmpty() }.joinToString(" · ")),
                description,
            ).apply { if (text.value.isNotEmpty()) setTitle(value) }.build()
            ComplicationType.RANGED_VALUE ->
                if (text.countdownTo == null && state.phase != GlancePhase.LESSON) {
                    NoDataComplicationData()
                } else {
                    RangedValueComplicationData.Builder(state.progress, 0f, 1f, description)
                        .setText(value)
                        .setTitle(plain(text.room))
                        .build()
                }
            else -> null
        }
    }

    private fun plain(text: String) = PlainComplicationText.Builder(text).build()

    private fun countdown(toMs: Long): ComplicationText =
        TimeDifferenceComplicationText.Builder(
            TimeDifferenceStyle.SHORT_SINGLE_UNIT,
            CountDownTimeReference(Instant.ofEpochMilli(toMs)),
        ).build()
}
