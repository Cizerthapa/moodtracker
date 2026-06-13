# notes

Mood-tagged notes with image attachments and a writing-streak tracker.

## Screens
| Screen | Purpose |
|--------|---------|
| `NotesScreen` | Mood-filtered list of notes; shows streak card at the top |
| `AddNoteScreen` | Compose or edit a note — title, body, mood picker, optional image |

## Mood tags
😊 Happy · 😌 Peaceful · 😐 Neutral · 😔 Sad · 😡 Upset · 😭 Crying

## Streak
`StreakService` tracks consecutive days with at least one note. The `StreakCard` widget displays the current streak on the notes list.

## Dependencies
- **NotesRepository** — Firestore + local SQLite (`LocalDatabase`) hybrid; syncs notes and images.
- **NoteImageService** — handles picking, uploading, and deleting note images via `StorageService`.
- **ActivityLogService** — logs note create/edit/delete events for the admin panel.
