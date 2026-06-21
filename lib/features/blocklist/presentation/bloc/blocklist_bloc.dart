import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/blocked_number.dart';
import '../../domain/usecases/block_number.dart';
import '../../domain/usecases/unblock_number.dart';
import '../../domain/repositories/blocklist_repository.dart';

part 'blocklist_event.dart';
part 'blocklist_state.dart';

@injectable
class BlocklistBloc extends Bloc<BlocklistEvent, BlocklistState> {
  final BlocklistRepository _repository;
  final BlockNumber _blockNumber;
  final UnblockNumber _unblockNumber;

  BlocklistBloc(this._repository, this._blockNumber, this._unblockNumber)
      : super(BlocklistInitial()) {
    on<BlocklistLoaded>(_onLoad);
    on<BlocklistNumberBlocked>(_onBlock);
    on<BlocklistNumberUnblocked>(_onUnblock);
  }

  Future<void> _onLoad(BlocklistLoaded event, Emitter<BlocklistState> emit) async {
    emit(BlocklistLoading());
    final numbers = await _repository.getAll();
    emit(BlocklistReady(numbers));
  }

  Future<void> _onBlock(BlocklistNumberBlocked event, Emitter<BlocklistState> emit) async {
    await _blockNumber(event.phoneNumber, label: event.label);
    add(const BlocklistLoaded());
  }

  Future<void> _onUnblock(BlocklistNumberUnblocked event, Emitter<BlocklistState> emit) async {
    await _unblockNumber(event.phoneNumber);
    add(const BlocklistLoaded());
  }
}
