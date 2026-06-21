part of 'settings_bloc.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

final class SettingsInitial extends SettingsState {}

final class SettingsReady extends SettingsState {
  final UserSettings settings;
  ThemeMode get themeMode => settings.themeMode;
  const SettingsReady(this.settings);
  @override
  List<Object?> get props => [settings];
}
