package com.sentri.sentri

import android.app.role.RoleManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.sentri.sentri/settings"
    private val roleRequestCode = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openCallScreeningSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(RoleManager::class.java)
                        if (roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
                            startActivity(
                                roleManager.createRequestRoleIntent(
                                    RoleManager.ROLE_CALL_SCREENING
                                )
                            )
                            result.success(null)
                        } else {
                            // Fallback: open general default apps settings
                            startActivity(
                                android.content.Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
                            )
                            result.success(null)
                        }
                    } else {
                        startActivity(
                            android.content.Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
                        )
                        result.success(null)
                    }
                }

                "isDefaultCallScreeningApp" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(RoleManager::class.java)
                        result.success(roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING))
                    } else {
                        result.success(false)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
