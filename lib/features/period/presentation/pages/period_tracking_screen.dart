import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/theme/theme_manager.dart';
import 'package:moodtrack/core/widgets/shimmer_loading.dart';
import 'package:moodtrack/features/period/domain/model/period_cycle_model.dart';
import 'package:moodtrack/features/period/data/repositories/period_repository.dart';
import 'package:moodtrack/features/period/presentation/pages/log_period_screen.dart';

const Color _kCycleColor = Color(0xFF9B7EC8);
const Color _kUserColor = Color(0xFFE8789A);
const Color _kPartnerColor = Color(0xFF7ABBE8);

class PeriodTrackingScreen extends StatefulWidget {
  const PeriodTrackingScreen({super.key});

  @override
  State<PeriodTrackingScreen> createState() => _PeriodTrackingScreenState();
}

class _PeriodTrackingScreenState extends State<PeriodTrackingScreen> {
  final PeriodRepository _repo = PeriodRepository();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  DateTime _focusedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedTab = 0; // 0 = Calendar, 1 = History

  void _navigateMonth(int delta) {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  void _openLogScreen({PeriodCycle? cycle}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LogPeriodScreen(
          existingCycle: cycle,
          onSave: (c) async {
            if (cycle != null) {
              await _repo.updateCycle(c);
            } else {
              await _repo.addCycle(c);
            }
          },
        ),
      ),
    );
  }

  /// Returns the predicted next start date based on the user's own cycle history.
  DateTime? _predictNext(List<PeriodCycle> cycles) {
    final mine = cycles
        .where((c) => c.ownerUid == _uid)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    if (mine.isEmpty) return null;
    if (mine.length == 1) {
      return mine[0].startDate.add(const Duration(days: 28));
    }

    int totalDays = 0;
    int count = 0;
    for (int i = 0; i < mine.length - 1 && i < 3; i++) {
      final diff =
          mine[i].startDate.difference(mine[i + 1].startDate).inDays;
      if (diff > 10 && diff < 60) {
        totalDays += diff;
        count++;
      }
    }
    final avgCycle = count > 0 ? (totalDays / count).round() : 28;
    return mine[0].startDate.add(Duration(days: avgCycle));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (_, __, ___) => Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildTabs(),
              Expanded(
                child: StreamBuilder<List<PeriodCycle>>(
                  stream: _repo.getPeriodsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return _buildShimmer();
                    final cycles = snapshot.data!;
                    return _selectedTab == 0
                        ? _buildCalendarTab(cycles)
                        : _buildHistoryTab(cycles);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(28.w, 24.h, 24.w, 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cycle Tracker',
                  style: GoogleFonts.outfit(
                    fontSize: 34.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warmBrown,
                    height: 1.1,
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 12.r,
                      color: _kUserColor,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'every cycle, understood',
                      style: GoogleFonts.outfit(
                        fontStyle: FontStyle.italic,
                        fontSize: 13.sp,
                        color: AppColors.softBrown,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _openLogScreen();
            },
            child: Container(
              width: 46.r,
              height: 46.r,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kCycleColor, _kUserColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kCycleColor.withValues(alpha: 0.3),
                    blurRadius: 14.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Icon(Icons.add_rounded, color: Colors.white, size: 22.r),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
      child: Row(
        children: [
          _tabButton(0, Icons.calendar_month_rounded, 'Calendar'),
          SizedBox(width: 12.w),
          _tabButton(1, Icons.history_rounded, 'History'),
        ],
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, String label) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        if (_selectedTab != index) {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: active ? _kCycleColor : Colors.transparent,
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16.r,
                color: active ? Colors.white : AppColors.softBrown),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: active ? Colors.white : AppColors.softBrown,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Calendar Tab ──────────────────────────────────────────────────────────

  Widget _buildCalendarTab(List<PeriodCycle> cycles) {
    final nextPeriod = _predictNext(cycles);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildMonthNav(),
          SizedBox(height: 12.h),
          _buildCalendarGrid(cycles),
          SizedBox(height: 14.h),
          _buildLegend(cycles),
          SizedBox(height: 14.h),
          if (nextPeriod != null) _buildPredictionCard(nextPeriod),
        ],
      ),
    );
  }

  Widget _buildMonthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _navigateMonth(-1),
          icon: Icon(Icons.chevron_left_rounded,
              color: AppColors.warmBrown, size: 28.r),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_focusedMonth),
          style: GoogleFonts.outfit(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.warmBrown,
          ),
        ),
        IconButton(
          onPressed: () => _navigateMonth(1),
          icon: Icon(Icons.chevron_right_rounded,
              color: AppColors.warmBrown, size: 28.r),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(List<PeriodCycle> cycles) {
    final firstDay =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final today = DateTime.now();
    final startOffset = firstDay.weekday - 1; // Mon=0 … Sun=6
    final totalCells = startOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();
    const weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.ivoryCard,
        borderRadius: BorderRadius.circular(20.r),
        border:
            Border.all(color: _kCycleColor.withValues(alpha: 0.15)),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays
                .map(
                  (d) => SizedBox(
                    width: 36.r,
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          color: AppColors.softBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 8.h),
          ...List.generate(rows, (row) {
            return Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final dayNum = cellIndex - startOffset + 1;

                  if (dayNum < 1 || dayNum > lastDay.day) {
                    return SizedBox(width: 36.r, height: 36.r);
                  }

                  final date = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month,
                    dayNum,
                  );
                  final isToday = date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;

                  Color? periodColor;
                  for (final c in cycles) {
                    if (c.isActiveOn(date)) {
                      periodColor =
                          c.ownerUid == _uid ? _kUserColor : _kPartnerColor;
                      break;
                    }
                  }

                  return _DayCell(
                    day: dayNum,
                    isToday: isToday,
                    periodColor: periodColor,
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegend(List<PeriodCycle> cycles) {
    final hasPartnerData =
        cycles.any((c) => c.ownerUid != _uid);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(_kUserColor, 'Your period'),
        if (hasPartnerData) ...[
          SizedBox(width: 20.w),
          _legendDot(_kPartnerColor, 'Partner\'s period'),
        ],
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.r,
          height: 10.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.outfit(
              fontSize: 12.sp, color: AppColors.softBrown),
        ),
      ],
    );
  }

  Widget _buildPredictionCard(DateTime nextPeriod) {
    final daysUntil = nextPeriod.difference(DateTime.now()).inDays;
    final isPast = daysUntil < 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kCycleColor.withValues(alpha: 0.1),
            _kUserColor.withValues(alpha: 0.07),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _kCycleColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: _kCycleColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(Icons.event_rounded, color: _kCycleColor, size: 22.r),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next Period',
                style: GoogleFonts.outfit(
                    fontSize: 12.sp, color: AppColors.softBrown),
              ),
              SizedBox(height: 2.h),
              Text(
                isPast
                    ? DateFormat('MMM d').format(nextPeriod)
                    : '${DateFormat('MMM d').format(nextPeriod)}  ·  in $daysUntil days',
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warmBrown,
                ),
              ),
              Text(
                'estimated · based on your history',
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  color: AppColors.softBrown,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── History Tab ───────────────────────────────────────────────────────────

  Widget _buildHistoryTab(List<PeriodCycle> cycles) {
    final mine = cycles
        .where((c) => c.ownerUid == _uid)
        .toList();

    if (mine.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
      physics: const BouncingScrollPhysics(),
      itemCount: mine.length,
      itemBuilder: (context, i) {
        final cycle = mine[i];
        return _CycleCard(
          cycle: cycle,
          onTap: () => _openLogScreen(cycle: cycle),
          onDelete: () => _confirmDelete(cycle),
        );
      },
    );
  }

  Future<void> _confirmDelete(PeriodCycle cycle) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.ivoryCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Delete Cycle?',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700, color: AppColors.warmBrown),
        ),
        content: Text(
          'This cycle log will be deleted permanently.',
          style:
              GoogleFonts.outfit(color: AppColors.softBrown, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: AppColors.softBrown)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(
                  color: _kUserColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && cycle.id != null) {
      await _repo.deleteCycle(cycle.id!);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌸', style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 18.h),
            Text(
              'No cycles logged yet',
              style: GoogleFonts.outfit(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Track your cycle to get insights\nand share with your partner.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontStyle: FontStyle.italic,
                fontSize: 14.sp,
                color: AppColors.softBrown,
                height: 1.6,
              ),
            ),
            SizedBox(height: 28.h),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _openLogScreen();
              },
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: _kCycleColor,
                  borderRadius: BorderRadius.circular(50.r),
                  boxShadow: [
                    BoxShadow(
                      color: _kCycleColor.withValues(alpha: 0.3),
                      blurRadius: 16.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Text(
                  'Log First Cycle',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: EdgeInsets.all(20.r),
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: ShimmerLoading(
              isLoading: true,
              child: ShimmerSkeleton(
                height: i == 0 ? 300.h : 100.h,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Day Cell ─────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final Color? periodColor;

  const _DayCell({
    required this.day,
    required this.isToday,
    this.periodColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36.r,
      height: 36.r,
      child: Container(
        margin: EdgeInsets.all(2.r),
        decoration: BoxDecoration(
          color: periodColor != null
              ? periodColor!.withValues(alpha: 0.85)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday && periodColor == null
              ? Border.all(
                  color: _kCycleColor.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : null,
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              color: periodColor != null
                  ? Colors.white
                  : isToday
                      ? _kCycleColor
                      : AppColors.warmBrown,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Cycle History Card ───────────────────────────────────────────────────────

class _CycleCard extends StatelessWidget {
  final PeriodCycle cycle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CycleCard({
    required this.cycle,
    required this.onTap,
    required this.onDelete,
  });

  String _flowLabel(int l) =>
      l == 1 ? 'Light' : l == 3 ? 'Heavy' : 'Medium';

  String _flowEmoji(int l) =>
      l == 1 ? '💧' : l == 3 ? '💧💧💧' : '💧💧';

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');
    final startStr = fmt.format(cycle.startDate);
    final endStr =
        cycle.endDate != null ? fmt.format(cycle.endDate!) : 'Ongoing';
    final duration =
        cycle.endDate != null ? '${cycle.durationDays}d' : '...';

    return Dismissible(
      key: Key(cycle.id ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.w),
        decoration: BoxDecoration(
          color: _kUserColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: _kUserColor, size: 24.r),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: AppColors.ivoryCard,
            borderRadius: BorderRadius.circular(20.r),
            border:
                Border.all(color: _kUserColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: _kUserColor.withValues(alpha: 0.06),
                blurRadius: 12.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14.r, color: _kUserColor),
                      SizedBox(width: 6.w),
                      Text(
                        '$startStr  →  $endStr',
                        style: GoogleFonts.outfit(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warmBrown,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _kUserColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    child: Text(
                      duration,
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        color: _kUserColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Text(_flowEmoji(cycle.flowLevel),
                      style: const TextStyle(fontSize: 14)),
                  SizedBox(width: 6.w),
                  Text(
                    '${_flowLabel(cycle.flowLevel)} flow',
                    style: GoogleFonts.outfit(
                        fontSize: 13.sp, color: AppColors.softBrown),
                  ),
                ],
              ),
              if (cycle.symptoms.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: cycle.symptoms
                      .take(4)
                      .map(
                        (s) => Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: _kCycleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                          child: Text(
                            s.replaceAll('_', ' '),
                            style: GoogleFonts.outfit(
                                fontSize: 11.sp, color: _kCycleColor),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (cycle.notes != null && cycle.notes!.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(
                  cycle.notes!,
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    color: AppColors.softBrown,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
