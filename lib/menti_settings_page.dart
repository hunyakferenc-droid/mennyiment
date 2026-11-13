import 'package:flutter/material.dart';

import 'app_language.dart';
import 'app_information.dart';
import 'menti_access.dart';
import 'menti_identity/menti_avatar_renderer.dart';
import 'menti_identity/menti_identity_controller.dart';
import 'menti_identity/menti_studio_page.dart';
import 'menti_experience_settings.dart';
import 'menti_intro.dart';
import 'menti_motion.dart';
import 'menti_complete_looks.dart';
import 'menti_ui.dart';

class MentiSettingsPage extends StatelessWidget {
  const MentiSettingsPage({super.key, this.onOpenBackup});
  final OpenLocalBackup? onOpenBackup;
  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final settings = MentiExperienceScope.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 26
            ? 104
            : kToolbarHeight,
        title: Text(
          s.experienceSettings,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [LanguageMenu()],
      ),
      body: MentiPageBody(
        children: [
          ListTile(
            key: const ValueKey('settings-complete-looks'),
            leading: const Icon(Icons.collections_outlined),
            title: Text(s.completeTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const CompleteLooksPage(),
              ),
            ),
          ),
          Text(
            s.visualSettingsInfo,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          MentiPanel(
            child: Column(
              children: [
                ListTile(
                  key: const ValueKey('settings-open-data'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(s.infoDataTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          DataSafetyPage(onOpenBackup: onOpenBackup),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  key: const ValueKey('settings-open-help'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.help_outline),
                  title: Text(s.infoHelpTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => MentiHelpPage(onOpenBackup: onOpenBackup),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  key: const ValueKey('settings-open-about'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: Text(s.infoAboutTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          MentiAboutPage(onOpenBackup: onOpenBackup),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            s.visualSettingsExperience,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (settings != null)
            MentiPanel(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    key: const ValueKey('experience-reactions'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.experienceReactions),
                    subtitle: Text(s.experienceReactionsHint),
                    value: settings.reactions,
                    onChanged: settings.ready && !settings.saving
                        ? settings.setReactions
                        : null,
                  ),
                  if (!settings.ready && settings.error == null)
                    const LinearProgressIndicator(),
                  if (settings.error != null)
                    MentiStatusMessage(
                      message: settings.error == 'save'
                          ? s.experienceSaveError
                          : s.experienceLoadError,
                      isError: true,
                      onRetry: settings.saving ? null : settings.load,
                      retryLabel: s.experienceReload,
                    ),
                ],
              ),
            ),
          const MentiPanel(child: MentiMotionPreference()),
          OutlinedButton.icon(
            key: const ValueKey('settings-open-intro'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MentiIntroPage()),
            ),
            icon: const Icon(Icons.help_outline),
            label: Text(s.experienceIntroOpen),
          ),
          MentiPanel(
            child: Column(
              children: [
                Text(
                  s.profileLocalTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const MentiCurrentAvatar(
                  size: 160,
                  legacyChild: SizedBox.shrink(),
                ),
                Text(
                  MentiIdentityScope.of(context)?.profile.name ?? 'Menti',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  MentiAccessScope.adultOf(context)
                      ? s.startAdult
                      : s.startMinor,
                ),
                const SizedBox(height: 8),
                Text(s.startLocalOnly),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MentiStudioPage(),
                    ),
                  ),
                  icon: const Icon(Icons.palette_outlined),
                  label: Text(s.avatarStudio),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
