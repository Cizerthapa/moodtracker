import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodtrack/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/theme/theme_manager.dart';
import 'package:moodtrack/core/widgets/shimmer_loading.dart';
import 'package:moodtrack/features/period/domain/model/period_cycle_model.dart';
import 'package:moodtrack/features/period/data/repositories/period_repository.dart';
import 'package:moodtrack/core/di/service_locator.dart';
import 'package:moodtrack/core/services/activity_log_service.dart';

import 'package:moodtrack/features/period/presentation/pages/log_period_screen.dart';

class PeriodTrackingScreen extends StatefulWidget {
  const PeriodTrackingScreen({super.key});

  @override
  State<PeriodTrackingScreen> createState() => _PeriodTrackingScreenState();
}

class _PeriodTrackingScreenState extends State<PeriodTrackingScreen> {
  final PeriodRepository _repo = sl<PeriodRepository>();
  final ActivityLogService _logger = sl<ActivityLogService>();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedTab = 0;

  String? _partnerUid;
  StreamSubscription<String?>? _partnerUidSub;

  @override
  void initState() {
    super.initState();
    _partnerUidSub = _repo.getPartnerUidStream().listen((uid) {
      if (mounted) setState(() => _partnerUid = uid);
    });
  }

  @override
  void dispose() {
    _partnerUidSub?.cancel();
    super.dispose();
  }

