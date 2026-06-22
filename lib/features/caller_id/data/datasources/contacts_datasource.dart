import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

abstract interface class ContactsDataSource {
  /// Returns the contact's display name if the number matches a saved contact,
  /// or null if not found or contacts permission has not been granted.
  Future<String?> findByNumber(String e164);
}

@Injectable(as: ContactsDataSource)
class ContactsDataSourceImpl implements ContactsDataSource {
  @override
  Future<String?> findByNumber(String e164) async {
    // Don't request permission mid-lookup — only use contacts if already granted.
    if (!await Permission.contacts.isGranted) return null;

    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final target = _last9(e164);

    for (final contact in contacts) {
      for (final phone in contact.phones) {
        final digits = phone.number.replaceAll(RegExp(r'\D'), '');
        if (digits.length >= 9 &&
            digits.substring(digits.length - 9) == target) {
          return contact.displayName;
        }
      }
    }
    return null;
  }

  static String _last9(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    return digits.length > 9 ? digits.substring(digits.length - 9) : digits;
  }
}
