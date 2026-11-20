import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';
import 'l10n/generated/app_localizations.dart';
import 'menti_alive_review_catalog.dart';
import 'menti_animation_catalog.dart';
import 'menti_animation_studio_model.dart';
import 'menti_animation_controller.dart';
import 'menti_animation_player.dart';
import 'menti_collection_model.dart';
import 'menti_collection_store.dart';
import 'menti_collection_widgets.dart';
import 'menti_design.dart';
import 'menti_life_events.dart';
import 'menti_motion.dart';
import 'menti_reaction_engine.dart';
import 'menti_animation_preview.dart' show mentiLifeReactionLabel;

/// Separate entry point only. This page has no route from the regular app.
class MentiAliveReviewApp extends StatefulWidget {
  const MentiAliveReviewApp({
    super.key,
    this.reviewEnabled = false,
    this.studioMode = false,
  });
  final bool reviewEnabled, studioMode;
  @override
  State<MentiAliveReviewApp> createState() => _MentiAliveReviewAppState();
}

class _MentiAliveReviewAppState extends State<MentiAliveReviewApp> {
  Locale _locale = const Locale('hu');
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Menti Alive – review',
    debugShowCheckedModeBanner: false,
    theme: MentiDesign.theme,
    locale: _locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MentiMotionScope(child: child!),
    home: MentiAlivePreviewPage(
      developerPreview: widget.reviewEnabled,
      studioMode: widget.studioMode,
      onLocale: (l) => setState(() => _locale = Locale(l)),
    ),
  );
}

class MentiAlivePreviewPage extends StatefulWidget {
  const MentiAlivePreviewPage({
    super.key,
    this.developerPreview = false,
    this.onLocale,
    this.controller,
    this.reviewCatalog,
    this.savedRaw,
    this.readPreferences = true,
    this.studioMode = false,
  });
  final bool developerPreview, readPreferences, studioMode;
  final void Function(String)? onLocale;
  final MentiAnimationController? controller;
  final MentiAliveReviewCatalog? reviewCatalog;
  final Object? savedRaw;
  @override
  State<MentiAlivePreviewPage> createState() => _MentiAlivePreviewPageState();
}

