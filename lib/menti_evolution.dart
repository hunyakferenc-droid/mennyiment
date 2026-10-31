import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Menti Evolution: drop-in character widget for the existing PNG asset.
/// No additional packages required.
class MentiEvolution extends StatefulWidget {
  const MentiEvolution({
    super.key,
    this.size = 260,
    this.reaction = 0,
    this.level = 1,
    this.assetPath = 'assets/images/menti_open.png',
    this.onTap,
  });

  final double size;
  final int reaction;
  final int level;
  final String assetPath;
  final VoidCallback? onTap;

  @override
  State<MentiEvolution> createState() => _MentiEvolutionState();
}

class _MentiEvolutionState extends State<MentiEvolution>
    with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _celebrate;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(covariant MentiEvolution oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reaction != widget.reaction ||
        oldWidget.level != widget.level) {
      _celebrate.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Menti, ${widget.level}. szintű karakter. Koppints az animációhoz.',
      button: true,
      child: GestureDetector(
        onTap: () {
          _celebrate.forward(from: 0);
          widget.onTap?.call();
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size * 1.14,
          child: AnimatedBuilder(
            animation: Listenable.merge([_idle, _celebrate]),
            builder: (context, child) {
              final idle = math.sin(_idle.value * math.pi * 2);
              final bump = math.sin(_celebrate.value * math.pi);
              final tilt = (idle * 0.015) + (bump * 0.08);
              final scale = 1 + bump * 0.07;
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: 10,
                    child: Container(
                      width: widget.size * (0.55 - bump * 0.07),
                      height: widget.size * 0.065,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.19),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, idle * 7 - bump * 16),
                    child: Transform.rotate(
                      angle: tilt,
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  ),
                  Positioned(
                    right: 3,
                    top: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF19392F),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF76E4B8)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        child: Text('LVL ${widget.level}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF76E4B8),
                            )),
                      ),
                    ),
                  ),
                  if (_celebrate.isAnimating)
                    Positioned(
                      top: 0,
                      left: 10,
                      child: Opacity(
                        opacity: (1 - _celebrate.value).clamp(0, 1),
                        child: const Icon(Icons.auto_awesome,
                            size: 33, color: Color(0xFFFFCE55)),
                      ),
                    ),
                ],
              );
            },
            child: Image.asset(
              widget.assetPath,
              cacheWidth: (widget.size * MediaQuery.devicePixelRatioOf(context))
                  .ceil().clamp(1, 1024),
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const Center(
                child: Text('Menti képe nem található'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
