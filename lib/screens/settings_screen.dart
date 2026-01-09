import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../services/backup_service.dart';
import '../config/constants.dart';
import 'instructions_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${AppConstants.emojiSettings} Settings'),
          ],
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance Section
              _buildSectionHeader(context, 'Appearance'),
              _buildDarkModeCard(context, settings),
              const SizedBox(height: 24),

              // Timer Settings Section
              _buildSectionHeader(context, 'Timer Durations'),
              _buildTimerCard(context, settings),
              const SizedBox(height: 24),

              // Sound Settings Section
              _buildSectionHeader(context, 'Audio'),
              _buildSoundCard(context, settings),
              const SizedBox(height: 24),

              // Suggestions Section
              _buildSectionHeader(context, 'Suggestions'),
              _buildSuggestionsToggle(context, settings),
              if (settings.suggestionsEnabled) ...[
                const SizedBox(height: 8),
                _buildSuggestionsList(
                  context,
                  settings,
                  'Break Suggestions',
                  '☕',
                  settings.breakSuggestions,
                  settings.addBreakSuggestion,
                  settings.removeBreakSuggestion,
                ),
                const SizedBox(height: 8),
                _buildSuggestionsList(
                  context,
                  settings,
                  'Celebration Suggestions',
                  '🎉',
                  settings.celebrationSuggestions,
                  settings.addCelebrationSuggestion,
                  settings.removeCelebrationSuggestion,
                ),
                const SizedBox(height: 8),
                _buildResetSuggestionsCard(context, settings),
              ],
              const SizedBox(height: 24),

              // Backup & Restore Section
              _buildSectionHeader(context, 'Backup & Restore'),
              _buildExportCard(context),
              const SizedBox(height: 8),
              _buildImportCard(context),
              const SizedBox(height: 24),

              // Other Section
              _buildSectionHeader(context, 'Other'),
              _buildInstructionsCard(context),
              const SizedBox(height: 8),
              _buildAboutCard(context),
              const SizedBox(height: 8),
              _buildResetCard(context, settings),
              const SizedBox(height: 24),

              // App Info
              _buildAppInfo(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildDarkModeCard(BuildContext context, SettingsProvider settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('Dark Mode'),
        subtitle: const Text('Use dark theme'),
        secondary: Text(
          settings.isDarkMode
              ? AppConstants.emojiDarkMode
              : AppConstants.emojiLightMode,
          style: const TextStyle(fontSize: 24),
        ),
        value: settings.isDarkMode,
        onChanged: (value) => settings.toggleDarkMode(),
      ),
    );
  }

  Widget _buildTimerCard(BuildContext context, SettingsProvider settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Work Duration
            Text(
              '${AppConstants.emojiTimer} Work Session: ${settings.workMinutes} minutes',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Slider(
              value: settings.workMinutes.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: '${settings.workMinutes} min',
              onChanged: (value) => settings.setWorkMinutes(value.toInt()),
            ),
            const SizedBox(height: 16),

            // Break Duration
            Text(
              '${AppConstants.emojiBreak} Break Session: ${settings.breakMinutes} minutes',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Slider(
              value: settings.breakMinutes.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              label: '${settings.breakMinutes} min',
              onChanged: (value) => settings.setBreakMinutes(value.toInt()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundCard(BuildContext context, SettingsProvider settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('Sound Alerts'),
        subtitle: const Text('Play sound when session completes'),
        secondary: const Icon(Icons.volume_up),
        value: settings.soundEnabled,
        onChanged: (value) => settings.toggleSound(),
      ),
    );
  }

  Widget _buildSuggestionsToggle(BuildContext context, SettingsProvider settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('Show Suggestions'),
        subtitle: const Text('Fun ideas for breaks and celebrations'),
        secondary: const Icon(Icons.lightbulb_outline),
        value: settings.suggestionsEnabled,
        onChanged: (value) => settings.toggleSuggestions(),
      ),
    );
  }

  Widget _buildSuggestionsList(
    BuildContext context,
    SettingsProvider settings,
    String title,
    String emoji,
    List<String> suggestions,
    Future<void> Function(String) onAdd,
    Future<void> Function(int) onRemove,
  ) {
    return Card(
      child: ExpansionTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text(title),
        subtitle: Text('${suggestions.length} items'),
        children: [
          ...suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            return ListTile(
              dense: true,
              title: Text(suggestion),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => onRemove(index),
              ),
            );
          }),
          ListTile(
            dense: true,
            leading: const Icon(Icons.add, color: Colors.green),
            title: const Text('Add suggestion'),
            onTap: () => _showAddSuggestionDialog(context, onAdd),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSuggestionDialog(
    BuildContext context,
    Future<void> Function(String) onAdd,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Suggestion'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter your suggestion',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await onAdd(result.trim());
    }
  }

  Widget _buildResetSuggestionsCard(BuildContext context, SettingsProvider settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.refresh),
        title: const Text('Reset Suggestions'),
        subtitle: const Text('Restore default suggestions'),
        onTap: () async {
          await settings.resetSuggestionsToDefaults();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Suggestions reset to defaults')),
            );
          }
        },
      ),
    );
  }

  Widget _buildExportCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.upload_file),
        title: const Text('Export Tasks'),
        subtitle: const Text('Save all tasks and tags to a file'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _exportTasks(context),
      ),
    );
  }

  Widget _buildImportCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.download),
        title: const Text('Import Tasks'),
        subtitle: const Text('Restore tasks from a backup file'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _importTasks(context),
      ),
    );
  }

  Future<void> _exportTasks(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final backupService = BackupService();
      final jsonData = await backupService.exportToJson();

      // Close loading indicator
      if (context.mounted) Navigator.pop(context);

      // Generate default filename
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final defaultFileName = 'goaly_backup_$timestamp.json';

      // Use save file dialog (works better on desktop)
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (savePath != null) {
        final file = File(savePath);
        await file.writeAsString(jsonData);

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Backup saved successfully')),
        );
      }
    } catch (e) {
      // Close loading indicator if still open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importTasks(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonData = await file.readAsString();

      if (!context.mounted) return;

      // Ask user for import mode
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Mode'),
          content: const Text('How do you want to import the backup?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Merge'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Replace All'),
            ),
          ],
        ),
      );

      if (replace == null || !context.mounted) return;

      // Confirm if replacing
      if (replace) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Replace All Data?'),
            content: const Text(
              'This will delete all your existing tasks and tags. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Replace'),
              ),
            ],
          ),
        );

        if (confirmed != true || !context.mounted) return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final backupService = BackupService();
      final importResult = await backupService.importFromJson(jsonData, replace: replace);

      // Close loading indicator
      if (context.mounted) Navigator.pop(context);

      // Reload tasks in provider
      if (context.mounted) {
        await context.read<TaskProvider>().loadTasks();
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(importResult.summary)),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Widget _buildInstructionsCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('How to Use Goaly'),
        subtitle: const Text('Tips and instructions'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InstructionsScreen()),
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('About'),
        subtitle: const Text('App info and credits'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        ),
      ),
    );
  }

  Widget _buildResetCard(BuildContext context, SettingsProvider settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.restore),
        title: const Text('Reset to Defaults'),
        subtitle: const Text('Restore all settings to default values'),
        onTap: () => _confirmReset(context, settings),
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${AppConstants.emojiGoal} ${AppConstants.appName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'A focused Pomodoro timer with task management',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, SettingsProvider settings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text(
            'Are you sure you want to reset all settings to their default values?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await settings.resetToDefaults();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to defaults')),
        );
      }
    }
  }
}
