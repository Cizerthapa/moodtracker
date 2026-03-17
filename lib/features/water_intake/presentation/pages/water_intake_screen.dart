import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/constants/app_strings.dart';
import 'package:moodtrack/core/constants/app_constants.dart';
import 'package:moodtrack/features/water_intake/data/repositories/water_repository.dart';
import 'package:moodtrack/core/widgets/shimmer_loading.dart';

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
        return const Color(0xFF6DAA7A); // Using a more earthy green from Notes screen meta
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

  DrinkEntry({required this.type, required this.amount, required this.timestamp});

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

class _WaterIntakeScreenState extends State<WaterIntakeScreen> with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: AppConstants.fadeTransitionDurationMs),
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
    
    final loadedHistory = historyJson.map((e) => DrinkEntry.fromJson(json.decode(e))).toList();
    
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
    return Scaffold(
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
                    AppStrings.waterIntakeHeader,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTabButton(0, Icons.track_changes_rounded, 'Goal'),
                      const SizedBox(width: 8),
                      _buildTabButton(1, Icons.history_rounded, 'History'),
                      const SizedBox(width: 8),
                      _buildTabButton(2, Icons.bar_chart_rounded, 'Trends'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Divider ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Divider(color: AppColors.roseDust.withOpacity(0.3), thickness: 1),
            ),

            // ── Body ───────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        children: [
                          ShimmerLoading(
                            isLoading: true,
                            child: const ShimmerSkeleton(height: 200, width: 200),
                          ),
                          const SizedBox(height: 48),
                          ShimmerLoading(
                            isLoading: true,
                            child: const ShimmerSkeleton(height: 100),
                          ),
                          const SizedBox(height: 48),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(3, (i) => const ShimmerLoading(
                              isLoading: true,
                              child: ShimmerSkeleton(height: 50, width: 80),
                            )),
                          )
                        ],
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildBody(),
                    ),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.roseDeep : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppColors.roseDeep : AppColors.champagne,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.softBrown),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.softBrown,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_viewIndex) {
      case 0: return _buildTrackView();
      case 1: return _buildHistoryView();
      case 2: return _buildChartView();
      default: return _buildTrackView();
    }
  }

  Widget _buildTrackView() {
    final progress = (_currentIntake / _dailyGoal).clamp(0.0, 1.0);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: AppColors.champagne.withOpacity(0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.roseDeep),
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    AppStrings.today,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      color: AppColors.softBrown,
                    ),
                  ),
                  Text(
                    '$_currentIntake',
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  Text(
                    AppStrings.drinkGoalMilli.replaceFirst('%s', '$_dailyGoal'),
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      color: AppColors.softBrown.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.selectBeverage,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: DrinkType.values.map((type) => _buildTypeChip(type)).toList(),
          ),
          const SizedBox(height: 48),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? type.color.withOpacity(0.15) : AppColors.ivoryCard,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? type.color : AppColors.champagne,
                width: 1.5,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: type.color.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ] : null,
            ),
            child: Icon(type.icon, color: isSelected ? type.color : AppColors.softBrown.withOpacity(0.5), size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            type.label,
            style: TextStyle(
              fontFamily: 'Georgia',
              color: isSelected ? type.color : AppColors.softBrown,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      ),
      onPressed: () => _addDrink(amount),
      child: Text(
        '+$amount ml',
        style: const TextStyle(
          fontFamily: 'Georgia',
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 48, color: AppColors.champagne),
            const SizedBox(height: 16),
            Text(
              AppStrings.noHistory,
              style: TextStyle(fontFamily: 'Georgia', color: AppColors.softBrown, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final entry = _history[index];
        return Dismissible(
          key: Key(entry.timestamp.toIso8601String() + index.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: AppColors.roseDeep.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.roseDeep),
          ),
          onDismissed: (_) => _deleteDrink(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.ivoryCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.champagne),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: entry.type.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(entry.type.icon, color: entry.type.color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.type.label,
                        style: const TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, color: AppColors.warmBrown),
                      ),
                      Text(
                        DateFormat('MMM d · h:mm a').format(entry.timestamp),
                        style: const TextStyle(fontFamily: 'Georgia', color: AppColors.softBrown, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${entry.amount} ml',
                  style: const TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.warmBrown),
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
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.last7Days,
            style: TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.warmBrown),
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
                          const TextStyle(color: Colors.white, fontFamily: 'Georgia', fontWeight: FontWeight.bold),
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
                              style: const TextStyle(color: AppColors.softBrown, fontSize: 11, fontFamily: 'Georgia'),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: dailyTotals[i],
                        color: AppColors.roseDeep,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxIntake,
                          color: AppColors.champagne.withOpacity(0.3),
                        ),
                      ),
                    ],
                  )),
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
