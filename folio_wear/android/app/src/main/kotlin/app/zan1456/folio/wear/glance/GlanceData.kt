package app.zan1456.folio.wear.glance

import android.content.ComponentName
import android.content.Context
import androidx.wear.tiles.TileService
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester

internal object GlanceData {
    private const val PREFS = "folio_wear"

    fun isPaired(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean("is_paired", false)

    fun stateNow(context: Context, nowMs: Long): GlanceState {
        val json = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString("timetable", null)
        return glanceStateAt(parseGlanceLessons(json), nowMs)
    }

    /** New data arrived: the tile and the complication should not wait for their period. */
    fun requestRefresh(context: Context) {
        TileService.getUpdater(context).requestUpdate(TintaTileService::class.java)
        ComplicationDataSourceUpdateRequester
            .create(context, ComponentName(context, TintaComplicationService::class.java))
            .requestUpdateAll()
    }
}
