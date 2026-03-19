import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/theme/theme_manager.dart';
import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/features/water_intake/data/repositories/water_repository.dart';
import 'package:moodtrack/core/widgets/shimmer_loading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum DrinkType {
  water,
  coffee,
  juice,
  tea;

  String get label => name[0].toUpperCase() + name.substring(1);
  IconData get icon {
    switch (this) {
      case DrinkType.water:
        return Icons.water_drop_rounded;
      case DrinkType.coffee:
        return Icons.coffee_rounded;
      case DrinkType.juice:
        return Icons.local_drink_rounded;
      case DrinkType.tea:
        return Icons.emoji_food_beverage_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DrinkType.water:
        return const Color(
          0xFF6DAA7A,
        ); // Using a more earthy green from Notes screen meta
      case DrinkType.coffee:
        return AppColors.warmBrown;
      case DrinkType.juice:
        return const Color(0xFFD4A832); // Using a warm gold
      case DrinkType.tea:
        return AppColors.roseDeep;
    }
  }
}

class DrinkEntry {
  final DrinkType type;
  final int amount;
  final DateTime timestamp;

  DrinkEntry({
    required this.type,
    required this.amount,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DrinkEntry.fromJson(Map<String, dynamic> json) => DrinkEntry(
    type: DrinkType.values.firstWhere((e) => e.name == json['type']),
    amount: json['amount'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class WaterIntakeScreen extends StatefulWidget {
  const WaterIntakeScreen({super.key});

  @override
  State<WaterIntakeScreen> createState() => _WaterIntakeScreenState();
}

class _WaterIntakeScreenState extends State<WaterIntakeScreen>
    with SingleTickerProviderStateMixin {
  final WaterRepository _repository = WaterRepository();
  int _currentIntake = 0;
  final int _dailyGoal = AppConstants.defaultDailyWaterGoal;
  List<DrinkEntry> _history = [];
  DrinkType _selectedType = DrinkType.water;
  bool _isLoading = true;
  int _viewIndex = 0; // 0: Track, 1: History, 2: Chart
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: AppConstants.fadeTransitionDurationMs,
      ),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final historyJson = await _repository.getDrinkHistoryStrings();

    final loadedHistory = historyJson
        .map((e) => DrinkEntry.fromJson(json.decode(e)))
        .toList();

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayIntake = loadedHistory
        .where((e) => DateFormat('yyyy-MM-dd').format(e.timestamp) == today)
        .fold(0, (sum, e) => sum + e.amount);

    if (mounted) {
      setState(() {
        _history = loadedHistory.reversed.toList();
        _currentIntake = todayIntake;
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  Future<void> _addDrink(int amount) async {
    final entry = DrinkEntry(
      type: _selectedType,
      amount: amount,
      timestamp: DateTime.now(),
    );

    await _repository.addDrink(json.encode(entry.toJson()));
    await _loadData();
  }

  Future<void> _deleteDrink(int index) async {
    final historyJson = await _repository.getDrinkHistoryStrings();
    final originalIndex = historyJson.length - 1 - index;

    await _repository.deleteDrink(originalIndex);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, _) => Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.waterIntakeHeader,
                      style: GoogleFonts.outfit(
                        fontSize: 34.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warmBrown,
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        _buildTabButton(0, Icons.track_changes_rounded, 'Goal'),
                        SizedBox(width: 8.w),
                        _buildTabButton(1, Icons.history_rounded, 'History'),
                        SizedBox(width: 8.w),
                        _buildTabButton(2, Icons.bar_chart_rounded, 'Trends'),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Divider ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Divider(
                  color: AppColors.roseDust.withValues(alpha: 0.3),
                  thickness: 1,
                ),
              ),

              // ── Body ───────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? Padding(
                        padding: EdgeInsets.all(28.0.r),
                        child: Column(
                          children: [
                            ShimmerLoading(
                              isLoading: true,
                              child: ShimmerSkeleton(
                                height: 200.r,
                                width: 200.r,
                              ),
                            ),
                            SizedBox(height: 48.h),
                            ShimmerLoading(
                              isLoading: true,
                              child: ShimmerSkeleton(height: 100.h),
                            ),
                            SizedBox(height: 48.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                3,
                                (i) => ShimmerLoading(
                                  isLoading: true,
                                  child: ShimmerSkeleton(
                                    height: 50.h,
                                    width: 80.w,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : FadeTransition(opacity: _fadeAnim, child: _buildBody()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _viewIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _viewIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.roseDeep : Colors.transparent,
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(
            color: isSelected ? AppColors.roseDeep : AppColors.champagne,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: isSelected ? Colors.white : AppColors.softBrown,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: isSelected ? Colors.white : AppColors.softBrown,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_viewIndex) {
      case 0:
        return _buildTrackView();
      case 1:
        return _buildHistoryView();
      case 2:
        return _buildChartView();
      default:
        return _buildTrackView();
    }
  }

  Widget _buildTrackView() {
    final progress = (_currentIntake / _dailyGoal).clamp(0.0, 1.0);
    return SingleChildScrollView(
      padding: EdgeInsets.all(28.r),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: SizedBox(
                  width: 200.r,
                  height: 200.r,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12.r,
                    backgroundColor: AppColors.champagne.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.roseDeep,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.today,
                    style: GoogleFonts.outfit(
                      fontStyle: FontStyle.italic,
                      color: AppColors.softBrown,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    '$_currentIntake',
                    style: GoogleFonts.outfit(
                      fontSize: 48.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.drinkGoalMilli(_dailyGoal.toString()),
                    style: GoogleFonts.outfit(
                      color: AppColors.softBrown.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 48.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppLocalizations.of(context)!.selectBeverage,
              style: GoogleFonts.outfit(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.warmBrown,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: DrinkType.values
                .map((type) => _buildTypeChip(type))
                .toList(),
          ),
          SizedBox(height: 48.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAddButton(150),
              _buildAddButton(250),
              _buildAddButton(500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(DrinkType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isSelected
                  ? type.color.withValues(alpha: 0.15)
                  : AppColors.ivoryCard,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? type.color : AppColors.champagne,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: type.color.withValues(alpha: 0.2),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              type.icon,
              color: isSelected
                  ? type.color
                  : AppColors.softBrown.withValues(alpha: 0.5),
              size: 28.r,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            type.label,
            style: GoogleFonts.outfit(
              color: isSelected ? type.color : AppColors.softBrown,
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(int amount) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedType.color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
      ),
      onPressed: () => _addDrink(amount),
      child: Text(
        '+$amount ml',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15.sp),
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 48.r, color: AppColors.champagne),
            SizedBox(height: 16.h),
            Text(
              AppLocalizations.of(context)!.noHistory,
              style: GoogleFonts.outfit(
                color: AppColors.softBrown,
                fontStyle: FontStyle.italic,
                fontSize: 14.sp,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final entry = _history[index];
        return Dismissible(
          key: Key(entry.timestamp.toIso8601String() + index.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 24.w),
            decoration: BoxDecoration(
              color: AppColors.roseDeep.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.roseDeep,
              size: 24.r,
            ),
          ),
          confirmDismiss: (direction) async {
            HapticFeedback.mediumImpact();
            return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.ivoryCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    title: Text(
                      'Remove Entry?',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: AppColors.warmBrown,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to remove this drink entry?',
                      style: GoogleFonts.outfit(
                        color: AppColors.softBrown,
                        fontSize: 14.sp,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.outfit(color: AppColors.softBrown),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.outfit(
                            color: AppColors.roseDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) => _deleteDrink(index),
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: AppColors.ivoryCard,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.champagne),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: entry.type.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    entry.type.icon,
                    color: entry.type.color,
                    size: 20.r,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.type.label,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: AppColors.warmBrown,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d · h:mm a').format(entry.timestamp),
                        style: GoogleFonts.outfit(
                          color: AppColors.softBrown,
                          fontSize: 11.sp,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${entry.amount} ml',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                    color: AppColors.warmBrown,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartView() {
    final now = DateTime.now();
    final List<double> dailyTotals = List.filled(7, 0.0);
    final List<String> days = [];
    double maxIntake = 3000.0;

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      days.add(DateFormat('E').format(date));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final total = _history
          .where((e) => DateFormat('yyyy-MM-dd').format(e.timestamp) == dateStr)
          .fold(0, (sum, e) => sum + e.amount);
      dailyTotals[i] = total.toDouble();
      if (dailyTotals[i] > maxIntake) maxIntake = dailyTotals[i] + 500;
    }

    return Padding(
      padding: EdgeInsets.all(28.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.last7Days,
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.warmBrown,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: RepaintBoundary(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxIntake,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.warmBrown,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()} ml',
                          GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: GoogleFonts.outfit(
                                color: AppColors.softBrown,
                                fontSize: 11.sp,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    7,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: dailyTotals[i],
                          color: AppColors.roseDeep,
                          width: 18.w,
                          borderRadius: BorderRadius.circular(6.r),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxIntake,
                            color: AppColors.champagne.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
