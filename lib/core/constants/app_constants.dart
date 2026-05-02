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

  // Audio Tracks
  static const String audioBirdsUrl = 'https://cdn.pixabay.com/download/audio/2022/01/18/audio_145c228d42.mp3';
  static const String audioWaterfallUrl = 'https://cdn.pixabay.com/download/audio/2021/08/04/audio_0625c1539c.mp3';
  static const String audioForestUrl = 'https://cdn.pixabay.com/download/audio/2021/09/06/audio_4f09d20c57.mp3';
}
