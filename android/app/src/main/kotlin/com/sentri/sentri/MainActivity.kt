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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openCallScreeningSettings" -> openCallScreeningSettings(result)
                "isDefaultCallScreeningApp" -> result.success(isDefaultCallScreeningApp())
                else -> result.notImplemented()
            }
        }
    }

    private fun isDefaultCallScreeningApp(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            return roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
        }
        return false
    }

    private fun openCallScreeningSettings(result: MethodChannel.Result) {
        val isSamsung = Build.MANUFACTURER.lowercase() == "samsung"

        // Samsung One UI locks ROLE_CALL_SCREENING to its own dialer.
        // Skip the role request on Samsung and use manual fallback instead.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && !isSamsung) {
            val roleManager = getSystemService(RoleManager::class.java)
            if (roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
                startActivity(
                    roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                )
                result.success("role_manager")
                return
            }
        }

        // Open Default Apps settings — works on Samsung One UI; Flutter shows manual steps
        try {
            startActivity(
                Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            )
            result.success(if (isSamsung) "samsung_manual" else "default_apps")
        } catch (e: Exception) {
            result.error("UNAVAILABLE", e.message, null)
        }
    }
}
