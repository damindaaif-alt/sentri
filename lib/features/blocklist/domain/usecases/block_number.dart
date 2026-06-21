import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../repositories/blocklist_repository.dart';

@injectable
class BlockNumber {
  final BlocklistRepository _repository;
  const BlockNumber(this._repository);

  Future<Failure?> call(String phoneNumber, {String? label}) async {
    try {
      await _repository.block(phoneNumber, label: label);
      return null;
    } on Exception catch (e) {
      return UnknownFailure(e.toString());
    }
  }
}
