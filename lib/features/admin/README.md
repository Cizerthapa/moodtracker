# admin

Developer / admin panel for monitoring app usage and managing content.

## Access
Only visible to users flagged as admins (checked via `AdminRepository`). The link appears at the bottom of `SettingsScreen`.

## Screen
**AdminPanelScreen** uses a 6-tab `TabBar`:

| Tab | Content |
|-----|---------|
| Stats | Aggregate counts — users, notes, journal entries, memories, water logs, period cycles |
| Users | List of all user profiles with last-seen timestamps |
| Notes | All notes across users |
| Journal | All journal entries across users |
| Memories | All shared memories |
| Logs | Activity log stream from `ActivityLogService` |

## Repository
- **AdminRepository** — reads Firestore collections with admin-level access; `getStats()` returns a `Map<String, int>` of counts.

## Visual theme
Uses a dark GitHub-inspired palette (`#0D1117` background, `#161B22` cards) to visually distinguish the admin panel from the user-facing app.