class _MentiAlivePreviewPageState extends State<MentiAlivePreviewPage>
    with WidgetsBindingObserver {
  late final c = widget.controller ?? MentiAnimationController();
  final _videoKey = GlobalKey();
  final _scroll = ScrollController();
  MentiAnimationCatalog _production = const MentiAnimationCatalog();
  CompleteLook? _saved;
  CompleteLook _selected = CompleteLook.find('boy-festival-v1')!;
  bool _ready = false,
      _error = false,
      _savedError = false,
      _enabled = true,
      _busy = false;
  bool _scheduled = false;
  int _sequence = 0;
  int _intent = 0;

  void _stop() {
    _intent++;
    c.stop();
  }

  MentiLifeReaction _lastReaction = MentiLifeReaction.welcome;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.studioMode) _selected = CompleteLook.find('girl-base-v1')!;
    if (widget.developerPreview) _load();
  }

  Future<void> _load() async {
    try {
      Object? raw = widget.savedRaw;
      if (widget.readPreferences) {
        final p = await SharedPreferences.getInstance();
        await p.reload();
        raw = p.get(CompleteLookStore.key);
      }
      try {
        final selection = CompleteLookSelection.decode(raw);
        if (selection.active) {
          _saved = CompleteLook.find(selection.lookId);
          _selected = _saved!;
        }
      } catch (_) {
        _savedError = true;
      }
      final catalog =
          widget.reviewCatalog ??
          MentiAliveReviewCatalog.decode(
            await rootBundle.loadString(
              'assets/menti_alive_review/catalog.json',
            ),
            developerPreview: true,
          );
      if (!mounted) return;
      if (widget.studioMode) {
        _production = MentiAnimationCatalog.decode(
          await rootBundle.loadString(
            'assets/menti_life/catalog.json',
            cache: false,
          ),
        );
      }
      if (!mounted) return;
      c.replaceCatalog(
        widget.studioMode
            ? MentiStudioPlaybackCatalog(_production, catalog)
            : catalog,
      );
      setState(() => _ready = true);
      _configure();
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _configure() {
    if (!mounted || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      c.configure(
        look: _selected.id,
        allowed:
            widget.developerPreview &&
            _ready &&
            _enabled &&
            MentiMotionScope.animateOf(context),
        frequency: MentiAnimationFrequency.normal,
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MentiMotionScope.settingsOf(context);
    MentiMotionScope.systemReducedOf(context);
    _configure();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _intent++;
    c.foreground(state == AppLifecycleState.resumed);
  }

  Future<void> _play(
    MentiLifeReaction reaction, {
    bool restart = false,
    bool event = false,
    MentiLifeEvent? signal,
  }) async {
    if (_busy) return;
    final intent = ++_intent;
    setState(() {
      _busy = true;
      _lastReaction = reaction;
    });
    try {
      final target = _videoKey.currentContext;
      if (target != null) {
        await Scrollable.ensureVisible(
          target,
          alignment: .1,
          duration: MentiMotionScope.reducedOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
        );
      }
      if (!mounted || intent != _intent) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || intent != _intent) return;
      final token = 'review-${_sequence++}';
      if (signal != null) {
        c.react(MentiLifeSignal(signal, token), manual: true);
      } else if (event) {
        c.react(
          MentiLifeSignal(
            reaction == MentiLifeReaction.congratulation
                ? MentiLifeEvent.xpMilestone
                : MentiLifeEvent.selfControlCompleted,
            token,
          ),
          manual: true,
        );
      } else if (restart) {
        await c.restart(reaction, token: token);
      } else {
        c.request(reaction, token: token, manual: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    if (widget.controller == null) {
      c.dispose();
    } else {
      c.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context), motion = MentiMotionScope.animateOf(context);
    if (!widget.developerPreview) {
      return Scaffold(
        appBar: AppBar(title: Text(s.aliveTitle)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(s.aliveGate),
        ),
      );
    }
    final enabled = _ready && _enabled && motion && !_busy;
    final inventory = MentiStudioInventory(
      production: _production,
      review: c.catalog,
    );
    final studioEvents = <(MentiLifeEvent, String)>[
      (MentiLifeEvent.journalSaved, s.studioJournal),
      (MentiLifeEvent.xpEarned, s.studioXp),
      (MentiLifeEvent.xpMilestone, s.studioLevel),
      (MentiLifeEvent.lookUnlocked, s.studioLook),
      (MentiLifeEvent.accessoryUnlocked, s.studioAccessory),
      (MentiLifeEvent.taskCompleted, s.studioChallenge),
      (MentiLifeEvent.encouragementRequested, s.studioEncourage),
    ];
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(1) > 1.5
            ? 112
            : 64,
        title: Text(widget.studioMode ? 'Menti Studio' : 'Menti Alive'),
        actions: [
          TextButton(
            onPressed: () => widget.onLocale?.call('hu'),
            child: const Text('HU'),
          ),
          TextButton(
            onPressed: () => widget.onLocale?.call('en'),
            child: const Text('EN'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          child: ListenableBuilder(
            listenable: c,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    s.alivePending,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(s.aliveIntro),
                if (widget.studioMode) ...[
                  const SizedBox(height: 12),
                  Text(
                    s.studioTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(s.studioInventory),
                  if (!_ready) Text(_error ? s.aliveLoadError : s.lifeLoading),
                  if (_ready)
                    Wrap(
                      key: const ValueKey('studio-inventory-ready'),
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.verified_outlined),
                          label: Text(
                            '${s.studioReadyCount}: ${inventory.count(MentiStudioStatus.approved)}',
                          ),
                        ),
                        Chip(
                          avatar: const Icon(Icons.pending_outlined),
                          label: Text(
                            '${s.studioReviewCount}: ${inventory.count(MentiStudioStatus.reviewRequired)}',
                          ),
                        ),
                        Chip(
                          avatar: const Icon(Icons.image_outlined),
                          label: Text(
                            '${s.studioMissingCount}: ${inventory.count(MentiStudioStatus.missing)}',
                          ),
                        ),
                      ],
                    ),
                  Text(s.studioFamily),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final family in MentiStudioInventory.families)
                        ChoiceChip(
                          key: ValueKey('studio-family-$family'),
                          label: Text(switch (family) {
                            'girl' => s.collectionGirl,
                            'neutral' => s.collectionNeutral,
                            _ => s.collectionBoy,
                          }),
                          selected: _selected.family == family,
                          onSelected: (_) {
                            _stop();
                            setState(
                              () => _selected = MentiStudioInventory.looks
                                  .firstWhere((look) => look.family == family),
                            );
                            _configure();
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  s.aliveSaved,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_saved != null)
                  Row(
                    children: [
                      CompleteLookArtwork(
                        look: _saved!,
                        size: 72,
                        background: false,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_saved!.name(context))),
                    ],
                  )
                else
                  Text(_savedError ? s.aliveSavedError : s.aliveNoSaved),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('alive-look-${_selected.id}'),
                  initialValue: _selected.id,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: s.aliveSelection),
                  items: [
                    for (final look
                        in (widget.studioMode
                            ? MentiStudioInventory.looks.where(
                                (look) => look.family == _selected.family,
                              )
                            : CompleteLook.all))
                      DropdownMenuItem(
                        value: look.id,
                        child: Text(
                          look.name(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (id) {
                    if (id == null) return;
                    _stop();
                    setState(() => _selected = CompleteLook.find(id)!);
                    _configure();
                  },
                ),
                TextButton(
                  key: const ValueKey('alive-candidates'),
                  onPressed: () {
                    _stop();
                    setState(
                      () => _selected = CompleteLook.find('boy-festival-v1')!,
                    );
                    _configure();
                  },
                  child: Text(s.aliveCandidateChoice),
                ),
                SwitchListTile(
                  key: const ValueKey('alive-enabled'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.aliveEnabled),
                  value: _enabled,
                  onChanged: (v) {
                    _stop();
                    setState(() => _enabled = v);
                    _configure();
                  },
                ),
                if (widget.studioMode) Text(s.studioPosterHint),
                if (!motion) Text(s.lifeReduced),
                if (_error)
                  Semantics(liveRegion: true, child: Text(s.aliveLoadError)),
                if (_error && widget.studioMode)
                  TextButton(
                    key: const ValueKey('studio-retry'),
                    onPressed: () {
                      _stop();
                      setState(() {
                        _error = false;
                        _ready = false;
                      });
                      _load();
                    },
                    child: Text(s.infoRetry),
                  ),
                Container(
                  key: _videoKey,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff2a2036),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.aliveAnimated),
                          MentiAnimationPlayer(
                            look: _selected,
                            size: 180,
                            controller: c,
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.aliveStatic),
                          CompleteLookArtwork(
                            look: _selected,
                            size: 180,
                            background: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(switch (c.status) {
                    MentiPlaybackStatus.loading => s.lifeLoading,
                    MentiPlaybackStatus.error => s.lifePlaybackError,
                    MentiPlaybackStatus.noClip => s.aliveNoMedia,
                    MentiPlaybackStatus.disabled =>
                      _enabled ? s.lifeReduced : s.aliveDisabled,
                    MentiPlaybackStatus.playing => s.alivePlaying,
                    _ => s.aliveReady,
                  }),
                ),
                Text(mentiLifeReactionLabel(s, _lastReaction)),
                OutlinedButton.icon(
                  key: const ValueKey('alive-stop'),
                  onPressed: _stop,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(s.aliveStop),
                ),
                Text(s.aliveBackground),
                Text(s.aliveReviewReference),
                for (final reaction
                    in (widget.studioMode
                        ? MentiLifeReaction.values
                        : [
                            MentiLifeReaction.welcome,
                            MentiLifeReaction.wink,
                            MentiLifeReaction.congratulation,
                          ]))
                  Builder(
                    builder: (context) {
                      final clip = c.catalog.find(_selected.id, reaction);
                      return Card(
                        key: widget.studioMode
                            ? ValueKey('studio-slot-${reaction.name}')
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                mentiLifeReactionLabel(s, reaction),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                widget.studioMode
                                    ? !_ready
                                          ? (_error
                                                ? s.aliveLoadError
                                                : s.lifeLoading)
                                          : switch (inventory
                                                .slot(_selected, reaction)
                                                .status) {
                                              MentiStudioStatus.missing =>
                                                s.studioMissing,
                                              MentiStudioStatus
                                                  .reviewRequired =>
                                                s.studioReview,
                                              MentiStudioStatus.approved =>
                                                s.studioApproved,
                                            }
                                    : s.alivePending,
                              ),
                              if (clip == null)
                                Text(s.aliveNoMedia)
                              else
                                Text(
                                  '${clip.width}×${clip.height} · ${NumberFormat('0.00', locale).format(clip.durationMs / 1000)} s · ${NumberFormat('0.0', locale).format(clip.bytes / 1024)} KiB',
                                ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilledButton(
                                    key: ValueKey(
                                      'alive-play-${reaction.name}',
                                    ),
                                    onPressed: enabled && clip != null
                                        ? () => _play(reaction)
                                        : null,
                                    child: Text(s.alivePlay),
                                  ),
                                  OutlinedButton(
                                    key: ValueKey(
                                      'alive-restart-${reaction.name}',
                                    ),
                                    onPressed: enabled && clip != null
                                        ? () => _play(reaction, restart: true)
                                        : null,
                                    child: Text(s.aliveRestart),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                if (widget.studioMode) ...[
                  ExpansionTile(
                    key: const ValueKey('studio-events'),
                    title: Text(s.studioEvents),
                    children: [
                      Text(s.studioEventHint),
                      for (final pair in studioEvents)
                        ListTile(
                          title: Text(pair.$2),
                          subtitle: Text(
                            mentiLifeReactionLabel(
                              s,
                              MentiReactionEngine.plan(pair.$1).reaction,
                            ),
                          ),
                          trailing: IconButton(
                            key: ValueKey('studio-event-${pair.$1.name}'),
                            tooltip: s.alivePlay,
                            onPressed: enabled
                                ? () => _play(
                                    MentiReactionEngine.plan(pair.$1).reaction,
                                    signal: pair.$1,
                                  )
                                : null,
                            icon: const Icon(Icons.play_circle_outline),
                          ),
                        ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text(s.studioPerformance),
                    children: [
                      Text(s.studioNoMeasurement),
                      for (final measurement in c.measurements.reversed.take(5))
                        Text(
                          '${measurement['clip']} · ${measurement['initializeMs']} ms · ${measurement['bytes']} B',
                        ),
                    ],
                  ),
                ],
                Text(s.aliveDemoHint),
                OutlinedButton(
                  key: const ValueKey('alive-xp-demo'),
                  onPressed: enabled
                      ? () =>
                            _play(MentiLifeReaction.congratulation, event: true)
                      : null,
                  child: Text(s.aliveXpDemo),
                ),
                OutlinedButton(
                  key: const ValueKey('alive-control-demo'),
                  onPressed: enabled
                      ? () => _play(MentiLifeReaction.breathing, event: true)
                      : null,
                  child: Text(s.aliveSelfControlDemo),
                ),
                Text(s.aliveReadOnly),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
