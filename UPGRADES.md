# Project Roadmap

This document outlines planned technical improvements and feature ideas for future development.

---

## Technical Improvements

### 1. Local Cache (Offline Mode)
Right now, connectivity is monitored, but the app has limited functionality when offline. The plan is to integrate **Hive** or **Isar** to cache Firestore data locally. This would allow the app to work fully offline and automatically sync when the connection is restored.

### 2. Full Localization (Multi-language Support)
All hardcoded strings should be moved into `.arb` files. This is a requirement for App Store distribution and is essential for reaching a global audience.

### 3. Repository Unit Tests
Since the project uses the `Result` pattern and `GetIt`, unit tests can be written to mock the database layer. This ensures that changes to the Repository do not unintentionally break the user interface.

### 4. Custom App Navigation System
Replace standard `Navigator.push` calls with a typed routing system such as **go_router**. This enables deep link support — for example, opening a specific memory directly from a notification.

---

## Feature Ideas

### 1. AI Mood Insights (Gemini Integration)
Use a small AI model to analyze journal entries and generate a **Weekly Sentiment Summary**, along with suggestions for improving mood based on patterns in the entries.

### 2. Voice Journaling
Add a record button to the `AddNoteScreen` that uses speech-to-text, allowing users to speak their thoughts instead of typing them.

### 3. Memory Map and Mood Heatmap
A visual map showing the geographic locations where memories were created, combined with a **Mood Heatmap Calendar** that highlights which days had the most positive entries.

### 4. Collaborative Shared Journal
Allow two users — for example, a couple — to link their accounts and maintain a shared **"Our Memories"** feed alongside their individual private journals.

### 5. Export to PDF
Let users export a journal or a month of entries into a formatted PDF file, usable as a digital scrapbook.

### 6. Daily Flashback Notifications
Send a push notification that says something like: *"One year ago today, you added this memory..."* — encouraging users to revisit and reflect on past moments.

---

*This roadmap will be updated as priorities are confirmed and development continues.*

------------------------------------  Next 

# MoodTrack — Fix Checklist

> All items from the May 2026 audit. Work through top to bottom.

---

## 🔴 High Priority

- [ ] **#3 Period cycles — delete from UI**
  Wrap history list items in `Dismissible`. Wire `onDismissed` to `_periodRepo.deleteCycle(cycle.id)`. Note: `_confirmDelete()` already exists in the screen, just connect it.

- [ ] **#1 Notes — add edit/update**
  Make `_NoteCard` tappable. On tap, push `AddNoteScreen` in edit mode with existing note data. Pass the same `id` to `saveNote()` — `insertOnConflictUpdate` in Drift handles the rest.

- [ ] **#4 User profile — delete account**
  Add `deleteAccount()` to `UserRepository`. It should delete all Firestore sub-collections (`memories`, `journals`, `periods`, `notes`), the user document, then call `FirebaseAuth.deleteUser()`. Add a "Delete Account" tile in Settings with a confirmation dialog.

- [ ] **#5 User profile — unlink partner**
  Add `unlinkPartner()` to `UserRepository`. Use a batch write to clear `partnerUid` and `partnerEmail` from both the current user and the partner (mutual unlink). In Settings, replace the static "Link Partner" tile with a `StreamBuilder` that switches between link and unlink based on `partnerUid`.

---

## 🟠 Medium Priority

- [ ] **#2 Water intake — add edit operation**
  Add `updateDrink(int index, String newEntryJson)` to `WaterRepository`. Update the entry at the given index in SharedPreferences. In the UI, long-press or tap a water entry to open a pre-filled edit bottom sheet.

- [ ] **#6 Settings — configurable daily water goal**
  Add `getWaterGoal()` and `setWaterGoal(int ml)` to `WaterRepository` using SharedPreferences (key: `water_daily_goal`, fallback: `AppConstants.defaultDailyWaterGoal`). Add a "Daily Water Goal" tile in Settings.

- [ ] **#7 Journal stream — return typed model**
  Change `getJournalsStream()` return type from `Stream<QuerySnapshot>` to `Stream<List<JournalEntry>>`. Map using `JournalEntry.fromFirestore` inside the stream. This ensures `.decryptIfNeeded()` is always applied consistently.

- [ ] **#8 Notes screen — replace polling with reactive stream**
  Remove `_loadNotes()` and `setState` calls. Replace with a `StreamBuilder` using `sl<AppDatabase>().watchAllNotes()`, which is already available in Drift.

- [ ] **#10 Memories stream — filter soft-deleted records**
  In `getMemoriesStream()`, add `.where('deletedAt', isNull: true)` before `.orderBy(...)`. One line change — Firestore handles missing fields correctly as null.

---

## 🟡 Low Priority

- [ ] **#9 Navigation — replace `Navigator.pop()` with `context.pop()`**
  Audit all screens for `Navigator.pop(context)` calls and replace with `context.pop()` from go_router to avoid navigation stack conflicts.

- [ ] **#11 Ambient sound — auto-resume on app foreground**
  Add a `WidgetsBindingObserver` to the app. On `AppLifecycleState.resumed`, check if `isPlaying` was true before backgrounding and call `togglePlay(currentTrack)` to restore audio.

- [ ] **#12 `AdminRepository` — inject Firestore dependency**
  Replace the hardcoded `FirebaseFirestore.instance` with an injected dependency via the constructor (with `sl<FirebaseFirestore>()` as fallback). Consistent with every other repository.

- [ ] **#13 Water drink history — migrate to Drift table**
  Replace the `List<String>` of JSON-encoded maps in SharedPreferences with a proper `DrinkEntries` Drift table. Eliminates silent parse failures and aligns with the existing database setup used for notes and journals.