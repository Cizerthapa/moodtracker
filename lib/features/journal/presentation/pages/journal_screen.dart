import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:moodtrack/models/journal_entry_model.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:moodtrack/core/navigation/app_routes.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/core/theme/theme_manager.dart';
import 'package:moodtrack/core/widgets/shimmer_loading.dart';
import 'package:moodtrack/features/journal/data/repositories/journal_repository.dart';
import 'package:moodtrack/core/di/service_locator.dart';
import 'package:moodtrack/core/error/result.dart';

// Mood metadata matching the original NotesScreen style
List<Map<String, dynamic>> _getJournalMoods(AppLocalizations l10n) => [
  {
    'emoji': '😊',
    'label': l10n.moodHappy,
    'tint': const Color(0xFFFFF8EC),
    'accent': const Color(0xFFD4A832),
  },
  {
    'emoji': '😌',
    'label': l10n.moodPeaceful,
    'tint': const Color(0xFFEEF7F0),
    'accent': const Color(0xFF6DAA7A),
  },
  {
    'emoji': '😐',
    'label': l10n.moodNeutral,
    'tint': const Color(0xFFF5F2ED),
    'accent': const Color(0xFF9C8878),
  },
  {
    'emoji': '😔',
    'label': l10n.moodSad,
    'tint': const Color(0xFFEFF3FA),
    'accent': const Color(0xFF7A8FBB),
  },
  {
    'emoji': '😡',
    'label': l10n.moodUpset,
    'tint': const Color(0xFFFFF0EC),
    'accent': const Color(0xFFC4635A),
  },
  {
    'emoji': '😭',
    'label': l10n.moodCrying,
    'tint': const Color(0xFFEFF3FA),
    'accent': const Color(0xFF6B8CB8),
  },
];

