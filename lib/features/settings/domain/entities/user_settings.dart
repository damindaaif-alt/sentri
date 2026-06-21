import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class UserSettings extends Equatable {
  final ThemeMode themeMode;
  final bool autoBlockHighRisk;
  final int blockThreshold; // riskScore >= this → auto-block
  final bool vishingDetectionEnabled;
  final bool showRealTimeOverlay;
  final bool notificationsEnabled;

  const UserSettings({
    this.themeMode = ThemeMode.system,
    this.autoBlockHighRisk = false,
    this.blockThreshold = 80,
    this.vishingDetectionEnabled = false,
    this.showRealTimeOverlay = true,
    this.notificationsEnabled = true,
  });

  UserSettings copyWith({
    ThemeMode? themeMode,
    bool? autoBlockHighRisk,
    int? blockThreshold,
    bool? vishingDetectionEnabled,
    bool? showRealTimeOverlay,
    bool? notificationsEnabled,
  }) =>
      UserSettings(
        themeMode: themeMode ?? this.themeMode,
        autoBlockHighRisk: autoBlockHighRisk ?? this.autoBlockHighRisk,
        blockThreshold: blockThreshold ?? this.blockThreshold,
        vishingDetectionEnabled:
            vishingDetectionEnabled ?? this.vishingDetectionEnabled,
        showRealTimeOverlay: showRealTimeOverlay ?? this.showRealTimeOverlay,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  @override
  List<Object?> get props => [
        themeMode,
        autoBlockHighRisk,
        blockThreshold,
        vishingDetectionEnabled,
        showRealTimeOverlay,
        notificationsEnabled,
      ];
}
