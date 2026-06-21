import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/threat_entry.dart';
import '../repositories/threat_feed_repository.dart';

@injectable
class GetThreatFeed {
  final ThreatFeedRepository _repository;
  const GetThreatFeed(this._repository);

  Future<(List<ThreatEntry>?, Failure?)> call() async {
    try {
      final entries = await _repository.getLatest();
      return (entries, null);
    } on Exception catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
