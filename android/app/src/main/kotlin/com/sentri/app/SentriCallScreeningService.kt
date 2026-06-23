package com.sentri.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log
import com.sentri.sentri.MainActivity

class SentriCallScreeningService : CallScreeningService() {

    companion object {
        private const val TAG             = "SentriScreening"
        private const val CH_BLOCKED      = "sentri_scam_blocked"
        private const val CH_HIGH_RISK    = "sentri_high_risk"
        private const val NOTIF_BLOCKED   = 1001
        private const val NOTIF_HIGH_RISK = 1002
        private const val WARN_THRESHOLD  = 40  // show warning, still allow
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        ensureNotificationChannels()
    }

    // ── Main entry point ──────────────────────────────────────────────────────

    override fun onScreenCall(callDetails: Call.Details) {
        val rawNumber = callDetails.handle?.schemeSpecificPart
        if (rawNumber.isNullOrBlank()) { allow(callDetails); return }

        Log.d(TAG, "Screening: $rawNumber")
        val decision = evaluateNumber(rawNumber)
        Log.i(TAG, "$rawNumber → score=${decision.riskScore} block=${decision.block} warn=${decision.warn} source=${decision.source}")

        when {
            decision.block -> {
                if (decision.notificationsEnabled) {
                    showBlockedNotification(rawNumber, decision.riskScore, decision.category)
                }
                respondToCall(callDetails, CallResponse.Builder()
                    .setRejectCall(true)
                    .setDisallowCall(true)
                    .setSkipCallLog(false)
                    .setSkipNotification(false)
                    .build())
            }
            decision.warn -> {
                if (decision.notificationsEnabled) {
                    showHighRiskNotification(rawNumber, decision.riskScore, decision.category)
                }
                allow(callDetails)
            }
            else -> allow(callDetails)
        }
    }

    // ── Decision engine ───────────────────────────────────────────────────────

    private data class Decision(
        val block: Boolean,
        val warn: Boolean,
        val riskScore: Int,
        val category: String,
        val source: String,
        val notificationsEnabled: Boolean = true,
    )

    private fun evaluateNumber(rawNumber: String): Decision {
        val last9 = last9Digits(rawNumber)
        if (last9.isEmpty()) return Decision(false, false, 0, "unknown", "none")

        return try {
            val dbPath = getDatabasePath("sentri.db").absolutePath
            SQLiteDatabase.openDatabase(dbPath, null, SQLiteDatabase.OPEN_READONLY).use { db ->
                val settings        = readSettings(db)
                val autoBlock       = settings["auto_block_high_risk"] == "true"
                val blockThreshold  = settings["block_threshold"]?.toIntOrNull() ?: 80
                val notifEnabled    = settings["notifications_enabled"] != "false"

                // 1. Explicit user blocklist — always block, regardless of settings
                if (isInBlocklist(db, last9)) {
                    return Decision(true, false, 100, "blocked", "blocklist", notifEnabled)
                }

                // 2. Threat intelligence feed (seeded + community reports from backend)
                val threatScore = highestRiskFromThreats(db, last9)
                if (threatScore != null) {
                    val (score, category) = threatScore
                    if (score >= blockThreshold) {
                        return Decision(true, false, score, category, "threat_feed", notifEnabled)
                    }
                    if (score >= WARN_THRESHOLD) {
                        return Decision(false, true, score, category, "threat_feed", notifEnabled)
                    }
                }

                // 3. Caller cache (numbers the user has previously looked up via the app)
                if (autoBlock) {
                    val cacheScore = highestRiskFromCache(db, last9)
                    if (cacheScore != null) {
                        val (score, category) = cacheScore
                        if (score >= blockThreshold) {
                            return Decision(true, false, score, category, "cache", notifEnabled)
                        }
                        if (score >= WARN_THRESHOLD) {
                            return Decision(false, true, score, category, "cache", notifEnabled)
                        }
                    }
                }

                Decision(false, false, 0, "unknown", "none", notifEnabled)
            }
        } catch (e: Exception) {
            Log.e(TAG, "DB evaluation failed: ${e.message}")
            Decision(false, false, 0, "unknown", "error")
        }
    }

