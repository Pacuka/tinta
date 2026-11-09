package app.zan1456.folio.wear

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.wearable.ChannelClient
import com.google.android.gms.wearable.Wearable
import java.io.File
import io.flutter.plugin.common.MethodChannel

/**
 * Handles all Wearable Data Layer communication from the phone side.
 *
 * Responsibilities:
 *  - Send timetable JSON to watch  (/folio/timetable)
 *  - Send notifications JSON to watch (/folio/notifications)
 *  - Cache latest data in SharedPreferences (used by WorkManager for morning sync)
 *  - Listen for sync requests from the watch
 *  - Report connection status back to Flutter
 */
class WearSyncManager(
    private val context: Context,
    private val flutterChannel: MethodChannel
) {

    private val TAG = "FolioPhone.WearSync"

    companion object {
        /**
         * Set once the phone turns out to have no Wear OS services (no
         * companion app, or a ROM without Google wear support). Further
         * calls are skipped until the process restarts.
         */
        @Volatile
        var wearUnavailable = false

        /**
         * Logs a failed Wearable call. A missing Wear API is normal on phones
         * without a watch, so it gets one short line instead of a stack trace.
         */
        fun logFailure(tag: String, what: String, e: Exception) {
            if ((e as? ApiException)?.statusCode == CommonStatusCodes.API_NOT_CONNECTED) {
                if (!wearUnavailable) Log.w(tag, "$what: Wear OS not available on this phone, skipping watch sync")
                wearUnavailable = true
            } else {
                Log.e(tag, "$what FAILED: ${e.message}", e)
            }
        }
    }
    private val prefs: SharedPreferences =
        context.getSharedPreferences("folio_wear_phone", Context.MODE_PRIVATE)

    // ── Connection ───────────────────────────────────────────────────────────

    fun checkConnection() {
        if (wearUnavailable) return
        Wearable.getNodeClient(context).connectedNodes
            .addOnSuccessListener { nodes ->
                val connected = nodes.isNotEmpty()
                Log.d(TAG, "checkConnection: connected=$connected nodes=${nodes.size}")
                nodes.forEach { Log.d(TAG, "  node id=${it.id} name=${it.displayName} nearby=${it.isNearby}") }
                prefs.edit().putBoolean("connected", connected).apply()
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    flutterChannel.invokeMethod("onConnectionChanged", connected)
                }
            }
            .addOnFailureListener { e -> logFailure(TAG, "checkConnection", e) }
    }

    fun isConnected(): Boolean = prefs.getBoolean("connected", false)

    // ── Sending data to watch ────────────────────────────────────────────────

    /**
     * Sends timetable JSON to the watch via Wearable Data Layer.
     * The DataItem is keyed by path so the watch always gets the latest version.
     */
    fun sendTimetable(json: String) {
        prefs.edit().putString("timetable", json).apply()
        if (wearUnavailable) return
        Log.d(TAG, "sendTimetable: ${json.length} chars")
        Wearable.getNodeClient(context).connectedNodes
            .addOnSuccessListener { nodes ->
                Log.d(TAG, "sendTimetable: ${nodes.size} node(s)")
                for (node in nodes) {
                    Wearable.getMessageClient(context)
                        .sendMessage(node.id, "/folio/timetable", json.toByteArray(Charsets.UTF_8))
                        .addOnSuccessListener { Log.d(TAG, "sendTimetable OK to ${node.id}") }
                        .addOnFailureListener { e -> logFailure(TAG, "sendTimetable to ${node.id}", e) }
                }
            }
            .addOnFailureListener { e -> logFailure(TAG, "sendTimetable: getNodes", e) }
    }

    /**
     * Sends the top-10 notifications JSON to the watch.
     */
    fun sendNotifications(json: String) {
        prefs.edit().putString("notifications", json).apply()
        if (wearUnavailable) return
        Log.d(TAG, "sendNotifications: ${json.length} chars")
        Wearable.getNodeClient(context).connectedNodes
            .addOnSuccessListener { nodes ->
                Log.d(TAG, "sendNotifications: ${nodes.size} node(s)")
                for (node in nodes) {
                    Wearable.getMessageClient(context)
                        .sendMessage(node.id, "/folio/notifications", json.toByteArray(Charsets.UTF_8))
                        .addOnSuccessListener { Log.d(TAG, "sendNotifications OK to ${node.id}") }
                        .addOnFailureListener { e -> logFailure(TAG, "sendNotifications to ${node.id}", e) }
                }
            }
            .addOnFailureListener { e -> logFailure(TAG, "sendNotifications: getNodes", e) }
    }

    /** Sends the average and upcoming homework/exams to the watch. */
    fun sendExtras(json: String) {
        prefs.edit().putString("extras", json).apply()
        if (wearUnavailable) return
        Log.d(TAG, "sendExtras: ${json.length} chars")
        Wearable.getNodeClient(context).connectedNodes
            .addOnSuccessListener { nodes ->
                for (node in nodes) {
                    Wearable.getMessageClient(context)
                        .sendMessage(node.id, "/folio/extras", json.toByteArray(Charsets.UTF_8))
                        .addOnSuccessListener { Log.d(TAG, "sendExtras OK to ${node.id}") }
                        .addOnFailureListener { e -> logFailure(TAG, "sendExtras to ${node.id}", e) }
                }
            }
            .addOnFailureListener { e -> logFailure(TAG, "sendExtras: getNodes", e) }
    }

    /**
     * Reads cached data from SharedPreferences and pushes it to the watch.
     * Used by [WearMorningSyncWorker] without needing the Flutter engine.
     */
    fun sendCachedData() {
        val timetable = prefs.getString("timetable", null)
        val notifications = prefs.getString("notifications", null)
        timetable?.let { sendTimetable(it) }
        notifications?.let { sendNotifications(it) }
        prefs.getString("extras", null)?.let { sendExtras(it) }
    }

    // ── Morning sync scheduling ──────────────────────────────────────────────

    fun scheduleMorningSync() {
        WearMorningSyncWorker.schedule(context)
    }

    // ── Settings ─────────────────────────────────────────────────────────────

    fun setSyncEnabled(enabled: Boolean) {
        prefs.edit().putBoolean("sync_enabled", enabled).apply()
        if (!enabled) {
            WearMorningSyncWorker.cancel(context)
        } else {
            scheduleMorningSync()
        }
    }

    fun getSyncEnabled(): Boolean = prefs.getBoolean("sync_enabled", true)

    // ── Watch app update ─────────────────────────────────────────────────────

    /** Asks the watch for its app version; it answers on /folio/watch-version. */
    /** Logged out on the phone: the watch forgets the school data too. */
    fun sendLogout() {
        prefs.edit().remove("timetable").remove("notifications").remove("extras").apply()
        if (wearUnavailable) return
        Wearable.getNodeClient(context).connectedNodes
            .addOnSuccessListener { nodes ->
                for (node in nodes) {
                    Wearable.getMessageClient(context)
                        .sendMessage(node.id, "/folio/logout", ByteArray(0))
                        .addOnFailureListener { e -> logFailure(TAG, "sendLogout", e) }
                }
            }
            .addOnFailureListener { e -> logFailure(TAG, "sendLogout: getNodes", e) }
    }

    fun requestWatchVersion() {
        if (wearUnavailable) return
        Wearable.getNodeClient(context).connectedNodes
            .addOnSuccessListener { nodes ->
                for (node in nodes) {
                    Wearable.getMessageClient(context)
                        .sendMessage(node.id, "/folio/version-request", ByteArray(0))
                        .addOnFailureListener { e -> logFailure(TAG, "requestWatchVersion", e) }
                }
            }
            .addOnFailureListener { e -> logFailure(TAG, "requestWatchVersion: getNodes", e) }
    }

    /**
     * Streams the watch installer at [path] to the watch over a channel.
     * [done] gets true once the whole file went through; called once, on the
     * main thread.
     */
    fun sendUpdateFile(path: String, done: (Boolean) -> Unit) {
        val file = File(path)
        var finished = false
        val main = android.os.Handler(android.os.Looper.getMainLooper())
        fun finish(ok: Boolean) = main.post {
            if (finished) return@post
            finished = true
            Log.d(TAG, "sendUpdateFile: ${if (ok) "sent" else "failed"}")
            done(ok)
        }
        if (wearUnavailable || !file.exists()) { finish(false); return }

        val client = Wearable.getChannelClient(context)
        Wearable.getNodeClient(context).connectedNodes
            .addOnSuccessListener { nodes ->
                val node = nodes.firstOrNull { it.isNearby } ?: nodes.firstOrNull()
                if (node == null) { finish(false); return@addOnSuccessListener }
                client.openChannel(node.id, "/folio/wear-update")
                    .addOnSuccessListener { channel ->
                        client.registerChannelCallback(channel, object : ChannelClient.ChannelCallback() {
                            override fun onOutputClosed(c: ChannelClient.Channel, closeReason: Int, appSpecificErrorCode: Int) {
                                finish(closeReason == CLOSE_REASON_NORMAL)
                            }
                            override fun onChannelClosed(c: ChannelClient.Channel, closeReason: Int, appSpecificErrorCode: Int) {
                                finish(false)
                            }
                        })
                        Log.d(TAG, "sendUpdateFile: ${file.length()} bytes to ${node.id}")
                        client.sendFile(channel, android.net.Uri.fromFile(file))
                            .addOnFailureListener { e -> logFailure(TAG, "sendUpdateFile", e); finish(false) }
                    }
                    .addOnFailureListener { e -> logFailure(TAG, "sendUpdateFile: openChannel", e); finish(false) }
            }
            .addOnFailureListener { e -> logFailure(TAG, "sendUpdateFile: getNodes", e); finish(false) }
    }

    // ── Pairing ───────────────────────────────────────────────────────────────

    /** Sends the pairing confirmation code to the watch. */
    fun sendPairConfirm(code: String) {
        if (wearUnavailable) return
        Log.d(TAG, "sendPairConfirm: code=$code")
        Wearable.getNodeClient(context).connectedNodes
            .addOnSuccessListener { nodes ->
                for (node in nodes) {
                    Wearable.getMessageClient(context)
                        .sendMessage(node.id, "/folio/pair-confirm", code.toByteArray(Charsets.UTF_8))
                        .addOnSuccessListener { Log.d(TAG, "sendPairConfirm OK to ${node.id}") }
                        .addOnFailureListener { e -> logFailure(TAG, "sendPairConfirm", e) }
                }
            }
            .addOnFailureListener { e -> logFailure(TAG, "sendPairConfirm: getNodes", e) }
    }
}
