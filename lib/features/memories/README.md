# memories

Shared couple memories — photos, milestones, and a relationship countdown.

## Screens
| Screen | Purpose |
|--------|---------|
| `MemoriesScreen` | Grid/list of all memories with search and shimmer loading |
| `AddMemoryScreen` | Create or edit a memory (title, date, photo, notes) |
| `MemoryDetailScreen` | Full-screen view of a single memory |
| `TogetherSinceScreen` | Displays days/months/years since the relationship start date |

## Domain
- **MemoryModel** — title, description, date, optional image URL, ownerUid.

## Repository
- **MemoriesRepository** — Firestore CRUD for memories; local cache via `getCachedMemories` for offline-first loading.
