package com.primadev.cineva

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver that ensures background update checks stay active
 * even across device reboots, app updates, or when the app is completely closed.
 */
class UpdateAlarmReceiver : BroadcastReceiver() {
    companion object {
        const val TAG = "CinevaUpdateAlarm"
        const val ACTION_CHECK_UPDATE = "com.primadev.cineva.ACTION_CHECK_UPDATE"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.i(TAG, "Broadcast received with action: $action")
        try {
            when (action) {
                Intent.ACTION_BOOT_COMPLETED,
                Intent.ACTION_MY_PACKAGE_REPLACED -> {
                    UpdateCheckWorker.schedule(context.applicationContext)
                }
                ACTION_CHECK_UPDATE -> {
                    UpdateCheckWorker.checkNow(context.applicationContext)
                    UpdateCheckWorker.scheduleAlarmFallback(context.applicationContext)
                }
            }
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to handle update broadcast: ${t.message}", t)
        }
    }
}

