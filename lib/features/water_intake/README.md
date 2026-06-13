# water_intake

Daily hydration tracker with goal progress, drink history, and weekly trends.

## Screen
**WaterIntakeScreen** has three tabs:

| Tab | Content |
|-----|---------|
| Goal | Circular progress ring showing today's intake vs daily goal; beverage type picker; quick-add buttons |
| History | Scrollable list of all drink entries; swipe-to-delete and tap-to-edit |
| Trends | Bar chart of the last 7 days' totals |

## Beverage types
Water, Coffee, Juice, Tea — each with its own icon and accent colour.

## Units
Supports ml, Liters, and Cups. The selected unit is persisted via `WaterRepository.setHydrationUnit`.

## Repository
- **WaterRepository** — persists drink history as JSON strings in local storage; exposes `addDrink`, `deleteDrink`, `updateDrink`, `getDailyWaterGoal`, `setDailyWaterGoal`, `getHydrationUnit`, `setHydrationUnit`.
