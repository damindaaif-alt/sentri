part of 'call_log_bloc.dart';

sealed class CallLogEvent extends Equatable {
  const CallLogEvent();
  @override
  List<Object?> get props => [];
}

final class CallLogLoadRequested extends CallLogEvent {
  const CallLogLoadRequested();
}

final class CallLogRefreshRequested extends CallLogEvent {
  const CallLogRefreshRequested();
}
