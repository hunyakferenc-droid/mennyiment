import 'package:flutter/material.dart';

import 'app_language.dart';
import 'menti_experience_settings.dart';
import 'menti_intro.dart';
import 'menti_motion.dart';
import 'menti_ui.dart';

class MentiSettingsPage extends StatelessWidget {
  const MentiSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final settings = MentiExperienceScope.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 26 ? 104 : kToolbarHeight,
        title: Text(s.experienceSettings, maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: const [LanguageMenu()],
      ),
      body: MentiPageBody(children: [
        if (settings != null) MentiPanel(child: Column(children: [
          SwitchListTile.adaptive(
            key: const ValueKey('experience-reactions'),
            contentPadding: EdgeInsets.zero,
            title: Text(s.experienceReactions),
            subtitle: Text(s.experienceReactionsHint),
            value: settings.reactions,
            onChanged: settings.ready && !settings.saving ? settings.setReactions : null,
          ),
          if (!settings.ready && settings.error == null) const LinearProgressIndicator(),
          if (settings.error != null) MentiStatusMessage(
            message: settings.error == 'save' ? s.experienceSaveError : s.experienceLoadError,
            isError: true, onRetry: settings.saving ? null : settings.load,
            retryLabel: s.experienceReload),
        ])),
        const MentiPanel(child: MentiMotionPreference()),
        OutlinedButton.icon(
          key: const ValueKey('settings-open-intro'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const MentiIntroPage())),
          icon: const Icon(Icons.help_outline), label: Text(s.experienceIntroOpen)),
      ]),
    );
  }
}
