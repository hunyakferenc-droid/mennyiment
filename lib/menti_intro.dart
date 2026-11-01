import 'package:flutter/material.dart';

import 'app_language.dart';
import 'menti_experience_settings.dart';
import 'menti_ui.dart';

/// Optional informational route. Opening, stepping and back navigation write nothing.
class MentiIntroPage extends StatefulWidget {
  const MentiIntroPage({super.key, this.settings});
  final MentiExperienceSettings? settings;
  @override
  State<MentiIntroPage> createState() => _MentiIntroPageState();
}

class _MentiIntroPageState extends State<MentiIntroPage> {
  int _step = 0;
  bool _saving = false;
  bool _failed = false;

  Future<void> _finish() async {
    if (_saving) return;
    final settings = widget.settings ?? MentiExperienceScope.of(context);
    setState(() { _saving = true; _failed = false; });
    final saved = settings != null && await settings.markIntroSeen();
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() { _saving = false; _failed = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final titles = [s.experienceIntro1Title, s.experienceIntro2Title,
      s.experienceIntro3Title, s.experienceIntro4Title];
    final texts = [s.experienceIntro1Body, s.experienceIntro2Body,
      s.experienceIntro3Body, s.experienceIntro4Body];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 26 ? 104 : kToolbarHeight,
        title: Text(s.experienceIntroTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: [TextButton(key: const ValueKey('intro-skip'),
          onPressed: _saving ? null : _finish, child: Text(s.experienceIntroSkip))],
      ),
      body: MentiPageBody(children: [
        Center(child: Image.asset('assets/images/menti_outfits/alap.png',
          width: 100, height: 100, excludeFromSemantics: true)),
        const SizedBox(height: 16),
        Semantics(liveRegion: true, child: Text(s.experienceIntroStep(_step + 1, 4), key: const ValueKey('intro-step'))),
        const SizedBox(height: 12),
        Text(titles[_step], key: const ValueKey('intro-title'),
          style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Text(texts[_step]),
        const SizedBox(height: 24),
        if (_failed) MentiStatusMessage(message: s.experienceSaveError, isError: true),
        Wrap(spacing: 12, runSpacing: 12, children: [
          if (_step > 0) OutlinedButton(key: const ValueKey('intro-previous'),
            onPressed: _saving ? null : () => setState(() { if (_step > 0) _step--; }),
            child: Text(s.experienceIntroBack)),
          FilledButton(key: const ValueKey('intro-next'),
            onPressed: _saving ? null : _step == 3 ? _finish : () => setState(() { if (_step < 3) _step++; }),
            child: Text(_step == 3 ? s.experienceIntroDone : s.experienceIntroNext)),
        ]),
      ]),
    );
  }
}
