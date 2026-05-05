import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodtrack/core/database/local_database.dart';
import 'package:moodtrack/core/di/service_locator.dart';
import 'package:moodtrack/core/constants/app_constants.dart';

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final int? milestone;
  final Map<String, int> activityMap;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    this.milestone,
    required this.activityMap,
  });
}

class StreakService {
  static const _milestones = [100, 60, 30, 14, 7];
  final AppDatabase _db = sl<AppDatabase>();

  Future<StreakData> getStreakData() async {
    final noteDates = await _getNoteDates();
    final journalDates = await _getJournalDates();

    final activityMap = <String, int>{};
    for (final d in noteDates) {
      activityMap[d] = (activityMap[d] ?? 0) + 1;
    }
    for (final d in journalDates) {
      activityMap[d] = (activityMap[d] ?? 0) + 1;
    }

    final dateSet = activityMap.keys.toSet();
    final current = _computeCurrentStreak(dateSet);
    final longest = await _updateLongestStreak(current);
    final milestone = _getMilestone(current);

    return StreakData(
      currentStreak: current,
      longestStreak: longest,
      milestone: milestone,
      activityMap: activityMap,
    );
  }

  Future<bool> hasEntryToday() async {
    final noteDates = await _getNoteDates();
    final journalDates = await _getJournalDates();
    final today = _dateKey(DateTime.now());
    return noteDates.contains(today) || journalDates.contains(today);
  }

  int _computeCurrentStreak(Set<String> dateSet) {
    int streak = 0;
    var check = DateTime.now();

    // If nothing logged today, start counting from yesterday
    if (!dateSet.contains(_dateKey(check))) {
      check = check.subtract(const Duration(days: 1));
    }

    while (dateSet.contains(_dateKey(check))) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<int> _updateLongestStreak(int current) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(AppConstants.longestStreakPrefsKey) ?? 0;
      if (current > stored) {
        await prefs.setInt(AppConstants.longestStreakPrefsKey, current);
        return current;
      }
      return stored;
    } catch (e) {
      log('StreakService: Error updating longest streak: $e', name: 'StreakService');
      return current;
    }
  }

  int? _getMilestone(int streak) {
    for (final m in _milestones) {
      if (streak >= m) return m;
    }
    return null;
  }

  Future<List<String>> _getNoteDates() async {
    try {
      return (await _db.getAllNotes()).map((n) => _dateKey(n.date)).toList();
    } catch (e) {
      log('StreakService: Error fetching note dates: $e', name: 'StreakService');
      return [];
    }
  }

  Future<List<String>> _getJournalDates() async {
    try {
      return (await _db.getAllJournals()).map((j) => _dateKey(j.date)).toList();
    } catch (e) {
      log('StreakService: Error fetching journal dates: $e', name: 'StreakService');
      return [];
    }
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
