import 'package:injectable/injectable.dart';

import '../../../../core/database/sentri_database.dart';
import '../../../../core/platform/call_directory_sync.dart';
import '../../domain/entities/blocked_number.dart';
import '../../domain/repositories/blocklist_repository.dart';

@Injectable(as: BlocklistRepository)
class BlocklistRepositoryImpl implements BlocklistRepository {
  final SentriDatabase _db;
  const BlocklistRepositoryImpl(this._db);

  @override
  Future<List<BlockedNumber>> getAll() async {
    final rows = await _db.getAllBlockedNumbers();
    return rows.map((r) => BlockedNumber(
          id: r['id'] as int,
          phoneNumber: r['phone_number'] as String,
          label: r['label'] as String?,
          isPermanent: (r['is_permanent'] as int) == 1,
          blockedAt: DateTime.fromMillisecondsSinceEpoch(r['blocked_at'] as int),
        )).toList();
  }

  @override
  Future<bool> isBlocked(String phoneNumber) => _db.isBlocked(phoneNumber);

  @override
  Future<void> block(String phoneNumber, {String? label}) async {
    await _db.blockNumber(phoneNumber, label: label);
    await _syncExtension();
  }

  @override
  Future<void> unblock(String phoneNumber) async {
    await _db.unblockNumber(phoneNumber);
    await _syncExtension();
  }

  Future<void> _syncExtension() async {
    final rows = await _db.getAllBlockedNumbers();
    final numbers = rows
        .map((r) => r['phone_number'] as String)
        .toList();
    await CallDirectorySync.sync(blockedNumbers: numbers);
  }
}
