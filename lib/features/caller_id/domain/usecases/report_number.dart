import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/caller_info.dart';
import '../repositories/caller_id_repository.dart';

@injectable
class ReportNumber {
  final CallerIdRepository _repository;
  const ReportNumber(this._repository);

  Future<Failure?> call({
    required String phoneNumber,
    required RiskCategory category,
    String? note,
  }) async {
    try {
      await _repository.reportNumber(
        phoneNumber: phoneNumber,
        category: category,
        note: note,
      );
      return null;
    } on Exception catch (e) {
      return UnknownFailure(e.toString());
    }
  }
}
