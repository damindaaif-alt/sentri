import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/sentri_database.dart';
import '../../domain/entities/user_settings.dart';

part 'settings_event.dart';
part 'settings_state.dart';

// DB key constants — private to this file
const _kThemeMode = 'theme_mode';
const _kAutoBlock = 'auto_block_high_risk';
const _kThreshold = 'block_threshold';
const _kVishing = 'vishing_detection_enabled';
const _kNotifications = 'notifications_enabled';
const _kCountryCode = 'home_country_code';

@singleton
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SentriDatabase _db;

  SettingsBloc(this._db) : super(SettingsInitial()) {
    on<SettingsLoaded>(_onLoad);
    on<SettingsUpdated>(_onUpdate);
  }

  Future<void> _onLoad(SettingsLoaded event, Emitter<SettingsState> emit) async {
    final themeRaw = await _db.getSetting(_kThemeMode);
    final autoBlock = await _db.getSetting(_kAutoBlock);
    final threshold = await _db.getSetting(_kThreshold);
    final vishing = await _db.getSetting(_kVishing);
    final notifications = await _db.getSetting(_kNotifications);
    final countryCode = await _db.getSetting(_kCountryCode);

    emit(SettingsReady(UserSettings(
      themeMode: _parseTheme(themeRaw),
      autoBlockHighRisk: autoBlock == 'true',
      blockThreshold: int.tryParse(threshold ?? '') ?? 80,
      vishingDetectionEnabled: vishing == 'true',
      notificationsEnabled: notifications != 'false',
      homeCountryCode: countryCode ?? '+1',
    )));
  }

  Future<void> _onUpdate(SettingsUpdated event, Emitter<SettingsState> emit) async {
    if (state is! SettingsReady) return;
    final updated = (state as SettingsReady).settings.copyWith(
          themeMode: event.themeMode,
          autoBlockHighRisk: event.autoBlockHighRisk,
          blockThreshold: event.blockThreshold,
          vishingDetectionEnabled: event.vishingDetectionEnabled,
          notificationsEnabled: event.notificationsEnabled,
          homeCountryCode: event.homeCountryCode,
        );
    emit(SettingsReady(updated));

    if (event.themeMode != null) {
      await _db.setSetting(_kThemeMode, _themeName(event.themeMode!));
    }
    if (event.autoBlockHighRisk != null) {
      await _db.setSetting(_kAutoBlock, '${event.autoBlockHighRisk}');
    }
    if (event.blockThreshold != null) {
      await _db.setSetting(_kThreshold, '${event.blockThreshold}');
    }
    if (event.vishingDetectionEnabled != null) {
      await _db.setSetting(_kVishing, '${event.vishingDetectionEnabled}');
    }
    if (event.notificationsEnabled != null) {
      await _db.setSetting(_kNotifications, '${event.notificationsEnabled}');
    }
    if (event.homeCountryCode != null) {
      await _db.setSetting(_kCountryCode, event.homeCountryCode!);
    }
  }

  static ThemeMode _parseTheme(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _themeName(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };
}
