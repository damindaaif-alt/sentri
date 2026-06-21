part of 'caller_id_bloc.dart';

sealed class CallerIdEvent extends Equatable {
  const CallerIdEvent();
  @override
  List<Object?> get props => [];
}

final class CallerIdLookupRequested extends CallerIdEvent {
  final String phoneNumber;
  const CallerIdLookupRequested(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}

final class CallerIdNumberReported extends CallerIdEvent {
  final String phoneNumber;
  final RiskCategory category;
  final String? note;
  const CallerIdNumberReported({
    required this.phoneNumber,
    required this.category,
    this.note,
  });
  @override
  List<Object?> get props => [phoneNumber, category, note];
}
