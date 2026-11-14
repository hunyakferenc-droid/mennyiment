import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_language.dart';
import 'l10n/generated/app_localizations.dart';
import 'menti_xp_store.dart';
import 'menti_collection_model.dart';
import 'menti_collection_store.dart';

class CompleteLookScope extends StatefulWidget {
  const CompleteLookScope({super.key, required this.child, this.store});
  final Widget child;
  final CompleteLookStore? store;
  static CompleteLookStore? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_CompleteInherited>()
      ?.notifier;
  @override
  State<CompleteLookScope> createState() => _CompleteLookScopeState();
}

class _CompleteLookScopeState extends State<CompleteLookScope>
    with WidgetsBindingObserver {
  late final store = widget.store ?? CompleteLookStore();
  bool _noticeScheduled = false;
  void _refresh() => store.load();
  void _announce() {
    if (_noticeScheduled) return;
    _noticeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _noticeScheduled = false;
      if (!mounted || AppLocalizations.of(context) == null) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      final ids = store.takeNewUnlocks();
      if (ids.isEmpty) return;
      final names = ids
          .map(
            (id) =>
                CompleteLook.find(id, catalog: store.catalog)?.name(context),
          )
          .whereType<String>()
          .join(', ');
      if (names.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(appStrings(context).collectionUnlockNotice(names)),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MentiXpStore.changes.addListener(_refresh);
    store.addListener(_announce);
    store.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MentiXpStore.changes.removeListener(_refresh);
    store.removeListener(_announce);
    if (widget.store == null) store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _CompleteInherited(notifier: store, child: widget.child);
}

class _CompleteInherited extends InheritedNotifier<CompleteLookStore> {
  const _CompleteInherited({required super.notifier, required super.child});
}

/// One complete PNG, shared canvas and footline. The environment is separate.
/// No legacy face, clothing, hat or reward overlay enters this renderer.
class CompleteLookArtwork extends StatelessWidget {
  const CompleteLookArtwork({
    super.key,
    required this.look,
    this.size = 260,
    this.background = false,
    this.decodeScale = 1,
  }) : assert(decodeScale >= 1 && decodeScale <= 3);
  final CompleteLook look;
  final double size;
  final bool background;

  /// Decode for the maximum zoom only in the magnifier, bounded by source size.
  final double decodeScale;
  static const backgroundColor = Color(0xFFF2EFF6);
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: look.name(context),
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: size,
          height: size * 4 / 3,
          child: ColoredBox(
            color: background ? backgroundColor : Colors.transparent,
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = math.min(
                    constraints.maxHeight * .88 / look.bounds.height,
                    constraints.maxWidth * .92 / look.bounds.width,
                  );
                  final width = look.sourceSize.width * scale;
                  final height = look.sourceSize.height * scale;
                  final cacheWidth =
                      (width *
                              MediaQuery.devicePixelRatioOf(context) *
                              decodeScale)
                          .ceil()
                          .clamp(1, look.sourceSize.width.toInt());
                  return Stack(
                    children: [
                      Positioned(
                        left:
                            (constraints.maxWidth - look.bounds.width * scale) /
                                2 -
                            look.bounds.left * scale,
                        top:
                            constraints.maxHeight * .94 -
                            look.bounds.bottom * scale,
                        width: width,
                        height: height,
                        child: Image.asset(
                          look.asset,
                          width: width,
                          height: height,
                          cacheWidth: cacheWidth,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stack) => Center(
                            child: Text(appStrings(context).completeImageError),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
