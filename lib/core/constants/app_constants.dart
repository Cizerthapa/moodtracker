class AppConstants {
  AppConstants._();

  // Water Intake
  static const int defaultDailyWaterGoal = 2500;
  
  // Transitions & Delays
  static const int splashDelaySeconds = 3;
  static const int defaultTransitionDurationMs = 300;
  static const int fadeTransitionDurationMs = 600;
  
  // Notifications
  static const int morningNotificationHour = 6;
  static const int morningNotificationMinute = 0;
  static const int nightNotificationHour = 23;
  static const int nightNotificationMinute = 59;
  static const int periodicNotificationIntervalSeconds = 30;
  static const int maxPeriodicNotifications = 30;

  // Firebase
  static const String memoriesCollection = 'memories';
  static const String periodsCollection = 'periods';
  static const String moodNotesPrefsKey = 'mood_notes';
  static const String drinkHistoryPrefsKey = 'drink_history';
  static const String waterGoalPrefsKey = 'water_goal';
  static const String notesCollection = 'notes';
  static const String notificationsPrefsKey = 'notifications_enabled';
  static const String biometricPrefsKey = 'biometric_enabled';
  static const String memoriesCacheKey = 'memories_cache';

  // Notifications
  static const String notificationMethodChannel = 'com.cizerthapa.moodtrack/notifications';
  static const String instantChannelId = 'instant_channel';
  static const String instantChannelName = 'Instant Notifications';
  static const String dailyChannelId = 'daily_channel';
  static const String dailyChannelName = 'Daily Messages';

  // Audio Tracks (local assets)
  static const String audioBirds = 'music/birds-relaxing.mp3';
  static const String audioWaterfall = 'music/waterfall.mp3';
  static const String audioForest = 'music/forest-music.mp3';

}
