import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/caller_info.dart';
import '../../domain/usecases/lookup_caller.dart';
import '../../domain/usecases/report_number.dart';

part 'caller_id_event.dart';
part 'caller_id_state.dart';

@injectable
class CallerIdBloc extends Bloc<CallerIdEvent, CallerIdState> {
  final LookupCaller _lookupCaller;
  final ReportNumber _reportNumber;

  CallerIdBloc(this._lookupCaller, this._reportNumber)
      : super(CallerIdInitial()) {
    on<CallerIdLookupRequested>(_onLookup);
    on<CallerIdNumberReported>(_onReport);
  }

  Future<void> _onLookup(
    CallerIdLookupRequested event,
    Emitter<CallerIdState> emit,
  ) async {
    emit(CallerIdLoading());
    final (info, failure) = await _lookupCaller(
      event.phoneNumber,
      countryCode: event.countryCode,
    );
    if (failure != null) {
      emit(CallerIdError(failure.message));
    } else {
      emit(CallerIdLoaded(info!));
    }
  }

  Future<void> _onReport(
    CallerIdNumberReported event,
    Emitter<CallerIdState> emit,
  ) async {
    final failure = await _reportNumber(
      phoneNumber: event.phoneNumber,
      category: event.category,
      note: event.note,
    );
    if (failure != null) {
      emit(CallerIdError(failure.message));
    } else {
      emit(const CallerIdReported());
    }
  }
}
