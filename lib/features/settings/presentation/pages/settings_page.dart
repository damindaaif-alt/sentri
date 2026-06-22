import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/sentri_database.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/settings_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  static const _screeningChannel =
      MethodChannel('com.sentri.sentri/settings');

  bool? _isScreeningActive; // null = loading
  bool _isSamsungDevice = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDeviceInfo();
    _checkScreeningStatus();
  }

  Future<void> _checkDeviceInfo() async {
    try {
      final info = await _screeningChannel
          .invokeMapMethod<String, dynamic>('getDeviceInfo');
      final manufacturer =
          (info?['manufacturer'] as String? ?? '').toLowerCase();
      if (mounted) setState(() => _isSamsungDevice = manufacturer == 'samsung');
    } on PlatformException {
      // ignore
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check every time the user comes back to the app (e.g. after granting role)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkScreeningStatus();
  }

  Future<void> _checkScreeningStatus() async {
    try {
      final active = await _screeningChannel
          .invokeMethod<bool>('isDefaultCallScreeningApp');
      if (mounted) setState(() => _isScreeningActive = active ?? false);
    } on PlatformException {
      if (mounted) setState(() => _isScreeningActive = false);
    }
  }

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
              // ── Protection ──────────────────────────────────────────────
              const _SectionHeader('Protection'),
              SwitchListTile(
                title: const Text('Auto-block high risk calls'),
                subtitle: Text('Block calls scoring ≥ ${s.blockThreshold}'),
                value: s.autoBlockHighRisk,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(SettingsUpdated(autoBlockHighRisk: v)),
              ),
              ListTile(
                title: const Text('Block threshold'),
                subtitle: Text('Current: ${s.blockThreshold} / 100'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThresholdPicker(context, s.blockThreshold),
              ),

              // ── Notifications ────────────────────────────────────────────
              const Divider(),
              const _SectionHeader('Notifications'),
              SwitchListTile(
                title: const Text('Risk alerts'),
                subtitle: const Text(
                    'Notify when an incoming call has a medium or higher risk score'),
                value: s.notificationsEnabled,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(SettingsUpdated(notificationsEnabled: v)),
              ),

              // ── AI Features ──────────────────────────────────────────────
              const Divider(),
              const _SectionHeader('AI Features'),
              SwitchListTile(
                title: const Text('Vishing detection (beta)'),
                subtitle: const Text(
                    'On-device real-time scam script detection'),
                value: s.vishingDetectionEnabled,
                onChanged: (v) => context
                    .read<SettingsBloc>()
                    .add(SettingsUpdated(vishingDetectionEnabled: v)),
              ),

              // ── Call Screening ───────────────────────────────────────────
              const Divider(),
              const _SectionHeader('Call Screening'),
              ListTile(
                leading: const Icon(Icons.phone_in_talk_outlined),
                title: const Text('Background call screening'),
                subtitle: Text(
                  _isSamsungDevice
                      ? 'Tap to learn about Samsung compatibility'
                      : _isScreeningActive == true
                          ? 'Sentri is actively screening calls'
                          : 'Tap to set Sentri as the default screening app',
                ),
                trailing: _isSamsungDevice
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue[400], size: 18),
                          const SizedBox(width: 4),
                          Text('Limited',
                              style: TextStyle(
                                  color: Colors.blue[400],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ],
                      )
                    : _isScreeningActive == null
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : _isScreeningActive == true
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: SentriColors.riskSafe, size: 18),
                                  const SizedBox(width: 4),
                                  Text('Active',
                                      style: TextStyle(
                                          color: SentriColors.riskSafe,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12)),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: SentriColors.riskMedium, size: 18),
                                  const SizedBox(width: 4),
                                  Text('Inactive',
                                      style: TextStyle(
                                          color: SentriColors.riskMedium,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12)),
                                ],
                              ),
                onTap: () => _isSamsungDevice
                    ? _showSamsungUnsupportedDialog(context)
                    : _isScreeningActive != true
                        ? _openCallScreeningSettings(context)
                        : null,
              ),

              // ── Regional ────────────────────────────────────────────────
              const Divider(),
              const _SectionHeader('Regional'),
              ListTile(
                title: const Text('Home country'),
                subtitle: const Text('Used to normalise local numbers without a country prefix'),
                trailing: Text(
                  _countryLabel(s.homeCountryCode),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                onTap: () => _showCountryPicker(context, s.homeCountryCode),
              ),

              // ── Appearance ───────────────────────────────────────────────
              const Divider(),
              const _SectionHeader('Appearance'),
              ListTile(
                title: const Text('Theme'),
                trailing: DropdownButton<ThemeMode>(
                  value: s.themeMode,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                        value: ThemeMode.system, child: Text('System')),
                    DropdownMenuItem(
                        value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(
                        value: ThemeMode.dark, child: Text('Dark')),
                  ],
                  onChanged: (v) => context
                      .read<SettingsBloc>()
                      .add(SettingsUpdated(themeMode: v)),
                ),
              ),

              // ── Data & Privacy ───────────────────────────────────────────
              const Divider(),
              const _SectionHeader('Data & Privacy'),
              ListTile(
                leading: const Icon(Icons.no_accounts_outlined),
                title: const Text('No contact upload'),
                subtitle: const Text(
                    'Sentri never reads or uploads your contacts'),
                enabled: false,
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('Clear caller cache'),
                subtitle: const Text('Remove locally cached risk data'),
                onTap: () => _clearCache(context),
              ),

              // ── About ────────────────────────────────────────────────────
              const Divider(),
              const _SectionHeader('About'),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Sentri'),
                subtitle: Text('Version ${AppConstants.appVersion}'),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy policy'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _showPrivacyDialog(context),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  static const _countries = [
    ('+94', 'Sri Lanka (+94)'),
    ('+64', 'New Zealand (+64)'),
    ('+61', 'Australia (+61)'),
    ('+1', 'United States / Canada (+1)'),
    ('+44', 'United Kingdom (+44)'),
    ('+91', 'India (+91)'),
    ('+65', 'Singapore (+65)'),
    ('+60', 'Malaysia (+60)'),
    ('+63', 'Philippines (+63)'),
    ('+49', 'Germany (+49)'),
  ];

  static String _countryLabel(String code) {
    for (final (c, label) in _countries) {
      if (c == code) return label;
    }
    return code;
  }

  void _showCountryPicker(BuildContext context, String current) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Home country'),
        children: _countries.map(((String, String) entry) {
          final (code, label) = entry;
          return SimpleDialogOption(
            onPressed: () {
              context
                  .read<SettingsBloc>()
                  .add(SettingsUpdated(homeCountryCode: code));
              Navigator.of(context).pop();
            },
            child: Row(
              children: [
                Expanded(child: Text(label)),
                if (code == current)
                  Icon(Icons.check, size: 18,
                      color: Theme.of(context).colorScheme.primary),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _openCallScreeningSettings(BuildContext context) async {
    try {
      await _screeningChannel.invokeMethod<String>('openCallScreeningSettings');
    } on PlatformException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not open settings')),
      );
    }
  }

  void _showSamsungUnsupportedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.info_outline, color: Colors.blue[400], size: 32),
        title: const Text('Samsung compatibility'),
        content: const Text(
          'Samsung One UI reserves background call screening for its own Phone app — '
          'third-party apps cannot be set as the screening app on this device.\n\n'
          'What still works on Samsung:\n'
          '• Manual blocklist — numbers you block are flagged in your call history\n'
          '• Number lookup — search and identify any number\n'
          '• Threat feed — browse community-reported scam numbers\n\n'
          'Background auto-rejection is available on stock Android (Pixel and others).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
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
              context
                  .read<SettingsBloc>()
                  .add(SettingsUpdated(blockThreshold: v));
              Navigator.of(context).pop();
            },
            child: Text('$v${v == current ? ' ✓' : ''}'),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear caller cache?'),
        content: const Text(
            'Locally cached risk scores will be removed. They will be re-fetched on the next lookup.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) {
      final count = await getIt<SentriDatabase>().clearAllCallerCache();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleared $count cached entries')),
        );
      }
    }
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Sentri is designed with privacy as a first principle:\n\n'
            '• Your contacts are never read or uploaded.\n'
            '• Call logs are processed on-device only.\n'
            '• Risk lookups use only the phone number — no metadata.\n'
            '• No advertising. No data selling. Ever.\n\n'
            'Full policy: https://sentri.app/privacy',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close')),
        ],
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
