# Project Roadmap

This document outlines planned technical improvements and feature ideas for future development.

---

## Technical Improvements

### 1. Local Cache (Offline Mode)
Right now, connectivity is monitored, but the app has limited functionality when offline. The plan is to integrate **Hive** or **Isar** to cache Firestore data locally. This would allow the app to work fully offline and automatically sync when the connection is restored.

### 2. Full Localization (Multi-language Support)
All hardcoded strings should be moved into `.arb` files. This is a requirement for App Store distribution and is essential for reaching a global audience.

### 3. Repository Unit Tests
Since the project uses the `Result` pattern and `GetIt`, unit tests can be written to mock the database layer. This ensures that changes to the Repository do not unintentionally break the user interface.

### 4. Custom App Navigation System
Replace standard `Navigator.push` calls with a typed routing system such as **go_router**. This enables deep link support — for example, opening a specific memory directly from a notification.

---

## Feature Ideas

### 1. AI Mood Insights (Gemini Integration)
Use a small AI model to analyze journal entries and generate a **Weekly Sentiment Summary**, along with suggestions for improving mood based on patterns in the entries.

### 2. Voice Journaling
Add a record button to the `AddNoteScreen` that uses speech-to-text, allowing users to speak their thoughts instead of typing them.

### 3. Memory Map and Mood Heatmap
A visual map showing the geographic locations where memories were created, combined with a **Mood Heatmap Calendar** that highlights which days had the most positive entries.

### 4. Collaborative Shared Journal
Allow two users — for example, a couple — to link their accounts and maintain a shared **"Our Memories"** feed alongside their individual private journals.

### 5. Export to PDF
Let users export a journal or a month of entries into a formatted PDF file, usable as a digital scrapbook.

### 6. Daily Flashback Notifications
Send a push notification that says something like: *"One year ago today, you added this memory..."* — encouraging users to revisit and reflect on past moments.

---

*This roadmap will be updated as priorities are confirmed and development continues.*