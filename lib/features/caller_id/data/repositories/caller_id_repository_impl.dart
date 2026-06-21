import 'package:injectable/injectable.dart';

import '../../domain/entities/caller_info.dart';
import '../../domain/repositories/caller_id_repository.dart';
import '../datasources/caller_id_local_datasource.dart';
import '../datasources/caller_id_remote_datasource.dart';

@Injectable(as: CallerIdRepository)
class CallerIdRepositoryImpl implements CallerIdRepository {
  final CallerIdRemoteDataSource _remote;
  final CallerIdLocalDataSource _local;

  const CallerIdRepositoryImpl(this._remote, this._local);

  @override
  Future<CallerInfo> lookup(String phoneNumber) async {
    final cached = await _local.getCached(phoneNumber);
    if (cached != null) return cached.toDomain();

    try {
      final model = await _remote.lookup(phoneNumber);
      await _local.cache(model);
      return model.toDomain();
    } catch (_) {
      // No cache and no network — return an unscored unknown caller so the
      // detail page still renders with block/report actions available.
      return CallerInfo(
        phoneNumber: phoneNumber,
        riskScore: 0,
        category: RiskCategory.unknown,
        spoofingStatus: SpoofingStatus.unknown,
        reportCount: 0,
      );
    }
  }

  @override
  Future<void> reportNumber({
    required String phoneNumber,
    required RiskCategory category,
    String? note,
  }) async {
    await _remote.reportNumber(
      phoneNumber: phoneNumber,
      category: category.name,
      note: note,
    );
    await _local.invalidate(phoneNumber);
  }

  @override
  Future<void> invalidateCache(String phoneNumber) =>
      _local.invalidate(phoneNumber);
}
