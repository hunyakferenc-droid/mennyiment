// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MennyiMent?';

  @override
  String get home => 'Home';

  @override
  String get journal => 'Journal';

  @override
  String get insights => 'Insights';

  @override
  String get menti => 'Menti';

  @override
  String get profile => 'Menti and profile';

  @override
  String get language => 'Language / Nyelv';

  @override
  String get automatic => 'Automatic';

  @override
  String get hungarian => 'Magyar';

  @override
  String get english => 'English';

  @override
  String get languageError => 'Could not save your language preference.';

  @override
  String get statistics => '📊 Statistics';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get previousPeriod => 'Previous period';

  @override
  String get nextPeriod => 'Next period';

  @override
  String get drinks => 'Drinks';

  @override
  String get pureAlcohol => 'Pure alcohol';

  @override
  String get drinkVolume => 'Drink volume';

  @override
  String get unloggedDays => 'Days without entries';

  @override
  String get knownSpending => 'Known spending';

  @override
  String get noSpendingData =>
      'No drinks recorded: spending data is not available yet.';

  @override
  String get completePrices =>
      'All recorded drinks have a price in this period.';

  @override
  String partialPrices(int count) {
    return 'Partial total: $count drink prices are missing or invalid. A missing price is not HUF 0.';
  }

  @override
  String get alcoholByPeriod => 'Alcohol by period (g)';

  @override
  String get frequentDrinks => 'Most frequent drinks';

  @override
  String get noDrinks => 'No drinks recorded in this period.';

  @override
  String get drinkingTimes => 'Times of recorded drinks';

  @override
  String get noPeriodData => 'No data for this period.';

  @override
  String peakTime(String start, String end, int count) {
    return 'Most entries: $start–$end ($count entries).';
  }

  @override
  String get statisticsCaution =>
      'Summaries use recorded drinks only. A day without entries is not a confirmed alcohol-free day. These data cannot establish sobriety or fitness to drive.';

  @override
  String drinkCount(int count) {
    return '$count drinks';
  }

  @override
  String dayCount(int count) {
    return '$count days';
  }

  @override
  String grams(String value) {
    return '$value g';
  }

  @override
  String litres(String value) {
    return '$value l';
  }

  @override
  String get chooseMenti => 'Choose your Menti';

  @override
  String get mentiProgress => 'Menti progress';

  @override
  String get addDrink => 'LOG A DRINK';

  @override
  String get explore => 'Explore';

  @override
  String get financeCenter => 'Finance centre – detailed overview';

  @override
  String get wellbeing => 'Wellbeing';

  @override
  String get wellbeingHint => 'Mood, sleep and next day';

  @override
  String get savings => 'Savings';

  @override
  String get savingsHint => 'Car, holiday, your own goal';

  @override
  String get weeklyInsights => 'Weekly insights';

  @override
  String get weeklyInsightsHint => 'Patterns and trends';

  @override
  String get mentiProgressHint => 'Levels and challenges';

  @override
  String get goals => 'Goals';

  @override
  String get goalsHint => 'Budget and calendar';

  @override
  String get statisticsHint => 'Recorded consumption';

  @override
  String get personalGoals => 'My personal weekly goals • self-check';

  @override
  String get weeklyReport => 'Weekly Menti report • wellbeing and spending';

  @override
  String get allEntries => 'All entries';

  @override
  String get statisticsNav => 'Statistics';

  @override
  String get recentEntries => 'Recent entries';

  @override
  String get backupTitle => 'Data backup';

  @override
  String get backupContents =>
      'The backup includes the app’s local journals, character profile, outfit, XP, goals and settings.';

  @override
  String get backupPrivacy =>
      'The file is not encrypted and contains personal data. Save it somewhere safe. The app does not upload it automatically; you choose where to save or share it.';

  @override
  String get backupRestoreDeferred =>
      'This version supports export. Restore is not available yet; existing data will not be overwritten.';

  @override
  String get backupPrepare => 'Prepare backup';

  @override
  String get backupWorking => 'Working…';

  @override
  String get backupPreview => 'Prepared backup';

  @override
  String backupCreated(String date) {
    return 'Created: $date';
  }

  @override
  String backupSize(String size) {
    return 'Size: $size bytes';
  }

  @override
  String get backupValidated =>
      'The file structure has been checked. This does not establish that every historic entry is valid.';

  @override
  String get backupSave => 'Save to file';

  @override
  String get backupSaved => 'The file has been saved.';

  @override
  String get backupCancelled =>
      'File saving was cancelled. App data is unchanged.';

  @override
  String get backupDownloadRequested =>
      'The download was requested from your browser. Check your downloads and confirm the file is present.';

  @override
  String get backupPrepareError =>
      'No backup was prepared. Data may have changed, be unreadable or exceed the supported size. Try again; local data is unchanged.';

  @override
  String get backupSaveError =>
      'File saving failed. Check the destination and try again. Local data is unchanged.';
}
