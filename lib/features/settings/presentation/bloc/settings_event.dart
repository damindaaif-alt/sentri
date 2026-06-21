part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

final class SettingsLoaded extends SettingsEvent {
  const SettingsLoaded();
}

final class SettingsUpdated extends SettingsEvent {
  final ThemeMode? themeMode;
  final bool? autoBlockHighRisk;
  final int? blockThreshold;
  final bool? vishingDetectionEnabled;

  const SettingsUpdated({
    this.themeMode,
    this.autoBlockHighRisk,
    this.blockThreshold,
    this.vishingDetectionEnabled,
  });

  @override
  List<Object?> get props =>
      [themeMode, autoBlockHighRisk, blockThreshold, vishingDetectionEnabled];
}
