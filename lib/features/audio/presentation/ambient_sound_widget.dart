import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/features/audio/ambient_sound_service.dart';

class AmbientSoundWidget extends StatefulWidget {
  const AmbientSoundWidget({super.key});

  @override
  State<AmbientSoundWidget> createState() => _AmbientSoundWidgetState();
}

class _AmbientSoundWidgetState extends State<AmbientSoundWidget> {
  final AmbientSoundService _soundService = AmbientSoundService();
  bool _isExpanded = false;

  void _toggleTrack(String trackName) async {
    await _soundService.togglePlay(trackName);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.ivoryCard,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
        border: Border.all(color: AppColors.champagne, width: 1.5),
      ),
      child: _isExpanded
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = false),
                  child: Icon(Icons.close_rounded, color: AppColors.roseDust, size: 24.r),
                ),
                SizedBox(width: 12.w),
                ..._soundService.tracks.keys.map((track) {
                  final isPlaying = _soundService.isPlaying && _soundService.currentTrack == track;
                  return GestureDetector(
                    onTap: () => _toggleTrack(track),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isPlaying ? AppColors.roseDeep : AppColors.champagne.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        track,
                        style: GoogleFonts.outfit(
                          fontSize: 13.sp,
                          color: isPlaying ? Colors.white : AppColors.warmBrown,
                          fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            )
          : GestureDetector(
              onTap: () => setState(() => _isExpanded = true),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _soundService.isPlaying ? Icons.music_note_rounded : Icons.music_off_rounded,
                    color: _soundService.isPlaying ? AppColors.roseDeep : AppColors.softBrown,
                    size: 24.r,
                  ),
                  if (_soundService.isPlaying) ...[
                    SizedBox(width: 8.w),
                    Text(
                      _soundService.currentTrack,
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.roseDeep,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
