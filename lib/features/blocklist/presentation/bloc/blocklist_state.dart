part of 'blocklist_bloc.dart';

sealed class BlocklistState extends Equatable {
  const BlocklistState();
  @override
  List<Object?> get props => [];
}

final class BlocklistInitial extends BlocklistState {}
final class BlocklistLoading extends BlocklistState {}

final class BlocklistReady extends BlocklistState {
  final List<BlockedNumber> numbers;
  const BlocklistReady(this.numbers);
  @override
  List<Object?> get props => [numbers];
}

final class BlocklistError extends BlocklistState {
  final String message;
  const BlocklistError(this.message);
  @override
  List<Object?> get props => [message];
}
