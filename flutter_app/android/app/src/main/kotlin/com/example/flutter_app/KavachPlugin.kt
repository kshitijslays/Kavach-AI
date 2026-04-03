package com.example.flutter_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class KavachPlugin : FlutterPlugin {
    private var messengers = mutableSetOf<io.flutter.plugin.common.BinaryMessenger>()
    private var context: Context? = null
    private var isReceiverRegistered = false

    companion object {
        private var instance: KavachPlugin? = null
        
        fun getInstance(): KavachPlugin {
            if (instance == null) {
                instance = KavachPlugin()
            }
            return instance!!
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val app = binding.applicationContext
        context = app
        messengers.add(binding.binaryMessenger)
        
        Log.d("KavachPlugin", "KavachPlugin attached to engine. Total engines: ${messengers.size}")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        messengers.remove(binding.binaryMessenger)
        Log.d("KavachPlugin", "KavachPlugin detached from engine. Remaining engines: ${messengers.size}")
        
        if (messengers.isEmpty()) {
            // We only unregister if NO more engines are attached
            // Actually, for power button trigger we might want to keep it alive via the service
            // context?.unregisterReceiver(screenReceiver)
            // isReceiverRegistered = false
        }
    }

    private var lastSOSNotifyTime: Long = 0
    private val SOS_COOLDOWN_MS: Long = 5000

    fun triggerSOSFromNative() {
        Log.d("KavachPlugin", "SOS trigger received from native code")
        triggerSOS()
    }

    private fun triggerSOS() {
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastSOSNotifyTime < SOS_COOLDOWN_MS) {
            Log.d("KavachPlugin", "SOS trigger ignored (cooldown active)")
            return
        }
        lastSOSNotifyTime = currentTime

        Log.d("KavachPlugin", "Triggering SOS via ${messengers.size} engines")
        
        // 1. Notify through all registered MethodChannels
        for (messenger in messengers) {
            try {
                MethodChannel(messenger, "com.example.kavach/sos").invokeMethod("trigger_sos", null)
            } catch (e: Exception) {
                Log.e("KavachPlugin", "Failed to trigger SOS on an engine", e)
            }
        }
        
        // Broadcast removed to prevent infinite loop with KavachSOSReceiver
    }
}
