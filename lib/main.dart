import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:moodtrack/core/services/notification_service.dart';
import 'package:moodtrack/core/theme/app_theme.dart';
import 'package:moodtrack/core/constants/app_strings.dart';
import 'package:moodtrack/core/widgets/auth_wrapper.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();
  
  runApp(const MoodTrackApp());
}

class MoodTrackApp extends StatelessWidget {
  const MoodTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

