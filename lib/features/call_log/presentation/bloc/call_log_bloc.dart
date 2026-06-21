import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/call_record.dart';
import '../../domain/usecases/get_call_log.dart';

part 'call_log_event.dart';
part 'call_log_state.dart';

@injectable
class CallLogBloc extends Bloc<CallLogEvent, CallLogState> {
  final GetCallLog _getCallLog;

  CallLogBloc(this._getCallLog) : super(CallLogInitial()) {
    on<CallLogLoadRequested>(_onLoad);
    on<CallLogRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    CallLogLoadRequested event,
    Emitter<CallLogState> emit,
  ) async {
    emit(CallLogLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    CallLogRefreshRequested event,
    Emitter<CallLogState> emit,
  ) async {
    if (state is CallLogLoaded) {
      emit(CallLogLoaded((state as CallLogLoaded).records, isRefreshing: true));
    }
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<CallLogState> emit) async {
    final (records, failure) = await _getCallLog();
    if (failure != null) {
      emit(CallLogError(failure.message));
    } else {
      emit(CallLogLoaded(records));
    }
  }
}
