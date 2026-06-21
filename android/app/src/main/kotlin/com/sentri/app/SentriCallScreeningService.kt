package com.sentri.app

import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log

/**
 * Android call screening service.
 *
 * Registered in AndroidManifest.xml as the default call screening app.
 * The Flutter engine is not running at screening time, so risk decisions
 * are made against a locally persisted blocklist written by the Dart layer
 * via shared SQLite (accessed via Room in a background process, or via
 * direct SQLite queries here).
 *
 * Production implementation: query the Drift DB file directly with
 * SupportSQLiteOpenHelper, or use a ContentProvider bridge.
 */
class SentriCallScreeningService : CallScreeningService() {

    companion object {
        private const val TAG = "SentriScreening"
    }

    override fun onScreenCall(callDetails: Call.Details) {
        val number = callDetails.handle?.schemeSpecificPart ?: run {
            allowCall(callDetails)
            return
        }

        Log.d(TAG, "Screening call from: $number")

        val decision = if (isBlocked(number)) {
            Log.i(TAG, "Blocking $number — found in local blocklist")
            CallResponse.Builder()
                .setRejectCall(true)
                .setDisallowCall(true)
                .setSkipCallLog(false)
                .setSkipNotification(false)
                .build()
        } else {
            CallResponse.Builder()
                .setRejectCall(false)
                .setDisallowCall(false)
                .build()
        }

        respondToCall(callDetails, decision)
    }

    private fun allowCall(callDetails: Call.Details) {
        respondToCall(
            callDetails,
            CallResponse.Builder().setRejectCall(false).build(),
        )
    }

    /**
     * Query the local SQLite blocklist written by the Flutter/Drift layer.
     * Replace with a proper DB helper in production.
     */
    private fun isBlocked(number: String): Boolean {
        return try {
            val dbPath = getDatabasePath("sentri.db").absolutePath
            val db = android.database.sqlite.SQLiteDatabase.openDatabase(
                dbPath,
                null,
                android.database.sqlite.SQLiteDatabase.OPEN_READONLY,
            )
            val cursor = db.rawQuery(
                "SELECT 1 FROM blocked_numbers WHERE phone_number = ? LIMIT 1",
                arrayOf(number),
            )
            val found = cursor.moveToFirst()
            cursor.close()
            db.close()
            found
        } catch (e: Exception) {
            Log.e(TAG, "DB query failed for $number: ${e.message}")
            false
        }
    }
}
