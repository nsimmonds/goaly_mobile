# Goaly Mobile

Goaly is a task management app that uses randomness to get you out of decision paralysis and help motivate you. It acts as a slightly deranged project manager or coach with a pomodoro timer.

## Philosophy

Instead of agonizing over which task to work on, Goaly picks a random task for you and starts a focused work session. Just add your tasks (dev tickets, side projects, chores, learning goals) and let the app decide what you work on next. 

## Pomodoro Method

Including brief breaks in your work can enhance productivity. The "pomodoro method" involves setting a timer for 25 minutes, working for that 25 minutes, and then giving yourself a 5 minute break. Goaly includes this, and enhances it by pulling from your task list while you work so you aren't also deciding what to work on. It means coming off break is frictionless; you're presented with exactly what to work on next.

We recognize that sometimes you get into a "flow state" and need to keep working on what you're working on. "Flow mode" keeps the pomodoro timer running, but keeps your task the same until you complete it or toggle it off.
 
## Features

- **Pomodoro Timer**: 25-minute work sessions with 5-minute breaks (configurable)
- **Auto-Cycling**: Work → Break → Work transitions automatically
- **Random Task Selection**: Each work session picks a new random task
- **Flow Mode**: Keep working on the same task across multiple sessions
- **Background Notifications**: Get alerted when your timer completes, even if the app is backgrounded
- **Dark Mode**: Full dark/light theme support
- **Break Suggestions**: Fun activity ideas shown during breaks (customizable)
- **Celebration Suggestions**: Reward ideas when completing tasks (customizable)

## Advanced Features

Behind the "Advanced Options" toggle you'll find additional features. These are completely optional.

- **Task Tagging**: Tag tasks with arbitrary tags for sorting and reporting
- **Time Tracking**: Tracks actual time spent on each task (excludes pause time)
- **Task Estimates**: Optional time estimates to compare against actual time
- **Task Dependencies**: Block tasks until prerequisite tasks are complete
- **Statistics Dashboard**: View completed tasks, time breakdown, and estimate accuracy

## AI Declaration

There is no AI in Goaly. Your data is your data and will not be used for any kind of training. There are lots of task managers with AI features if you want those; we think there are also lots of people who want an app that predictably does a thing and does it well. Any suggestions are built directly into the app.

To be clear, AI *is* used as a coding assistant in work on Goaly. We are not Luddites about the use of AI...well, not strongly Luddite. But the world also needs apps that just do a thing well and do the same thing every time you press the button.

## Status

Goaly is in beta with public signups:
- Android: https://play.google.com/store/apps/details?id=com.goaly.goaly_mobile
- iOS: https://testflight.apple.com/join/EU2wEpkP

Local builds are available if you want to build it yourself.

## Getting Started with a local build

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
3. Return to home and tap the green timer button to start
4. Work on the randomly selected task shown in the timer
5. When done, tap the timer button or let it run out
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
│   ├── task.dart             # Task data model
│   └── tag.dart              # Tag data model
├── providers/
│   ├── settings_provider.dart
│   ├── task_provider.dart
│   └── timer_provider.dart
├── services/
│   ├── database_service.dart
│   ├── dependency_validator.dart
│   ├── backup_service.dart       # JSON export/import
│   └── notification_service.dart # Background alerts
└── screens/
    ├── home_screen.dart
    ├── task_list_screen.dart
    ├── settings_screen.dart
    ├── stats_screen.dart
    ├── instructions_screen.dart
    └── about_screen.dart
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
- `file_selector` - File selection for backup import/export
- `intl` - Date formatting
- `flutter_local_notifications` - Background timer alerts
- `timezone` / `flutter_timezone` - Timezone-aware scheduling

## Building for Release

### Android

```bash
# Build signed AAB for Play Console (with obfuscation)
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
# Output: build/app/outputs/bundle/release/app-release.aab
```

Requires `android/key.properties` with keystore credentials (not checked into git).

### iOS

```bash
# Build IPA for TestFlight (with obfuscation)
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info
```

Requires Xcode signing configured with Apple Developer account.

**Note**: Keep `build/debug-info/` for crash symbolication. Do not commit to git.

## TODO

See [TODO.md](TODO.md) for the full roadmap.

## Editorial note

Hi, I'm Nick. Right now I maintain this myself, but I use the "editorial we" throughout to minimize rewriting if I ever hire anyone. Also my cat Freddie helps.

## License

All Rights Reserved. See [LICENSE](LICENSE) for details.
