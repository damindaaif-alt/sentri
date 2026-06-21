import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/call_record.dart';
import '../repositories/call_log_repository.dart';

@injectable
class GetCallLog {
  final CallLogRepository _repository;
  const GetCallLog(this._repository);

  Future<(List<CallRecord>, Failure?)> call({int limit = 100}) async {
    try {
      final records = await _repository.getRecent(limit: limit);
      return (records, null);
    } on Exception catch (e) {
      return (const <CallRecord>[], UnknownFailure(e.toString()));
    }
  }
}
