import 'package:call_log/call_log.dart' as device;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/phone_number_utils.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../widgets/risk_score_badge.dart';

class NumberLookupPage extends StatefulWidget {
  const NumberLookupPage({super.key});

  @override
  State<NumberLookupPage> createState() => _NumberLookupPageState();
}

class _NumberLookupPageState extends State<NumberLookupPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  // Deduplicated call log entries — loaded once on init
  List<_Entry> _allEntries = [];
  List<_Entry> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCallLog();
    _controller.addListener(_onQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadCallLog() async {
    final raw = await device.CallLog.query();

    // Deduplicate by digit-only key so 021894338 and +6421894338 collapse to one entry.
    // Keep the entry whose number has a + prefix (international) if available,
    // otherwise keep the first seen (most recent, since CallLog is newest-first).
    final seen = <String, _Entry>{};
    for (final e in raw) {
      final number = e.number ?? '';
      if (number.isEmpty) continue;
      final digits = number.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) continue;
      // Use last 9 digits as key — matches local (0220521066) and
      // international (+64220521066) formats of the same number
      final key = digits.length > 9 ? digits.substring(digits.length - 9) : digits;
      if (key.isEmpty) continue;
      final entry = _Entry(
        number: number,
        name: e.name?.isNotEmpty == true ? e.name : null,
        timestamp: DateTime.fromMillisecondsSinceEpoch(e.timestamp ?? 0),
      );
      if (!seen.containsKey(key)) {
        seen[key] = entry;
      } else if (number.startsWith('+') && !seen[key]!.number.startsWith('+')) {
        // Prefer the international format for display
        seen[key] = entry;
      }
    }

    if (mounted) {
      setState(() {
        _allEntries = seen.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _filtered = _allEntries;
        _loading = false;
      });
    }
  }

  void _onQuery() {
    final q = _controller.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _allEntries;
      } else {
        _filtered = _allEntries.where((e) {
          final nameMatch = e.name?.toLowerCase().contains(q) ?? false;
          final numberMatch = e.number.contains(q);
          return nameMatch || numberMatch;
        }).toList();
      }
    });
  }

  String get _countryCode {
    final s = getIt<SettingsBloc>().state;
    return s is SettingsReady ? s.settings.homeCountryCode : '+1';
  }

  String? get _normalised =>
      PhoneNumberUtils.toE164(_controller.text.trim(), defaultCountryCode: _countryCode);
  bool get _isValid =>
      _normalised != null && PhoneNumberUtils.isValid(_normalised!);

  void _goToDetail(String number, {String? name}) {
    _focus.unfocus();
    final encoded = Uri.encodeComponent(number);
    final nameParam =
        name != null ? '?name=${Uri.encodeComponent(name)}' : '';
    context.push(
      '${AppRoutes.callerDetail.replaceFirst(':number', encoded)}$nameParam',
    );
  }

  void _lookup() {
    if (!_isValid) return;
    final number = _normalised!;
    // check if we already have a name for this number in the call log
    final match = _allEntries.where((e) => e.number == number).firstOrNull;
    _goToDetail(number, name: match?.name);
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final showResults = query.isNotEmpty || _allEntries.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Number Lookup')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchBar(
            controller: _controller,
            focus: _focus,
            isValid: _isValid,
            onLookup: _lookup,
            onClear: () {
              _controller.clear();
              _focus.requestFocus();
            },
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : showResults
                    ? _ResultsList(
                        entries: _filtered,
                        query: query,
                        onTap: (e) => _goToDetail(e.number, name: e.name),
                        onPaste: _handlePaste,
                        emptyQuery: query.isEmpty,
                      )
                    : _EmptyHint(onPaste: _handlePaste),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      _controller.text = data!.text!.trim();
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _Entry {
  final String number;
  final String? name;
  final DateTime timestamp;
  const _Entry(
      {required this.number, this.name, required this.timestamp});
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final bool isValid;
  final VoidCallback onLookup;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focus,
    required this.isValid,
    required this.onLookup,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            focusNode: focus,
            autofocus: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: 'Name or number…',
              hintStyle: theme.textTheme.titleLarge?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(Icons.search,
                  color: SentriColors.primary, size: 22),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: onClear,
                    )
                  : null,
              filled: false,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            ),
            onSubmitted: (_) => onLookup(),
          ),
          if (isValid) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onLookup,
              icon: const Icon(Icons.manage_search, size: 18),
              label: Text('Look up ${controller.text.trim()}'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Results list ──────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final List<_Entry> entries;
  final String query;
  final void Function(_Entry) onTap;
  final VoidCallback onPaste;
  final bool emptyQuery;

  const _ResultsList({
    required this.entries,
    required this.query,
    required this.onTap,
    required this.onPaste,
    required this.emptyQuery,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty && !emptyQuery) {
      return _NoMatch(query: query, onPaste: onPaste);
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: entries.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              emptyQuery ? 'Recent calls' : 'Matches',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
            ),
          );
        }
        final e = entries[i - 1];
        return _EntryTile(entry: e, query: query, onTap: () => onTap(e));
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  final _Entry entry;
  final String query;
  final VoidCallback onTap;
  const _EntryTile(
      {required this.entry, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasName = entry.name != null;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          _initials(entry.name ?? entry.number),
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      title: _Highlighted(
        text: hasName ? entry.name! : entry.number,
        query: query,
        style: theme.textTheme.bodyLarge!
            .copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: hasName
          ? _Highlighted(
              text: entry.number,
              query: query,
              style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  static String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
  }
}

/// Highlights [query] within [text] using the primary colour.
class _Highlighted extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  const _Highlighted(
      {required this.text, required this.query, required this.style});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);

    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx == -1) return Text(text, style: style);

    return RichText(
      text: TextSpan(children: [
        TextSpan(text: text.substring(0, idx), style: style),
        TextSpan(
          text: text.substring(idx, idx + q.length),
          style: style.copyWith(
            color: SentriColors.primary,
            backgroundColor:
                SentriColors.primary.withOpacity(0.12),
          ),
        ),
        TextSpan(text: text.substring(idx + q.length), style: style),
      ]),
    );
  }
}

// ── No match ──────────────────────────────────────────────────────────────────

class _NoMatch extends StatelessWidget {
  final String query;
  final VoidCallback onPaste;
  const _NoMatch({required this.query, required this.onPaste});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No results for "$query"',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'If this is a full international number (e.g. +94 77 123 4567) the Look up button will appear above.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Empty hint (no call log loaded yet) ───────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final VoidCallback onPaste;
  const _EmptyHint({required this.onPaste});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_search_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('Search by name or number',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Search your call history or enter any international number for a risk check.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onPaste,
            icon: const Icon(Icons.content_paste_outlined, size: 16),
            label: const Text('Paste from clipboard'),
          ),
        ],
      ),
    );
  }
}
