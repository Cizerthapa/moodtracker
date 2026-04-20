import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/models/memory_model.dart';

class MemoryCard extends StatefulWidget {
  final MemoryModel memory;
  final int index;
  final VoidCallback onTap;

  const MemoryCard({
    super.key,
    required this.memory,
    required this.index,
    required this.onTap,
  });

  @override
  State<MemoryCard> createState() => MemoryCardState();
}

class MemoryCardState extends State<MemoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnique = widget.memory.isUnique;
    final String title = widget.memory.title;
    final String description = widget.memory.desc;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: isUnique ? const Color(0xFFFFF0EC) : AppColors.ivoryCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnique
                  ? AppColors.roseDeep.withOpacity(0.35)
                  : AppColors.champagne,
              width: isUnique ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnique
                    ? AppColors.roseDeep.withOpacity(0.07)
                    : AppColors.warmBrown.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Icon dot
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isUnique
                        ? AppColors.roseDeep.withOpacity(0.12)
                        : AppColors.champagne,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUnique ? Icons.star_rounded : Icons.favorite_rounded,
                    color: isUnique ? AppColors.roseDeep : AppColors.roseDust,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontStyle: FontStyle.italic,
                          fontSize: 11.sp,
                          color: isUnique
                              ? AppColors.roseDeep
                              : AppColors.softBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warmBrown,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: isUnique ? AppColors.roseDeep : AppColors.roseDust,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
