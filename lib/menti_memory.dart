import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_language.dart';
import 'menti_club_store.dart';

enum _MemoryPhase { ready, showing, input, result }

/// The example stays visible until the player supplies its one correct symbol.
class MentiMemory extends StatefulWidget {
  const MentiMemory({
    super.key,
    required this.store,
    this.onComplete,
    this.resultCharacter,
  });

  final MentiClubStore store;
  final Future<ClubSave> Function()? onComplete;
  final Widget Function(bool passed)? resultCharacter;

  @override
  State<MentiMemory> createState() => _MentiMemoryState();
}

class _MentiMemoryState extends State<MentiMemory> with WidgetsBindingObserver {
  static const _icons = [
    Icons.circle_outlined,
    Icons.change_history,
    Icons.square_outlined,
  ];
  final _random = Random();
  final List<int> _pattern = [];
  var _phase = _MemoryPhase.ready;
  var _level = 1;
  var _step = 0;
  var _offset = 0;
  var _practice = true;
  var _failedPractice = false;
  var _passed = false;
  var _saving = false;
  var _failed = false;
  Timer? _preview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _preview?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _preview?.cancel();
    if (state == AppLifecycleState.resumed && _phase == _MemoryPhase.showing) {
      _showNext();
    }
  }

  void _start() {
    _preview?.cancel();
    setState(() {
      _pattern
        ..clear()
        ..addAll(
          List.generate(_level + 2, (_) => _random.nextInt(_icons.length)),
        );
      _phase = _MemoryPhase.showing;
      _offset = _step = 0;
      _failed = false;
    });
    _showNext();
  }

  void _showNext() {
    _preview = Timer(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      setState(() {
        if (_offset + 1 == _pattern.length) {
          _phase = _MemoryPhase.input;
        } else {
          _offset++;
        }
      });
      if (_phase == _MemoryPhase.showing) _showNext();
    });
  }

  void _press(int index) {
    if (_practice) {
      setState(() {
        _practice = index != 0;
        _failedPractice = _practice;
      });
      return;
    }
    if (_phase != _MemoryPhase.input) return;
    if (index != _pattern[_step]) {
      setState(() {
        _phase = _MemoryPhase.result;
        _passed = false;
      });
      return;
    }
    setState(() {
      _step++;
      if (_step == _pattern.length) {
        _phase = _MemoryPhase.result;
        _passed = true;
      }
    });
    if (_passed && _phase == _MemoryPhase.result) unawaited(_save());
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    final record = await widget.store.memory(_level);
    final result = record == ClubSave.failed
        ? record
        : await widget.onComplete?.call();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _failed = result == ClubSave.failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hu = appStrings(context).localeName == 'hu';
    final labels = hu
        ? ['Kör', 'Háromszög', 'Négyzet']
        : ['Circle', 'Triangle', 'Square'];
    final result = _phase == _MemoryPhase.result;
    final showing = _practice || _phase == _MemoryPhase.showing;
    final cue = _practice
        ? 0
        : showing
        ? _pattern[_offset]
        : null;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(
          LogicalKeyboardKey.digit1,
          includeRepeats: false,
        ): () =>
            _press(0),
        const SingleActivator(
          LogicalKeyboardKey.digit2,
          includeRepeats: false,
        ): () =>
            _press(1),
        const SingleActivator(
          LogicalKeyboardKey.digit3,
          includeRepeats: false,
        ): () =>
            _press(2),
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: !_saving,
          child: Scaffold(
            appBar: AppBar(
              title: Text(hu ? 'Menti Emlékminta' : 'Menti Memory Pattern'),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_practice)
                  Text(
                    hu
                        ? 'Próba: válaszd ki a mutatott jelet.'
                        : 'Practice: choose the symbol shown.',
                  ),
                if (_failedPractice)
                  Text(hu ? 'Próbáld a kört.' : 'Try the circle.'),
                if (cue != null)
                  Semantics(
                    liveRegion: true,
                    child: ListTile(
                      leading: Icon(_icons[cue], size: 32),
                      title: Text(
                        labels[cue],
                        key: const ValueKey('memory-cue'),
                      ),
                      subtitle: _practice
                          ? null
                          : Text('${_offset + 1} / ${_pattern.length}'),
                    ),
                  ),
                if (!_practice && _phase == _MemoryPhase.ready) ...[
                  Text(
                    hu
                        ? 'Jegyezd meg a jelek sorrendjét.'
                        : 'Remember the order of the symbols.',
                  ),
                  for (var n = 1; n <= 3; n++)
                    ChoiceChip(
                      selected: _level == n,
                      onSelected: (_) => setState(() => _level = n),
                      label: Text(
                        hu
                            ? '$n. szint · ${n + 2} jel'
                            : 'Level $n · ${n + 2} symbols',
                      ),
                    ),
                  FilledButton(
                    key: const ValueKey('memory-start'),
                    onPressed: _start,
                    child: Text(hu ? 'Minta indítása' : 'Start pattern'),
                  ),
                ],
                if (_phase == _MemoryPhase.input)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      hu
                          ? 'Te jössz · $_step / ${_pattern.length}'
                          : 'Your turn · $_step / ${_pattern.length}',
                      key: const ValueKey('memory-input'),
                    ),
                  ),
                if (_practice || _phase == _MemoryPhase.input)
                  for (var n = 0; n < _icons.length; n++)
                    OutlinedButton.icon(
                      key: ValueKey('memory-symbol-$n'),
                      onPressed: () => _press(n),
                      icon: Icon(_icons[n]),
                      label: Text('${n + 1}. ${labels[n]}'),
                    ),
                if (result) ...[
                  if (widget.resultCharacter != null)
                    Center(child: widget.resultCharacter!(_passed)),
                  Text(
                    _passed
                        ? (hu ? 'Megvan a minta!' : 'Pattern matched!')
                        : (hu
                              ? 'A következő jel: ${labels[_pattern[_step]]}'
                              : 'The next symbol was ${labels[_pattern[_step]]}'),
                    key: const ValueKey('memory-result'),
                  ),
                  Text('$_step / ${_pattern.length}'),
                  if (_failed)
                    TextButton(
                      onPressed: () async {
                        await widget.store.load();
                        if (mounted) await _save();
                      },
                      child: Text(hu ? 'Mentés újra' : 'Retry save'),
                    ),
                  FilledButton(
                    key: const ValueKey('memory-replay'),
                    onPressed: _saving || _failed ? null : _start,
                    child: Text(hu ? 'Új minta' : 'New pattern'),
                  ),
                  TextButton(
                    onPressed: _saving || _failed
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(hu ? 'Vissza Mentihez' : 'Back to Menti'),
                  ),
                ],
                Text(
                  hu
                      ? 'Saját rekord: ${widget.store.record.best}. szint'
                      : 'Personal best: level ${widget.store.record.best}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
