import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_language.dart';
import 'drink_journal.dart';

/// A read-only snapshot. Opening this route cannot migrate or change records.
/// Editing remains on the existing home persistence path.
class DrinkJournalPage extends StatelessWidget {
  DrinkJournalPage({super.key, required List<Drink> drinks})
      : drinks = List.unmodifiable(drinks.toList()
          ..sort((a, b) => b.time.compareTo(a.time)));

  final List<Drink> drinks;

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat.yMMMd(locale).add_Hm();
    return Scaffold(
      appBar: AppBar(title: Text(s.journal)),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('journal-add-drink'),
        onPressed: () => Navigator.of(context).pop(true),
        tooltip: s.addDrink,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(top: false, child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          itemCount: drinks.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(drinks.isEmpty ? s.homeEmptyJournal : s.drinkCount(drinks.length),
                  style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(s.statisticsCaution),
              ]),
            );
            final drink = drinks[index - 1];
            return Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(drink.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(dateFormat.format(drink.time.toLocal())),
                Wrap(spacing: 12, runSpacing: 8, children: [
                  Text('${drink.ml} ml'),
                  Text('${NumberFormat.decimalPattern(locale).format(drink.percent)}%'),
                  Text(drink.priceFt == null ? s.homeUnknownPrice
                      : localeCurrency(drink.priceFt!, locale)),
                ]),
              ]),
            ));
          },
        ),
      ))),
    );
  }
}
