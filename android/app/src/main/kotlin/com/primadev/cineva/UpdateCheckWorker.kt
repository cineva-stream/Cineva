package com.primadev.cineva

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit

class UpdateCheckWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    companion object {
        const val TAG = "CinevaUpdateWorker"
        const val CHANNEL_ID = "cineva_app_updates"
        const val NOTIFICATION_ID = 9901
        const val PREFS_NAME = "cineva_update_prefs"
        const val KEY_LAST_NOTIFIED = "last_notified_version"
        const val KEY_LAST_NOTIFIED_TIME = "last_notified_timestamp"
        const val WORK_NAME = "CinevaUpdateCheckWork"
        private const val GITHUB_API_URL = "https://api.github.com/repos/cineva-stream/Cineva/releases/latest"

        /**
         * Schedules multi-layered background update checks:
         * 1. 15-minute periodic WorkManager (minimum allowed by Android)
         * 2. Short-delay OneTimeWorkRequest (executes ~2m after scheduling, ensuring fast checks after app is backgrounded)
         * 3. AlarmManager safety fallback against aggressive OEM task killers
         */
        fun schedule(context: Context) {
            try {
                val constraints = Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()

                // Layer 1: Frequent 15-minute Periodic WorkManager with flex interval
                val periodicWorkRequest = PeriodicWorkRequestBuilder<UpdateCheckWorker>(
                    15, TimeUnit.MINUTES,
                    5, TimeUnit.MINUTES
                )
                    .setConstraints(constraints)
                    .build()

                WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                    WORK_NAME,
                    ExistingPeriodicWorkPolicy.UPDATE,
                    periodicWorkRequest
                )
                Log.i(TAG, "Periodic WorkManager update check scheduled (15m interval)")

                // Layer 2: Fast one-time check (runs 2 minutes after scheduling)
                val oneTimeRequest = OneTimeWorkRequestBuilder<UpdateCheckWorker>()
                    .setConstraints(constraints)
                    .setInitialDelay(2, TimeUnit.MINUTES)
                    .build()

                WorkManager.getInstance(context).enqueueUniqueWork(
                    "${WORK_NAME}_OneTime",
                    ExistingWorkPolicy.REPLACE,
                    oneTimeRequest
                )
                Log.i(TAG, "One-time fast background check scheduled (2m initial delay)")

                // Layer 3: AlarmManager fallback for OEM background killer survival
                scheduleAlarmFallback(context)
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to schedule background update check: ${t.message}", t)
            }
        }

        /**
         * Fallback scheduler using Android AlarmManager.
         * Wakes up every 30 minutes to ensure background check runs even if WorkManager is restricted by OEM.
         */
        fun scheduleAlarmFallback(context: Context) {
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                    ?: return

                val intent = Intent(context, UpdateAlarmReceiver::class.java).apply {
                    action = UpdateAlarmReceiver.ACTION_CHECK_UPDATE
                }

                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    9902,
                    intent,
                    flags
                )

                val triggerAt = System.currentTimeMillis() + TimeUnit.MINUTES.toMillis(30)
                val interval = TimeUnit.MINUTES.toMillis(30)

                alarmManager.setInexactRepeating(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    interval,
                    pendingIntent
                )
                Log.i(TAG, "AlarmManager fallback scheduled (every 30m)")
            } catch (t: Throwable) {
                Log.w(TAG, "Non-fatal: Failed to schedule AlarmManager fallback: ${t.message}")
            }
        }

        /**
         * Triggers an immediate one-time background check.
         */
        fun checkNow(context: Context) {
            try {
                val constraints = Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()

                val oneTimeRequest = OneTimeWorkRequestBuilder<UpdateCheckWorker>()
                    .setConstraints(constraints)
                    .build()

                WorkManager.getInstance(context).enqueue(oneTimeRequest)
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to trigger update check now: ${t.message}", t)
            }
        }

        /**
         * Creates the notification channel and displays a dynamic update notification.
         */
        fun showNotification(
            context: Context,
            version: String,
            title: String,
            body: String
        ) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Pembaruan Cineva",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifikasi pembaruan versi terbaru aplikasi Cineva"
                    enableLights(true)
                    enableVibration(true)
                    setShowBadge(true)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
                notificationManager.createNotificationChannel(channel)
            }

            val launchIntent = (context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("from_update_notification", true)
                putExtra("update_version", version)
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            val isIndonesian = try {
                val lang = java.util.Locale.getDefault().language.lowercase()
                lang == "in" || lang == "id"
            } catch (_: Throwable) {
                true
            }

            val defaultMessage = if (isIndonesian) {
                "Update Tersedia, Segera update sekarang untuk menikmati layanan streaming dengan lebih baik."
            } else {
                "New version available, Update now to improve your streaming."
            }

            val cleanBody = if (body.isNotBlank() && (body.contains("Update") || body.contains("streaming") || body.contains("stream"))) {
                body
            } else {
                defaultMessage
            }

            val displayTitle = if (title.isNotEmpty() && !title.startsWith("https://")) {
                title
            } else {
                if (isIndonesian) "Pembaruan Cineva v$version Tersedia! 🎬" else "Cineva v$version Update Available! 🎬"
            }

            val largeIconBitmap = try {
                BitmapFactory.decodeResource(context.resources, R.drawable.logo_cineva)
            } catch (_: Throwable) {
                null
            }

            val notificationBuilder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.logo_cineva)
                .setContentTitle(displayTitle)
                .setContentText(cleanBody)
                .setStyle(
                    NotificationCompat.BigTextStyle()
                        .bigText(cleanBody)
                        .setBigContentTitle(displayTitle)
                        .setSummaryText("Cineva v$version")
                )
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setColor(0xFFF59E0B.toInt()) // Cineva Gold / Primary
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .addAction(
                    R.drawable.logo_cineva,
                    if (isIndonesian) "Perbarui Sekarang" else "Update Now",
                    pendingIntent
                )

            if (largeIconBitmap != null) {
                notificationBuilder.setLargeIcon(largeIconBitmap)
            }

            val notification = notificationBuilder.build()

            try {
                NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
                Log.i(TAG, "Update notification successfully posted for v$version")
            } catch (e: SecurityException) {
                Log.w(TAG, "Notification permission missing: ${e.message}")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to post notification: ${e.message}", e)
            }
        }

        /**
         * Semantic version comparison: returns true if remoteVer > currentVer.
         */
        fun isVersionNewer(remoteVer: String, currentVer: String): Boolean {
            try {
                val cleanRemote = remoteVer.lowercase().replace(Regex("[^0-9.]"), "")
                val cleanCurrent = currentVer.lowercase().replace(Regex("[^0-9.]"), "")

                val rParts = cleanRemote.split(".").map { it.toIntOrNull() ?: 0 }
                val cParts = cleanCurrent.split(".").map { it.toIntOrNull() ?: 0 }

                val maxLen = maxOf(rParts.size, cParts.size)
                for (i in 0 until maxLen) {
                    val r = if (i < rParts.size) rParts[i] else 0
                    val c = if (i < cParts.size) cParts[i] else 0
                    if (r > c) return true
                    if (r < c) return false
                }
                return false
            } catch (_: Exception) {
                return false
            }
        }
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            Log.i(TAG, "Starting background update check against GitHub API...")
            val currentVersion = context.packageManager
                .getPackageInfo(context.packageName, 0)
                .versionName ?: "1.0.0"

            val url = URL(GITHUB_API_URL)
            val connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = 15000
                readTimeout = 15000
                setRequestProperty("Accept", "application/vnd.github.v3+json")
                setRequestProperty("User-Agent", "Cineva-Android-App")
            }

            if (connection.responseCode != 200) {
                Log.w(TAG, "GitHub API returned code: ${connection.responseCode}")
                return@withContext Result.retry()
            }

            val responseText = connection.inputStream.use { stream ->
                BufferedReader(InputStreamReader(stream)).readText()
            }

            val json = JSONObject(responseText)
            val tagName = json.optString("tag_name", "")
            val cleanRemoteVersion = tagName.replaceFirst(Regex("^[vV]"), "").trim()

            if (cleanRemoteVersion.isEmpty()) {
                Log.i(TAG, "No valid tag_name found in release payload.")
                return@withContext Result.success()
            }

            if (!isVersionNewer(cleanRemoteVersion, currentVersion)) {
                Log.i(TAG, "App is up to date (Current: $currentVersion, Remote: $cleanRemoteVersion).")
                return@withContext Result.success()
            }

            // Cooldown check:
            // Alert user immediately when new release is detected.
            // If already notified for this exact version, only re-notify after 4 hours
            // if the user has still not updated the app.
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val lastNotified = prefs.getString(KEY_LAST_NOTIFIED, null)
            val lastNotifiedTime = prefs.getLong(KEY_LAST_NOTIFIED_TIME, 0L)
            val currentTime = System.currentTimeMillis()
            val fourHoursMs = TimeUnit.HOURS.toMillis(4)

            val shouldNotify = (lastNotified != cleanRemoteVersion) ||
                    (currentTime - lastNotifiedTime > fourHoursMs)

            if (!shouldNotify) {
                Log.i(TAG, "Notification for v$cleanRemoteVersion is within cooldown interval.")
                return@withContext Result.success()
            }

            val releaseTitle = json.optString("name", "Cineva v$cleanRemoteVersion")
            val changelogBody = json.optString("body", "")

            showNotification(
                context = context,
                version = cleanRemoteVersion,
                title = releaseTitle,
                body = ""
            )

            // Mark this version as notified and record timestamp
            prefs.edit()
                .putString(KEY_LAST_NOTIFIED, cleanRemoteVersion)
                .putLong(KEY_LAST_NOTIFIED_TIME, currentTime)
                .apply()
            Log.i(TAG, "Background update check completed: notification shown for v$cleanRemoteVersion")

            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Exception during background update check: ${e.message}", e)
            Result.retry()
        }
    }
}
