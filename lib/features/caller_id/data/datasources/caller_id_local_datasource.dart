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
    final payload = await _db.getCachedCaller(phoneNumber);
    if (payload == null) return null;
    return CallerInfoModel.fromJson(payload);
  }

  @override
  Future<void> cache(CallerInfoModel model) =>
      _db.cacheCaller(model.phoneNumber, model.toJson());

  @override
  Future<void> invalidate(String phoneNumber) =>
      _db.invalidateCallerCache(phoneNumber);
}
