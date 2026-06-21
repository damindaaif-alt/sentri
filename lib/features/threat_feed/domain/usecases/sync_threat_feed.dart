import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/threat_entry.dart';
import '../repositories/threat_feed_repository.dart';

@injectable
class SyncThreatFeed {
  final ThreatFeedRepository _repository;
  const SyncThreatFeed(this._repository);

  Future<(List<ThreatEntry>?, Failure?)> call() async {
    try {
      final entries = await _repository.sync();
      return (entries, null);
    } on Exception catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
