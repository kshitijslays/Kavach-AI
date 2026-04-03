package com.example.flutter_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.util.Log

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Correct way to add a singleton plugin instance
        flutterEngine.plugins.add(KavachPlugin.getInstance())
        Log.d("MainActivity", "KavachPlugin registered in Flutter engine")
    }
}