Map<String, dynamic> _moodMeta(String emoji, AppLocalizations l10n) =>
    _getJournalMoods(l10n).firstWhere(
      (m) => m['emoji'] == emoji,
      orElse: () => _getJournalMoods(l10n)[2],
    );

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  final JournalRepository _repository = sl<JournalRepository>();
  bool _isLoading = false;
  bool _encryptionEnabled = false;
  int _selectedTab = 0; // 0 = Entries, 1 = Graph
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadEncryptionSetting();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadEncryptionSetting() async {
    final result = await _repository.getEncryptionEnabled();
    if (result is Success<bool> && mounted) {
      setState(() => _encryptionEnabled = result.data);
    }
  }

  Future<void> _addJournal(String? title, String text, String emoji) async {
    final result = await _repository.addJournal(
      title: title,
      text: text,
      mood: emoji,
      encrypt: _encryptionEnabled,
    );
    if (result is Failure && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text((result).message)));
    }
  }

  Future<void> _deleteJournal(String id) async {
    final result = await _repository.deleteJournal(id);
    if (result is Failure && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text((result).message)));
    }
  }

  void _showAddEntryScreen() {
    context.pushNamed(
      AppRoutes.addJournal,
      extra: <String, dynamic>{
        'onSave': (String? title, String text, String emoji) async {
          await _addJournal(title, text, emoji);
        },
        'moods': _getJournalMoods(AppLocalizations.of(context)!),
        'isEditing': false,
      },
    );
  }

  void _showEditEntryScreen(
    String id,
    String? title,
    String text,
    String emoji,
    bool isEncrypted,
  ) {
    context.pushNamed(
      AppRoutes.addJournal,
      extra: <String, dynamic>{
        'onSave': (String? newTitle, String newText, String newEmoji) async {
          await _repository.updateJournal(
            id,
            title: newTitle,
            text: newText,
            mood: newEmoji,
            encrypt: isEncrypted,
          );
        },
        'moods': _getJournalMoods(AppLocalizations.of(context)!),
        'initialTitle': title,
        'initialText': text,
        'initialMood': emoji,
        'isEditing': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, _) => Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(28.w, 24.h, 24.w, 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.journalHeader,
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
                                Icons.auto_awesome_rounded,
                                size: 12.r,
                                color: AppColors.roseDust,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                AppLocalizations.of(context)!.journalSubHeader,
                                style: GoogleFonts.outfit(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13.sp,
                                  color: AppColors.softBrown,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              if (_encryptionEnabled) ...[
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.roseDeep.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_rounded,
                                        size: 10.r,
                                        color: AppColors.roseDeep,
                                      ),
                                      SizedBox(width: 3.w),
                                      Text(
                                        'Encrypted',
                                        style: GoogleFonts.outfit(
                                          fontSize: 9.sp,
                                          color: AppColors.roseDeep,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showAddEntryScreen();
                      },
                      child: Container(
                        width: 46.r,
                        height: 46.r,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.roseDeep, AppColors.roseDust],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.roseDeep.withValues(alpha: 0.3),
                              blurRadius: 14.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 20.r,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tabs ────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                child: Row(
                  children: [
                    _buildTabButton(0, Icons.list_rounded, 'Entries'),
                    SizedBox(width: 12.w),
                    _buildTabButton(1, Icons.bar_chart_rounded, 'Mood Graph'),
                  ],
                ),
              ),

              // ── Content ──────────────────────────────────────────────
              Expanded(
                child: StreamBuilder<List<JournalEntry>>(
                  stream: _repository.getJournalsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      _isLoading = true;
                      _fadeController.reset();
                      return ListView.builder(
                        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 100.h),
                        itemCount: 4,
                        itemBuilder: (context, i) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: ShimmerLoading(
                            isLoading: true,
                            child: ShimmerSkeleton(
                              height: 120.h,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                        ),
                      );
                    }

                    if (_isLoading) {
                      _isLoading = false;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _fadeController.forward();
                      });
                    }

                    final docs = snapshot.data!;
                    if (docs.isEmpty) {
                      return _JournalEmptyState(onAdd: _showAddEntryScreen);
                    }

                    return FadeTransition(
                      opacity: _fadeAnim,
                      child: _selectedTab == 0
                          ? _buildEntriesList(docs)
                          : _buildMoodGraph(docs),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        if (_selectedTab != index) {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
          _fadeController.forward(from: 0.0);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.roseDeep : Colors.transparent,
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16.r,
              color: isSelected ? Colors.white : AppColors.softBrown,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : AppColors.softBrown,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList(List<JournalEntry> docs) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 100.h),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final l10n = AppLocalizations.of(context)!;
        final doc = docs[index];
        final decryptedText = _repository.decryptIfNeeded({'text': doc.text, 'encrypted': doc.encrypted});
        final decryptedTitle = _repository.decryptIfNeeded({'title': doc.title, 'encrypted': doc.encrypted}, isTitle: true);
        final emoji = doc.mood.isEmpty ? '😐' : doc.mood;
        final meta = _moodMeta(emoji, l10n);
        final ts = doc.timestamp;
        final date = ts ?? DateTime.now();
        final formattedDate = DateFormat('MMM d · h:mm a').format(date);

        return _JournalEntryCard(
          id: doc.id,
          title: decryptedTitle,
          text: decryptedText,
          emoji: emoji,
          moodMeta: meta,
          formattedDate: formattedDate,
          isEncrypted: doc.encrypted,
          onDelete: () => _deleteJournal(doc.id),
          onTap: () => _showEditEntryScreen(
            doc.id,
            decryptedTitle,
            decryptedText,
            emoji,
            doc.encrypted,
          ),
        );
      },
    );
  }

  Widget _buildMoodGraph(List<JournalEntry> docs) {
    // Map moods to a score 1 to 6
    int moodScore(String emoji) {
      switch (emoji) {
        case '😭':
          return 1;
        case '😡':
          return 2;
        case '😔':
          return 3;
        case '😐':
          return 4;
        case '😌':
          return 5;
        case '😊':
          return 6;
        default:
          return 4;
      }
    }

    // Filter to current month
    final now = DateTime.now();
    final spots = <FlSpot>[];
    for (final doc in docs) {
      final ts = doc.timestamp;
      if (ts == null) continue;
      final date = ts;
      if (date.year == now.year && date.month == now.month) {
        final emoji = doc.mood.isEmpty ? '😐' : doc.mood;
        spots.add(FlSpot(date.day.toDouble(), moodScore(emoji).toDouble()));
      }
    }

    // Sort spots by day
    spots.sort((a, b) => a.x.compareTo(b.x));

    if (spots.isEmpty) {
      return Center(
        child: Text(
          'No entries this month to generate a graph.',
          style: GoogleFonts.outfit(color: AppColors.softBrown),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 100.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Mood Flow',
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.warmBrown,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            DateFormat('MMMM yyyy').format(now),
            style: GoogleFonts.outfit(
              color: AppColors.softBrown,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 30.h),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.roseDust.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: GoogleFonts.outfit(
                              color: AppColors.softBrown,
                              fontSize: 11.sp,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        String e = '';
                        switch (value.toInt()) {
                          case 1:
                            e = '😭';
                            break;
                          case 2:
                            e = '😡';
                            break;
                          case 3:
                            e = '😔';
                            break;
                          case 4:
                            e = '😐';
                            break;
                          case 5:
                            e = '😌';
                            break;
                          case 6:
                            e = '😊';
                            break;
                        }
                        if (e.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(e, style: TextStyle(fontSize: 16.sp)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 1,
                maxX: 31,
                minY: 0.5,
                maxY: 6.5,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.roseDeep,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.roseDeep,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.roseDeep.withValues(alpha: 0.1),
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

// ─── Journal Entry Card ────────────────────────────────────────────────────────

class _JournalEntryCard extends StatelessWidget {
  final String id;
  final String? title;
  final String text;
  final String emoji;
  final Map<String, dynamic> moodMeta;
  final String formattedDate;
  final bool isEncrypted;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _JournalEntryCard({
    required this.id,
    this.title,
    required this.text,
    required this.emoji,
    required this.moodMeta,
    required this.formattedDate,
    required this.isEncrypted,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = moodMeta['tint'] as Color;
    final accent = moodMeta['accent'] as Color;
    final label = moodMeta['label'] as String;

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
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
                  'Delete Entry?',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warmBrown,
                  ),
                ),
                content: Text(
                  'This journal entry will be deleted permanently.',
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
      onDismissed: (_) => onDelete(),
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
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: accent.withValues(alpha: 0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.06),
                blurRadius: 12.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(18.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          formattedDate,
                          style: GoogleFonts.outfit(
                            fontStyle: FontStyle.italic,
                            fontSize: 11.sp,
                            color: AppColors.softBrown,
                          ),
                        ),
                        if (isEncrypted) ...[
                          SizedBox(width: 6.w),
                          Icon(
                            Icons.lock_rounded,
                            size: 10.r,
                            color: AppColors.roseDust.withValues(alpha: 0.6),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50.r),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: TextStyle(fontSize: 14.sp)),
                          SizedBox(width: 5.w),
                          Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontSize: 11.sp,
                              color: accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (title != null && title!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    title!,
                    style: GoogleFonts.outfit(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],
                SizedBox(height: title == null ? 12.h : 0),
                Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    color: AppColors.warmBrown.withValues(alpha: 0.8),
                    height: 1.55,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _JournalEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _JournalEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📖', style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 18.h),
            Text(
              AppLocalizations.of(context)!.journalEmptyTitle,
              style: GoogleFonts.outfit(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              AppLocalizations.of(context)!.journalEmptySubtitle,
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
              onTap: onAdd,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.roseDeep,
                  borderRadius: BorderRadius.circular(50.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.roseDeep.withValues(alpha: 0.3),
                      blurRadius: 16.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Text(
                  AppLocalizations.of(context)!.writeANoteButton,
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
