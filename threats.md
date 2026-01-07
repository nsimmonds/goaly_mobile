# Security Threats and Vulnerabilities

Last Updated: 2026-01-07

## Executive Summary

The Goaly Mobile app is a local-only Pomodoro timer application with SQLite database storage and SharedPreferences for settings. The overall security posture is **GOOD** for a local-only application. No critical or high-severity vulnerabilities were identified. Several low-severity and informational findings are documented below for security hardening.

## Active Vulnerabilities

### SEC-001: Debug Print Statements in Production Code
- **Severity**: LOW
- **Location**: `/Users/nicksimmonds/code/goaly_mobile/lib/screens/home_screen.dart` (lines 27, 34-37, 393)
- **Description**: Multiple `print()` statements are present in production code, which could expose internal application state in debug logs.
- **Status**: Open

### SEC-002: JSON Deserialization Without Schema Validation
- **Severity**: LOW
- **Location**: `/Users/nicksimmonds/code/goaly_mobile/lib/providers/settings_provider.dart` (lines 50-58)
- **Description**: JSON data from SharedPreferences is decoded without schema validation. While SharedPreferences is local storage, corrupted data could cause runtime exceptions.
- **Status**: Open

### SEC-003: Unencrypted Local Database Storage
- **Severity**: INFORMATIONAL
- **Location**: `/Users/nicksimmonds/code/goaly_mobile/lib/services/database_service.dart`
- **Description**: SQLite database stores task data in plaintext. For a Pomodoro timer app, this is acceptable as the data is not sensitive, but applications handling personal data should consider encryption.
- **Status**: Acknowledged - Low risk for this use case

### SEC-004: Unencrypted SharedPreferences Storage
- **Severity**: INFORMATIONAL
- **Location**: `/Users/nicksimmonds/code/goaly_mobile/lib/providers/settings_provider.dart`
- **Description**: Settings are stored using SharedPreferences which is not encrypted. For user preferences like dark mode and timer durations, this is acceptable.
- **Status**: Acknowledged - Low risk for this use case

## Security Strengths Identified

1. **SQL Injection Prevention**: The database service properly uses parameterized queries with `whereArgs` for all database operations. No string concatenation is used in SQL queries.

2. **No Network Attack Surface**: The application is entirely local with no network requests, eliminating remote attack vectors.

3. **No Hardcoded Secrets**: No API keys, tokens, passwords, or other secrets were found in the codebase.

4. **Proper Input Validation**: Task descriptions are trimmed and validated for empty strings before database insertion.

5. **Type-Safe Database Operations**: The `db.insert()`, `db.query()`, `db.update()`, and `db.delete()` methods are used with proper parameterization.

6. **Circular Dependency Prevention**: The `DependencyValidator` class properly prevents circular task dependencies using BFS traversal.

7. **Minimal Permissions**: AndroidManifest.xml requests no special permissions beyond Flutter defaults.

## Recently Patched

*No recently patched vulnerabilities*

## Dependency Alerts

### Direct Dependencies (from pubspec.lock)

| Package | Version | Known CVEs | Status |
|---------|---------|------------|--------|
| sqflite | 2.4.2 | None known | OK |
| shared_preferences | 2.5.4 | None known | OK |
| provider | 6.1.5+1 | None known | OK |
| audioplayers | 5.2.1 | None known | OK |
| path_provider | 2.1.5 | None known | OK |
| intl | 0.18.1 | None known | OK |
| cupertino_icons | 1.0.8 | None known | OK |

### Transitive Dependencies of Note

| Package | Version | Notes |
|---------|---------|-------|
| http | 1.6.0 | Transitive dependency (unused directly) |
| crypto | 3.0.7 | Transitive dependency |

**Recommendation**: Run `flutter pub outdated` periodically to check for security updates.

## Threat Intelligence

### Flutter/Dart Ecosystem (January 2026)

1. **Local Storage Security**: flutter_secure_storage is recommended for sensitive data, but not required for non-sensitive timer/task data.

2. **Platform Channel Security**: No custom platform channels are used in this application, eliminating native bridge vulnerabilities.

3. **WebView Risks**: No WebView components are used, eliminating XSS and JavaScript injection risks.

## Security Recommendations

### Priority 1 (Should Address)

1. **Remove Debug Print Statements**: Replace `print()` calls with conditional logging that is disabled in release builds.
   - Files affected: `home_screen.dart`, `task_provider.dart`

2. **Add JSON Schema Validation**: Wrap JSON deserialization in try-catch blocks with fallback to defaults.
   - Files affected: `settings_provider.dart`

### Priority 2 (Consider for Future)

3. **Add Input Length Limits**: Consider adding maximum length validation for task descriptions to prevent excessive data storage.

4. **Database Backup Mechanism**: Consider implementing export/backup functionality with appropriate security measures if users request data portability.

### Priority 3 (Nice to Have)

5. **Code Obfuscation**: Enable Dart obfuscation for release builds using `--obfuscate` flag.

6. **Release Build Verification**: Implement pre-release security checklist including log statement removal.

## Audit Trail

| Date | Auditor | Scope | Findings |
|------|---------|-------|----------|
| 2026-01-07 | Security Evaluator Agent | Full codebase review | 2 LOW, 2 INFORMATIONAL |

---

*This document should be reviewed and updated with each significant code change or dependency update.*
