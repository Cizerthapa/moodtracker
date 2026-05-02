import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:moodtrack/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:moodtrack/core/services/notification_service.dart';
import 'package:moodtrack/core/theme/app_theme.dart';
import 'package:moodtrack/core/theme/theme_manager.dart';
import 'package:moodtrack/core/constants/app_strings.dart';
import 'package:moodtrack/core/services/ui_state_manager.dart';
import 'package:moodtrack/core/widgets/ui_state_wrapper.dart';
import 'package:moodtrack/core/managers/locale_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moodtrack/core/di/service_locator.dart';
import 'package:moodtrack/core/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize DI
  await initServiceLocator();

  // Initialize Notifications
  final notificationService = sl<NotificationService>();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => LocaleManager()),
        ChangeNotifierProvider(create: (_) => sl<UIStateManager>()),
      ],
      child: const MoodTrackApp(),
    ),
  );
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
        return Consumer2<ThemeManager, LocaleManager>(
          builder: (context, themeManager, localeManager, child) {
            return MaterialApp.router(
              title: AppStrings.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.getTheme(themeManager.palette),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: localeManager.locale,
              // UIStateWrapper wraps every page via the builder
              builder: (context, child) => UIStateWrapper(child: child!),
              routerConfig: AppRouter.router,
            );
          },
        );
      },
    );
  }
}
