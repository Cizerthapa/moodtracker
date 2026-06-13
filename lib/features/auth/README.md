# auth

Handles user authentication via Firebase.

## Screens
- **LoginScreen** — combined login/signup form with animated entry, toggle between modes, and forgot-password bottom sheet.

## Repositories
- **AuthRepository** — `signIn`, `signUp`, `sendPasswordResetEmail`, sign-out wrappers around `firebase_auth`.
- **UserRepository** — `updateLastSeen`, `refreshFcmToken`, and user profile reads/writes in Firestore.

## Flow
1. `SplashScreen` routes here if no authenticated user is detected.
2. On successful auth, navigates to `AppRoutes.home` and calls `updateLastSeen` + `refreshFcmToken`.