    // ── DB helpers ────────────────────────────────────────────────────────────

    private fun readSettings(db: SQLiteDatabase): Map<String, String> {
        val map = mutableMapOf<String, String>()
        db.rawQuery("SELECT key, value FROM user_settings", null).use { c ->
            while (c.moveToNext()) map[c.getString(0)] = c.getString(1)
        }
        return map
    }

    private fun isInBlocklist(db: SQLiteDatabase, last9: String): Boolean {
        db.rawQuery("SELECT phone_number FROM blocked_numbers", null).use { c ->
            while (c.moveToNext()) {
                if (last9Digits(c.getString(0)) == last9) return true
            }
        }
        return false
    }

    private fun highestRiskFromThreats(db: SQLiteDatabase, last9: String): Pair<Int, String>? {
        var best: Pair<Int, String>? = null
        db.rawQuery("SELECT phone_number, risk_score, category FROM threat_entries", null).use { c ->
            while (c.moveToNext()) {
                if (last9Digits(c.getString(0)) == last9) {
                    val score = c.getInt(1)
                    if (best == null || score > best!!.first) best = Pair(score, c.getString(2))
                }
            }
        }
        return best
    }

    private fun highestRiskFromCache(db: SQLiteDatabase, last9: String): Pair<Int, String>? {
        var best: Pair<Int, String>? = null
        db.rawQuery("SELECT phone_number, payload FROM caller_cache", null).use { c ->
            while (c.moveToNext()) {
                if (last9Digits(c.getString(0)) == last9) {
                    val score    = extractInt(c.getString(1), "risk_score") ?: continue
                    val category = extractStr(c.getString(1), "category") ?: "unknown"
                    if (best == null || score > best!!.first) best = Pair(score, category)
                }
            }
        }
        return best
    }

    // Minimal JSON field extraction — avoids adding a JSON library dependency
    private fun extractInt(json: String, key: String): Int? =
        Regex(""""$key"\s*:\s*(\d+)""").find(json)?.groupValues?.get(1)?.toIntOrNull()

    private fun extractStr(json: String, key: String): String? =
        Regex(""""$key"\s*:\s*"([^"]+)"""").find(json)?.groupValues?.get(1)

    // ── Notifications ─────────────────────────────────────────────────────────

    private fun ensureNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(NotificationManager::class.java)

        nm.createNotificationChannel(NotificationChannel(
            CH_BLOCKED, "Scam calls blocked", NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Sentri silently rejected a known scam call"
            enableVibration(true)
        })

        nm.createNotificationChannel(NotificationChannel(
            CH_HIGH_RISK, "High-risk call warnings", NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Incoming call has a high scam risk score"
            enableVibration(true)
        })
    }

    private fun tapIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun showBlockedNotification(number: String, score: Int, category: String) {
        val label = category.replaceFirstChar { it.uppercaseChar() }
        notify(NOTIF_BLOCKED, Notification.Builder(this, CH_BLOCKED)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Scam call blocked")
            .setContentText("$number ($label · risk $score) was silently rejected")
            .setAutoCancel(true)
            .setContentIntent(tapIntent())
            .build())
    }

    private fun showHighRiskNotification(number: String, score: Int, category: String) {
        val label = category.replaceFirstChar { it.uppercaseChar() }
        notify(NOTIF_HIGH_RISK, Notification.Builder(this, CH_HIGH_RISK)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("High-risk call — answer with caution")
            .setContentText("$number may be a $label (risk score $score)")
            .setAutoCancel(true)
            .setContentIntent(tapIntent())
            .build())
    }

    private fun notify(id: Int, notification: Notification) {
        try {
            getSystemService(NotificationManager::class.java).notify(id, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Notification failed: ${e.message}")
        }
    }

    private fun allow(callDetails: Call.Details) =
        respondToCall(callDetails, CallResponse.Builder().setRejectCall(false).build())

    private fun last9Digits(number: String): String {
        val digits = number.filter { it.isDigit() }
        return if (digits.length > 9) digits.takeLast(9) else digits
    }
}
