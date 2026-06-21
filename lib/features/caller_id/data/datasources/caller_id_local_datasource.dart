import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/sentri_database.dart';
import '../models/caller_info_model.dart';

abstract interface class CallerIdLocalDataSource {
  Future<CallerInfoModel?> getCached(String phoneNumber);
  Future<void> cache(CallerInfoModel model);
  Future<void> invalidate(String phoneNumber);
}

@Injectable(as: CallerIdLocalDataSource)
class CallerIdLocalDataSourceImpl implements CallerIdLocalDataSource {
  final SentriDatabase _db;
  const CallerIdLocalDataSourceImpl(this._db);

  @override
  Future<CallerInfoModel?> getCached(String phoneNumber) async {
    final row = await (_db.select(_db.callerCache)
          ..where((t) => t.phoneNumber.equals(phoneNumber))
          ..where(
            (t) => t.cachedAt.isBiggerThanValue(
              DateTime.now().subtract(const Duration(hours: 1)),
            ),
          ))
        .getSingleOrNull();

    if (row == null) return null;
    return CallerInfoModel.fromJson(row.payload);
  }

  @override
  Future<void> cache(CallerInfoModel model) async {
    await _db.into(_db.callerCache).insertOnConflictUpdate(
          CallerCacheCompanion.insert(
            phoneNumber: model.phoneNumber,
            payload: model.toJson(),
            cachedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> invalidate(String phoneNumber) async {
    await (_db.delete(_db.callerCache)
          ..where((t) => t.phoneNumber.equals(phoneNumber)))
        .go();
  }
}
