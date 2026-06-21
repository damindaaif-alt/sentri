part of 'call_log_bloc.dart';

sealed class CallLogState extends Equatable {
  const CallLogState();
  @override
  List<Object?> get props => [];
}

final class CallLogInitial extends CallLogState {}

final class CallLogLoading extends CallLogState {}

final class CallLogLoaded extends CallLogState {
  final List<CallRecord> records;
  final bool isRefreshing;
  const CallLogLoaded(this.records, {this.isRefreshing = false});
  @override
  List<Object?> get props => [records, isRefreshing];
}

final class CallLogError extends CallLogState {
  final String message;
  const CallLogError(this.message);
  @override
  List<Object?> get props => [message];
}
