import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../repositories/blocklist_repository.dart';

@injectable
class UnblockNumber {
  final BlocklistRepository _repository;
  const UnblockNumber(this._repository);

  Future<Failure?> call(String phoneNumber) async {
    try {
      await _repository.unblock(phoneNumber);
      return null;
    } on Exception catch (e) {
      return UnknownFailure(e.toString());
    }
  }
}
