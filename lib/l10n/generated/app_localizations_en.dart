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
  String get dailyOpen => 'A mindful moment today  •  +10 XP';

  @override
  String get dailyOpenSaved => 'Today’s check-in and evening reflection ✓';

  @override
  String get dailyTitle => 'A moment for yourself';

  @override
  String get dailyMorning => 'Good morning!';

  @override
  String get dailyAfternoon => 'Have a lovely day!';

  @override
  String get dailyEveningGreeting => 'Good evening!';

  @override
  String dailyGreeting(String greeting, String name) {
    return '$greeting $name is here with you.';
  }

  @override
  String get dailyOptional =>
      'Every answer is optional. No drink logging is needed. There is no penalty for missed days.';

  @override
  String get dailyWelcome => 'Glad you are here. Take today at your own pace.';

  @override
  String get dailySupportLow =>
      'Does today feel difficult? A short rest or a chat may help. You do not have to solve everything today.';

  @override
  String get dailySupportMid =>
      'Thank you for checking in with yourself. A small, comfortable step counts.';

  @override
  String get dailySupportHigh =>
      'Lovely to hear you feel good! What small kindness could you do for yourself today?';

  @override
  String get dailyMood => 'How is your mood right now?';

  @override
  String get dailyEnergy => 'How much energy do you have right now?';

  @override
  String get dailyScale => '1 = very low, 5 = very high';

  @override
  String get dailySkip => 'Skip';

  @override
  String get dailyGoal => 'Today’s personal goal (optional)';

  @override
  String get dailyGoalHint => 'For example: a short walk or a rest';

  @override
  String get dailyEvening => 'Evening reflection (optional)';

  @override
  String get dailyEveningHint =>
      'What felt good today? What would you take into tomorrow?';

  @override
  String get dailyReward =>
      'Checking in earns +10 XP once a day. You can skip every answer.';

  @override
  String get dailyRewardDone =>
      'You already received today’s check-in XP. You can freely update your answers.';

  @override
  String get dailySave => 'Save check-in';

  @override
  String get dailySaved =>
      'Check-in saved. The daily reward is counted only once.';

  @override
  String get dailyLater => 'Skip for now';

  @override
  String get dailyLoadError =>
      'Could not safely load today’s data. Your data have not been overwritten.';

  @override
  String get dailySaveError =>
      'Saving did not finish. Please retry; your daily XP will not be duplicated.';

  @override
  String get dailyRetry => 'Retry';

  @override
  String get evolutionTitle => 'Menti progress';

  @override
  String evolutionLevel(int level) {
    return 'Level $level';
  }

  @override
  String evolutionRemaining(int xp) {
    return '$xp XP to the next level';
  }

  @override
  String evolutionTotal(int xp) {
    return '$xp XP in total';
  }

  @override
  String get evolutionNext => 'Next reward';

  @override
  String get evolutionAll =>
      'All current outfit rewards earned. Go at your own pace!';

  @override
  String evolutionUnlock(int level, int xp) {
    return 'Level $level • $xp XP to go';
  }

  @override
  String get evolutionDaily => 'Daily mindful self-check';

  @override
  String get evolutionDailyHint =>
      'Reflect on your day. +10 XP once a day, shared with Home.';

  @override
  String get evolutionChecked => 'Today\'s self-check is complete';

  @override
  String get evolutionCheck => 'I reflected on my day';

  @override
  String get evolutionWeekly => 'Weekly mindful steps';

  @override
  String get evolutionWeeklyHint =>
      'Self-reported, once per week. Opportunities renew on Monday.';

  @override
  String get evolutionReview => 'I reviewed my journal';

  @override
  String get evolutionCost => 'I reflected on my spending';

  @override
  String get evolutionGoal => 'I set a personal goal';

  @override
  String get evolutionDone => 'Done';

  @override
  String evolutionPoints(int xp) {
    return '+$xp XP • once per week';
  }

  @override
  String get evolutionBadges => 'Achievement badges';

  @override
  String get evolutionReflectionBadge => 'Mindful self-check • 1 distinct day';

  @override
  String get evolutionGoalBadge => 'Personal goal • set 1 weekly goal';

  @override
  String get evolutionConsistencyBadge =>
      'Consistency • 7 distinct days, breaks are welcome';

  @override
  String get evolutionEarned => 'Earned';

  @override
  String get evolutionLocked => 'Still available';

  @override
  String evolutionWeek(int days, int tasks) {
    return 'This week: $days self-checks • $tasks mindful steps';
  }

  @override
  String get evolutionPolicy =>
      'Alcohol quantity and money spent do not earn XP. There is no negative XP or penalty for missed days. Badges award no extra XP and do not measure health or alcohol-free days.';

  @override
  String get evolutionError =>
      'Progress could not be loaded or saved. Please try again.';

  @override
  String get evolutionRetry => 'Retry';

  @override
  String evolutionSaved(int xp) {
    return 'Saved • +$xp XP';
  }

  @override
  String get evolutionWardrobe => 'Open wardrobe';

  @override
  String get evolutionBasic => 'Basic outfit';

  @override
  String get evolutionParty => 'Party outfit';

  @override
  String get evolutionSport => 'Sport outfit';

  @override
  String get evolutionBusiness => 'Business outfit';

  @override
  String get evolutionFestival => 'Festival outfit';

  @override
  String get evolutionLegendary => 'Legendary outfit';

  @override
  String get evolutionImage => 'Preview is currently unavailable';

  @override
  String get evolutionRules =>
      'Unlocks: Basic, Party and Sport at level 1, Business at 2, Festival at 3, Legendary at 5. Earned outfits stay yours.';

  @override
  String get challengeSaveError => 'Could not save. Please retry.';

  @override
  String get challengeCustom => 'Your weekly goal';

  @override
  String get challengeDaysPerWeek => 'Days per week';

  @override
  String get challengeCancel => 'Cancel';

  @override
  String get challengeSave => 'Save';

  @override
  String get challengeReflection => 'Mindful self-check';

  @override
  String get challengeJournal => 'Consistent wellbeing journal';

  @override
  String get challengeHabit => 'Mindful habit: a short daily pause';

  @override
  String get challengeTitle => 'Personal weekly challenges';

  @override
  String get challengeOptional =>
      'At your own pace. Every challenge is optional and can be skipped or stopped without penalty. No XP rewards or deductions.';

  @override
  String get challengePrevious => 'Previous week';

  @override
  String get challengeNext => 'Next week';

  @override
  String get challengeLoadError =>
      'Data could not be read. It will not be overwritten.';

  @override
  String get challengeRetry => 'Retry';

  @override
  String get challengeDays => 'days';

  @override
  String get challengeSkipped => 'Skipped – no penalty.';

  @override
  String get challengeStopped => 'Stopped – no penalty.';

  @override
  String get challengeJournalHint =>
      'Counts days with a saved wellbeing entry. No drink entry is needed.';

  @override
  String get challengeChoose => 'Choose';

  @override
  String get challengeEdit => 'Edit goal';

  @override
  String get challengeDoneToday => 'I did this today';

  @override
  String get challengeSkip => 'Skip this week';

  @override
  String get challengeStop => 'Stop';

  @override
  String get challengeSummary => 'Weekly progress summary';

  @override
  String get challengeJournalDays => 'Days with wellbeing entries';

  @override
  String get challengeCaution =>
      'A missing entry is unknown, not an alcohol-free day. These challenges do not label alcohol-free days. Editing a goal affects only the selected week; previous check-ins are retained.';

  @override
  String get challengeRefresh => 'Refresh summary';

  @override
  String get backupTitle => 'Data backup and restore';

  @override
  String get backupContents =>
      'Back up all local journals, Daily Menti answers, XP and history, permanent outfit unlocks, weekly challenges, characters, goals and settings, including future app keys.';

  @override
  String get backupPrivacy =>
      'The file is not encrypted and contains personal data. Save it somewhere safe. The app does not upload it automatically; you choose where to save or share it.';

  @override
  String get backupRestoreDeferred =>
      'Choose a backup for a validated preview before restoring. No changes are made until you explicitly confirm.';

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

  @override
  String get restorePick => 'Choose backup to restore';

  @override
  String get restoreHint =>
      'Restore adds or replaces only keys present in the file. Other local data is kept. Permanent outfit unlocks are combined. Review the keys below before confirming.';

  @override
  String get restorePreview => 'Restore preview';

  @override
  String restoreCounts(int added, int replaced, int unchanged) {
    return '$added new, $replaced replaced, $unchanged unchanged keys';
  }

  @override
  String get restoreConfirm => 'Restore these data';

  @override
  String get restoreQuestion => 'Restore the reviewed backup?';

  @override
  String get restoreWarning =>
      'The listed data will be written to this device. Existing values for these keys will be replaced. Do you want to continue?';

  @override
  String get restoreCancel => 'Cancel';

  @override
  String get restoreInvalid =>
      'The backup is invalid, unsupported, too large or unreadable. No user data was written.';

  @override
  String get restoreFailed =>
      'Restore failed. The original data was recovered. Prepare a new preview before retrying.';

  @override
  String get restoreRecovery =>
      'Recovery is incomplete. Editing is blocked until the original data can be recovered. Keep this app’s local data and retry.';

  @override
  String get restoreRetry => 'Retry recovery';

  @override
  String get restoreSuccess => 'Data restored.';

  @override
  String get restoreStale =>
      'Local data changed or storage is unavailable. No restore was completed. Choose the file again.';

  @override
  String get homeEyebrow => 'MENNYIMENT? • YOUR MENTI';

  @override
  String get homeGreeting => 'Hi! How are you today?';

  @override
  String get homeIntro => 'Your mindful choices today matter.';

  @override
  String get homeMentiHint => 'Progress grows from small, mindful steps.';

  @override
  String homeTotalXp(int xp) {
    return '$xp XP in total';
  }

  @override
  String get homeLevelProgress => 'Progress towards the next Menti level';

  @override
  String get homeXpHint =>
      'XP rewards check-ins and mindful weekly tasks, never the number of drinks.';

  @override
  String get homeTodayDrinks => 'Drinks recorded today';

  @override
  String get homeTodaySpending => 'Known spending today';

  @override
  String get homeMonthSpending => 'Known spending this month';

  @override
  String get homeWeekDays => 'Days with entries this week';

  @override
  String homeMissingPrices(int today, int month) {
    return 'Missing drink prices: $today today, $month this month. Spending totals are partial.';
  }

  @override
  String get homeEmptyJournal =>
      'No entries yet. Use the add button to record a drink.';

  @override
  String get homeUnknownPrice => 'Unknown price';

  @override
  String get homeJournalUnavailable =>
      'Journal data is currently unavailable. Your original data has been preserved.';

  @override
  String get homeJournalRetry => 'Reload journal';

  @override
  String get homeLoading => 'Loading journal…';

  @override
  String get homeRecordActions => 'Entry actions';

  @override
  String get homeEnterPrice => 'Add price';

  @override
  String homeEditPrice(String price) {
    return 'Price: $price – edit';
  }

  @override
  String get homeDeleteEntry => 'Delete entry';

  @override
  String get homeCheckInUnavailable =>
      'Menti progress could not be loaded. Please retry.';

  @override
  String get homeRetryProgress => 'Reload Menti';

  @override
  String get homeJournalSaveError =>
      'The journal could not be saved. Your change was not applied. Retry or reload the journal.';

  @override
  String get homeJournalLoadError =>
      'The journal could not be loaded safely. Your original data is preserved and editing is disabled.';

  @override
  String get goalPageTitle => 'My personal goals';

  @override
  String get goalOwnPace => 'At your own pace';

  @override
  String get goalIntro =>
      'You choose what to track. Mindful reflection matters, never the number of drinks.';

  @override
  String get goalBudgetTitle => 'Weekly drink budget';

  @override
  String goalRecordedSpending(String amount) {
    return 'Recorded spending: $amount';
  }

  @override
  String get goalNoBudget => 'No budget set yet.';

  @override
  String goalBudgetValue(String amount) {
    return 'Your weekly budget: $amount';
  }

  @override
  String goalMissingPrices(int count) {
    return '$count drink prices are missing. Spending is only a partial total, so meeting the budget cannot be confirmed.';
  }

  @override
  String get goalOverBudget => 'Recorded spending is above your budget.';

  @override
  String get goalWithinBudget =>
      'Recorded spending is within your budget. This does not confirm total weekly spending.';

  @override
  String get goalEditBudget => 'Edit budget';

  @override
  String get goalReflectionTitle => 'Mindful weekly check-ins';

  @override
  String goalProgress(int count, int target) {
    return '$count / $target check-ins';
  }

  @override
  String get goalCheckDone => 'Today’s check-in is done';

  @override
  String get goalCheckAction => 'I reflected on my day today';

  @override
  String get goalCurrentWeekOnly =>
      'Check-ins can only be recorded for the current week';

  @override
  String get goalEditTarget => 'Edit weekly target';

  @override
  String get goalMentiThought => 'A thought from Menti';

  @override
  String get goalThoughtComplete =>
      'Your recorded check-ins show that you reached your weekly goal.';

  @override
  String get goalThoughtStart =>
      'No perfect day needed. A short reflection is a good start.';

  @override
  String goalThoughtProgress(int count) {
    return 'You have taken time to reflect $count times. Keep your own pace!';
  }

  @override
  String get goalCaution =>
      'A missing journal entry does not prove an alcohol-free day. Spending is self-reported. This check-in does not award extra XP.';

  @override
  String get goalBudgetDialog => 'Weekly drink budget (HUF)';

  @override
  String get goalTargetDialog => 'Weekly check-in target';

  @override
  String get goalBudgetHint => 'For example 10000';

  @override
  String get goalTargetHint => '1–7 days';

  @override
  String get goalBudgetHelp => 'A zero budget is allowed.';

  @override
  String get goalTargetHelp => 'At most one check-in per day.';

  @override
  String get goalInvalidValue => 'Invalid goal value.';

  @override
  String get goalLoadError =>
      'Your goals could not be loaded safely. Original data is preserved and editing is disabled.';

  @override
  String get goalSaveError =>
      'Your goals could not be saved. The change is not shown as completed. Reload the data and retry.';

  @override
  String get goalReload => 'Reload goals';

  @override
  String get hubTitle => 'My Menti • Overview';

  @override
  String get hubIntro =>
      'Your recorded data in one place. A missing entry is not an alcohol-free day.';

  @override
  String get hubProfile => 'Character and outfit';

  @override
  String get hubXp => 'Menti progress';

  @override
  String get hubDaily => 'Today’s check-in';

  @override
  String get hubGoals => 'Personal weekly goal';

  @override
  String get hubChallenges => 'Weekly challenges';

  @override
  String get hubJournal => 'Weekly drink journal and spending';

  @override
  String get hubMissing => 'Menti has no saved data for this section yet.';

  @override
  String get hubReadError =>
      'This data could not be read reliably. It has not been replaced with a default value.';

  @override
  String get hubGlobalError =>
      'The overview could not be loaded. Your original data has not been changed.';

  @override
  String get hubRefresh => 'Refresh overview';

  @override
  String hubUpdated(String date) {
    return 'Snapshot: $date';
  }

  @override
  String hubWeek(String start, String end) {
    return 'Current week: $start – $end';
  }

  @override
  String get hubDailyAnswers => 'Today’s daily answers are recorded.';

  @override
  String get hubNoDailyAnswers =>
      'No answers are recorded in today’s daily entry.';

  @override
  String get hubXpToday => 'Today’s XP check-in is recorded.';

  @override
  String get hubNoXpToday => 'This XP record has no check-in for today.';

  @override
  String hubWeekChecks(int count) {
    return 'Recorded daily XP check-ins this week: $count';
  }

  @override
  String get hubNoTarget => 'No personal target is saved.';

  @override
  String get hubNoCheckDays => 'No check-in day list is saved.';

  @override
  String get hubGoalConfirmed =>
      'The recorded check-ins confirm that this goal is complete.';

  @override
  String get hubGoalOngoing =>
      'The recorded check-ins do not yet complete this goal.';

  @override
  String get hubNoChallenges => 'No challenges are selected for this week.';

  @override
  String get hubEvidenceMissing =>
      'The journal evidence needed for this goal is missing or unreadable.';

  @override
  String get hubRecordedEmpty =>
      'The saved journal has 0 entries this week. This does not confirm alcohol-free days.';

  @override
  String get hubKnownZero =>
      'The recorded sum of known prices is 0. Unknown prices are not counted as zero.';

  @override
  String get hubOutfitBasic => 'Basic outfit';

  @override
  String get hubOutfitParty => 'Party outfit';

  @override
  String get hubOutfitSport => 'Sport outfit';

  @override
  String get hubOutfitBusiness => 'Business outfit';

  @override
  String get hubOutfitFestival => 'Festival outfit';

  @override
  String get hubOutfitLegendary => 'Legendary outfit';

  @override
  String get hubFamilyBoy => 'Boy Menti';

  @override
  String get hubFamilyGirl => 'Girl Menti';

  @override
  String get hubFamilyNeutral => 'Neutral Menti';

  @override
  String get hubImageError =>
      'The selected character image could not be displayed.';

  @override
  String get reactionTitle => 'A message from Menti';

  @override
  String get hubOverview => 'Overview';

  @override
  String get experienceSettings => 'Settings and help';

  @override
  String get experienceIntroTitle => 'Meet Menti';

  @override
  String get experienceIntroInvite =>
      'A new companion for your journal. Meet Menti?';

  @override
  String get experienceIntroOpen => 'Menti introduction';

  @override
  String get experienceIntroSkip => 'Skip';

  @override
  String get experienceIntroNext => 'Next';

  @override
  String get experienceIntroBack => 'Previous';

  @override
  String get experienceIntroDone => 'Open my journal';

  @override
  String experienceIntroStep(int step, int total) {
    return 'Step $step / $total';
  }

  @override
  String get experienceIntro1Title => 'Hi, I’m Menti!';

  @override
  String get experienceIntro1Body =>
      'Your orange companion for self-reflection. You choose your pace, character and outfit. No registration is required.';

  @override
  String get experienceIntro2Title => 'Your journal, your call';

  @override
  String get experienceIntro2Body =>
      'Record drinks and known prices, then review your summaries. A missing entry does not prove an alcohol-free day, and an unknown price is not zero.';

  @override
  String get experienceIntro3Title => 'A minute for yourself';

  @override
  String get experienceIntro3Body =>
      'Daily Menti and your personal goals support mindful reflection. XP is linked to existing check-ins and tasks, never to the number of drinks.';

  @override
  String get experienceIntro4Title => 'Your data and backups';

  @override
  String get experienceIntro4Body =>
      'Your journal uses local storage. You start backups and restores yourself. An exported file may contain personal data and is not encrypted; keep it private. This app cannot determine sobriety or fitness to drive.';

  @override
  String get experienceReactions => 'Menti messages and reactions';

  @override
  String get experienceReactionsHint =>
      'Turning this off only changes presentation. Your XP and goals stay unchanged.';

  @override
  String get experienceLoadError =>
      'This presentation preference could not be read safely. The original value is preserved.';

  @override
  String get experienceSaveError =>
      'The preference could not be confirmed as saved. The previous state remains active; reload and retry.';

  @override
  String get experienceReload => 'Reload preferences';

  @override
  String get experienceMotionTitle => 'Reduce Menti motion';

  @override
  String get experienceMotionHint =>
      'A still image instead of floating, wobbling and reaction animations.';

  @override
  String get experienceMotionSystem =>
      'System reduced motion is active. This switch cannot override it.';

  @override
  String get experienceMotionLoadError =>
      'Could not load the motion preference.';

  @override
  String get experienceMotionSaveError =>
      'Could not save the motion preference. Please retry.';

  @override
  String get experienceToday => 'Today with Menti';

  @override
  String get experienceTodayStart1 =>
      'A minute for yourself? Menti is listening; your journal can wait.';

  @override
  String get experienceTodayStart2 =>
      'Your own pace is a good pace. A short check-in may be enough for today.';

  @override
  String get experienceTodayAnswers =>
      'Today’s answers are saved. That’s in Menti’s notebook.';

  @override
  String get experienceTodayChecked =>
      'Today’s check-in is recorded. An imaginary nod from Menti.';

  @override
  String get experienceTodayGoal =>
      'Your recorded days complete your weekly check-in goal. Mindful steps count!';

  @override
  String get experienceTodayChallenge =>
      'Your records show a completed weekly challenge. Menti tips the hat.';

  @override
  String get experienceTodayUnknown =>
      'Some data is unavailable. Menti won’t guess; you can retry in the overview.';

  @override
  String get experienceOpenDaily => 'Open daily Menti';

  @override
  String get experienceOpenHub => 'Open overview';

  @override
  String get experienceEmptyJournal =>
      'Menti’s notebook has no entries yet. Record something when it is useful for you.';

  @override
  String get experienceAddEntry => 'Record an entry';

  @override
  String get experienceTodayLoading => 'Menti is checking today’s records…';

  @override
  String get avatarFamilyBoy => 'Boy';

  @override
  String get avatarFamilyGirl => 'Girl';

  @override
  String get avatarFamilyNeutral => 'Neutral';

  @override
  String get avatarAgeYoung => 'Young';

  @override
  String get avatarAgeAdult => 'Adult';

  @override
  String get avatarAgeVeteran => 'Veteran';

  @override
  String get avatarFaceCheerful => 'Cheerful';

  @override
  String get avatarFaceCalm => 'Calm';

  @override
  String get avatarFacePlayful => 'Playful';

  @override
  String get avatarFaceConfident => 'Confident';

  @override
  String get avatarFaceSleepy => 'Sleepy';

  @override
  String get avatarFaceDetermined => 'Determined';

  @override
  String get avatarEyesRound => 'Round';

  @override
  String get avatarEyesWide => 'Wide';

  @override
  String get avatarEyesRelaxed => 'Relaxed';

  @override
  String get avatarEyesSharp => 'Sharp';

  @override
  String get avatarHairBoyCrop => 'Crop';

  @override
  String get avatarHairBoyWaves => 'Waves';

  @override
  String get avatarHairBoyCurls => 'Curls';

  @override
  String get avatarHairBoyBraid => 'Braid';

  @override
  String get avatarHairBoyBob => 'Bob';

  @override
  String get avatarHairBoyCrest => 'Crest';

  @override
  String get avatarHairGirlCrop => 'Crop';

  @override
  String get avatarHairGirlWaves => 'Waves';

  @override
  String get avatarHairGirlCurls => 'Curls';

  @override
  String get avatarHairGirlBraid => 'Braid';

  @override
  String get avatarHairGirlBob => 'Bob';

  @override
  String get avatarHairGirlCrest => 'Crest';

  @override
  String get avatarHairNeutralCrop => 'Crop';

  @override
  String get avatarHairNeutralWaves => 'Waves';

  @override
  String get avatarHairNeutralCurls => 'Curls';

  @override
  String get avatarHairNeutralBraid => 'Braid';

  @override
  String get avatarHairNeutralBob => 'Bob';

  @override
  String get avatarHairNeutralCrest => 'Crest';

  @override
  String get avatarHeadwearCrownCap => 'Crown cap';

  @override
  String get avatarHeadwearSportCap => 'Sport cap';

  @override
  String get avatarHeadwearBeanie => 'Beanie';

  @override
  String get avatarHeadwearHeadphones => 'Headphones';

  @override
  String get avatarHeadwearPartyCrown => 'Party crown';

  @override
  String get avatarHeadwearHood => 'Hood';

  @override
  String get avatarHeadwearNone => 'No headwear';

  @override
  String get avatarHeadwearPartyHat => 'Party hat';

  @override
  String get avatarHeadwearBeret => 'Beret';

  @override
  String get avatarOutfitBasic => 'Classic set';

  @override
  String get avatarOutfitBasicAlt => 'Classic set · extra';

  @override
  String get avatarOutfitParty => 'Party';

  @override
  String get avatarOutfitPartyAlt => 'Party · extra';

  @override
  String get avatarOutfitSport => 'Sport';

  @override
  String get avatarOutfitSportAlt => 'Sport · extra';

  @override
  String get avatarOutfitBusiness => 'Business';

  @override
  String get avatarOutfitBusinessAlt => 'Business · extra';

  @override
  String get avatarOutfitFestival => 'Festival';

  @override
  String get avatarOutfitFestivalAlt => 'Festival · extra';

  @override
  String get avatarOutfitLegendary => 'Legendary';

  @override
  String get avatarOutfitLegendaryAlt => 'Legendary · extra';

  @override
  String get avatarOutfitStreet => 'Street';

  @override
  String get avatarOutfitStreetAlt => 'Street · extra';

  @override
  String get avatarOutfitCozy => 'Cozy';

  @override
  String get avatarOutfitCozyAlt => 'Cozy · extra';

  @override
  String get avatarOutfitExplorer => 'Explorer';

  @override
  String get avatarOutfitExplorerAlt => 'Explorer · extra';

  @override
  String get avatarOutfitCreative => 'Creative';

  @override
  String get avatarOutfitCreativeAlt => 'Creative · extra';

  @override
  String get avatarStyleClassic => 'Classic';

  @override
  String get avatarStyleStreet => 'Street';

  @override
  String get avatarStyleSporty => 'Sporty';

  @override
  String get avatarStyleBusiness => 'Business';

  @override
  String get avatarStyleParty => 'Party';

  @override
  String get avatarStyleFestival => 'Festival';

  @override
  String get avatarStyleCozy => 'Cozy';

  @override
  String get avatarStyleLegendary => 'Legendary';

  @override
  String get avatarGlassesNone => 'No glasses';

  @override
  String get avatarGlassesRoundGlasses => 'Round glasses';

  @override
  String get avatarGlassesSunglasses => 'Sunglasses';

  @override
  String get avatarNeckNone => 'No neck accessory';

  @override
  String get avatarNeckChain => 'Gold chain';

  @override
  String get avatarNeckScarf => 'Scarf';

  @override
  String get avatarNeckBow => 'Bow tie';

  @override
  String get avatarHeldNone => 'Empty hands';

  @override
  String get avatarHeldNotebook => 'Notebook';

  @override
  String get avatarHeldFlower => 'Flower';

  @override
  String get avatarHeldSparkWand => 'Star wand';

  @override
  String get avatarDetailNone => 'No face detail';

  @override
  String get avatarDetailFreckles => 'Freckles';

  @override
  String get avatarDetailStar => 'Star mark';

  @override
  String get avatarDetailMoon => 'Moon mark';

  @override
  String get avatarBackNone => 'No back accessory';

  @override
  String get avatarBackBackpack => 'Backpack';

  @override
  String get avatarBackCape => 'Cape';

  @override
  String get avatarAccentGold => 'Gold';

  @override
  String get avatarAccentViolet => 'Violet';

  @override
  String get avatarAccentBlue => 'Blue';

  @override
  String get avatarAccentMint => 'Mint';

  @override
  String get avatarAccentRose => 'Rose';

  @override
  String get avatarAccentOrange => 'Orange';

  @override
  String get avatarBackgroundAmber => 'Amber';

  @override
  String get avatarBackgroundViolet => 'Violet dusk';

  @override
  String get avatarBackgroundOcean => 'Ocean';

  @override
  String get avatarBackgroundForest => 'Forest';

  @override
  String get avatarBackgroundRose => 'Rose garden';

  @override
  String get avatarBackgroundMidnight => 'Midnight';

  @override
  String get avatarAuraSunrise => 'Sunrise';

  @override
  String get avatarAuraViolet => 'Violet glow';

  @override
  String get avatarAuraOcean => 'Wave';

  @override
  String get avatarAuraForest => 'Leaves';

  @override
  String get avatarAuraStarlight => 'Starlight';

  @override
  String get avatarAuraRose => 'Rose glow';

  @override
  String get avatarReactionProud => 'Proud';

  @override
  String get avatarReactionMotivating => 'Motivating';

  @override
  String get avatarReactionFunny => 'Funny';

  @override
  String get avatarReactionSleepy => 'Sleepy';

  @override
  String get avatarReactionCalming => 'Calming';

  @override
  String get avatarReactionCelebrating => 'Celebrating';

  @override
  String get avatarReactionFocused => 'Focused';

  @override
  String get avatarStudio => 'Menti Studio 2.2';

  @override
  String get avatarSave => 'Save';

  @override
  String get avatarSaving => 'Saving…';

  @override
  String get avatarSaved => 'Your Menti has been saved.';

  @override
  String get avatarSaveError => 'Could not confirm the save. Reload your data.';

  @override
  String get avatarReadError =>
      'The profile could not be loaded or saved. Reload your data.';

  @override
  String get avatarRetry => 'Reload';

  @override
  String get avatarXpUnavailable =>
      'XP data is unreadable. Only default and previously unlocked items are available.';

  @override
  String get avatarRandom => 'Random Menti';

  @override
  String get avatarRevert => 'Revert';

  @override
  String get avatarReset => 'Basic Menti';

  @override
  String get avatarCancel => 'Cancel';

  @override
  String get avatarPresetName => 'Preset name';

  @override
  String get avatarAddPreset => 'Save named preset';

  @override
  String get avatarFavorite => 'Favorite preset';

  @override
  String get avatarDuplicate => 'Duplicate';

  @override
  String get avatarApply => 'Apply';

  @override
  String get avatarNoPresets => 'You have no saved presets yet.';

  @override
  String get avatarPresetHint => 'Use Save to keep favorites and duplicates.';

  @override
  String get avatarUnsaved => 'Unsaved changes';

  @override
  String get avatarUnsavedBody =>
      'Use Save to keep your new Menti. Discard the changes now?';

  @override
  String get avatarDiscard => 'Discard changes';

  @override
  String get avatarDefault => 'Available by default';

  @override
  String get avatarUnlocked => 'Unlocked';

  @override
  String get avatarNew => 'Newly unlocked';

  @override
  String get avatarTabBasics => 'Basics';

  @override
  String get avatarTabFace => 'Face and head';

  @override
  String get avatarTabOutfit => 'Clothing';

  @override
  String get avatarTabAccessories => 'Accessories';

  @override
  String get avatarTabAtmosphere => 'Atmosphere';

  @override
  String get avatarTabPresets => 'Presets';

  @override
  String get avatarFieldFamily => 'Character type';

  @override
  String get avatarFieldAge => 'Age';

  @override
  String get avatarFieldStyle => 'Style';

  @override
  String get avatarFieldFace => 'Expression';

  @override
  String get avatarFieldEyes => 'Eyes';

  @override
  String get avatarFieldHair => 'Hair and silhouette';

  @override
  String get avatarFieldHeadwear => 'Headwear';

  @override
  String get avatarFieldOutfit => 'Outfit';

  @override
  String get avatarFieldAccent => 'Accent color';

  @override
  String get avatarFieldGlasses => 'Glasses';

  @override
  String get avatarFieldNeck => 'Neck accessory';

  @override
  String get avatarFieldHeld => 'Held prop';

  @override
  String get avatarFieldDetail => 'Face detail';

  @override
  String get avatarFieldBack => 'Back accessory';

  @override
  String get avatarFieldBackground => 'Background';

  @override
  String get avatarFieldAura => 'Aura';

  @override
  String get avatarFieldReaction => 'Visual personality';

  @override
  String avatarPreview(String name) {
    return 'Menti preview: $name';
  }

  @override
  String avatarLocked(int level) {
    return 'Unlocks at level $level';
  }

  @override
  String get avatarHeadwearCowboy => 'Cowboy hat';

  @override
  String get startLanguage => 'Hey! Which language shall we use?';

  @override
  String get startWelcome =>
      'I’m Menti. Small steps, your own pace — and a mascot by your side.';

  @override
  String get startAgeTitle => 'First, one important question';

  @override
  String get startAgeBody =>
      'Are you 18 or older? Your Menti’s appearance is independent of your age. Under 18, only lifestyle and character features are available.';

  @override
  String get startAdult => 'I am 18 or older';

  @override
  String get startMinor => 'I am under 18';

  @override
  String get startLocalOnly =>
      'This is a local age declaration, not identity verification. Your profile stays on this device; no account registration is required.';

  @override
  String get startCharacter => 'Meet your own Menti!';

  @override
  String get startName => 'Nickname';

  @override
  String get startNameBody =>
      'What should I call you? You can restyle your Menti in the Studio anytime.';

  @override
  String get startFinish => 'Save and let’s go';

  @override
  String get startSaveError =>
      'We couldn’t finish safely. Your data is preserved; please retry. If the profile is damaged, restore a backup.';

  @override
  String get wellbeingQuestion => 'How are you feeling?';

  @override
  String get wellbeingBody =>
      'Your mood and sleep matter. There are no right or wrong answers.';

  @override
  String get wellbeingMood => 'Mood';

  @override
  String get wellbeingScale => '1 = very low, 5 = very good';

  @override
  String get wellbeingSleep => 'Sleep quality';

  @override
  String get wellbeingSleepHint => 'Your own rating of your most recent sleep';

  @override
  String get wellbeingHangover => 'Hangover symptoms';

  @override
  String get wellbeingHangoverHint => '0 = none, 4 = very strong';

  @override
  String get wellbeingVeryBad => 'Very low';

  @override
  String get wellbeingBad => 'Low';

  @override
  String get wellbeingMedium => 'Moderate';

  @override
  String get wellbeingGood => 'Good';

  @override
  String get wellbeingVeryGood => 'Very good';

  @override
  String get wellbeingNone => 'None';

  @override
  String get wellbeingMild => 'Mild';

  @override
  String get wellbeingStrong => 'Strong';

  @override
  String get wellbeingVeryStrong => 'Very strong';

  @override
  String get wellbeingNote => 'Note (optional)';

  @override
  String get wellbeingNoteHint => 'What influenced how you felt today?';

  @override
  String get wellbeingUpdate => 'Update entry';

  @override
  String get wellbeingSave => 'Save day';

  @override
  String get wellbeingDelete => 'Delete this day’s entry';

  @override
  String wellbeingHistory(int count) {
    return 'Previous days ($count)';
  }

  @override
  String get wellbeingEmpty => 'No saved days yet.';

  @override
  String wellbeingSummary(int mood, int sleep) {
    return 'Mood $mood/5 • Sleep $sleep/5';
  }

  @override
  String wellbeingSymptoms(int rating) {
    return 'Symptoms $rating/4';
  }

  @override
  String get wellbeingCaution =>
      'These are personal observations, not medical assessments. Seek medical help for severe symptoms.';

  @override
  String get wellbeingSaved => 'Your daily wellbeing has been saved.';

  @override
  String get wellbeingReadError =>
      'The journal cannot be read safely. Your existing data is preserved; editing is disabled.';

  @override
  String get wellbeingSafeHint => 'Mood, sleep and personal notes';

  @override
  String get profileLocalTitle => 'My Menti';

  @override
  String get journalCustomWriteError =>
      'Your custom drinks could not be changed. The original data is preserved.';

  @override
  String get journalNewCustom => 'New custom drink';

  @override
  String get journalDrinkName => 'Drink name';

  @override
  String get journalDrinkHint => 'For example, a homemade drink';

  @override
  String get journalMl => 'Amount (ml)';

  @override
  String get journalPercent => 'Alcohol content (%)';

  @override
  String get journalInvalid => 'Please enter valid details.';

  @override
  String journalSetPrice(String name) {
    return 'Set price: $name';
  }

  @override
  String get journalPrice => 'Price paid (HUF)';

  @override
  String get journalRemovePrice => 'Remove price';

  @override
  String get journalInvalidAmount => 'Please enter a valid amount.';

  @override
  String journalSaved(String name) {
    return '$name saved to your journal';
  }

  @override
  String get journalAddTitle => 'Add a drink';

  @override
  String get journalFavorites => '⭐ Your favorites';

  @override
  String get journalFavorite => 'Favorite';

  @override
  String get journalCustoms => 'Custom drinks';

  @override
  String get journalDeleteCustom => 'Delete custom drink';

  @override
  String get journalCustomReadError =>
      'Custom drinks could not be loaded safely; editing is disabled.';

  @override
  String get journalCreateCustom => 'Create a custom drink';

  @override
  String get journalDeleteTitle => 'Delete this entry?';

  @override
  String journalDeleteBody(String name) {
    return 'The entry for $name will be removed from your journal.';
  }

  @override
  String get journalDelete => 'Delete';

  @override
  String get journalDetailsHint => 'Record what you actually consumed.';

  @override
  String get journalMlError => 'Enter an amount between 1 and 10,000 ml.';

  @override
  String get journalPercentError => 'Enter an alcohol content from 0 to 100%.';

  @override
  String get journalOptionalPrice => 'Price paid (HUF) — optional';

  @override
  String get journalPriceHint => 'Leave blank to save the price as unknown.';

  @override
  String get journalPriceError =>
      'Enter a valid price from 0 to 10,000,000 HUF.';

  @override
  String get journalSave => 'Save to journal';

  @override
  String get catalogBeer => 'Beer (standard)';

  @override
  String get catalogLager => 'Lager';

  @override
  String get catalogDarkBeer => 'Dark beer';

  @override
  String get catalogWhiteWine => 'White wine';

  @override
  String get catalogRedWine => 'Red wine';

  @override
  String get catalogRoseWine => 'Rosé';

  @override
  String get catalogSmallSpritzer => 'Small wine spritzer';

  @override
  String get catalogLargeSpritzer => 'Large wine spritzer';

  @override
  String get catalogPalinka => 'Pálinka';

  @override
  String get catalogUnicum => 'Unicum (standard)';
}
