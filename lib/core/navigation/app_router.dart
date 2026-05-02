import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtrack/core/navigation/app_routes.dart';
import 'package:moodtrack/features/admin/presentation/pages/admin_panel_screen.dart';
import 'package:moodtrack/features/auth/presentation/pages/login_screen.dart';
import 'package:moodtrack/features/entry/presentation/pages/entry_screen.dart';
import 'package:moodtrack/features/journal/presentation/pages/add_journal_entry_screen.dart';
import 'package:moodtrack/features/journal/presentation/pages/journal_screen.dart';
import 'package:moodtrack/features/memories/domain/model/memories_model.dart';
import 'package:moodtrack/features/memories/presentation/pages/add_memory_screen.dart';
import 'package:moodtrack/features/memories/presentation/pages/memories_screen.dart';
import 'package:moodtrack/features/memories/presentation/pages/memory_detail_screen.dart';
import 'package:moodtrack/features/memories/presentation/pages/together_since_screen.dart';
import 'package:moodtrack/features/notes/presentation/pages/add_note_screen.dart';
import 'package:moodtrack/features/notes/presentation/pages/notes_screen.dart';
import 'package:moodtrack/features/period/presentation/pages/period_tracking_screen.dart';
import 'package:moodtrack/features/settings/presentation/pages/settings_screen.dart';
import 'package:moodtrack/features/splash/presentation/pages/splash_screen.dart';
import 'package:moodtrack/core/di/service_locator.dart';
import 'package:moodtrack/core/error/result.dart';
import 'package:moodtrack/features/memories/data/repositories/memories_repository.dart';
import 'package:moodtrack/features/water_intake/presentation/pages/water_intake_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Only protect the /home subtree; splash and login are always public.
      final isGoingToProtected = state.matchedLocation.startsWith('/home') ||
          state.matchedLocation.startsWith('/admin');
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;

      if (isGoingToProtected && !isLoggedIn) {
        return '/login';
      }
      return null;
    },
    routes: [
      // ── Splash ─────────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        name: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth ───────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Home (Entry) ────────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: AppRoutes.home,
        builder: (context, state) => const EntryScreen(),
        routes: [
          // ── Memories ─────────────────────────────────────────────────────
          GoRoute(
            path: 'memories',
            name: AppRoutes.memories,
            builder: (context, state) => const MemoriesScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: AppRoutes.addMemory,
                pageBuilder: (context, state) => CustomTransitionPage(
                  fullscreenDialog: true,
                  child: const AddMemoryScreen(),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                ),
              ),
              // Deep-link route: /home/memories/:memoryId
              GoRoute(
                path: ':memoryId',
                name: AppRoutes.memoryDetail,
                builder: (context, state) {
                  // Memory passed as 'extra' for in-app navigation,
                  // or load by ID from notification deep links.
                  final memory = state.extra as MemoryModel?;
                  if (memory != null) {
                    return MemoryDetailScreen(memory: memory);
                  }
                  
                  final memoryId = state.pathParameters['memoryId'];
                  if (memoryId == null) {
                    return const Scaffold(
                      body: Center(child: Text('Memory not found')),
                    );
                  }

                  return FutureBuilder<Result<MemoryModel>>(
                    future: sl<MemoriesRepository>().getMemoryById(memoryId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      if (snapshot.hasData && snapshot.data is Success<MemoryModel>) {
                        return MemoryDetailScreen(memory: (snapshot.data as Success<MemoryModel>).data);
                      }
                      
                      return Scaffold(
                        appBar: AppBar(title: const Text('Error')),
                        body: const Center(child: Text('Failed to load memory.')),
                      );
                    },
                  );
                },
              ),
            ],
          ),

          // ── Notes ────────────────────────────────────────────────────────
          GoRoute(
            path: 'notes',
            name: AppRoutes.notes,
            builder: (context, state) => const NotesScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: AppRoutes.addNote,
                pageBuilder: (context, state) {
                  final args = state.extra as Map<String, dynamic>?;
                  final onSave = args?['onSave']
                      as Function(String, String, String, dynamic)?;
                  return CustomTransitionPage(
                    fullscreenDialog: true,
                    child: AddNoteScreen(
                      onSave: onSave ?? (_, __, ___, ____) {},
                      initialTitle: args?['initialTitle'] as String?,
                      initialText: args?['initialText'] as String?,
                      initialEmoji: args?['initialEmoji'] as String?,
                      initialImage: args?['initialImage'] as String?,
                    ),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                  );
                },
              ),
            ],
          ),

          // ── Journal ──────────────────────────────────────────────────────
          GoRoute(
            path: 'journal',
            name: AppRoutes.journal,
            builder: (context, state) => const JournalScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: AppRoutes.addJournal,
                pageBuilder: (context, state) {
                  final args = state.extra as Map<String, dynamic>?;
                  return CustomTransitionPage(
                    fullscreenDialog: true,
                    child: AddJournalEntryScreen(
                      onSave: args?['onSave'] ??
                          (_, __, ___) => Future.value(),
                      moods: args?['moods'] ?? [],
                      initialTitle: args?['initialTitle'],
                      initialText: args?['initialText'],
                      initialMood: args?['initialMood'],
                      isEditing: args?['isEditing'] ?? false,
                    ),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                  );
                },
              ),
            ],
          ),

          // ── Settings ─────────────────────────────────────────────────────
          GoRoute(
            path: 'settings',
            name: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
            routes: [
              // ── Together Since ─────────────────────────────────────────
              GoRoute(
                path: 'together-since',
                name: AppRoutes.togetherSince,
                pageBuilder: (context, state) => CustomTransitionPage(
                  fullscreenDialog: true,
                  child: const TogetherSinceScreen(),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                ),
              ),
            ],
          ),

          // ── Period ───────────────────────────────────────────────────────
          GoRoute(
            path: 'period',
            name: AppRoutes.period,
            pageBuilder: (context, state) => CustomTransitionPage(
              fullscreenDialog: true,
              child: const PeriodTrackingScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          ),
          // ── Water Intake ────────────────────────────────────────────────
          GoRoute(
            path: 'water',
            name: AppRoutes.water,
            pageBuilder: (context, state) => CustomTransitionPage(
              fullscreenDialog: true,
              child: const WaterIntakeScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          ),
        ],
      ),

      // ── Admin ───────────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        name: AppRoutes.admin,
        pageBuilder: (context, state) => CustomTransitionPage(
          fullscreenDialog: true,
          child: const AdminPanelScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
    ],
  );
}
