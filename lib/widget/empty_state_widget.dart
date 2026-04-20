import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moodtrack/core/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const EmptyState({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 52.sp,
              color: AppColors.roseDust.withOpacity(0.5),
            ),
            SizedBox(height: 18.h),
            Text(
              'No memories yet',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Every adventure starts with a first step.\nAdd your first memory together.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                fontSize: 14.sp,
                color: AppColors.softBrown,
                height: 1.6.h,
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
                      color: AppColors.roseDeep.withOpacity(0.3),
                      blurRadius: 16.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Text(
                  'Add a Memory',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
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
