import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/features/auth/data/repositories/user_repository.dart';

class TogetherSinceScreen extends StatefulWidget {
  const TogetherSinceScreen({super.key});

  @override
  State<TogetherSinceScreen> createState() => _TogetherSinceScreenState();
}

class _TogetherSinceScreenState extends State<TogetherSinceScreen> {
  DateTime? _startDate;
  bool _isLoading = true;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadDate();
  }

  Future<void> _loadDate() async {
    final profile = await UserRepository().getUserProfile();
    if (profile?.relationshipStartDate != null) {
      _startDate = profile!.relationshipStartDate;
      _startTimer();
    }
    setState(() => _isLoading = false);
  }

  void _startTimer() {
    _timer?.cancel();
    if (_startDate != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _elapsed = DateTime.now().difference(_startDate!);
          });
        }
      });
      _elapsed = DateTime.now().difference(_startDate!);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.roseDeep,
              onPrimary: Colors.white,
              onSurface: AppColors.warmBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _isLoading = true);
      await UserRepository().setRelationshipStartDate(picked);
      _startDate = picked;
      _startTimer();
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.warmBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Together Since",
          style: GoogleFonts.outfit(color: AppColors.warmBrown, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.roseDeep))
          : _startDate == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 60.r, color: AppColors.roseDust.withValues(alpha: 0.5)),
                      SizedBox(height: 16.h),
                      Text("When did the magical journey start?", style: GoogleFonts.outfit(color: AppColors.softBrown, fontSize: 16.sp)),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: _pickDate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.roseDeep,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text("Set Date", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_rounded, color: AppColors.roseDeep, size: 70.r),
                          SizedBox(height: 24.h),
                          Text(
                            "${_elapsed.inDays} Days",
                            style: GoogleFonts.outfit(
                              fontSize: 52.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.warmBrown,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: AppColors.champagne,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              "${_elapsed.inHours % 24} Hours, ${_elapsed.inMinutes % 60} Minutes, ${_elapsed.inSeconds % 60} Seconds",
                              style: GoogleFonts.outfit(fontSize: 16.sp, color: AppColors.softBrown, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 48.h),
                          TextButton(
                            onPressed: _pickDate,
                            child: Text("Change Date", style: TextStyle(color: AppColors.roseDust)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
