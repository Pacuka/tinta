package app.zan1456.folio.wear

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import app.zan1456.folio.wear.glance.GlanceData
import com.google.android.gms.wearable.ChannelClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService

class WearDataListenerService : WearableListenerService() {

    private val TAG = "FolioWear.ListenerSvc"

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate: service started by system")
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy")
        super.onDestroy()
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        Log.d(TAG, "onDataChanged: ${dataEvents.count} event(s)")
        for (event in dataEvents) {
            val path = event.dataItem.uri.path ?: continue
            Log.d(TAG, "  event type=${event.type} path=$path")
            if (event.type != DataEvent.TYPE_CHANGED) continue

            val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap

            when (path) {
                "/folio/timetable" -> {
                    val json = dataMap.getString("json")
                    if (json == null) { Log.w(TAG, "timetable: json key missing") }
                    else {
                        Log.d(TAG, "timetable received: ${json.length} chars")
                        saveAndNotify("timetable", json)
                        Handler(Looper.getMainLooper()).post {
                            MainActivity.methodChannel?.invokeMethod("onTimetableReceived", json)
                        }
                    }
                }
                "/folio/notifications" -> {
                    val json = dataMap.getString("json")
                    if (json == null) { Log.w(TAG, "notifications: json key missing") }
                    else {
                        Log.d(TAG, "notifications received: ${json.length} chars")
                        saveAndNotify("notifications", json)
                        Handler(Looper.getMainLooper()).post {
                            MainActivity.methodChannel?.invokeMethod("onNotificationsReceived", json)
                        }
                    }
                }
                else -> Log.w(TAG, "unknown path: $path")
            }
        }
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        val path = messageEvent.path
        val payload = messageEvent.data
        Log.d(TAG, "onMessageReceived: path=$path payloadSize=${payload.size}")
        if (path in WearDataReset.DATA_PATHS && !WearUpdateInstaller.isPaired(this)) {
            Log.d(TAG, "not paired, data ignored")
            return
        }
        when (path) {
            "/folio/timetable" -> {
                val json = payload.toString(Charsets.UTF_8)
                Log.d(TAG, "timetable: ${json.length} chars")
                saveAndNotify("timetable", json)
                Handler(Looper.getMainLooper()).post {
                    MainActivity.methodChannel?.invokeMethod("onTimetableReceived", json)
                }
            }
            "/folio/notifications" -> {
                val json = payload.toString(Charsets.UTF_8)
                Log.d(TAG, "notifications: ${json.length} chars")
                saveAndNotify("notifications", json)
                Handler(Looper.getMainLooper()).post {
                    MainActivity.methodChannel?.invokeMethod("onNotificationsReceived", json)
                }
            }
            "/folio/extras" -> {
                val json = payload.toString(Charsets.UTF_8)
                Log.d(TAG, "extras: ${json.length} chars")
                if (WearConnectionHelper.isValidExtras(json)) {
                    saveAndNotify("extras", json)
                    Handler(Looper.getMainLooper()).post {
                        MainActivity.methodChannel?.invokeMethod("onExtrasReceived", json)
                    }
                }
            }
            "/folio/ping" -> {
                Log.d(TAG, "ping: delivering cached data")
                val prefs = getSharedPreferences("folio_wear", Context.MODE_PRIVATE)
                val timetable = prefs.getString("timetable", null)
                val notifications = prefs.getString("notifications", null)
                Handler(Looper.getMainLooper()).post {
                    timetable?.let { MainActivity.methodChannel?.invokeMethod("onTimetableReceived", it) }
                    notifications?.let { MainActivity.methodChannel?.invokeMethod("onNotificationsReceived", it) }
                }
            }
            "/folio/pair-confirm" -> {
                // The activity's listener is gone while it is paused.
                val code = payload.toString(Charsets.UTF_8)
                val prefs = getSharedPreferences("folio_wear", Context.MODE_PRIVATE)
                if (code == prefs.getString("pairing_code", null)) {
                    prefs.edit().putBoolean("is_paired", true).apply()
                }
                Handler(Looper.getMainLooper()).post {
                    MainActivity.methodChannel?.invokeMethod("onPairConfirmed", code)
                }
            }
            WearDataReset.LOGOUT_PATH -> {
                // The activity's listener is gone while it is paused.
                WearDataReset.clear(this)
                Handler(Looper.getMainLooper()).post {
                    MainActivity.methodChannel?.invokeMethod("onLoggedOut", null)
                }
            }
            WearUpdateInstaller.VERSION_REQUEST_PATH ->
                WearUpdateInstaller.sendVersion(this, messageEvent.sourceNodeId)
            else -> Log.w(TAG, "unknown message path: $path")
        }
    }

    // ── App update from the phone ───────────────────────────────────────────

    override fun onChannelOpened(channel: ChannelClient.Channel) {
        if (channel.path != WearUpdateInstaller.CHANNEL_PATH) return
        val client = Wearable.getChannelClient(this)
        if (!WearUpdateInstaller.isPaired(this)) {
            Log.w(TAG, "update from an unpaired phone, refused")
            client.close(channel)
            return
        }
        WearUpdateInstaller.rememberSender(this, channel.nodeId)
        val part = WearUpdateInstaller.partFile(this)
        part.delete()
        client.receiveFile(channel, android.net.Uri.fromFile(part), false)
    }

    override fun onInputClosed(channel: ChannelClient.Channel, closeReason: Int, appSpecificErrorCode: Int) {
        if (channel.path != WearUpdateInstaller.CHANNEL_PATH) return
        WearUpdateInstaller.onReceived(this, closeReason == ChannelClient.ChannelCallback.CLOSE_REASON_NORMAL)
    }

    override fun onConnectedNodes(connectedNodes: MutableList<com.google.android.gms.wearable.Node>) {
        Log.d(TAG, "onConnectedNodes: count=${connectedNodes.size}")
        connectedNodes.forEach { Log.d(TAG, "  node id=${it.id} name=${it.displayName} nearby=${it.isNearby}") }
        val connected = connectedNodes.isNotEmpty()
        WearConnectionHelper.isConnected = connected
        Handler(Looper.getMainLooper()).post {
            MainActivity.methodChannel?.invokeMethod("onConnectionChanged", connected)
        }
    }

    override fun onPeerConnected(peer: com.google.android.gms.wearable.Node) {
        Log.d(TAG, "onPeerConnected: id=${peer.id} name=${peer.displayName} nearby=${peer.isNearby}")
        WearConnectionHelper.isConnected = true
        Handler(Looper.getMainLooper()).post {
            MainActivity.methodChannel?.invokeMethod("onConnectionChanged", true)
        }
    }

    override fun onPeerDisconnected(peer: com.google.android.gms.wearable.Node) {
        Log.d(TAG, "onPeerDisconnected: id=${peer.id} name=${peer.displayName}")
        WearConnectionHelper.isConnected = false
        Handler(Looper.getMainLooper()).post {
            MainActivity.methodChannel?.invokeMethod("onConnectionChanged", false)
        }
    }

    private fun saveAndNotify(key: String, json: String) {
        getSharedPreferences("folio_wear", Context.MODE_PRIVATE)
            .edit()
            .putString(key, json)
            .apply()
        if (key == "timetable") GlanceData.requestRefresh(this)
    }
}
