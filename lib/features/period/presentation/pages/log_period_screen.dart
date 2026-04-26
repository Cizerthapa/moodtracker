import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/features/period/domain/model/period_cycle_model.dart';

const Color _kCycleColor = Color(0xFF9B7EC8);
const Color _kPeriodColor = Color(0xFFE8789A);

const List<Map<String, String>> _kSymptoms = [
  {'key': 'cramps', 'label': 'Cramps', 'emoji': '😣'},
  {'key': 'bloating', 'label': 'Bloating', 'emoji': '😮'},
  {'key': 'headache', 'label': 'Headache', 'emoji': '🤕'},
  {'key': 'fatigue', 'label': 'Fatigue', 'emoji': '😴'},
  {'key': 'mood_swings', 'label': 'Mood Swings', 'emoji': '😤'},
  {'key': 'back_pain', 'label': 'Back Pain', 'emoji': '😬'},
  {'key': 'nausea', 'label': 'Nausea', 'emoji': '🤢'},
  {'key': 'spotting', 'label': 'Spotting', 'emoji': '💧'},
];

class LogPeriodScreen extends StatefulWidget {
  final PeriodCycle? existingCycle;
  final Future<void> Function(PeriodCycle cycle) onSave;

  const LogPeriodScreen({
    super.key,
    this.existingCycle,
    required this.onSave,
  });

  @override
  State<LogPeriodScreen> createState() => _LogPeriodScreenState();
}

class _LogPeriodScreenState extends State<LogPeriodScreen> {
  late DateTime _startDate;
  DateTime? _endDate;
  late int _flowLevel;
  late List<String> _selectedSymptoms;
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.existingCycle != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingCycle;
    _startDate = c?.startDate ?? DateTime.now();
    _endDate = c?.endDate;
    _flowLevel = c?.flowLevel ?? 2;
    _selectedSymptoms = List<String>.from(c?.symptoms ?? []);
    _notesCtrl.text = c?.notes ?? '';
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    HapticFeedback.lightImpact();
    final initial = isStart ? _startDate : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kCycleColor),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final notes = _notesCtrl.text.trim();
      final cycle = PeriodCycle(
        id: widget.existingCycle?.id,
        startDate: _startDate,
        endDate: _endDate,
        symptoms: List<String>.from(_selectedSymptoms),
        flowLevel: _flowLevel,
        notes: notes.isEmpty ? null : notes,
        ownerUid: uid,
      );
      await widget.onSave(cycle);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Dates'),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: _DateTile(
                            label: 'Start',
                            date: _startDate,
                            onTap: () => _pickDate(isStart: true),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _DateTile(
                            label: 'End (optional)',
                            date: _endDate,
                            onTap: () => _pickDate(isStart: false),
                            onClear: _endDate != null
                                ? () => setState(() => _endDate = null)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    _sectionLabel('Flow Level'),
                    SizedBox(height: 10.h),
                    _buildFlowSelector(),
                    SizedBox(height: 24.h),
                    _sectionLabel('Symptoms'),
                    SizedBox(height: 10.h),
                    _buildSymptomChips(),
                    SizedBox(height: 24.h),
                    _sectionLabel('Notes (optional)'),
                    SizedBox(height: 10.h),
                    _buildNotesField(),
                    SizedBox(height: 32.h),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.ivoryCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.champagne),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 20.r,
                color: AppColors.warmBrown,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            _isEditing ? 'Edit Cycle' : 'Log Period',
            style: GoogleFonts.outfit(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.warmBrown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.warmBrown,
        ),
      );

  Widget _buildFlowSelector() {
    const labels = {1: 'Light', 2: 'Medium', 3: 'Heavy'};
    const emojis = {1: '💧', 2: '💧💧', 3: '💧💧💧'};

    return Row(
      children: [1, 2, 3].map((level) {
        final isSelected = _flowLevel == level;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _flowLevel = level);
            },
            child: Container(
              margin: EdgeInsets.only(right: level < 3 ? 8.w : 0),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: isSelected ? _kCycleColor : AppColors.ivoryCard,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isSelected ? _kCycleColor : AppColors.champagne,
                ),
              ),
              child: Column(
                children: [
                  Text(emojis[level]!, style: const TextStyle(fontSize: 14)),
                  SizedBox(height: 4.h),
                  Text(
                    labels[level]!,
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      color: isSelected ? Colors.white : AppColors.softBrown,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSymptomChips() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _kSymptoms.map((s) {
        final key = s['key']!;
        final isSelected = _selectedSymptoms.contains(key);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isSelected) {
                _selectedSymptoms.remove(key);
              } else {
                _selectedSymptoms.add(key);
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? _kCycleColor.withValues(alpha: 0.13)
                  : AppColors.ivoryCard,
              borderRadius: BorderRadius.circular(50.r),
              border: Border.all(
                color: isSelected ? _kCycleColor : AppColors.champagne,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s['emoji']!, style: const TextStyle(fontSize: 14)),
                SizedBox(width: 5.w),
                Text(
                  s['label']!,
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    color: isSelected ? _kCycleColor : AppColors.softBrown,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ivoryCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.champagne),
      ),
      child: TextField(
        controller: _notesCtrl,
        maxLines: 4,
        style: GoogleFonts.outfit(fontSize: 14.sp, color: AppColors.warmBrown),
        decoration: InputDecoration(
          hintText: 'Any notes about this cycle...',
          hintStyle: GoogleFonts.outfit(
            color: AppColors.softBrown.withValues(alpha: 0.6),
            fontSize: 14.sp,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16.r),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _save,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kCycleColor, _kPeriodColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50.r),
          boxShadow: [
            BoxShadow(
              color: _kCycleColor.withValues(alpha: 0.3),
              blurRadius: 16.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _isEditing ? 'Update Cycle' : 'Save Cycle',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Date Tile ────────────────────────────────────────────────────────────────

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.ivoryCard,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: hasDate
                ? const Color(0xFF9B7EC8).withValues(alpha: 0.4)
                : AppColors.champagne,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    color: AppColors.softBrown,
                  ),
                ),
                if (onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(
                      Icons.close_rounded,
                      size: 14.r,
                      color: AppColors.softBrown,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              hasDate
                  ? DateFormat('MMM d, yyyy').format(date!)
                  : 'Tap to set',
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: hasDate ? FontWeight.w700 : FontWeight.w400,
                color: hasDate ? AppColors.warmBrown : AppColors.softBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
