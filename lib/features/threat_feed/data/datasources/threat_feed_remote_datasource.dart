import 'package:injectable/injectable.dart';

import '../../../../core/network/dio_client.dart';
import '../models/threat_entry_model.dart';

abstract interface class ThreatFeedRemoteDataSource {
  Future<List<ThreatEntryModel>> fetchLatest();
}

@Injectable(as: ThreatFeedRemoteDataSource)
class ThreatFeedRemoteDataSourceImpl implements ThreatFeedRemoteDataSource {
  final DioClient _client;
  const ThreatFeedRemoteDataSourceImpl(this._client);

  @override
  Future<List<ThreatEntryModel>> fetchLatest() async {
    final response = await _client.instance.get('/threats/latest');
    final list = response.data as List<dynamic>;
    return list
        .map((j) => ThreatEntryModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
