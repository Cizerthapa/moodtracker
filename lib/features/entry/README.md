# entry

Home screen — the main navigation hub shown after login.

## Screen
**EntryScreen** is a stateless widget that renders:

- A personalised greeting ("Welcome back, [name]").
- Quick-access cards/buttons that navigate to the other feature screens (Journal, Notes, Water Intake, Period Tracking, Memories).
- The **AmbientSoundWidget** (from `features/audio`) docked at the bottom for background music controls.

## Notes
This screen holds no business logic of its own. All data is fetched inside the individual feature screens it links to.
