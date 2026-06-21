part of 'caller_id_bloc.dart';

sealed class CallerIdState extends Equatable {
  const CallerIdState();
  @override
  List<Object?> get props => [];
}

final class CallerIdInitial extends CallerIdState {}

final class CallerIdLoading extends CallerIdState {}

final class CallerIdLoaded extends CallerIdState {
  final CallerInfo callerInfo;
  const CallerIdLoaded(this.callerInfo);
  @override
  List<Object?> get props => [callerInfo];
}

final class CallerIdReported extends CallerIdState {
  const CallerIdReported();
}

final class CallerIdError extends CallerIdState {
  final String message;
  const CallerIdError(this.message);
  @override
  List<Object?> get props => [message];
}
