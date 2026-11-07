package app.zan1456.folio.wear

import org.json.JSONException
import org.json.JSONObject

object WearConnectionHelper {
    var isConnected: Boolean = false

    /** A bad message must not overwrite the last good one. */
    fun isValidExtras(json: String): Boolean = try {
        JSONObject(json).getJSONArray("todos")
        true
    } catch (e: JSONException) {
        false
    }
}
