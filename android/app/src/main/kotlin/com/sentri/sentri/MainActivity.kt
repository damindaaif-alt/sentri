package com.sentri.sentri

import android.app.role.RoleManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.widget.Toast
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
        // Strategy 1: Android 10+ RoleManager (standard AOSP, works on Pixel/stock)
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

        // Strategy 2: Direct app settings page (works on Samsung One UI)
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success("app_settings")
            return
        } catch (_: Exception) {}

        // Strategy 3: Default apps settings (last resort)
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
