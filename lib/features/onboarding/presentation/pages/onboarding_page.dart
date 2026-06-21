import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;
  bool _requesting = false;

  static const _steps = [
    _Step(
      icon: Icons.shield_outlined,
      title: 'Welcome to Sentri',
      body:
          'Your privacy-first guardian against scam calls, vishing attacks, and number spoofing.',
      isPermissionStep: false,
    ),
    _Step(
      icon: Icons.visibility_off_outlined,
      title: 'Zero data upload',
      body:
          'Your contacts never leave your device. Sentri identifies callers without uploading your address book.',
      isPermissionStep: false,
    ),
    _Step(
      icon: Icons.psychology_outlined,
      title: 'AI-powered protection',
      body:
          'Real-time risk scoring, STIR/SHAKEN spoofing detection, and optional on-device vishing AI.',
      isPermissionStep: false,
    ),
    _Step(
      icon: Icons.lock_outlined,
      title: 'One permission needed',
      body:
          'Sentri needs phone access to screen calls and show caller risk scores. Nothing else.',
      isPermissionStep: true,
    ),
  ];

  bool get _isLastPage => _page == _steps.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button — hidden on the permissions page
            Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                opacity: _isLastPage ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: _isLastPage ? null : _skip,
                  child: const Text('Skip'),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _steps.length,
                itemBuilder: (_, i) => _StepView(step: _steps[i]),
              ),
            ),

            // Dot indicators
            _DotsIndicator(count: _steps.length, current: _page),
            const SizedBox(height: 24),

            // Primary button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _requesting ? null : _onNext,
                  child: _requesting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isLastPage ? 'Grant permission' : 'Continue'),
                ),
              ),
            ),

            // "Already granted" fallback on permission page
            if (_isLastPage)
              TextButton(
                onPressed: _skip,
                child: const Text('I already granted this'),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _onNext() async {
    if (!_isLastPage) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    setState(() => _requesting = true);

    final statuses = await [
      Permission.phone,
    ].request();

    if (!mounted) return;
    setState(() => _requesting = false);

    final granted = statuses[Permission.phone]?.isGranted ?? false;
    if (granted) {
      await _markComplete();
      if (mounted) context.go(AppRoutes.home);
    } else {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _skip() async {
    await _markComplete();
    if (mounted) context.go(AppRoutes.home);
  }

  Future<void> _markComplete() async {
    await getIt<FlutterSecureStorage>().write(
      key: AppConstants.keyOnboardingComplete,
      value: 'true',
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission needed'),
        content: const Text(
          "Without phone permission Sentri can't screen calls or show risk scores. "
          'You can grant it later in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _skip(); // let them in anyway
            },
            child: const Text('Continue anyway'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _Step {
  final IconData icon;
  final String title;
  final String body;
  final bool isPermissionStep;
  const _Step(
      {required this.icon,
      required this.title,
      required this.body,
      required this.isPermissionStep});
}

// ── Step view ─────────────────────────────────────────────────────────────────

class _StepView extends StatelessWidget {
  final _Step step;
  const _StepView({required this.step});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  SentriColors.primary.withOpacity(0.18),
                  SentriColors.primary.withOpacity(0.04),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: SentriColors.primary.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Icon(step.icon, size: 56, color: SentriColors.primary),
          ),
          const SizedBox(height: 48),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          if (step.isPermissionStep) ...[
            const SizedBox(height: 32),
            _PermissionTile(
              icon: Icons.phone_outlined,
              label: 'Phone & call log access',
              sublabel: 'To screen calls and show risk scores',
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  const _PermissionTile(
      {required this.icon,
      required this.label,
      required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: SentriColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(sublabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dots ──────────────────────────────────────────────────────────────────────

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _DotsIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active
                ? SentriColors.primary
                : SentriColors.primary.withOpacity(0.25),
          ),
        );
      }),
    );
  }
}
