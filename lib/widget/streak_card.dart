import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/core/services/streak_service.dart';

class StreakCard extends StatefulWidget {
  final StreakData data;

  const StreakCard({super.key, required this.data});

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _expandAnim;

  static const _cardTint = Color(0xFFFFF6EC);
  static const _accent = Color(0xFFE8943A);
  static const _gold = Color(0xFFD4A832);
  static const _subText = Color(0xFF8C6050);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        decoration: BoxDecoration(
          color: _cardTint,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: _accent.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.08),
              blurRadius: 14.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(18.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('🔥', style: TextStyle(fontSize: 26.sp)),
                  10.horizontalSpace,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${data.currentStreak}',
                            style: GoogleFonts.outfit(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.bold,
                              color: _accent,
                              height: 1.0,
                            ),
                          ),
                          5.horizontalSpace,
                          Text(
                            data.currentStreak == 1 ? 'day streak' : 'days streak',
                            style: GoogleFonts.outfit(
                              fontSize: 13.sp,
                              color: _subText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (data.currentStreak == 0)
                        Text(
                          'Log today to start your streak!',
                          style: GoogleFonts.outfit(
                            fontSize: 11.sp,
                            fontStyle: FontStyle.italic,
                            color: _subText.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '✨ Best',
                        style: GoogleFonts.outfit(fontSize: 10.sp, color: _gold),
                      ),
                      Text(
                        '${data.longestStreak} days',
                        style: GoogleFonts.outfit(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: _gold,
                        ),
                      ),
                    ],
                  ),
                  8.horizontalSpace,
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 280),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 22.r, color: _accent),
                  ),
                ],
              ),

              // ── Expanded section ──────────────────────────────────────────
              SizeTransition(
                sizeFactor: _expandAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.milestone != null) ...[
                      12.verticalSpace,
                      _MilestoneBadge(milestone: data.milestone!),
                    ],
                    14.verticalSpace,
                    Divider(color: _accent.withValues(alpha: 0.2), thickness: 1, height: 1),
                    12.verticalSpace,
                    Row(
                      children: [
                        Icon(Icons.grid_on_rounded, size: 12.r, color: _subText),
                        5.horizontalSpace,
                        Text(
                          'Activity Calendar',
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _subText,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    10.verticalSpace,
                    _StreakHeatmap(activityMap: data.activityMap),
                    10.verticalSpace,
                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Less',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: _subText.withValues(alpha: 0.55),
                          ),
                        ),
                        4.horizontalSpace,
                        ...[0.0, 0.35, 0.65, 1.0].map(
                          (opacity) => Container(
                            width: 9.r,
                            height: 9.r,
                            margin: EdgeInsets.only(right: 2.r),
                            decoration: BoxDecoration(
                              color: opacity == 0
                                  ? const Color(0xFFF0DDD0).withValues(alpha: 0.8)
                                  : _accent.withValues(alpha: opacity),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                        4.horizontalSpace,
                        Text(
                          'More',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: _subText.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Milestone Badge ──────────────────────────────────────────────────────────

class _MilestoneBadge extends StatelessWidget {
  final int milestone;
  const _MilestoneBadge({required this.milestone});

  static const _labels = {
    7: ('🌱', 'Week-Long Warrior!'),
    14: ('🌿', 'Fortnight Keeper!'),
    30: ('🌸', 'Monthly Maven!'),
    60: ('⭐', 'Two-Month Star!'),
    100: ('🏆', 'Century Legend!'),
  };

  @override
  Widget build(BuildContext context) {
    final entry = _labels[milestone];
    final emoji = entry?.$1 ?? '🎉';
    final label = entry?.$2 ?? '$milestone-Day Achiever!';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A832).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50.r),
        border: Border.all(color: const Color(0xFFD4A832).withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 14.sp)),
          6.horizontalSpace,
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB8860B),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Streak Heatmap ───────────────────────────────────────────────────────────

class _StreakHeatmap extends StatelessWidget {
  final Map<String, int> activityMap;
  static const _numWeeks = 12;
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _subText = Color(0xFF8C6050);
  static const _accent = Color(0xFFE8943A);

  const _StreakHeatmap({required this.activityMap});

  List<List<DateTime?>> _buildWeeks() {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final startOfThisWeek = todayNorm.subtract(Duration(days: todayNorm.weekday - 1));
    final startDate = startOfThisWeek.subtract(Duration(days: (_numWeeks - 1) * 7));

    return List.generate(_numWeeks, (w) {
      return List.generate(7, (d) {
        final date = startDate.add(Duration(days: w * 7 + d));
        return date.isAfter(todayNorm) ? null : date;
      });
    });
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Color _cellColor(DateTime? date) {
    if (date == null) return Colors.transparent;
    final count = activityMap[_dateKey(date)] ?? 0;
    if (count == 0) return const Color(0xFFF0DDD0).withValues(alpha: 0.8);
    if (count == 1) return _accent.withValues(alpha: 0.35);
    if (count == 2) return _accent.withValues(alpha: 0.65);
    return _accent;
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();

    return LayoutBuilder(
      builder: (context, constraints) {
        const labelWidth = 16.0;
        const labelGap = 4.0;
        const cellGap = 2.0;
        final availableForCells =
            constraints.maxWidth - labelWidth - labelGap - (_numWeeks - 1) * cellGap;
        final cellSize = (availableForCells / _numWeeks).clamp(8.0, 20.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: List.generate(7, (i) {
                return SizedBox(
                  width: labelWidth,
                  height: cellSize + cellGap,
                  child: Center(
                    child: Text(
                      _dayLabels[i],
                      style: TextStyle(
                        fontSize: 8.5.sp,
                        color: _subText.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: labelGap),
            ...weeks.map((week) {
              return Padding(
                padding: const EdgeInsets.only(right: cellGap),
                child: Column(
                  children: week.map((date) {
                    return Container(
                      width: cellSize,
                      height: cellSize,
                      margin: const EdgeInsets.only(bottom: cellGap),
                      decoration: BoxDecoration(
                        color: _cellColor(date),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
