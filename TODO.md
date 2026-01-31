# Goaly TODO

## Bugs

(none)

## High Priority

(none)

## Medium Priority

- [ ] Loading state during export/import — show spinner during backup operations
- [ ] Arc text painter performance — cache or optimize curved text rendering
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

- [x] CI optimization: combined build-deploy.yml with artifact reuse (deploy jobs download from build)
- [x] Accessibility labels for timer button (Semantics widget with state-aware labels)
- [x] AudioPlayer memory leak — investigated, false positive (single instance, properly disposed)
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
