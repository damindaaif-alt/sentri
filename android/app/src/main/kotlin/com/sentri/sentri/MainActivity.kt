package com.sentri.sentri

import android.app.role.RoleManager
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.sentri.sentri/settings"

    private val isSamsung get() = Build.MANUFACTURER.lowercase() == "samsung"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openCallScreeningSettings" -> openCallScreeningSettings(result)
                "isDefaultCallScreeningApp" -> result.success(isDefaultCallScreeningApp())
                "getDeviceInfo" -> result.success(mapOf("manufacturer" to Build.MANUFACTURER))
                else -> result.notImplemented()
            }
        }
    }

    private fun isDefaultCallScreeningApp(): Boolean {
        if (isSamsung) return false // Samsung locks this role to its own Phone app
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            return roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
        }
        return false
    }

    private fun openCallScreeningSettings(result: MethodChannel.Result) {
        if (isSamsung) {
            // Samsung One UI locks ROLE_CALL_SCREENING to its own dialer.
            // Signal Flutter to show an explanation dialog instead.
            result.success("samsung_unsupported")
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            if (roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
                startActivity(
                    roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                )
                result.success("role_manager")
                return
            }
        }

        try {
            startActivity(
                Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            )
            result.success("default_apps")
        } catch (e: Exception) {
            result.error("UNAVAILABLE", e.message, null)
        }
    }
}
