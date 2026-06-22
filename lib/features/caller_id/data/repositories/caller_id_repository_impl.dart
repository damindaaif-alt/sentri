import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/caller_info.dart';
import '../../domain/repositories/caller_id_repository.dart';
import '../datasources/caller_id_local_datasource.dart';
import '../datasources/caller_id_remote_datasource.dart';
import '../datasources/contacts_datasource.dart';

@Injectable(as: CallerIdRepository)
class CallerIdRepositoryImpl implements CallerIdRepository {
  final CallerIdRemoteDataSource _remote;
  final CallerIdLocalDataSource _local;
  final ContactsDataSource _contacts;

  const CallerIdRepositoryImpl(this._remote, this._local, this._contacts);

  @override
  Future<(CallerInfo, Failure?)> lookup(String phoneNumber) async {
    // Device contacts take priority — a saved contact is always trusted.
    final contactName = await _contacts.findByNumber(phoneNumber);
    if (contactName != null) {
      return (CallerInfo(
        phoneNumber: phoneNumber,
        name: contactName,
        riskScore: 0,
        category: RiskCategory.safe,
        spoofingStatus: SpoofingStatus.unknown,
        reportCount: 0,
        evidenceTags: const ['in_contacts'],
      ), null);
    }

    final cached = await _local.getCached(phoneNumber);
    if (cached != null) return (cached.toDomain(), null);

    try {
      final model = await _remote.lookup(phoneNumber);
      await _local.cache(model);
      return (model.toDomain(), null);
    } on DioException catch (e) {
      final fallback = _unknown(phoneNumber);
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return (fallback, const NetworkFailure());
      }
      final code = e.response?.statusCode;
      return (fallback, ServerFailure(statusCode: code));
    } catch (_) {
      // Parsing or unexpected error — still render the detail page
      return (_unknown(phoneNumber), const UnknownFailure());
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

  static CallerInfo _unknown(String phoneNumber) => CallerInfo(
        phoneNumber: phoneNumber,
        riskScore: 0,
        category: RiskCategory.unknown,
        spoofingStatus: SpoofingStatus.unknown,
        reportCount: 0,
      );
}
