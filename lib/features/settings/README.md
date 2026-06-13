# settings

User preferences, account management, and app configuration.

## Screen
**SettingsScreen** is organised into sections:

| Section | Options |
|---------|---------|
| Profile | Display name, avatar |
| Notifications | Toggle daily reminder; schedule time |
| Privacy | Journal encryption toggle; biometric lock toggle |
| Hydration | Daily water goal (ml) |
| Appearance | Theme (light / dark / system); language picker (en, ne, zh, ja) |
| Account | Sign out; delete account |
| Admin | Visible only to admin users — navigates to `AdminPanelScreen` |

## Repository
- **SettingsRepository** — reads/writes all preference keys to local shared preferences; exposes typed getters/setters for each setting.

## Dependencies
Uses `NotificationService`, `JournalRepository` (encryption flag), `WaterRepository` (goal), `LocaleManager` (language), `ThemeManager` (appearance), `AuthRepository` (sign-out / delete), and `ActivityLogService` (audit trail).
