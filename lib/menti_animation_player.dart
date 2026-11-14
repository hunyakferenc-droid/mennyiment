import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'menti_animation_catalog.dart';
import 'menti_animation_controller.dart';
import 'menti_animation_settings.dart';
import 'menti_collection_model.dart';
import 'menti_collection_widgets.dart';
import 'menti_experience_settings.dart';
import 'menti_life_events.dart';
import 'menti_motion.dart';

class MentiAnimationScope extends StatefulWidget {
  const MentiAnimationScope({
    super.key,
    required this.child,
    this.controller,
    this.settings,
  });
  final Widget child;
  final MentiAnimationController? controller;
  final MentiAnimationSettings? settings;
  static MentiAnimationSession? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LifeInherited>()?.session;
  @override
  State<MentiAnimationScope> createState() => _MentiAnimationScopeState();
}

class MentiAnimationSession {
  MentiAnimationSession(this.controller, this.settings);
  final MentiAnimationController controller;
  final MentiAnimationSettings settings;
}

class _MentiAnimationScopeState extends State<MentiAnimationScope>
    with WidgetsBindingObserver {
  late final controller = widget.controller ?? MentiAnimationController();
  late final settings = widget.settings ?? MentiAnimationSettings();
  late final session = MentiAnimationSession(controller, settings);
  bool _opened = false, _scheduled = false, _catalogReady = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    settings.addListener(_refresh);
    controller.addListener(_controllerChanged);
    MentiLifeEvents.instance.addListener(_event);
    settings.load();
    _catalogReady = widget.controller != null;
    if (!_catalogReady) _catalog();
  }

  Future<void> _catalog() async {
    try {
      final catalog = MentiAnimationCatalog.decode(
        await rootBundle.loadString('assets/menti_life/catalog.json'),
      );
      if (mounted) {
        _catalogReady = true;
        controller.replaceCatalog(catalog);
        _refresh();
      }
    } catch (_) {
      if (mounted) {
        _catalogReady = true;
        controller.replaceCatalog(const MentiAnimationCatalog());
        _refresh();
      }
    }
  }

  void _controllerChanged() {
    if (!_opened) _refresh();
  }

  void _event() {
    final signal = MentiLifeEvents.instance.last;
    if (signal != null) controller.react(signal);
  }

  void _refresh() {
    if (!mounted || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final complete = CompleteLookScope.of(context), prefs = settings;
      controller.configure(
        look: complete?.ready == true && complete!.selection.active
            ? complete.selection.lookId
            : null,
        allowed:
            prefs.ready &&
            !prefs.saving &&
            prefs.value.enabled &&
            MentiMotionScope.animateOf(context) &&
            MentiExperienceScope.reactionsOf(context),
        frequency: prefs.value.frequency,
      );
      if (_catalogReady &&
          !_opened &&
          controller.lookId != null &&
          controller.hasVisibleHost) {
        _opened = true;
        controller.react(
          const MentiLifeSignal(MentiLifeEvent.appOpened, 'open'),
        );
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    CompleteLookScope.of(context);
    MentiMotionScope.settingsOf(context);
    MentiMotionScope.systemReducedOf(context);
    MentiExperienceScope.of(context);
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    controller.foreground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) settings.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MentiLifeEvents.instance.removeListener(_event);
    settings.removeListener(_refresh);
    controller.removeListener(_controllerChanged);
    if (widget.settings == null) settings.dispose();
    if (widget.controller == null) {
      controller.dispose();
    } else {
      controller.foreground(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _LifeInherited(session: session, child: widget.child);
}

class _LifeInherited extends InheritedWidget {
  const _LifeInherited({required this.session, required super.child});
  final MentiAnimationSession session;
  @override
  bool updateShouldNotify(_LifeInherited oldWidget) =>
      session != oldWidget.session;
}

class MentiAnimationPlayer extends StatefulWidget {
  const MentiAnimationPlayer({
    super.key,
    required this.look,
    this.size = 260,
    this.controller,
  });
  final CompleteLook look;
  final double size;
  final MentiAnimationController? controller;
  @override
  State<MentiAnimationPlayer> createState() => _MentiAnimationPlayerState();
}

class _MentiAnimationPlayerState extends State<MentiAnimationPlayer> {
  MentiAnimationController? _controller;
  final Object _host = Object();
  bool _visible = false;
  ScrollPosition? _scroll;
  void _scrolled() => _register();
  void _register() {
    final controller =
        widget.controller ?? MentiAnimationScope.of(context)?.controller;
    if (_controller != controller) {
      _controller?.removeHost(_host);
      _controller = controller;
    }
    _visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        MentiMotionScope.animateOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final box = context.findRenderObject();
        if (box is RenderBox && box.hasSize) {
          final bounds = box.localToGlobal(Offset.zero) & box.size;
          var viewport = Offset.zero & MediaQuery.sizeOf(context);
          final parent = RenderAbstractViewport.maybeOf(box);
          if (parent is RenderBox) {
            final viewportBox = parent as RenderBox;
            if (viewportBox.hasSize) {
              viewport = viewport.intersect(
                viewportBox.localToGlobal(Offset.zero) & viewportBox.size,
              );
            }
          }
          _visible = _visible && bounds.overlaps(viewport);
        } else {
          _visible = false;
        }
        _controller?.host(
          _host,
          look: widget.look.id,
          size: widget.size,
          visible: _visible,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _scroll) {
      _scroll?.removeListener(_scrolled);
      _scroll = position;
      _scroll?.addListener(_scrolled);
    }
    _register();
  }

  @override
  void didUpdateWidget(covariant MentiAnimationPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _register();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_scrolled);
    _controller?.removeHost(_host);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poster = CompleteLookArtwork(
      look: widget.look,
      size: widget.size,
      background: false,
    );
    final c = _controller;
    if (c == null) return poster;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final media = c.owns(_host) && _visible ? c.handle : null;
        if (media == null) return poster;
        return SizedBox(
          width: widget.size,
          height: widget.size * 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(child: ClipRect(child: media.view)),
              if (!media.frameVisible) poster,
            ],
          ),
        );
      },
    );
  }
}
