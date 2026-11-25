import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_language.dart';
import 'menti_club_store.dart';
import 'menti_fitness.dart';

class MentiMovementCards extends StatefulWidget {
  const MentiMovementCards({
    super.key,
    required this.store,
    this.nextTestDay,
    this.testClock,
    this.onComplete,
  });
  final VoidCallback? nextTestDay;
  final DateTime Function()? testClock;
  final MentiClubStore store;
  final Future<ClubSave> Function()? onComplete;
  @override
  State<MentiMovementCards> createState() => _CardsState();
}

class _CardsState extends State<MentiMovementCards> {
  bool seated = true, started = false, busy = false, finished = false;
  int card = 0, performed = 0;
  ClubSave? result;
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    setState(() => busy = true);
    final next = await (widget.onComplete ?? widget.store.cards)();
    if (mounted) {
      setState(() {
        result = next;
        busy = false;
      });
    }
  }

  Future<void> next(bool skip) async {
    if (!started || finished || busy) return;
    setState(() {
      if (!skip) performed++;
      card++;
      if (card == 3) finished = true;
    });
    if (finished && performed > 0) {
      await save();
    } else if (!finished) {
      setState(() => busy = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final instructions = seated
        ? [s.cardsSeated1, s.cardsSeated2, s.cardsSeated3]
        : [s.cardsStanding1, s.cardsStanding2, s.cardsStanding3];
    return Scaffold(
      appBar: AppBar(title: Text(s.cardsTitle)),
      body: SafeArea(
        child: Focus(
          autofocus: true,
          focusNode: focus,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent || !started || finished || busy) {
              return KeyEventResult.ignored;
            }
            if (event.logicalKey == LogicalKeyboardKey.keyS) {
              next(true);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.keyN) {
              next(false);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Center(child: MentiFitnessArtwork()),
                  Text(s.cardsIntro),
                  if (widget.store.key == MentiClubStore.testKey &&
                      widget.nextTestDay != null &&
                      widget.testClock != null) ...[
                    Text(s.clubTestNotice),
                    Text(
                      s.clubTestDate(
                        DateFormat.yMMMd(s.localeName)
                            .format(widget.testClock!()),
                      ),
                    ),
                    OutlinedButton(
                      key: const ValueKey('cards-next-test-day'),
                      onPressed: busy
                          ? null
                          : () {
                              widget.nextTestDay!();
                              setState(() {});
                            },
                      child: Text(s.clubNextDay),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (!started) ...[
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          key: const ValueKey('cards-seated'),
                          label: Text(s.cardsSeated),
                          selected: seated,
                          onSelected: (_) => setState(() => seated = true),
                        ),
                        ChoiceChip(
                          key: const ValueKey('cards-standing'),
                          label: Text(s.cardsStanding),
                          selected: !seated,
                          onSelected: (_) => setState(() => seated = false),
                        ),
                      ],
                    ),
                    FilledButton(
                      key: const ValueKey('cards-start'),
                      onPressed: () => setState(() => started = true),
                      child: Text(s.rhythmPlay),
                    ),
                  ] else if (!finished) ...[
                    Text(
                      s.cardsStep(card + 1),
                      key: const ValueKey('cards-step'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(instructions[card]),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('cards-next'),
                      onPressed: busy ? null : () => next(false),
                      child: Text(s.cardsDone),
                    ),
                    OutlinedButton(
                      key: const ValueKey('cards-skip'),
                      onPressed: busy ? null : () => next(true),
                      child: Text(s.cardsSkip),
                    ),
                    Text(s.cardsKeyboard),
                  ] else ...[
                    Text(
                      s.cardsResult(performed),
                      key: const ValueKey('cards-result'),
                    ),
                    Text(
                      performed == 0
                          ? s.cardsAllSkipped
                          : result == ClubSave.failed
                          ? s.clubSaveError
                          : busy
                          ? s.clubSaving
                          : result == ClubSave.alreadyToday
                          ? s.clubAlreadyToday
                          : result == ClubSave.full
                          ? s.clubFull
                          : s.clubDaySaved,
                    ),
                    if (result == ClubSave.failed)
                      OutlinedButton(
                        key: const ValueKey('cards-save-retry'),
                        onPressed: busy
                            ? null
                            : () async {
                                await widget.store.load();
                                await save();
                              },
                        child: Text(s.homeRetryProgress),
                      ),
                    FilledButton(
                      key: const ValueKey('cards-club'),
                      onPressed: busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(s.rhythmBack),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const ValueKey('cards-exit'),
                    onPressed: busy ? null : () => Navigator.of(context).pop(),
                    child: Text(s.cardsExit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
