package com.sentri.app

import android.database.sqlite.SQLiteDatabase
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log

class SentriCallScreeningService : CallScreeningService() {

    companion object {
        private const val TAG = "SentriScreening"
    }

    override fun onScreenCall(callDetails: Call.Details) {
        val rawNumber = callDetails.handle?.schemeSpecificPart
        if (rawNumber.isNullOrBlank()) {
            allow(callDetails)
            return
        }

        Log.d(TAG, "Screening: $rawNumber")

        val blocked = queryBlocklist(rawNumber)
        Log.i(TAG, "$rawNumber → ${if (blocked) "BLOCK" else "allow"}")

        val response = if (blocked) {
            CallResponse.Builder()
                .setRejectCall(true)
                .setDisallowCall(true)
                .setSkipCallLog(false)   // still record it
                .setSkipNotification(false)
                .build()
        } else {
            CallResponse.Builder()
                .setRejectCall(false)
                .setDisallowCall(false)
                .build()
        }
        respondToCall(callDetails, response)
    }

    private fun allow(callDetails: Call.Details) {
        respondToCall(callDetails, CallResponse.Builder().setRejectCall(false).build())
    }

    /**
     * Queries the sqflite DB written by the Flutter layer.
     *
     * Matching strategy: compare the last 9 digits of both the incoming
     * number and each stored number so that local (0771234567) and
     * international (+94771234567) formats of the same number match.
     */
    private fun queryBlocklist(incomingRaw: String): Boolean {
        val incomingKey = last9Digits(incomingRaw)
        if (incomingKey.isEmpty()) return false

        return try {
            val dbPath = getDatabasePath("sentri.db").absolutePath
            val db = SQLiteDatabase.openDatabase(
                dbPath, null, SQLiteDatabase.OPEN_READONLY
            )
            val cursor = db.rawQuery(
                """
                SELECT phone_number FROM blocked_numbers
                """.trimIndent(),
                null
            )
            var found = false
            while (cursor.moveToNext()) {
                val stored = cursor.getString(0) ?: continue
                if (last9Digits(stored) == incomingKey) {
                    found = true
                    break
                }
            }
            cursor.close()
            db.close()
            found
        } catch (e: Exception) {
            Log.e(TAG, "DB query failed: ${e.message}")
            false
        }
    }

    // Same normalisation as Dart PhoneNumberUtils / dedup logic
    private fun last9Digits(number: String): String {
        val digits = number.filter { it.isDigit() }
        return if (digits.length > 9) digits.takeLast(9) else digits
    }
}
