abstract class PhoneNumberUtils {
  /// Normalises a raw phone number string to E.164 format.
  /// Returns null if the input cannot be parsed.
  static String? toE164(String raw, {String defaultCountryCode = '+1'}) {
    // Strip all non-digit characters except leading +
    var digits = raw.replaceAll(RegExp(r'[^\d+]'), '');

    if (digits.startsWith('+')) return digits.length >= 8 ? digits : null;

    // Remove leading 0 (trunk prefix used in many countries)
    if (digits.startsWith('0')) digits = digits.substring(1);

    if (digits.isEmpty) return null;
    return '$defaultCountryCode$digits';
  }

  static String mask(String e164) {
    if (e164.length < 7) return '***';
    return '${e164.substring(0, e164.length - 4)}****';
  }

  static bool isValid(String e164) {
    return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(e164);
  }
}
