import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/sentri_database.dart';
import '../../domain/entities/blocked_number.dart';
import '../../domain/repositories/blocklist_repository.dart';

@Injectable(as: BlocklistRepository)
class BlocklistRepositoryImpl implements BlocklistRepository {
  final SentriDatabase _db;
  const BlocklistRepositoryImpl(this._db);

  @override
  Future<List<BlockedNumber>> getAll() async {
    final rows = await _db.select(_db.blockedNumbers).get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<bool> isBlocked(String phoneNumber) async {
    final row = await (_db.select(_db.blockedNumbers)
          ..where((t) => t.phoneNumber.equals(phoneNumber)))
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> block(String phoneNumber, {String? label}) async {
    await _db.into(_db.blockedNumbers).insertOnConflictUpdate(
          BlockedNumbersCompanion.insert(
            phoneNumber: phoneNumber,
            label: Value(label),
            blockedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> unblock(String phoneNumber) async {
    await (_db.delete(_db.blockedNumbers)
          ..where((t) => t.phoneNumber.equals(phoneNumber)))
        .go();
  }

  BlockedNumber _toEntity(BlockedNumber row) => row;
}
