// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/blocklist/data/repositories/blocklist_repository_impl.dart'
    as _i82;
import '../../features/blocklist/domain/repositories/blocklist_repository.dart'
    as _i236;
import '../../features/blocklist/domain/usecases/block_number.dart' as _i200;
import '../../features/blocklist/domain/usecases/unblock_number.dart' as _i316;
import '../../features/blocklist/presentation/bloc/blocklist_bloc.dart'
    as _i692;
import '../../features/call_log/data/repositories/call_log_repository_impl.dart'
    as _i1027;
import '../../features/call_log/domain/repositories/call_log_repository.dart'
    as _i159;
import '../../features/call_log/domain/usecases/get_call_log.dart' as _i661;
import '../../features/call_log/presentation/bloc/call_log_bloc.dart' as _i54;
import '../../features/caller_id/data/datasources/caller_id_local_datasource.dart'
    as _i555;
import '../../features/caller_id/data/datasources/caller_id_remote_datasource.dart'
    as _i244;
import '../../features/caller_id/data/datasources/contacts_datasource.dart'
    as _i908;
import '../../features/caller_id/data/repositories/caller_id_repository_impl.dart'
    as _i251;
import '../../features/caller_id/domain/repositories/caller_id_repository.dart'
    as _i99;
import '../../features/caller_id/domain/usecases/lookup_caller.dart' as _i843;
import '../../features/caller_id/domain/usecases/report_number.dart' as _i443;
import '../../features/caller_id/presentation/bloc/caller_id_bloc.dart'
    as _i880;
import '../../features/settings/presentation/bloc/settings_bloc.dart' as _i585;
import '../../features/threat_feed/data/datasources/threat_feed_local_datasource.dart'
    as _i901;
import '../../features/threat_feed/data/datasources/threat_feed_remote_datasource.dart'
    as _i902;
import '../../features/threat_feed/data/repositories/threat_feed_repository_impl.dart'
    as _i903;
import '../../features/threat_feed/domain/repositories/threat_feed_repository.dart'
    as _i904;
import '../../features/threat_feed/domain/usecases/get_threat_feed.dart'
    as _i905;
import '../../features/threat_feed/domain/usecases/sync_threat_feed.dart'
    as _i906;
import '../../features/threat_feed/presentation/bloc/threat_feed_bloc.dart'
    as _i907;
import '../database/sentri_database.dart' as _i715;
import '../network/dio_client.dart' as _i667;
import 'third_party_module.dart' as _i811;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final thirdPartyModule = _$ThirdPartyModule();
    gh.singleton<_i715.SentriDatabase>(() => _i715.SentriDatabase());
    gh.singleton<_i558.FlutterSecureStorage>(
        () => thirdPartyModule.secureStorage);
    gh.singleton<_i585.SettingsBloc>(() => _i585.SettingsBloc(gh<_i715.SentriDatabase>()));
    gh.factory<_i236.BlocklistRepository>(
        () => _i82.BlocklistRepositoryImpl(gh<_i715.SentriDatabase>()));
    gh.factory<_i159.CallLogRepository>(
        () => _i1027.CallLogRepositoryImpl(gh<_i715.SentriDatabase>()));
    gh.factory<_i555.CallerIdLocalDataSource>(
        () => _i555.CallerIdLocalDataSourceImpl(gh<_i715.SentriDatabase>()));
    gh.factory<_i908.ContactsDataSource>(
        () => _i908.ContactsDataSourceImpl());
    gh.singleton<_i667.DioClient>(
        () => _i667.DioClient(gh<_i558.FlutterSecureStorage>()));
    gh.factory<_i200.BlockNumber>(
        () => _i200.BlockNumber(gh<_i236.BlocklistRepository>()));
    gh.factory<_i316.UnblockNumber>(
        () => _i316.UnblockNumber(gh<_i236.BlocklistRepository>()));
    gh.factory<_i661.GetCallLog>(
        () => _i661.GetCallLog(gh<_i159.CallLogRepository>()));
    gh.factory<_i244.CallerIdRemoteDataSource>(
        () => _i244.CallerIdRemoteDataSourceImpl(gh<_i667.DioClient>()));
    gh.factory<_i692.BlocklistBloc>(() => _i692.BlocklistBloc(
          gh<_i236.BlocklistRepository>(),
          gh<_i200.BlockNumber>(),
          gh<_i316.UnblockNumber>(),
        ));
    gh.factory<_i54.CallLogBloc>(
        () => _i54.CallLogBloc(gh<_i661.GetCallLog>()));
    gh.factory<_i99.CallerIdRepository>(() => _i251.CallerIdRepositoryImpl(
          gh<_i244.CallerIdRemoteDataSource>(),
          gh<_i555.CallerIdLocalDataSource>(),
          gh<_i908.ContactsDataSource>(),
        ));
    gh.factory<_i843.LookupCaller>(
        () => _i843.LookupCaller(gh<_i99.CallerIdRepository>()));
    gh.factory<_i443.ReportNumber>(
        () => _i443.ReportNumber(gh<_i99.CallerIdRepository>()));
    gh.factory<_i880.CallerIdBloc>(() => _i880.CallerIdBloc(
          gh<_i843.LookupCaller>(),
          gh<_i443.ReportNumber>(),
        ));
    gh.factory<_i902.ThreatFeedRemoteDataSource>(
        () => _i902.ThreatFeedRemoteDataSourceImpl(gh<_i667.DioClient>()));
    gh.factory<_i901.ThreatFeedLocalDataSource>(
        () => _i901.ThreatFeedLocalDataSourceImpl(gh<_i715.SentriDatabase>()));
    gh.factory<_i904.ThreatFeedRepository>(
        () => _i903.ThreatFeedRepositoryImpl(
              gh<_i902.ThreatFeedRemoteDataSource>(),
              gh<_i901.ThreatFeedLocalDataSource>(),
            ));
    gh.factory<_i905.GetThreatFeed>(
        () => _i905.GetThreatFeed(gh<_i904.ThreatFeedRepository>()));
    gh.factory<_i906.SyncThreatFeed>(
        () => _i906.SyncThreatFeed(gh<_i904.ThreatFeedRepository>()));
    gh.factory<_i907.ThreatFeedBloc>(() => _i907.ThreatFeedBloc(
          gh<_i905.GetThreatFeed>(),
          gh<_i906.SyncThreatFeed>(),
          gh<_i904.ThreatFeedRepository>(),
        ));
    return this;
  }
}

class _$ThirdPartyModule extends _i811.ThirdPartyModule {}
