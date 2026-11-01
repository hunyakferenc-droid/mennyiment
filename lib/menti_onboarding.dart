import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_language.dart';
import 'data_backup_page.dart';
import 'menti_access.dart';
import 'menti_identity/menti_avatar_renderer.dart';
import 'menti_identity/menti_identity_controller.dart';

/// Explicit age declaration for all installs; existing profiles bypass creation.
/// The completion flag is written only after the character save succeeds.
class MentiStartGate extends StatefulWidget {
  const MentiStartGate({super.key, required this.child, this.onRestored});
  final Widget child;
  final VoidCallback? onRestored;
  @override
  State<MentiStartGate> createState() => _MentiStartGateState();
}

class _MentiStartGateState extends State<MentiStartGate> {
  int _step = 0;
  bool? _adult;
  bool _busy = false, _failed = false;
  final _name = TextEditingController(text: 'Menti');
  final _scroll = ScrollController();
  @override
  void dispose() {
    _name.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _finish(
    MentiAccessSettings access,
    MentiIdentityController identity,
  ) async {
    if (_busy || _adult == null || !identity.writable) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    var ok = true;
    if (!access.existing) {
      identity.rename(_name.text);
      ok = await identity.save();
    }
    if (ok) ok = await access.finish(isAdult: _adult!);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final access = MentiAccessScope.of(context)!;
    final identity = MentiIdentityScope.of(context)!;
    final s = appStrings(context);
    if (!access.ready || !identity.ready) {
      return Scaffold(
        body: Center(
          child: identity.error != null
              ? TextButton(onPressed: identity.load, child: Text(s.avatarRetry))
              : const CircularProgressIndicator(),
        ),
      );
    }
    if (access.complete) return widget.child;
    final language = AppLanguageScope.of(context);
    final last = access.existing ? 1 : 3;
    final canContinue =
        !_busy &&
        access.writable &&
        (_step != 1 || _adult != null) &&
        (_step != 3 || _name.text.trim().isNotEmpty) &&
        identity.writable;
    final titles = [
      s.startLanguage,
      s.startAgeTitle,
      s.startCharacter,
      s.startName,
    ];
    Widget choices(String field) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in identity.choices(field))
          ChoiceChip(
            key: ValueKey('start-$field-${option.id}'),
            label: Text(option.label(s)),
            selected: identity.draft.profile.visual.value(field) == option.id,
            onSelected: _busy ? null : (_) => identity.choose(option),
          ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('MennyiMent?'),
        actions: [
          IconButton(
            tooltip: s.backupTitle,
            icon: const Icon(Icons.backup_outlined),
            onPressed: _busy
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          DataBackupPage(onRestored: widget.onRestored),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (_step > 0)
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _step--;
                        if (_scroll.hasClients) _scroll.jumpTo(0);
                      }),
                child: Text(s.experienceIntroBack),
              ),
            FilledButton(
              key: const ValueKey('start-next'),
              onPressed: !canContinue
                  ? null
                  : () {
                      if (_step == last) {
                        _finish(access, identity);
                      } else {
                        setState(() {
                          _step++;
                          _failed = false;
                          if (_scroll.hasClients) _scroll.jumpTo(0);
                        });
                      }
                    },
              child: Text(
                _busy
                    ? s.avatarSaving
                    : _step == last
                    ? s.startFinish
                    : s.experienceIntroNext,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(24),
              children: [
                LinearProgressIndicator(value: (_step + 1) / (last + 1)),
                const SizedBox(height: 24),
                Text(
                  titles[_step],
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                if (_step == 0) ...[
                  Text(s.startWelcome),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final code in ['hu', 'en'])
                        ChoiceChip(
                          key: ValueKey('start-language-$code'),
                          label: Text(code == 'hu' ? s.hungarian : s.english),
                          selected: language?.selection == code,
                          onSelected: language == null || language.saving
                              ? null
                              : (_) async {
                                  final ok = await language.select(code);
                                  if (mounted && !ok) {
                                    setState(() => _failed = true);
                                  }
                                },
                        ),
                    ],
                  ),
                  Center(
                    child: MentiAvatarRenderer(
                      profile: identity.draft.profile,
                      size: 140,
                      showBackground: false,
                    ),
                  ),
                ],
                if (_step == 1) ...[
                  Text(s.startAgeBody),
                  const SizedBox(height: 12),
                  RadioGroup<bool>(
                    groupValue: _adult,
                    onChanged: _busy
                        ? (_) {}
                        : (v) => setState(() => _adult = v),
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          key: const ValueKey('start-adult'),
                          value: true,
                          title: Text(s.startAdult),
                        ),
                        RadioListTile<bool>(
                          key: const ValueKey('start-minor'),
                          value: false,
                          title: Text(s.startMinor),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    s.startLocalOnly,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_step >= 2) ...[
                  Center(
                    child: MentiAvatarRenderer(
                      profile: identity.draft.profile,
                      size: math.min(
                        260,
                        math.max(120, MediaQuery.sizeOf(context).width - 80),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_step == 2) ...[
                  Text(s.avatarFieldFamily),
                  choices('family'),
                  const SizedBox(height: 16),
                  Text(s.avatarFieldAge),
                  choices('age'),
                  const SizedBox(height: 16),
                  Text(s.avatarFieldAccent),
                  choices('accent'),
                ],
                if (_step == 3) ...[
                  Text(s.startNameBody),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('start-name'),
                    controller: _name,
                    maxLength: 80,
                    enabled: !_busy,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: s.startName),
                  ),
                ],
                if (_failed || access.failed || identity.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(s.startSaveError),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
