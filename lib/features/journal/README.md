# journal

Mood-tagged journal with optional end-to-end encryption and a monthly mood graph.

## Screens
| Screen | Purpose |
|--------|---------|
| `JournalScreen` | Lists all entries; tab-switches to a monthly mood line-chart |
| `AddJournalEntryScreen` | Compose or edit an entry — title (optional), body text, mood emoji picker |

## Mood scale
😊 Happy · 😌 Peaceful · 😐 Neutral · 😔 Sad · 😡 Upset · 😭 Crying

## Encryption
When the user enables journal encryption in Settings, new and edited entries are stored encrypted. The lock icon badge appears in the header and on individual cards. `JournalRepository.decryptIfNeeded` handles transparent decryption at read time.

## Repository
- **JournalRepository** — Firestore stream-based CRUD (`getJournalsStream`, `addJournal`, `updateJournal`, `deleteJournal`); `getEncryptionEnabled` / toggle; `decryptIfNeeded`.
