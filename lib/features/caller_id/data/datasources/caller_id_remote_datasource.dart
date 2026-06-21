import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/dio_client.dart';
import '../models/caller_info_model.dart';

abstract interface class CallerIdRemoteDataSource {
  Future<CallerInfoModel> lookup(String phoneNumber);
  Future<void> reportNumber({
    required String phoneNumber,
    required String category,
    String? note,
  });
}

@Injectable(as: CallerIdRemoteDataSource)
class CallerIdRemoteDataSourceImpl implements CallerIdRemoteDataSource {
  final DioClient _client;
  const CallerIdRemoteDataSourceImpl(this._client);

  @override
  Future<CallerInfoModel> lookup(String phoneNumber) async {
    final response = await _client.instance.get(
      '/caller/lookup',
      queryParameters: {'number': phoneNumber},
    );
    return CallerInfoModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> reportNumber({
    required String phoneNumber,
    required String category,
    String? note,
  }) async {
    await _client.instance.post(
      '/caller/report',
      data: {
        'phone_number': phoneNumber,
        'category': category,
        if (note != null) 'note': note,
      },
    );
  }
}
