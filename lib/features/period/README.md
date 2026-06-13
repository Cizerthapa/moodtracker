# period

Menstrual cycle tracker with calendar view and optional partner sharing.

## Screens
| Screen | Purpose |
|--------|---------|
| `PeriodTrackingScreen` | Monthly calendar with logged cycles; tabs for own vs partner view |
| `LogPeriodScreen` | Log or edit a cycle entry — start date, end date, symptoms, notes |

## Domain
- **PeriodCycleModel** — startDate, endDate, symptoms, notes, ownerUid.

## Partner sharing
`PeriodRepository.getPartnerUidStream()` streams the linked partner's UID. When a partner is connected, `PeriodTrackingScreen` shows a second tab with their cycle data (read-only unless they share edit access).

## Repository
- **PeriodRepository** — Firestore CRUD for cycles; `getPartnerUidStream`; activity logging via `ActivityLogService`.
