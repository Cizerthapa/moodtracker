import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodtrack/features/auth/data/repositories/user_repository.dart';
import 'package:moodtrack/features/memories/data/repositories/memories_repository.dart';
import 'package:moodtrack/features/audio/ambient_sound_service.dart';
import 'package:moodtrack/features/settings/data/repositories/settings_repository.dart';
import 'package:moodtrack/features/water_intake/data/repositories/water_repository.dart';
import 'package:moodtrack/features/notes/data/repositories/notes_repository.dart';
import 'package:moodtrack/core/services/encryption_service.dart';
import 'package:moodtrack/core/services/fcm_service.dart';
import 'package:moodtrack/core/services/notification_service.dart';

import 'package:moodtrack/features/journal/data/repositories/journal_repository.dart';
import 'package:moodtrack/features/admin/data/repositories/admin_repository.dart';
import 'package:moodtrack/core/services/storage_service.dart';
import 'package:moodtrack/core/services/ui_state_manager.dart';
import 'package:moodtrack/core/database/local_database.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // ── Database ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => AppDatabase());
  // ── Firebase ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);

  // ── Services ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => EncryptionService());
  sl.registerLazySingleton(() => FcmService());
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => AmbientSoundService());
  sl.registerLazySingleton(() => StorageService());
  sl.registerLazySingleton(() => UIStateManager());

  // ── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => UserRepository());
  sl.registerLazySingleton(() => MemoriesRepository());
  sl.registerLazySingleton(() => SettingsRepository());
  sl.registerLazySingleton(() => WaterRepository());
  sl.registerLazySingleton(() => NotesRepository());
  sl.registerLazySingleton(() => JournalRepository());
  sl.registerLazySingleton(() => AdminRepository());
}
