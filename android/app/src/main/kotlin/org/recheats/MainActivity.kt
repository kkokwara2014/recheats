package org.recheats

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createOrderNotificationChannel()
    }

    private fun createOrderNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            ORDER_CHANNEL_ID,
            "Order updates",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Status updates for your RechEats orders"
            enableVibration(true)
        }

        val manager = getSystemService(NotificationManager::class.java)
        manager?.createNotificationChannel(channel)
    }

    companion object {
        const val ORDER_CHANNEL_ID = "recheats_orders"
    }
}
