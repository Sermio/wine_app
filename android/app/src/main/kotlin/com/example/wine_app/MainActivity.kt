package com.smt.wine_app

import android.content.Context
import android.content.SharedPreferences
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "flutter_shared_preferences"
    private lateinit var sharedPreferences: SharedPreferences

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        sharedPreferences = getSharedPreferences("flutter_shared_preferences", Context.MODE_PRIVATE)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getString" -> {
                    val key = call.argument<String>("key") ?: call.arguments as String
                    val value = sharedPreferences.getString(key, null)
                    result.success(value)
                }
                "setString" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<String>("value")
                    if (key != null && value != null) {
                        sharedPreferences.edit().putString(key, value).apply()
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Key and value must not be null", null)
                    }
                }
                "remove" -> {
                    val key = call.argument<String>("key") ?: call.arguments as String
                    sharedPreferences.edit().remove(key).apply()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