  void _navigateMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  void _openLogScreen({PeriodCycle? cycle, bool isPartner = false}) {
    final resolvedIsPartner = isPartner || (cycle != null && cycle.ownerUid != _uid);
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LogPeriodScreen(
          existingCycle: cycle,
          isPartnerCycle: resolvedIsPartner,
          onSave: (c) async {
            if (resolvedIsPartner) {
              final targetUid = cycle?.ownerUid ?? _partnerUid;
              if (targetUid == null) return;
              if (cycle != null) {
                await _repo.updatePartnerCycle(targetUid, c);
                _logger.log('period_cycle_updated', metadata: {'isPartner': true});
              } else {
                await _repo.addPartnerCycle(targetUid, c);
                _logger.log('period_cycle_added', metadata: {'isPartner': true});
              }
            } else {
              if (cycle != null) {
                await _repo.updateCycle(c);
                _logger.log('period_cycle_updated', metadata: {'isPartner': false});
              } else {
                await _repo.addCycle(c);
                _logger.log('period_cycle_added', metadata: {'isPartner': false});
              }
            }
          },
        ),
      ),
    );
  }

  PeriodCycle? _getMostRecentCycle(List<PeriodCycle> cycles) {
    final mine = cycles.where((c) => c.ownerUid == _uid).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return mine.isEmpty ? null : mine.first;
  }

  int _getAverageCycleLength(List<PeriodCycle> cycles) {
    final mine = cycles.where((c) => c.ownerUid == _uid).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    if (mine.isEmpty || mine.length == 1) return 28;

    int totalDays = 0;
    int count = 0;
    for (int i = 0; i < mine.length - 1 && i < 3; i++) {
      final diff = mine[i].startDate.difference(mine[i + 1].startDate).inDays;
      if (diff > 10 && diff < 60) {
        totalDays += diff;
        count++;
      }
    }
    return count > 0 ? (totalDays / count).round() : 28;
  }

  int _getAveragePeriodLength(List<PeriodCycle> cycles) {
    final mine = cycles.where((c) => c.ownerUid == _uid).toList();
    if (mine.isEmpty) return 5;
    int totalDays = 0;
    int count = 0;
    for (final c in mine) {
      if (c.endDate != null) {
        totalDays += c.durationDays;
        count++;
      }
    }
    return count > 0 ? (totalDays / count).round() : 5;
  }

  DateTime? _predictNext(List<PeriodCycle> cycles) {
    final mostRecent = _getMostRecentCycle(cycles);
    if (mostRecent == null) return null;
    final avgCycle = _getAverageCycleLength(cycles);
    return mostRecent.startDate.add(Duration(days: avgCycle));
  }

  void _showInfoSheet() {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InfoBottomSheet(l10n: l10n),
    );
  }

  bool _isFertileWindow(DateTime date, PeriodCycle? mostRecent, int avgCycleLength) {
    if (mostRecent == null) return false;
    final diff = date.difference(mostRecent.startDate).inDays;
    if (diff > -60) {
      final dayOfCycle = (diff % avgCycleLength) + 1;
      final ovulationWindowStart = avgCycleLength - 18;
      final lutealPhaseStart = avgCycleLength - 13;
      return dayOfCycle >= ovulationWindowStart && dayOfCycle < lutealPhaseStart;
    }
    return false;
  }

  bool _isSafeWindow(DateTime date, PeriodCycle? mostRecent, int avgCycleLength) {
    if (mostRecent == null) return false;
    final diff = date.difference(mostRecent.startDate).inDays;
    if (diff > -60) {
      final dayOfCycle = (diff % avgCycleLength) + 1;
      final ovulationWindowStart = avgCycleLength - 18;
      final lutealPhaseStart = avgCycleLength - 13;
      return dayOfCycle < ovulationWindowStart || dayOfCycle >= lutealPhaseStart;
    }
    return false;
  }

  Future<bool> _confirmDelete(PeriodCycle cycle) async {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.ivoryCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          l10n.deleteCycleTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.warmBrown),
        ),
        content: Text(
          l10n.deleteCycleContent,
          style: GoogleFonts.outfit(color: AppColors.softBrown, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel, style: GoogleFonts.outfit(color: AppColors.softBrown)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.delete,
              style: GoogleFonts.outfit(color: AppColors.userColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && cycle.id != null) {
      if (cycle.ownerUid != _uid) {
        await _repo.deletePartnerCycle(cycle.ownerUid, cycle.id!);
      } else {
        await _repo.deleteCycle(cycle.id!);
      }
      _logger.log('period_cycle_deleted', metadata: {'isPartner': cycle.ownerUid != _uid});
    }
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (ctx, tm, child) => Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: StreamBuilder<List<PeriodCycle>>(
            stream: _repo.getPeriodsStream(),
            builder: (context, snapshot) {
              final cycles = snapshot.data ?? [];
              final nextPeriod = _predictNext(cycles);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PeriodHeader(
                    onInfo: _showInfoSheet,
                    onAdd: () {
                      HapticFeedback.lightImpact();
                      _openLogScreen();
                    },
                  ),
                  _PeriodTabs(
                    selectedTab: _selectedTab,
                    onTabChanged: (i) {
                      if (_selectedTab != i) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTab = i);
                      }
                    },
                  ),
                  if (snapshot.hasData && nextPeriod != null)
                    _NextPeriodBanner(nextPeriod: nextPeriod),
                  Expanded(
                    child: !snapshot.hasData
                        ? const _PeriodShimmer()
                        : _selectedTab == 0
                        ? _buildCalendarTab(cycles)
                        : _buildHistoryTab(cycles),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Calendar Tab ──────────────────────────────────────────────────────────

  Widget _buildCalendarTab(List<PeriodCycle> cycles) {
    final nextPeriod = _predictNext(cycles);
    final mostRecent = _getMostRecentCycle(cycles);
    final avgLength = _getAverageCycleLength(cycles);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _MonthNav(
            focusedMonth: _focusedMonth,
            onPrev: () => _navigateMonth(-1),
            onNext: () => _navigateMonth(1),
          ),
          12.verticalSpace,
          _buildCalendarGrid(cycles, mostRecent, avgLength, nextPeriod),
          14.verticalSpace,
          _CalendarLegend(hasPartnerData: cycles.any((c) => c.ownerUid != _uid)),
          14.verticalSpace,
          if (mostRecent != null) _PhaseCard(cycle: mostRecent, avgCycleLength: avgLength),
          if (mostRecent != null && nextPeriod != null) 14.verticalSpace,
          if (nextPeriod != null) _PredictionCard(nextPeriod: nextPeriod),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
    List<PeriodCycle> cycles,
    PeriodCycle? mostRecent,
    int avgCycleLength,
    DateTime? nextPeriod,
  ) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final today = DateTime.now();
    final startOffset = firstDay.weekday - 1;
    final totalCells = startOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();
    const weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.ivoryCard,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.cycleColor.withValues(alpha: 0.15)),
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
          8.verticalSpace,
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

                  final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                  final isToday =
                      date.year == today.year && date.month == today.month && date.day == today.day;

                  Color? periodColor;
                  bool isPredicted = false;
                  double opacity = 1.0;

                  PeriodCycle? activeCycle;
                  for (final c in cycles) {
                    if (c.isActiveOn(date)) {
                      activeCycle = c;
                      periodColor =
                          c.ownerUid == _uid ? AppColors.userColor : AppColors.partnerColor;
                      break;
                    }
                  }

                  if (activeCycle != null) {
                    final dayOfPeriod = date.difference(activeCycle.startDate).inDays + 1;
                    final totalDuration = activeCycle.endDate != null
                        ? activeCycle.durationDays
                        : _getAveragePeriodLength(cycles);

                    if (totalDuration >= 3) {
                      if (dayOfPeriod >= totalDuration) {
                        opacity = 0.35;
                      } else if (dayOfPeriod >= totalDuration - 1) {
                        opacity = 0.65;
                      }
                    }
                  } else if (nextPeriod != null) {
                    final avgPeriod = _getAveragePeriodLength(cycles);
                    final nextEnd = nextPeriod.add(Duration(days: avgPeriod - 1));
                    final d = DateTime(date.year, date.month, date.day);
                    final start = DateTime(nextPeriod.year, nextPeriod.month, nextPeriod.day);
                    final end = DateTime(nextEnd.year, nextEnd.month, nextEnd.day);

                    if (!d.isBefore(start) && !d.isAfter(end)) {
                      periodColor = AppColors.userColor;
                      isPredicted = true;
                      final dayOfPeriod = d.difference(start).inDays + 1;
                      if (avgPeriod >= 3) {
                        if (dayOfPeriod >= avgPeriod) {
                          opacity = 0.4;
                        } else if (dayOfPeriod >= avgPeriod - 1) {
                          opacity = 0.7;
                        }
                      }
                    }
                  }

                  final isFertile = _isFertileWindow(date, mostRecent, avgCycleLength);
                  final isSafe = _isSafeWindow(date, mostRecent, avgCycleLength);

                  return _DayCell(
                    day: dayNum,
                    isToday: isToday,
                    periodColor: periodColor,
                    isFertileWindow: isFertile,
                    isSafeWindow: isSafe,
                    isPredicted: isPredicted,
                    opacity: opacity,
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── History Tab ───────────────────────────────────────────────────────────

  Widget _buildHistoryTab(List<PeriodCycle> cycles) {
    final mine = cycles.where((c) => c.ownerUid == _uid).toList();
    final partnerCycles = cycles.where((c) => c.ownerUid != _uid).toList();
    final hasPartner = _partnerUid != null || partnerCycles.isNotEmpty;

    if (mine.isEmpty && !hasPartner) {
      return _EmptyState(onAdd: _openLogScreen);
    }

    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
      physics: const BouncingScrollPhysics(),
      children: [
        _SectionHeader(title: l10n.yourCycles, icon: Icons.person_rounded, color: AppColors.userColor),
        8.verticalSpace,
        if (mine.isEmpty)
          _InlineSectionEmpty(message: l10n.noCyclesLogged, onAdd: () => _openLogScreen())
        else
          ...mine.map(
            (c) => _CycleCard(
              cycle: c,
              isPartnerCard: false,
              onTap: () => _openLogScreen(cycle: c),
              onDelete: () => _confirmDelete(c),
            ),
          ),

        if (hasPartner) ...[
          20.verticalSpace,
          _SectionHeader(
            title: l10n.partnerCycles,
            icon: Icons.favorite_rounded,
            color: AppColors.partnerColor,
          ),
          8.verticalSpace,
          if (partnerCycles.isEmpty)
            _InlineSectionEmpty(
              message: l10n.noPartnerCycles,
              onAdd: _partnerUid != null ? () => _openLogScreen(isPartner: true) : null,
              addLabel: l10n.logForPartner,
            )
          else
            ...partnerCycles.map(
              (c) => _CycleCard(
                cycle: c,
                isPartnerCard: true,
                onTap: () => _openLogScreen(cycle: c),
                onDelete: () => _confirmDelete(c),
              ),
            ),
        ],
      ],
    );
  }
}

// ─── Next Period Banner ───────────────────────────────────────────────────────

class _NextPeriodBanner extends StatelessWidget {
  final DateTime nextPeriod;
  const _NextPeriodBanner({required this.nextPeriod});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final daysUntil = nextPeriod
        .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .inDays;
    final isPast = daysUntil < 0;
    final isToday = daysUntil == 0;
    final isSoon = daysUntil > 0 && daysUntil <= 3;

    final bannerColor = isPast || isToday ? AppColors.userColor : AppColors.cycleColor;

    String label;
    String sublabel;
    if (isToday) {
      label = l10n.periodExpectedToday;
      sublabel = l10n.basedOnCycleHistory;
    } else if (isPast) {
      label = l10n.periodDaysAgo(daysUntil.abs());
      sublabel = l10n.haveYouLoggedIt;
    } else if (isSoon) {
      label = l10n.periodSoonIn(daysUntil);
      sublabel = l10n.periodSoonHeadsUp;
    } else {
      label = l10n.nextPeriodIn(daysUntil);
      sublabel = DateFormat('MMMM d').format(nextPeriod) + l10n.estimatedDot;
    }

    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bannerColor.withValues(alpha: 0.13), bannerColor.withValues(alpha: 0.06)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: bannerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPast ? Icons.warning_amber_rounded : Icons.calendar_today_rounded,
              size: 18.r,
              color: bannerColor,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warmBrown,
                  ),
                ),
                Text(
                  sublabel,
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    color: AppColors.softBrown,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM d').format(nextPeriod),
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: bannerColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Period Header ────────────────────────────────────────────────────────────

class _PeriodHeader extends StatelessWidget {
  final VoidCallback onInfo;
  final VoidCallback onAdd;
  const _PeriodHeader({required this.onInfo, required this.onAdd});

  @override
  Widget build(BuildContext context) {
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
                  AppLocalizations.of(context)!.cycleTrackerHeader,
                  style: GoogleFonts.outfit(
                    fontSize: 34.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warmBrown,
                    height: 1.1,
                    letterSpacing: -0.8,
                  ),
                ),
                4.verticalSpace,
                Row(
                  children: [
                    Icon(Icons.favorite_rounded, size: 12.r, color: AppColors.userColor),
                    6.horizontalSpace,
                    Text(
                      AppLocalizations.of(context)!.cycleTrackerSlogan,
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
            onTap: onInfo,
            child: Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: AppColors.ivoryCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.champagne),
              ),
              child: Icon(Icons.help_outline_rounded, size: 20.r, color: AppColors.softBrown),
            ),
          ),
          10.horizontalSpace,
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 46.r,
              height: 46.r,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cycleColor, AppColors.userColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cycleColor.withValues(alpha: 0.3),
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
}

