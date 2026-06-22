import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/phone_number_utils.dart';
import '../entities/caller_info.dart';
import '../repositories/caller_id_repository.dart';

@injectable
class LookupCaller {
  final CallerIdRepository _repository;
  const LookupCaller(this._repository);

  Future<(CallerInfo?, Failure?)> call(
    String rawNumber, {
    String countryCode = '+1',
  }) async {
    final e164 = PhoneNumberUtils.toE164(rawNumber, defaultCountryCode: countryCode);
    if (e164 == null) {
      return (null, const UnknownFailure('Invalid phone number format.'));
    }

    try {
      final (info, failure) = await _repository.lookup(e164);
      return (info, failure);
    } on Exception catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
