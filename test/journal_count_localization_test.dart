import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/l10n/generated/app_localizations_en.dart';

void main() {
  test('English journal and calendar counts use singular only for one', () {
    final strings = AppLocalizationsEn();
    expect(strings.drinkCount(0), '0 drinks');
    expect(strings.drinkCount(1), '1 drink');
    expect(strings.drinkCount(2), '2 drinks');
    expect(strings.dayCount(0), '0 days');
    expect(strings.dayCount(1), '1 day');
    expect(strings.dayCount(2), '2 days');
  });
}