// ─── Period Tabs ──────────────────────────────────────────────────────────────

class _PeriodTabs extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  const _PeriodTabs({required this.selectedTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
      child: Row(
        children: [
          _TabButton(
            index: 0,
            icon: Icons.calendar_month_rounded,
            label: l10n.calendar,
            selectedTab: selectedTab,
            onTap: onTabChanged,
          ),
          12.horizontalSpace,
          _TabButton(
            index: 1,
            icon: Icons.history_rounded,
            label: l10n.history,
            selectedTab: selectedTab,
            onTap: onTabChanged,
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final int selectedTab;
  final ValueChanged<int> onTap;

  const _TabButton({
    required this.index,
    required this.icon,
    required this.label,
    required this.selectedTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = selectedTab == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: active ? AppColors.cycleColor : Colors.transparent,
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16.r, color: active ? Colors.white : AppColors.softBrown),
            6.horizontalSpace,
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
}

// ─── Month Nav ────────────────────────────────────────────────────────────────

class _MonthNav extends StatelessWidget {
  final DateTime focusedMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthNav({
    required this.focusedMonth,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: Icon(Icons.chevron_left_rounded, color: AppColors.warmBrown, size: 28.r),
        ),
        Text(
          DateFormat('MMMM yyyy').format(focusedMonth),
          style: GoogleFonts.outfit(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.warmBrown,
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(Icons.chevron_right_rounded, color: AppColors.warmBrown, size: 28.r),
        ),
      ],
    );
  }
}

// ─── Phase Card ───────────────────────────────────────────────────────────────

class _PhaseCard extends StatelessWidget {
  final PeriodCycle cycle;
  final int avgCycleLength;

  const _PhaseCard({required this.cycle, required this.avgCycleLength});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final diff = today.difference(cycle.startDate).inDays;
    if (diff > 60) return const SizedBox();

    final phase = cycle.getCurrentPhase(today, avgCycleLength);
    final l10n = AppLocalizations.of(context)!;

    String title;
    String focus;
    String insight;
    IconData icon;
    Color color;

    switch (phase) {
      case CyclePhase.menstrual:
        title = l10n.menstrualPhase;
        focus = l10n.menstrualFocus;
        insight = l10n.menstrualInsight;
        icon = Icons.water_drop_rounded;
        color = AppColors.userColor;
        break;
      case CyclePhase.follicular:
        title = l10n.follicularPhase;
        focus = l10n.follicularFocus;
        insight = l10n.follicularInsight;
        icon = Icons.spa_rounded;
        color = Colors.teal;
        break;
      case CyclePhase.ovulatory:
        title = l10n.ovulatoryPhase;
        focus = l10n.ovulatoryFocus;
        insight = l10n.ovulatoryInsight;
        icon = Icons.favorite_rounded;
        color = Colors.orangeAccent;
        break;
      case CyclePhase.luteal:
        title = l10n.lutealPhase;
        focus = l10n.lutealFocus;
        insight = l10n.lutealInsight;
        icon = Icons.nightlight_round;
        color = AppColors.cycleColor;
        break;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: color, size: 22.r),
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.currentPhase,
                  style: GoogleFonts.outfit(fontSize: 12.sp, color: AppColors.softBrown),
                ),
                2.verticalSpace,
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warmBrown,
                  ),
                ),
                4.verticalSpace,
                Text(
                  focus,
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    color: AppColors.softBrown,
                    height: 1.3,
                  ),
                ),
                12.verticalSpace,
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: color.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 16.r, color: color),
                      8.horizontalSpace,
                      Expanded(
                        child: Text(
                          insight,
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            color: AppColors.softBrown.withValues(alpha: 0.9),
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Calendar Legend ──────────────────────────────────────────────────────────

class _CalendarLegend extends StatelessWidget {
  final bool hasPartnerData;
  const _CalendarLegend({required this.hasPartnerData});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16.w,
      runSpacing: 8.h,
      children: [
        _LegendDot(color: AppColors.userColor, label: l10n.yourPeriod),
        _LegendDot(color: AppColors.userColor.withValues(alpha: 0.4), label: l10n.nextPeriodLabel),
        _LegendDot(color: Colors.orangeAccent, label: l10n.fertileWindow),
        _LegendDot(color: Colors.green.shade400, label: l10n.safeWindow),
        if (hasPartnerData) _LegendDot(color: AppColors.partnerColor, label: l10n.partnerPeriod),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.r,
          height: 10.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        6.horizontalSpace,
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12.sp, color: AppColors.softBrown),
        ),
      ],
    );
  }
}

