package app.zan1456.folio.wear

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.os.Build
import android.util.Log
import com.google.android.gms.wearable.Wearable
import org.json.JSONObject
import java.io.File

/**
 * Installs a new version of the watch app that the phone sent over.
 *
 * The phone opens a channel on [CHANNEL_PATH] and streams the APK into
 * [partFile]; once complete it becomes [pendingFile]. The system install
 * prompt may only open while the app is on screen, so the install starts
 * from [MainActivity.onResume] (or right away if it is already open).
 * The outcome goes back to the phone on [RESULT_PATH]: "ok" or "error:…".
 */
object WearUpdateInstaller {
    private const val TAG = "FolioWear.Update"
    private const val PREFS = "folio_wear"

    const val VERSION_REQUEST_PATH = "/folio/version-request"
    const val VERSION_PATH = "/folio/watch-version"
    const val CHANNEL_PATH = "/folio/wear-update"
    const val RESULT_PATH = "/folio/wear-update-result"

    /** True while [MainActivity] is resumed. */
    @Volatile
    var activityResumed = false

    @Volatile
    private var installing = false

    /**
     * The first install also asks for the "install unknown apps" permission.
     * Wear OS then ends the session as aborted instead of going on to the
     * install prompt, so that one abort retries instead of giving up.
     */
    @Volatile
    private var askedPermission = false

    fun partFile(ctx: Context) = File(ctx.filesDir, "wear-update.apk.part")
    fun pendingFile(ctx: Context) = File(ctx.filesDir, "wear-update.apk")

    /** Only the paired phone may send an update. */
    fun isPaired(ctx: Context) =
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean("is_paired", false)

    fun rememberSender(ctx: Context, nodeId: String) {
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString("update_node", nodeId).apply()
    }

    fun sendVersion(ctx: Context, nodeId: String) {
        val info = ctx.packageManager.getPackageInfo(ctx.packageName, 0)
        val code = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode
                   else @Suppress("DEPRECATION") info.versionCode.toLong()
        val json = JSONObject().put("name", info.versionName).put("code", code).toString()
        Wearable.getMessageClient(ctx).sendMessage(nodeId, VERSION_PATH, json.toByteArray())
            .addOnFailureListener { e -> Log.w(TAG, "sendVersion failed: ${e.message}") }
    }

    /** Called when the transfer finished; [ok] is false if it broke off. */
    fun onReceived(ctx: Context, ok: Boolean) {
        val part = partFile(ctx)
        if (!ok || !part.exists() || part.length() == 0L) {
            part.delete()
            sendResult(ctx, "error:transfer")
            return
        }
        val apk = pendingFile(ctx)
        apk.delete()
        if (!part.renameTo(apk)) {
            sendResult(ctx, "error:transfer")
            return
        }
        Log.d(TAG, "update received: ${apk.length()} bytes")
        if (activityResumed) installIfPending(ctx)
    }

    /** Starts the system install of a received update, if there is one. */
    fun installIfPending(ctx: Context) {
        val apk = pendingFile(ctx)
        if (!apk.exists() || installing) return
        installing = true
        askedPermission = !ctx.packageManager.canRequestPackageInstalls()
        try {
            val installer = ctx.packageManager.packageInstaller
            val params = PackageInstaller.SessionParams(
                PackageInstaller.SessionParams.MODE_FULL_INSTALL
            ).apply { setAppPackageName(ctx.packageName) }
            val sessionId = installer.createSession(params)
            installer.openSession(sessionId).use { session ->
                session.openWrite("tinta-wear.apk", 0, apk.length()).use { out ->
                    apk.inputStream().use { it.copyTo(out) }
                    session.fsync(out)
                }
                val intent = Intent(ctx, InstallResultReceiver::class.java)
                // Mutable: the system adds the status extras.
                val pending = PendingIntent.getBroadcast(
                    ctx, sessionId, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                )
                session.commit(pending.intentSender)
            }
        } catch (e: Exception) {
            Log.e(TAG, "install failed to start", e)
            finish(ctx, "error:install")
        }
    }

    /** The user left the prompt; retried once if it was only the permission. */
    fun onAborted(ctx: Context) {
        if (askedPermission && ctx.packageManager.canRequestPackageInstalls()) {
            askedPermission = false
            installing = false
            if (activityResumed) installIfPending(ctx)
            return
        }
        finish(ctx, "error:aborted")
    }

    /** Cleans up after an install attempt and tells the phone. */
    fun finish(ctx: Context, result: String) {
        installing = false
        pendingFile(ctx).delete()
        sendResult(ctx, result)
    }

    private fun sendResult(ctx: Context, result: String) {
        Log.d(TAG, "result: $result")
        val node = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString("update_node", null) ?: return
        Wearable.getMessageClient(ctx).sendMessage(node, RESULT_PATH, result.toByteArray())
            .addOnFailureListener { e -> Log.w(TAG, "sendResult failed: ${e.message}") }
    }
}

/** Receives the install session's status from the system. */
class InstallResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)
        when (status) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                val confirm = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                } else {
                    @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_INTENT)
                }
                if (confirm == null) {
                    WearUpdateInstaller.finish(context, "error:install")
                    return
                }
                confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(confirm)
            }
            // After a successful update this runs in the new version.
            PackageInstaller.STATUS_SUCCESS -> WearUpdateInstaller.finish(context, "ok")
            PackageInstaller.STATUS_FAILURE_ABORTED -> WearUpdateInstaller.onAborted(context)
            else -> {
                val msg = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
                Log.w("FolioWear.Update", "install failed: status=$status $msg")
                WearUpdateInstaller.finish(context, "error:install")
            }
        }
    }
}
