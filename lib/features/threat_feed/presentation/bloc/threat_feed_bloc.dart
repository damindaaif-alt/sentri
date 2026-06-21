import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/get_threat_feed.dart';
import '../../domain/usecases/sync_threat_feed.dart';
import '../../domain/repositories/threat_feed_repository.dart';
import 'threat_feed_event.dart';
import 'threat_feed_state.dart';

@injectable
class ThreatFeedBloc extends Bloc<ThreatFeedEvent, ThreatFeedState> {
  final GetThreatFeed _get;
  final SyncThreatFeed _sync;
  final ThreatFeedRepository _repository;

  ThreatFeedBloc(this._get, this._sync, this._repository)
      : super(const ThreatFeedInitial()) {
    on<ThreatFeedLoadRequested>(_onLoad);
    on<ThreatFeedSyncRequested>(_onSync);
    on<ThreatFeedFilterChanged>(_onFilter);
    on<ThreatFeedAutoBlockRequested>(_onAutoBlock);
  }

  Future<void> _onLoad(
      ThreatFeedLoadRequested _, Emitter<ThreatFeedState> emit) async {
    emit(const ThreatFeedLoading());
    final (entries, failure) = await _get();
    if (failure != null) {
      emit(ThreatFeedError(failure.message));
      return;
    }
    final syncedAt = await _repository.lastSyncedAt();
    emit(ThreatFeedLoaded(allEntries: entries!, syncedAt: syncedAt));
  }

  Future<void> _onSync(
      ThreatFeedSyncRequested _, Emitter<ThreatFeedState> emit) async {
    final current = state;
    if (current is ThreatFeedLoaded) {
      emit(current.copyWith(isSyncing: true));
    }
    final (entries, failure) = await _sync();
    if (failure != null) {
      if (current is ThreatFeedLoaded) emit(current.copyWith(isSyncing: false));
      return;
    }
    final syncedAt = await _repository.lastSyncedAt();
    final prev = state is ThreatFeedLoaded ? state as ThreatFeedLoaded : null;
    emit(ThreatFeedLoaded(
      allEntries: entries!,
      activeFilter: prev?.activeFilter,
      syncedAt: syncedAt,
      autoBlockEnabled: prev?.autoBlockEnabled ?? false,
    ));
  }

  Future<void> _onFilter(
      ThreatFeedFilterChanged event, Emitter<ThreatFeedState> emit) async {
    if (state is ThreatFeedLoaded) {
      final current = state as ThreatFeedLoaded;
      emit(current.copyWith(activeFilter: () => event.category));
    }
  }

  Future<void> _onAutoBlock(
      ThreatFeedAutoBlockRequested _, Emitter<ThreatFeedState> emit) async {
    if (state is! ThreatFeedLoaded) return;
    final current = state as ThreatFeedLoaded;
    await _repository.autoBlockCritical();
    emit(current.copyWith(autoBlockEnabled: true));
  }
}
