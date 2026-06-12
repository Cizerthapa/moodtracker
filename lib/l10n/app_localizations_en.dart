// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Aves World';

  @override
  String get appSlogan => 'Treasuring your feelings, one step at a time.';

  @override
  String get madeWithLoveBy => 'made with love by';

  @override
  String get authorName => 'Cizer Thapa';

  @override
  String get welcomeBack => 'Welcome Back,';

  @override
  String get userName => 'Sangya 💕';

  @override
  String get trackMoodToday => 'Let\'s track your mood today ✨';

  @override
  String get ourStoryTitle => 'Our Story';

  @override
  String get ourStorySubtitle => 'Pinned memories of every adventure.';

  @override
  String get hydrationTitle => 'Hydration';

  @override
  String get hydrationSubtitle => 'Staying fresh & keeping healthy.';

  @override
  String get journalTitle => 'Journal';

  @override
  String get journalSubtitle => 'Reflection for a peaceful mind.';

  @override
  String get ourStoryHeader => 'Our Story';

  @override
  String get ourStorySlogan => 'every moment, treasured';

  @override
  String get noMemories => 'No memories yet';

  @override
  String get noMemoriesSubtitle =>
      'Every adventure starts with a first step.\nAdd your first memory together.';

  @override
  String get addMemory => 'Add a Memory';

  @override
  String get newMemoryTitle => 'New Memory';

  @override
  String get newMemoryDescription => 'Description here';

  @override
  String get memoryDetailTitle => 'Memory Detail';

  @override
  String get deleteMemoryTitle => 'Forget this memory?';

  @override
  String get deleteMemoryContent =>
      'This moment will be gone forever. Are you sure?';

  @override
  String get keepIt => 'Keep it';

  @override
  String get letGo => 'Let go';

  @override
  String get specialMemoryCallout =>
      'A truly special moment — marked as unforgettable.';

  @override
  String get loveNoteText =>
      'Every moment with you\nis a memory worth keeping.';

  @override
  String get memoryTitleLabel => 'Memory Title';

  @override
  String get memoryDateLabel => 'Date / Description';

  @override
  String get saveMemory => 'Save Memory';

  @override
  String get waterIntakeHeader => 'Hydration';

  @override
  String get today => 'Today';

  @override
  String drinkGoalMilli(String amount) {
    return 'of $amount ml';
  }

  @override
  String get selectBeverage => 'Select Beverage';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get noHistory => 'No history yet.';

  @override
  String get journalHeader => 'Journal';

  @override
  String get journalSubHeader => 'feelings, thoughts & little moments';

  @override
  String get howAreYouFeeling => 'How are you feeling?';

  @override
  String get pickAMood => 'Pick a mood, then write your heart out.';

  @override
  String get writeThoughtsHint => 'Write your thoughts...';

  @override
  String get saveNoteButton => 'Save Note';

  @override
  String get journalEmptyTitle => 'Your journal is empty';

  @override
  String get journalEmptySubtitle =>
      'Write down how you feel.\nEvery little thought matters.';

  @override
  String get writeANoteButton => 'Write a Note';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodPeaceful => 'Peaceful';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get moodSad => 'Sad';

  @override
  String get moodUpset => 'Upset';

  @override
  String get moodCrying => 'Crying';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get notificationsSubtitle => 'Daily morning, night & periodic alerts';

  @override
  String get testNotification => 'Test Notification';

  @override
  String get testNotificationSubtitle => 'Send an instant notification';

  @override
  String get notificationsOn =>
      'Notifications turned on! (30s interval for 15m)';

  @override
  String get notificationsOff => 'Notifications turned off.';

  @override
  String get testNotificationTitle => 'Test Success! 🎉';

  @override
  String get testNotificationBody => 'This is a notification from Aves World.';

  @override
  String get morningTitle => 'Good Morning! ☀️';

  @override
  String get morningBody =>
      'Today is a beautiful day to track your progress. Have an amazing morning!';

  @override
  String get nightTitle => 'Sweet Dreams 🌙';

  @override
  String get nightBody =>
      'You did great today. Rest well and see you tomorrow!';

  @override
  String get periodicHeader => 'Aves World Alert';

  @override
  String get periodicMessage0 => 'Cizer loves you! ❤️';

  @override
  String get periodicMessage1 => 'What are you doing? Thinking of you!';

  @override
  String get periodicMessage2 => 'You are amazing! ✨';

  @override
  String get periodicMessage3 => 'Just a little reminder that you are special.';

  @override
  String get periodicMessage4 => 'How is your mood today? Hope it is great!';

  @override
  String get periodicMessage5 => 'Drink some water! 🥤';

  @override
  String get periodicMessage6 => 'Take a deep breath. 😌';

  @override
  String get searchJournalHint => 'Search your journal...';

  @override
  String get noNotesMatch => 'No notes match your search';

  @override
  String get pleaseWriteSomething => 'Please write something before saving.';

  @override
  String get titleHint => 'Title';

  @override
  String get startWritingHint => 'Start writing...';

  @override
  String get saveButton => 'Save';

  @override
  String get editMemory => 'Edit Memory';

  @override
  String get shortNoteDesc => 'Short Note / Description';

  @override
  String get herFavStory => 'Her Favorite Story';

  @override
  String get hisFavStory => 'His Favorite Story';

  @override
  String get cycleTrackerHeader => 'Cycle Tracker';

  @override
  String get cycleTrackerSlogan => 'every cycle, understood';

  @override
  String get calendar => 'Calendar';

  @override
  String get history => 'History';

  @override
  String get periodExpectedToday => 'Period expected today';

  @override
  String get basedOnCycleHistory => 'Based on your cycle history';

  @override
  String periodDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Period was expected $count days ago',
      one: 'Period was expected 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get haveYouLoggedIt => 'Have you logged it?';

  @override
  String periodSoonIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Period in $count days',
      one: 'Period in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get periodSoonHeadsUp => 'Heads up — it\'s coming soon!';

  @override
  String nextPeriodIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Next period in $count days',
      one: 'Next period in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get estimatedDot => ' · estimated';

  @override
  String get currentPhase => 'Current Phase';

  @override
  String get menstrualPhase => 'Menstrual Phase';

  @override
  String get menstrualFocus =>
      'Focus on rest, hydration, and pain management (cramps).';

  @override
  String get menstrualInsight =>
      'Did you know? Progesterone and estrogen are at their lowest right now, which is why your energy might dip.';

  @override
  String get follicularPhase => 'Follicular Phase';

  @override
  String get follicularFocus =>
      'Focus on rising energy, creativity, and new beginnings.';

  @override
  String get follicularInsight =>
      'Did you know? You might feel extra energetic today due to rising estrogen levels.';

  @override
  String get ovulatoryPhase => 'Ovulatory Phase (Fertility Window)';

  @override
  String get ovulatoryFocus =>
      'The \"high energy\" window. Highest chance of conception.';

  @override
  String get ovulatoryInsight =>
      'Did you know? Testosterone and estrogen peak now, often boosting confidence and mood!';

  @override
  String get lutealPhase => 'Luteal Phase';

  @override
  String get lutealFocus =>
      'Focus on PMS tracking, skin changes (breakouts), and cravings.';

  @override
  String get lutealInsight =>
      'Did you know? Progesterone rises during this phase, which can naturally make you feel more introverted or relaxed.';

  @override
  String get yourPeriod => 'Your period';

  @override
  String get fertileWindow => 'Fertile Window';

  @override
  String get safeWindow => 'Safe for Intercourse';

  @override
  String get partnerPeriod => 'Partner\'s period';

  @override
  String get nextPeriodLabel => 'Next Period';

  @override
  String get estimatedBasedOnHistory => 'estimated · based on your history';

  @override
  String get deleteCycleTitle => 'Delete Cycle?';

  @override
  String get deleteCycleContent =>
      'This cycle log will be deleted permanently.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get noCyclesLogged => 'No cycles logged yet';

  @override
  String get trackCycleSubtitle =>
      'Track your cycle to get insights\nand share with your partner.';

  @override
  String get logFirstCycle => 'Log First Cycle';

  @override
  String get lightFlow => 'Light';

  @override
  String get mediumFlow => 'Medium';

  @override
  String get heavyFlow => 'Heavy';

  @override
  String get flowSuffix => ' flow';

  @override
  String get editCycle => 'Edit Cycle';

  @override
  String get logPeriod => 'Log Period';

  @override
  String get dates => 'Dates';

  @override
  String get start => 'Start';

  @override
  String get endOptional => 'End (optional)';

  @override
  String get tapToSet => 'Tap to set';

  @override
  String get flowLevel => 'Flow Level';

  @override
  String get symptoms => 'Symptoms';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get notesHint => 'Any notes about this cycle...';

  @override
  String get updateCycle => 'Update Cycle';

  @override
  String get saveCycle => 'Save Cycle';

  @override
  String get yourCycles => 'Your Cycles';

  @override
  String get partnerCycles => "Partner's Cycles";

  @override
  String get editPartnerCycle => "Edit Partner's Cycle";

  @override
  String get noPartnerCycles => 'No partner cycles logged yet';

  @override
  String get partnerBadge => 'Partner';

  @override
  String get howItWorksTitle => 'How It Works';

  @override
  String get colorsLegendTitle => 'Colour Guide';

  @override
  String get yourPeriodDesc => 'Days your period is active — logged by you.';

  @override
  String get partnerPeriodDesc => "Days your partner's period is active — logged by them.";

  @override
  String get predictedPeriodDesc => 'Predicted next period based on your cycle history.';

  @override
  String get fertileWindowDesc => 'Higher fertility — roughly days 8–19 of your cycle.';

  @override
  String get safeWindowDesc => 'Lower fertility — before day 8 or after day 19.';

  @override
  String get predictionsExplained =>
      'Predictions are calculated from the average of your last 3 cycle lengths. The more you log, the more accurate they become.';

  @override
  String get phasesExplained =>
      'Your current phase (Menstrual → Follicular → Ovulatory → Luteal) updates each day based on where you are in your cycle.';

  @override
  String get gotIt => 'Got it';

  @override
  String get logForPartner => 'Log for Partner';
}
