part of 'blocklist_bloc.dart';

sealed class BlocklistEvent extends Equatable {
  const BlocklistEvent();
  @override
  List<Object?> get props => [];
}

final class BlocklistLoaded extends BlocklistEvent {
  const BlocklistLoaded();
}

final class BlocklistNumberBlocked extends BlocklistEvent {
  final String phoneNumber;
  final String? label;
  const BlocklistNumberBlocked(this.phoneNumber, {this.label});
  @override
  List<Object?> get props => [phoneNumber, label];
}

final class BlocklistNumberUnblocked extends BlocklistEvent {
  final String phoneNumber;
  const BlocklistNumberUnblocked(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}
