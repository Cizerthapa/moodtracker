import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ne'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Aves World'**
  String get appName;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Treasuring your feelings, one step at a time.'**
  String get appSlogan;

  /// No description provided for @madeWithLoveBy.
  ///
  /// In en, this message translates to:
  /// **'made with love by'**
  String get madeWithLoveBy;

  /// No description provided for @authorName.
  ///
  /// In en, this message translates to:
  /// **'Cizer Thapa'**
  String get authorName;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back,'**
  String get welcomeBack;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'Sangya 💕'**
  String get userName;

  /// No description provided for @trackMoodToday.
  ///
  /// In en, this message translates to:
  /// **'Let\'s track your mood today ✨'**
  String get trackMoodToday;

  /// No description provided for @ourStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Story'**
  String get ourStoryTitle;

  /// No description provided for @ourStorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pinned memories of every adventure.'**
  String get ourStorySubtitle;

  /// No description provided for @hydrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydrationTitle;

  /// No description provided for @hydrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Staying fresh & keeping healthy.'**
  String get hydrationSubtitle;

  /// No description provided for @journalTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journalTitle;

  /// No description provided for @journalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reflection for a peaceful mind.'**
  String get journalSubtitle;

  /// No description provided for @ourStoryHeader.
  ///
  /// In en, this message translates to:
  /// **'Our Story'**
  String get ourStoryHeader;

  /// No description provided for @ourStorySlogan.
  ///
  /// In en, this message translates to:
  /// **'every moment, treasured'**
  String get ourStorySlogan;

  /// No description provided for @noMemories.
  ///
  /// In en, this message translates to:
  /// **'No memories yet'**
  String get noMemories;

  /// No description provided for @noMemoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every adventure starts with a first step.\nAdd your first memory together.'**
  String get noMemoriesSubtitle;

  /// No description provided for @addMemory.
  ///
  /// In en, this message translates to:
  /// **'Add a Memory'**
  String get addMemory;

  /// No description provided for @newMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New Memory'**
  String get newMemoryTitle;

  /// No description provided for @newMemoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Description here'**
  String get newMemoryDescription;

  /// No description provided for @memoryDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory Detail'**
  String get memoryDetailTitle;

  /// No description provided for @deleteMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Forget this memory?'**
  String get deleteMemoryTitle;

  /// No description provided for @deleteMemoryContent.
  ///
  /// In en, this message translates to:
  /// **'This moment will be gone forever. Are you sure?'**
  String get deleteMemoryContent;

  /// No description provided for @keepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepIt;

  /// No description provided for @letGo.
  ///
  /// In en, this message translates to:
  /// **'Let go'**
  String get letGo;

  /// No description provided for @specialMemoryCallout.
  ///
  /// In en, this message translates to:
  /// **'A truly special moment — marked as unforgettable.'**
  String get specialMemoryCallout;

  /// No description provided for @loveNoteText.
  ///
  /// In en, this message translates to:
  /// **'Every moment with you\nis a memory worth keeping.'**
  String get loveNoteText;

  /// No description provided for @memoryTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory Title'**
  String get memoryTitleLabel;

  /// No description provided for @memoryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date / Description'**
  String get memoryDateLabel;

  /// No description provided for @saveMemory.
  ///
  /// In en, this message translates to:
  /// **'Save Memory'**
  String get saveMemory;

  /// No description provided for @waterIntakeHeader.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get waterIntakeHeader;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @drinkGoalMilli.
  ///
  /// In en, this message translates to:
  /// **'of {amount} ml'**
  String drinkGoalMilli(String amount);

  /// No description provided for @selectBeverage.
  ///
  /// In en, this message translates to:
  /// **'Select Beverage'**
  String get selectBeverage;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history yet.'**
  String get noHistory;

  /// No description provided for @journalHeader.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journalHeader;

  /// No description provided for @journalSubHeader.
  ///
  /// In en, this message translates to:
  /// **'feelings, thoughts & little moments'**
  String get journalSubHeader;

  /// No description provided for @howAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get howAreYouFeeling;

  /// No description provided for @pickAMood.
  ///
  /// In en, this message translates to:
  /// **'Pick a mood, then write your heart out.'**
  String get pickAMood;

  /// No description provided for @writeThoughtsHint.
  ///
  /// In en, this message translates to:
  /// **'Write your thoughts...'**
  String get writeThoughtsHint;

  /// No description provided for @saveNoteButton.
  ///
  /// In en, this message translates to:
  /// **'Save Note'**
  String get saveNoteButton;

  /// No description provided for @journalEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your journal is empty'**
  String get journalEmptyTitle;

  /// No description provided for @journalEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Write down how you feel.\nEvery little thought matters.'**
  String get journalEmptySubtitle;

  /// No description provided for @writeANoteButton.
  ///
  /// In en, this message translates to:
  /// **'Write a Note'**
  String get writeANoteButton;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodHappy;

  /// No description provided for @moodPeaceful.
  ///
  /// In en, this message translates to:
  /// **'Peaceful'**
  String get moodPeaceful;

  /// No description provided for @moodNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodNeutral;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get moodSad;

  /// No description provided for @moodUpset.
  ///
  /// In en, this message translates to:
  /// **'Upset'**
  String get moodUpset;

  /// No description provided for @moodCrying.
  ///
  /// In en, this message translates to:
  /// **'Crying'**
  String get moodCrying;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily morning, night & periodic alerts'**
  String get notificationsSubtitle;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @testNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send an instant notification'**
  String get testNotificationSubtitle;

  /// No description provided for @notificationsOn.
  ///
  /// In en, this message translates to:
  /// **'Notifications turned on! (30s interval for 15m)'**
  String get notificationsOn;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications turned off.'**
  String get notificationsOff;

  /// No description provided for @testNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Success! 🎉'**
  String get testNotificationTitle;

  /// No description provided for @testNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'This is a notification from Aves World.'**
  String get testNotificationBody;

  /// No description provided for @morningTitle.
  ///
  /// In en, this message translates to:
  /// **'Good Morning! ☀️'**
  String get morningTitle;

  /// No description provided for @morningBody.
  ///
  /// In en, this message translates to:
  /// **'Today is a beautiful day to track your progress. Have an amazing morning!'**
  String get morningBody;

  /// No description provided for @nightTitle.
  ///
  /// In en, this message translates to:
  /// **'Sweet Dreams 🌙'**
  String get nightTitle;

  /// No description provided for @nightBody.
  ///
  /// In en, this message translates to:
  /// **'You did great today. Rest well and see you tomorrow!'**
  String get nightBody;

  /// No description provided for @periodicHeader.
  ///
  /// In en, this message translates to:
  /// **'Aves World Alert'**
  String get periodicHeader;

  /// No description provided for @periodicMessage0.
  ///
  /// In en, this message translates to:
  /// **'Cizer loves you! ❤️'**
  String get periodicMessage0;

  /// No description provided for @periodicMessage1.
  ///
  /// In en, this message translates to:
  /// **'What are you doing? Thinking of you!'**
  String get periodicMessage1;

  /// No description provided for @periodicMessage2.
  ///
  /// In en, this message translates to:
  /// **'You are amazing! ✨'**
  String get periodicMessage2;

  /// No description provided for @periodicMessage3.
  ///
  /// In en, this message translates to:
  /// **'Just a little reminder that you are special.'**
  String get periodicMessage3;

  /// No description provided for @periodicMessage4.
  ///
  /// In en, this message translates to:
  /// **'How is your mood today? Hope it is great!'**
  String get periodicMessage4;

  /// No description provided for @periodicMessage5.
  ///
  /// In en, this message translates to:
  /// **'Drink some water! 🥤'**
  String get periodicMessage5;

  /// No description provided for @periodicMessage6.
  ///
  /// In en, this message translates to:
  /// **'Take a deep breath. 😌'**
  String get periodicMessage6;

  /// No description provided for @searchJournalHint.
  ///
  /// In en, this message translates to:
  /// **'Search your journal...'**
  String get searchJournalHint;

  /// No description provided for @noNotesMatch.
  ///
  /// In en, this message translates to:
  /// **'No notes match your search'**
  String get noNotesMatch;

  /// No description provided for @pleaseWriteSomething.
  ///
  /// In en, this message translates to:
  /// **'Please write something before saving.'**
  String get pleaseWriteSomething;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleHint;

  /// No description provided for @startWritingHint.
  ///
  /// In en, this message translates to:
  /// **'Start writing...'**
  String get startWritingHint;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @editMemory.
  ///
  /// In en, this message translates to:
  /// **'Edit Memory'**
  String get editMemory;

  /// No description provided for @shortNoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Short Note / Description'**
  String get shortNoteDesc;

  /// No description provided for @herFavStory.
  ///
  /// In en, this message translates to:
  /// **'Her Favorite Story'**
  String get herFavStory;

  /// No description provided for @hisFavStory.
  ///
  /// In en, this message translates to:
  /// **'His Favorite Story'**
  String get hisFavStory;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ne', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ne':
      return AppLocalizationsNe();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
