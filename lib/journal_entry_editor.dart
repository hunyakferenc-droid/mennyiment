import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_language.dart';
import 'drink_catalog.dart';
import 'drink_journal.dart';

/// Draft UI only. The owner persists through the existing journal write path.
class JournalEntryEditor extends StatefulWidget {
  const JournalEntryEditor({
    super.key,
    required this.drink,
    required this.onSave,
    this.priceOnly = false,
    this.clock = DateTime.now,
  });
  final Drink drink;
  final Future<bool> Function(Drink) onSave;
  final bool priceOnly;
  final DateTime Function() clock;

  @override
  State<JournalEntryEditor> createState() => _JournalEntryEditorState();
}

class _JournalEntryEditorState extends State<JournalEntryEditor> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  late final List<String> _initial;
  bool _saving = false, _leaving = false, _allowPop = false;
  bool _removePrice = false, _failed = false;
  String? _dateError;
  bool _localized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localized) return;
    _localized = true;
    if (Localizations.localeOf(context).languageCode == 'hu') {
      for (final index in [2, 3]) {
        _initial[index] = _initial[index].replaceAll('.', ',');
        _fields[index].text = _initial[index];
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final d = widget.drink;
    _initial = [
      d.name,
      '${d.ml}',
      '${d.percent}',
      d.priceFt?.toString() ?? '',
      DateFormat('yyyy-MM-dd').format(d.time.toLocal()),
      DateFormat('HH:mm').format(d.time.toLocal()),
    ];
    _fields = _initial.map((s) => TextEditingController(text: s)).toList();
    for (final c in _fields) {
      c.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) {
      setState(() {
        _dateError = null;
      });
    }
  }

  bool get _dirty =>
      _removePrice || _fields.indexed.any((e) => e.$2.text != _initial[e.$1]);
  double? _number(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _leave() async {
    if (_saving || _leaving) return;
    _leaving = true;
    try {
      if (_dirty) {
        final s = appStrings(context);
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            scrollable: true,
            title: Text(s.entryDiscardTitle),
            content: Text(s.entryDiscardBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.entryKeepEditing),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.entryDiscard),
              ),
            ],
          ),
        );
        if (discard != true) return;
      }
      if (mounted) {
        setState(() => _allowPop = true);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.pop(context, false);
      }
    } finally {
      _leaving = false;
    }
  }

  DateTime? _timestamp() {
    if (_fields[4].text == _initial[4] && _fields[5].text == _initial[5]) {
      return widget.drink.time;
    }
    final date = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$')
        .firstMatch(_fields[4].text.trim());
    final time = RegExp(r'^(\d{2}):(\d{2})$')
        .firstMatch(_fields[5].text.trim());
    if (date == null || time == null) return null;
    final y = int.parse(date[1]!),
        m = int.parse(date[2]!),
        day = int.parse(date[3]!);
    final h = int.parse(time[1]!), min = int.parse(time[2]!);
    final old = widget.drink.time.toLocal();
    final sameTime = _fields[5].text == _initial[5];
    final value = DateTime(
      y,
      m,
      day,
      h,
      min,
      sameTime ? old.second : 0,
      sameTime ? old.millisecond : 0,
      sameTime ? old.microsecond : 0,
    );
    if (y < 1 ||
        value.year != y ||
        value.month != m ||
        value.day != day ||
        value.hour != h ||
        value.minute != min) {
      return null;
    }
    return value;
  }

  Future<void> _save() async {
    if (_saving || _leaving || !_form.currentState!.validate()) return;
    final timestamp = widget.priceOnly ? widget.drink.time : _timestamp();
    if (timestamp == null ||
        (timestamp != widget.drink.time && timestamp.isAfter(widget.clock()))) {
      setState(() => _dateError = appStrings(context).entryDateError);
      return;
    }
    final priceChanged = _removePrice || _fields[3].text != _initial[3];
    final next = widget.drink.edited(
      name: widget.priceOnly || _fields[0].text == _initial[0]
          ? null
          : _fields[0].text.trim(),
      ml: widget.priceOnly ? null : _number(_fields[1].text)!.toInt(),
      percent: widget.priceOnly ? null : _number(_fields[2].text),
      time: timestamp,
      editPrice: priceChanged,
      priceFt: _fields[3].text.trim().isEmpty ? null : _number(_fields[3].text),
    );
    setState(() {
      _saving = true;
      _failed = false;
    });
    var ok = false;
    try {
      ok = await widget.onSave(next);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (ok) {
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    Widget field(
      int i,
      String label, {
      String? helper,
      TextInputType? keyboard,
      String? Function(String?)? validator,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey('entry-field-$i'),
        controller: _fields[i],
        enabled: !_saving,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 5,
          errorMaxLines: 4,
        ),
        validator: validator,
      ),
    );
    return PopScope<bool>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight:
              56 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: _saving ? null : _leave,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            widget.priceOnly ? s.entryEditPrice : s.entryEdit,
            maxLines: 2,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    if (widget.priceOnly)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          s.journalSetPrice(
                            catalogDrinkLabel(widget.drink.name, s),
                          ),
                        ),
                      ),
                    if (!widget.priceOnly) ...[
                      field(
                        0,
                        s.journalDrinkName,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? s.journalInvalid
                            : null,
                      ),
                      field(
                        1,
                        s.journalMl,
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          final n = _number(v ?? '');
                          return n == null ||
                                  !n.isFinite ||
                                  n < 1 ||
                                  n > 10000 ||
                                  n != n.roundToDouble()
                              ? s.journalMlError
                              : null;
                        },
                      ),
                      field(
                        2,
                        s.journalPercent,
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          final n = _number(v ?? '');
                          return n == null || !n.isFinite || n < 0 || n > 100
                              ? s.journalPercentError
                              : null;
                        },
                      ),
                    ],
                    field(
                      3,
                      s.journalPrice,
                      helper: s.journalPriceHint,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return null;
                        final n = _number(v!);
                        return n == null || !n.isFinite || n < 0 || n > 10000000
                            ? s.journalPriceError
                            : null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _saving
                            ? null
                            : () {
                                _fields[3].clear();
                                setState(() => _removePrice = true);
                              },
                        child: Text(s.journalRemovePrice),
                      ),
                    ),
                    if (!widget.priceOnly) ...[
                      field(
                        4,
                        s.entryDate,
                        helper: s.entryDateHint,
                        keyboard: TextInputType.datetime,
                      ),
                      field(
                        5,
                        s.entryTime,
                        helper: s.entryTimeHint,
                        keyboard: TextInputType.datetime,
                      ),
                      Text(s.entryFutureRule),
                    ],
                    if (_dateError != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _dateError!,
                          key: const ValueKey('entry-date-error'),
                        ),
                      ),
                    if (_failed)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          s.homeJournalSaveError,
                          key: const ValueKey('entry-save-error'),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const ValueKey('entry-save'),
                      onPressed: _saving ? null : _save,
                      child: Text(s.avatarSave),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _leave,
                      child: Text(s.avatarCancel),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
