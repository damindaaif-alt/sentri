import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/user_settings.dart';

part 'settings_event.dart';
part 'settings_state.dart';

@singleton
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsInitial()) {
    on<SettingsLoaded>(_onLoad);
    on<SettingsUpdated>(_onUpdate);
  }

  Future<void> _onLoad(SettingsLoaded event, Emitter<SettingsState> emit) async {
    // In production: load from Drift UserSettings table
    emit(SettingsReady(const UserSettings()));
  }

  Future<void> _onUpdate(SettingsUpdated event, Emitter<SettingsState> emit) async {
    if (state is SettingsReady) {
      final updated = (state as SettingsReady).settings.copyWith(
            themeMode: event.themeMode,
            autoBlockHighRisk: event.autoBlockHighRisk,
            blockThreshold: event.blockThreshold,
            vishingDetectionEnabled: event.vishingDetectionEnabled,
          );
      // In production: persist to Drift
      emit(SettingsReady(updated));
    }
  }
}
