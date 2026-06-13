# splash

App entry point with animated branding and optional biometric authentication.

## Screen
**SplashScreen** does three things on launch:

1. Plays a pulsing heart animation while checking auth state.
2. If biometric lock is enabled in Settings, prompts `LocalAuthentication` (fingerprint / face ID) before proceeding.
3. Routes to `AppRoutes.home` if a Firebase user is signed in, or `AppRoutes.login` otherwise.

## Details
- Displays a randomly selected encouraging message from a predefined list (e.g. "you look beautiful today 💕").
- Checks for app version mismatches via `PackageInfo` and Firestore for potential force-upgrade flows.
