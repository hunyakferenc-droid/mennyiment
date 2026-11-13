import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_language.dart';
import 'drink_journal.dart';
import 'drink_catalog.dart';
import 'journal_query.dart';
import 'statistics_summary.dart';
import 'menti_ui.dart';

/// Filtering is read-only; edits delegate to the owner's single write path.
class DrinkJournalPage extends StatefulWidget {
  DrinkJournalPage({
    super.key,
    required List<Drink> drinks,
    this.hasSavedJournal = true,
    this.clock = DateTime.now,
    this.onEdit,
    this.canEdit = true,
  }) : _sourceDrinks = List.unmodifiable(drinks),
       drinks = List.unmodifiable(
         drinks.toList()..sort((a, b) => b.time.compareTo(a.time)),
       );

  // Preserve the existing public newest-first snapshot contract. Queries use
  // the original order so equal sort keys keep the caller's record order.
  final List<Drink> drinks;
  final List<Drink> _sourceDrinks;
  final bool hasSavedJournal;
  final DateTime Function() clock;
  final Future<bool> Function(int, Drink, bool)? onEdit;
  final bool canEdit;

  @override
  State<DrinkJournalPage> createState() => _DrinkJournalPageState();
}

class _DrinkJournalPageState extends State<DrinkJournalPage> {
  final _search = TextEditingController();
  JournalPeriod _period = JournalPeriod.all;
  JournalPrice _price = JournalPrice.all;
  JournalOrder _order = JournalOrder.newest;
  late DateTime _anchor;
  late final DateTime _openedDay;
  bool _opening = false;
  bool _filtersOpen = false;

