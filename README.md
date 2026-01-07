# Goaly Mobile

A Flutter Pomodoro timer app designed for the "disciplined dilettante" - people with many interests who struggle with decision paralysis.

## Philosophy

Instead of agonizing over which task to work on, Goaly picks a random task for you and starts a focused work session. Just add your tasks (dev tickets, side projects, chores, learning goals) and let the app decide what you work on next.

## Features

- **Pomodoro Timer**: 25-minute work sessions with 5-minute breaks (configurable)
- **Auto-Cycling**: Work → Break → Work transitions automatically
- **Random Task Selection**: Each work session picks a new random task
- **Time Tracking**: Tracks actual time spent on each task (excludes pause time)
- **Task Estimates**: Optional time estimates to compare against actual time
- **Task Dependencies**: Block tasks until prerequisite tasks are complete
- **Statistics Dashboard**: View completed tasks, time breakdown, and estimate accuracy
- **Break Suggestions**: Fun activity ideas shown during breaks (customizable)
- **Celebration Suggestions**: Reward ideas when completing tasks (customizable)
- **Dark Mode**: Full dark/light theme support

## Getting Started

### Prerequisites

- Flutter SDK (3.38+)
- macOS, iOS simulator, or Android emulator

### Installation

```bash
# Clone the repository
git clone https://github.com/nsimmonds/goaly_mobile.git
cd goaly_mobile

# Install dependencies
flutter pub get

# Run on macOS
flutter run -d macos

# Or run on iOS simulator
flutter run
```

## Usage

### Quick Start

1. Tap "Add Your First Task" to go to the Tasks screen
2. Add some tasks (optionally with time estimates)
3. Return to home and tap "Start Work Session"
4. Work on the randomly selected task
5. When done, tap "Task Complete!" or let the timer run out
6. Choose "Keep Working" for a new task or "Celebrate" to stop

### Task Dependencies

When adding a task, you can select "Depends On" to block it until another task is complete. Blocked tasks:
- Show a lock icon instead of checkbox
- Are grayed out in the list
- Won't be selected for work sessions

### Statistics

Tap the chart icon to view:
- **Summary**: Total completed, total time, average per task
- **Time Breakdown**: Stats for today, this week, this month, all time
- **Estimate Accuracy**: How your estimates compare to actual time

## Architecture

```
lib/
├── main.dart                 # App entry with Provider setup
├── config/
│   ├── constants.dart        # App constants, DB version
│   └── theme.dart            # Light/dark themes
├── models/
│   └── task.dart             # Task data model
├── providers/
│   ├── settings_provider.dart
│   ├── task_provider.dart
│   └── timer_provider.dart
├── services/
│   ├── database_service.dart
│   └── dependency_validator.dart
└── screens/
    ├── home_screen.dart
    ├── task_list_screen.dart
    ├── settings_screen.dart
    └── stats_screen.dart
```

**State Management**: Provider pattern with ChangeNotifier

**Database**: SQLite via sqflite package

**Timer**: DateTime-based (stores end time, calculates remaining)

## Dependencies

- `provider` - State management
- `sqflite` - SQLite database
- `shared_preferences` - Settings persistence
- `audioplayers` - Completion sounds
- `path_provider` / `path` - File paths

## Building for Release

### Android

```bash
# Build signed AAB for Play Console
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

Requires `android/key.properties` with keystore credentials (not checked into git).

### iOS

```bash
# Build IPA for TestFlight
flutter build ipa --release
```

Requires Xcode signing configured with Apple Developer account.

## TODO

- [ ] Replace `print()` with `debugPrint()` in home_screen.dart (lines 27, 34, 36, 393)
- [ ] Add try-catch for JSON parsing in settings_provider.dart (lines 50-58)
- [ ] Add input length validation for task descriptions
- [ ] Enable code obfuscation for release builds (`--obfuscate --split-debug-info`)

## License

MIT
