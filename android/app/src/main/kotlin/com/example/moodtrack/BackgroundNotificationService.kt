package com.example.moodtrack

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.example.moodtrack.R

class BackgroundNotificationService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var count = 0
    private val maxCount = 30
    private val interval: Long = 30000 // 30 seconds

    private val messages = listOf(
        "Cizer loves you! ❤️",
        "What are you doing? Thinking of you!",
        "You are amazing! ✨",
        "Just a little reminder that you are special.",
        "How is your mood today? Hope it is great!",
        "Drink some water! \uD83E\uDD64",
        "Take a deep breath. \uD83D\uDE0C"
    )

    private val runnable = object : Runnable {
        override fun run() {
            if (count >= maxCount) {
                stopSelf()
                return
            }
            sendNotification()
            count++
            handler.postDelayed(this, interval)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification = createForegroundNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(1, notification)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        count = 0
        handler.removeCallbacks(runnable)
        handler.postDelayed(runnable, interval)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(runnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                "BackgroundServiceChannel",
                "Background Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            
            val alertChannel = NotificationChannel(
                "instant_channel", 
                "Instant Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
            manager.createNotificationChannel(alertChannel)
        }
    }

    private fun createForegroundNotification(): Notification {
        return NotificationCompat.Builder(this, "BackgroundServiceChannel")
            .setContentTitle("MoodTrack Service")
            .setContentText("Keeping track of notifications")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()
    }

    private fun sendNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val message = messages.random()
        
        val notification = NotificationCompat.Builder(this, "instant_channel")
            .setContentTitle("MoodTrack Alert")
            .setContentText(message)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
            
        manager.notify((System.currentTimeMillis() % 10000).toInt(), notification)
    }
}
