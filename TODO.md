# Goaly TODO

## Bugs

- [ ] AudioPlayer memory leak fix — ensure players are properly disposed

## High Priority

- [ ] Accessibility labels for timer button — important for App Store compliance
- [ ] Empty state when all tasks completed — better UX when task list is cleared

## Medium Priority

- [ ] Loading state during export/import — show spinner during backup operations
- [ ] Arc text painter performance — cache or optimize curved text rendering
- [ ] CI optimization: reuse build artifacts in deploy workflow — avoid double-building
- [ ] Re-enable macOS code signing with `macos-sign` tag trigger — currently disabled (too slow for every deploy)

## Low Priority

- [ ] Custom notification sounds
- [ ] Additional themes (beyond light/dark)
- [ ] Unit tests for notification_service.dart
- [ ] Centralize hardcoded strings
- [ ] Haptic feedback on interactions
- [ ] Pull-to-refresh on task list
- [ ] App icon in About screen
- [ ] Persist stats screen filters

## Completed

- [x] Fix mounted checks after async (home_screen, about_screen)
- [x] Background notifications when timer completes
- [x] Reopen completed tasks (bidirectional checkbox)
- [x] Screen pinning prompts for focus mode
- [x] JSON backup and restore
- [x] Flow mode (same task across sessions)
- [x] Notification permission handling with warning banner
- [x] Database reset option for recovery
- [x] Safe backup import with rollback on failure
- [x] Privacy policy link
