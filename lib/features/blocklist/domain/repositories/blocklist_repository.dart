import '../entities/blocked_number.dart';

abstract interface class BlocklistRepository {
  Future<List<BlockedNumber>> getAll();
  Future<bool> isBlocked(String phoneNumber);
  Future<void> block(String phoneNumber, {String? label});
  Future<void> unblock(String phoneNumber);
}
