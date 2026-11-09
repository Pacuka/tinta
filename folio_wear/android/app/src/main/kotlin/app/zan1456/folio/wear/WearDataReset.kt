package app.zan1456.folio.wear

import android.content.Context
import app.zan1456.folio.wear.glance.GlanceData

/** Forgets everything the phone sent, on unpair or on logout on the phone. */
object WearDataReset {
    const val LOGOUT_PATH = "/folio/logout"

    /** School data: kept only while the watch is paired. */
    val DATA_PATHS = setOf("/folio/timetable", "/folio/notifications", "/folio/extras")

    fun clear(ctx: Context) {
        // offline_mode is a watch setting, not school data: it stays.
        ctx.getSharedPreferences("folio_wear", Context.MODE_PRIVATE).edit()
            .remove("timetable")
            .remove("notifications")
            .remove("extras")
            .remove("update_node")
            .putBoolean("is_paired", false)
            .apply()
        WearUpdateInstaller.partFile(ctx).delete()
        WearUpdateInstaller.pendingFile(ctx).delete()
        GlanceData.requestRefresh(ctx)
    }
}