// ─── Prediction Card ──────────────────────────────────────────────────────────

class _PredictionCard extends StatelessWidget {
  final DateTime nextPeriod;
  const _PredictionCard({required this.nextPeriod});

  @override
  Widget build(BuildContext context) {
    final daysUntil = nextPeriod.difference(DateTime.now()).inDays;
    final isPast = daysUntil < 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cycleColor.withValues(alpha: 0.1),
            AppColors.userColor.withValues(alpha: 0.07),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.cycleColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.cycleColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(Icons.event_rounded, color: AppColors.cycleColor, size: 22.r),
          ),
          16.horizontalSpace,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.nextPeriodLabel,
                style: GoogleFonts.outfit(fontSize: 12.sp, color: AppColors.softBrown),
              ),
              2.verticalSpace,
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
                AppLocalizations.of(context)!.estimatedBasedOnHistory,
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
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 14.r, color: color),
        ),
        8.horizontalSpace,
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.warmBrown,
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.2), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Inline Section Empty ─────────────────────────────────────────────────────

class _InlineSectionEmpty extends StatelessWidget {
  final String message;
  final VoidCallback? onAdd;
  final String? addLabel;

  const _InlineSectionEmpty({
    required this.message,
    this.onAdd,
    this.addLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.ivoryCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.champagne),
      ),
      child: Row(
        children: [
          Text(
            message,
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              color: AppColors.softBrown,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (onAdd != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onAdd!();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.cycleColor,
                  borderRadius: BorderRadius.circular(50.r),
                ),
                child: Text(
                  addLabel ?? '+ Add',
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌸', style: TextStyle(fontSize: 48.sp)),
            18.verticalSpace,
            Text(
              l10n.noCyclesLogged,
              style: GoogleFonts.outfit(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            ),
            10.verticalSpace,
            Text(
              l10n.trackCycleSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontStyle: FontStyle.italic,
                fontSize: 14.sp,
                color: AppColors.softBrown,
                height: 1.6,
              ),
            ),
            28.verticalSpace,
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onAdd();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.cycleColor,
                  borderRadius: BorderRadius.circular(50.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cycleColor.withValues(alpha: 0.3),
                      blurRadius: 16.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Text(
                  l10n.logFirstCycle,
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
}

// ─── Period Shimmer ───────────────────────────────────────────────────────────

class _PeriodShimmer extends StatelessWidget {
  const _PeriodShimmer();

  @override
  Widget build(BuildContext context) {
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

// ─── Info Bottom Sheet ─────────────────────────────────────────────────────────

class _InfoBottomSheet extends StatelessWidget {
  final AppLocalizations l10n;
  const _InfoBottomSheet({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.champagne,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppColors.cycleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.info_outline_rounded,
                            color: AppColors.cycleColor, size: 20.r),
                      ),
                      12.horizontalSpace,
                      Text(
                        l10n.howItWorksTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warmBrown,
                        ),
                      ),
                    ],
                  ),
                  20.verticalSpace,
                  _InfoSectionTitle(title: l10n.colorsLegendTitle),
                  12.verticalSpace,
                  _ColorRow(color: AppColors.userColor, label: l10n.yourPeriod, description: l10n.yourPeriodDesc),
                  10.verticalSpace,
                  _ColorRow(color: AppColors.partnerColor, label: l10n.partnerPeriod, description: l10n.partnerPeriodDesc),
                  10.verticalSpace,
                  _ColorRow(
                    color: AppColors.userColor.withValues(alpha: 0.35),
                    label: l10n.nextPeriodLabel,
                    description: l10n.predictedPeriodDesc,
                  ),
                  10.verticalSpace,
                  _ColorRow(color: Colors.orangeAccent, label: l10n.fertileWindow, description: l10n.fertileWindowDesc),
                  10.verticalSpace,
                  _ColorRow(color: Colors.green.shade400, label: l10n.safeWindow, description: l10n.safeWindowDesc),
                  20.verticalSpace,
                  const _InfoSectionTitle(title: 'Predictions'),
                  10.verticalSpace,
                  _InfoParagraph(
                    icon: Icons.auto_graph_rounded,
                    color: AppColors.cycleColor,
                    text: l10n.predictionsExplained,
                  ),
                  16.verticalSpace,
                  const _InfoSectionTitle(title: 'Cycle Phases'),
                  10.verticalSpace,
                  _InfoParagraph(
                    icon: Icons.loop_rounded,
                    color: Colors.teal,
                    text: l10n.phasesExplained,
                  ),
                  10.verticalSpace,
                  _PhaseRow(icon: Icons.water_drop_rounded, color: AppColors.userColor, phase: 'Menstrual', days: 'Days 1–5'),
                  6.verticalSpace,
                  _PhaseRow(icon: Icons.spa_rounded, color: Colors.teal, phase: 'Follicular', days: 'Days 6–10'),
                  6.verticalSpace,
                  _PhaseRow(icon: Icons.favorite_rounded, color: Colors.orangeAccent, phase: 'Ovulatory', days: 'Days 11–16'),
                  6.verticalSpace,
                  _PhaseRow(icon: Icons.nightlight_round, color: AppColors.cycleColor, phase: 'Luteal', days: 'Days 17–28'),
                  28.verticalSpace,
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.cycleColor, AppColors.userColor],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      child: Center(
                        child: Text(
                          l10n.gotIt,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Section Title ───────────────────────────────────────────────────────

class _InfoSectionTitle extends StatelessWidget {
  final String title;
  const _InfoSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.softBrown,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Color Row ────────────────────────────────────────────────────────────────

class _ColorRow extends StatelessWidget {
  final Color color;
  final String label;
  final String description;

  const _ColorRow({
    required this.color,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Container(
            width: 12.r,
            height: 12.r,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        10.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warmBrown,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  color: AppColors.softBrown,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Info Paragraph ───────────────────────────────────────────────────────────

class _InfoParagraph extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoParagraph({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.r, color: color),
          10.horizontalSpace,
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: AppColors.softBrown,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Phase Row ────────────────────────────────────────────────────────────────

class _PhaseRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String phase;
  final String days;

  const _PhaseRow({
    required this.icon,
    required this.color,
    required this.phase,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 14.r, color: color),
        ),
        10.horizontalSpace,
        Text(
          phase,
          style: GoogleFonts.outfit(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.warmBrown,
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50.r),
          ),
          child: Text(
            days,
            style: GoogleFonts.outfit(
              fontSize: 11.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Day Cell ─────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final Color? periodColor;
  final bool isFertileWindow;
  final bool isSafeWindow;
  final bool isPredicted;
  final double opacity;

  const _DayCell({
    required this.day,
    required this.isToday,
    this.periodColor,
    this.isFertileWindow = false,
    this.isSafeWindow = false,
    this.isPredicted = false,
    this.opacity = 1.0,
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
              ? (isPredicted
                  ? periodColor!.withValues(alpha: 0.25 * opacity)
                  : periodColor!.withValues(alpha: 0.85 * opacity))
              : isFertileWindow
              ? Colors.orangeAccent.withValues(alpha: 0.15)
              : isSafeWindow
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday && periodColor == null
              ? Border.all(color: AppColors.cycleColor.withValues(alpha: 0.5), width: 1.5)
              : isPredicted
              ? Border.all(
                  color: periodColor!.withValues(alpha: 0.4),
                  width: 1,
                  style: BorderStyle.solid,
                )
              : isFertileWindow && periodColor == null
              ? Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3), width: 1)
              : isSafeWindow && periodColor == null
              ? Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              color: periodColor != null
                  ? (isPredicted ? AppColors.warmBrown : Colors.white)
                  : isToday
                  ? AppColors.cycleColor
                  : isFertileWindow
                  ? Colors.orange.shade300
                  : isSafeWindow
                  ? Colors.green.shade400
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
  final bool isPartnerCard;
  final VoidCallback onTap;
  final Future<bool?> Function() onDelete;

  const _CycleCard({
    required this.cycle,
    required this.isPartnerCard,
    required this.onTap,
    required this.onDelete,
  });

  String _flowLabel(BuildContext context, int l) {
    final l10n = AppLocalizations.of(context)!;
    return l == 1
        ? l10n.lightFlow
        : l == 3
        ? l10n.heavyFlow
        : l10n.mediumFlow;
  }

  String _flowEmoji(int l) => l == 1
      ? '💧'
      : l == 3
      ? '💧💧💧'
      : '💧💧';

  Color get _accentColor => isPartnerCard ? AppColors.partnerColor : AppColors.userColor;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');
    final startStr = fmt.format(cycle.startDate);
    final endStr = cycle.endDate != null ? fmt.format(cycle.endDate!) : 'Ongoing';
    final duration = cycle.endDate != null ? '${cycle.durationDays}d' : '...';
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: Key(cycle.id ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final result = await onDelete();
        return result ?? false;
      },
      background: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.w),
        decoration: BoxDecoration(
          color: AppColors.userColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Icon(Icons.delete_outline_rounded, color: AppColors.userColor, size: 24.r),
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
            border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withValues(alpha: 0.06),
                blurRadius: 12.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14.r, color: _accentColor),
                  6.horizontalSpace,
                  Expanded(
                    child: Text(
                      '$startStr  →  $endStr',
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warmBrown,
                      ),
                    ),
                  ),
                  if (isPartnerCard)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      child: Text(
                        l10n.partnerBadge,
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp,
                          color: _accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (isPartnerCard) 6.horizontalSpace,
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    child: Text(
                      duration,
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        color: _accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  10.horizontalSpace,
                  Icon(Icons.edit_rounded, size: 14.r, color: AppColors.softBrown.withValues(alpha: 0.5)),
                ],
              ),
              10.verticalSpace,
              Row(
                children: [
                  Text(_flowEmoji(cycle.flowLevel), style: const TextStyle(fontSize: 14)),
                  6.horizontalSpace,
                  Text(
                    '${_flowLabel(context, cycle.flowLevel)}${AppLocalizations.of(context)!.flowSuffix}',
                    style: GoogleFonts.outfit(fontSize: 13.sp, color: AppColors.softBrown),
                  ),
                ],
              ),
              if (cycle.symptoms.isNotEmpty) ...[
                8.verticalSpace,
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: cycle.symptoms
                      .take(4)
                      .map(
                        (s) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                          child: Text(
                            s.replaceAll('_', ' '),
                            style: GoogleFonts.outfit(
                              fontSize: 11.sp,
                              color: _accentColor,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (cycle.notes != null && cycle.notes!.isNotEmpty) ...[
                8.verticalSpace,
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