  Future<void> _edit(int index, Drink drink, bool priceOnly) async {
    if (_opening || !widget.canEdit || widget.onEdit == null) return;
    _opening = true;
    try {
      final saved = await widget.onEdit!(index, drink, priceOnly);
      if (!saved || !mounted) return;
      final s = appStrings(context);
      final matches =
          JournalQuery(
            search: _search.text,
            period: _period,
            price: _price,
            order: _order,
          ).apply(
            widget._sourceDrinks,
            _anchor,
            label: (d) => catalogDrinkLabel(d.name, s),
          );
      final visible =
          index < widget._sourceDrinks.length &&
          matches.any((d) => identical(d, widget._sourceDrinks[index]));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visible ? s.entrySaved : s.entrySavedFiltered)),
      );
    } finally {
      _opening = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _openedDay = StatisticsRange.day(widget.clock());
    _anchor = _openedDay;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _move(int direction) => setState(() {
    switch (_period) {
      case JournalPeriod.all:
        break;
      case JournalPeriod.day:
        _anchor = StatisticsRange.addDays(_anchor, direction);
      case JournalPeriod.week:
        _anchor = StatisticsRange.addDays(_anchor, 7 * direction);
      case JournalPeriod.month:
        _anchor = DateTime(_anchor.year, _anchor.month + direction, 1);
      case JournalPeriod.year:
        _anchor = DateTime(_anchor.year + direction, 1, 1);
    }
  });

  void _reset() => setState(() {
    _search.clear();
    _period = JournalPeriod.all;
    _price = JournalPrice.all;
    _order = JournalOrder.newest;
    _anchor = _openedDay;
  });

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final locale = Localizations.localeOf(context).languageCode;
    final query = JournalQuery(
      search: _search.text,
      period: _period,
      price: _price,
      order: _order,
    );
    final drinks = query.apply(
      widget._sourceDrinks,
      _anchor,
      label: (drink) => catalogDrinkLabel(drink.name, s),
    );
    final totals = JournalTotals(drinks);
    final positions = <Drink, Queue<int>>{};
    for (final entry in widget._sourceDrinks.indexed) {
      (positions[entry.$2] ??= Queue<int>()).add(entry.$1);
    }
    final sourceIndices = [for (final d in drinks) positions[d]!.removeFirst()];
    final range = query.range(_anchor);
    final dateFormat = DateFormat.yMMMd(locale).add_Hm();
    final number = NumberFormat.decimalPattern(locale);
    // Keep recorded fractional amounts visible in the journal.
    final currency = NumberFormat.currency(
      locale: locale,
      symbol: locale == 'hu' ? 'Ft' : 'HUF',
      decimalDigits: 2,
    );
    final periodLabels = [
      s.journalAllTime,
      s.journalDay,
      s.week,
      s.month,
      s.year,
    ];
    final priceLabels = [
      s.journalAllPrices,
      s.journalMissingPrices,
      s.journalKnownPrices,
    ];
    final orderLabels = [
      s.journalNewest,
      s.journalOldest,
      s.journalHighestPrice,
    ];
    final activeCount =
        (_search.text.trim().isNotEmpty ? 1 : 0) +
        (_period != JournalPeriod.all ? 1 : 0) +
        (_price != JournalPrice.all ? 1 : 0) +
        (_order != JournalOrder.newest ? 1 : 0);
    return Scaffold(
      appBar: AppBar(title: Text(s.journal)),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('journal-add-drink'),
        onPressed: () => Navigator.of(context).pop(true),
        tooltip: s.visualAdd,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              itemCount: drinks.length + 2,
              itemBuilder: (context, index) {
                if (index == drinks.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      s.statisticsCaution,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: const ValueKey('journal-search'),
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: s.journalSearch,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: s.journalClearSearch,
                                    onPressed: () => setState(_search.clear),
                                    icon: const Icon(Icons.clear),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Semantics(
                              expanded: _filtersOpen,
                              child: OutlinedButton.icon(
                                key: const ValueKey('journal-filter-toggle'),
                                onPressed: () => setState(
                                  () => _filtersOpen = !_filtersOpen,
                                ),
                                icon: Icon(
                                  _filtersOpen ? Icons.expand_less : Icons.tune,
                                ),
                                label: Text(
                                  activeCount > 0
                                      ? s.visualFiltersCount(activeCount)
                                      : s.visualFilters,
                                ),
                              ),
                            ),
                            if (activeCount > 0)
                              TextButton.icon(
                                key: const ValueKey('journal-reset'),
                                onPressed: _reset,
                                icon: const Icon(Icons.filter_alt_off_outlined),
                                label: Text(s.journalReset),
                              ),
                          ],
                        ),
                        if (activeCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (_search.text.trim().isNotEmpty)
                                  InputChip(
                                    label: Text(_search.text),
                                    onDeleted: () => setState(_search.clear),
                                    deleteButtonTooltipMessage:
                                        s.journalClearSearch,
                                  ),
                                if (_period != JournalPeriod.all)
                                  InputChip(
                                    label: Text(periodLabels[_period.index]),
                                    onDeleted: () => setState(() {
                                      _period = JournalPeriod.all;
                                      _anchor = _openedDay;
                                    }),
                                    deleteButtonTooltipMessage: s.journalReset,
                                  ),
                                if (_price != JournalPrice.all)
                                  InputChip(
                                    label: Text(priceLabels[_price.index]),
                                    onDeleted: () => setState(
                                      () => _price = JournalPrice.all,
                                    ),
                                    deleteButtonTooltipMessage: s.journalReset,
                                  ),
                                if (_order != JournalOrder.newest)
                                  InputChip(
                                    label: Text(orderLabels[_order.index]),
                                    onDeleted: () => setState(
                                      () => _order = JournalOrder.newest,
                                    ),
                                    deleteButtonTooltipMessage: s.journalReset,
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Visibility(
                          visible: _filtersOpen,
                          maintainState: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final value in JournalPeriod.values)
                                    ChoiceChip(
                                      label: Text(periodLabels[value.index]),
                                      selected: _period == value,
                                      onSelected: (_) =>
                                          setState(() => _period = value),
                                    ),
                                ],
                              ),
                              if (range != null)
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: s.previousPeriod,
                                      onPressed: () => _move(-1),
                                      icon: const Icon(Icons.chevron_left),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${DateFormat.yMMMd(locale).format(range.start)} – '
                                        '${DateFormat.yMMMd(locale).format(StatisticsRange.addDays(range.end, -1))}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: s.nextPeriod,
                                      onPressed: () => _move(1),
                                      icon: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<JournalPrice>(
                                key: ValueKey('journal-price-${_price.name}'),
                                initialValue: _price,
                                isExpanded: true,
                                itemHeight: null,
                                decoration: InputDecoration(
                                  labelText: s.journalPriceFilter,
                                ),
                                items: [
                                  for (final value in JournalPrice.values)
                                    DropdownMenuItem(
                                      value: value,
                                      child: Text(priceLabels[value.index]),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _price = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<JournalOrder>(
                                key: ValueKey('journal-order-${_order.name}'),
                                initialValue: _order,
                                isExpanded: true,
                                itemHeight: null,
                                decoration: InputDecoration(
                                  labelText: s.journalSort,
                                ),
                                items: [
                                  for (final value in JournalOrder.values)
                                    DropdownMenuItem(
                                      value: value,
                                      child: Text(orderLabels[value.index]),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _order = value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        if (widget.drinks.isEmpty)
                          MentiStatusMessage(
                            message: widget.hasSavedJournal
                                ? s.experienceEmptyJournal
                                : s.hubMissing,
                            onRetry: () => Navigator.of(context).pop(true),
                            retryLabel: s.experienceAddEntry,
                          )
                        else if (drinks.isEmpty)
                          MentiStatusMessage(
                            message: s.journalNoMatches,
                            onRetry: _reset,
                            retryLabel: s.journalReset,
                          )
                        else
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.drinkCount(totals.count),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                  Text(
                                    '${s.journalVolume}: ${number.format(totals.ml)} ml',
                                  ),
                                  Text(
                                    '${s.journalKnownCost}: ${currency.format(totals.knownCost)}',
                                  ),
                                  Text(
                                    '${s.journalPriceCoverage}: ${totals.pricedCount}/${totals.count}',
                                  ),
                                  if (totals.missingCount > 0)
                                    Text(s.journalPartialCost),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Semantics(
                          container: true,
                          child: Text(
                            s.visualJournalScope,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final drink = drinks[index - 1];
                final sourceIndex = sourceIndices[index - 1];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catalogDrinkLabel(drink.name, s),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(dateFormat.format(drink.time.toLocal())),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text('${drink.ml} ml'),
                            Text('${number.format(drink.percent)}%'),
                            Text(
                              !JournalQuery.hasPrice(drink)
                                  ? s.homeUnknownPrice
                                  : currency.format(drink.priceFt!),
                            ),
                          ],
                        ),
                        if (widget.onEdit != null)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TextButton.icon(
                                key: ValueKey('journal-edit-$sourceIndex'),
                                onPressed: widget.canEdit
                                    ? () => _edit(sourceIndex, drink, false)
                                    : null,
                                icon: const Icon(Icons.edit_outlined),
                                label: Text(s.entryEdit),
                              ),
                              TextButton.icon(
                                key: ValueKey('journal-price-$sourceIndex'),
                                onPressed: widget.canEdit
                                    ? () => _edit(sourceIndex, drink, true)
                                    : null,
                                icon: const Icon(Icons.payments_outlined),
                                label: Text(s.entryEditPrice),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
