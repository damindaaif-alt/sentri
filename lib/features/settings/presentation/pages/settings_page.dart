import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is! SettingsReady) return const SizedBox.shrink();
          final s = state.settings;
          return ListView(
            children: [
              const _SectionHeader('Protection'),
              SwitchListTile(
                title: const Text('Auto-block high risk calls'),
                subtitle: Text('Block calls scoring ≥ ${s.blockThreshold}'),
                value: s.autoBlockHighRisk,
                onChanged: (v) => context.read<SettingsBloc>().add(
                      SettingsUpdated(autoBlockHighRisk: v),
                    ),
              ),
              ListTile(
                title: const Text('Block threshold'),
                subtitle: Text('Current: ${s.blockThreshold} / 100'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThresholdPicker(context, s.blockThreshold),
              ),
              const Divider(),
              const _SectionHeader('AI Features'),
              SwitchListTile(
                title: const Text('Vishing detection (beta)'),
                subtitle: const Text('On-device real-time scam script detection'),
                value: s.vishingDetectionEnabled,
                onChanged: (v) => context.read<SettingsBloc>().add(
                      SettingsUpdated(vishingDetectionEnabled: v),
                    ),
              ),
              const Divider(),
              const _SectionHeader('Appearance'),
              ListTile(
                title: const Text('Theme'),
                trailing: DropdownButton<ThemeMode>(
                  value: s.themeMode,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                  ],
                  onChanged: (v) => context.read<SettingsBloc>().add(
                        SettingsUpdated(themeMode: v),
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showThresholdPicker(BuildContext context, int current) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Block threshold'),
        content: const Text(
          'Calls with a risk score at or above this value will be automatically blocked.',
        ),
        actions: [60, 70, 80, 90].map((v) {
          return TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(SettingsUpdated(blockThreshold: v));
              Navigator.of(context).pop();
            },
            child: Text('$v${v == current ? ' ✓' : ''}'),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}
