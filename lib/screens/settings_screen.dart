import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../config/constants.dart';

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

              // Reset Section
              _buildSectionHeader(context, 'Other'),
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
