import 'package:flutter/material.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use Goaly'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            icon: Icons.timer,
            title: 'The Pomodoro Technique',
            content: 'Goaly uses the Pomodoro technique to help you stay focused. '
                'Work in focused 25-minute sessions, then take a 5-minute break. '
                'After completing a session, the app automatically transitions to the next phase.',
          ),
          _buildSection(
            context,
            icon: Icons.task_alt,
            title: 'Managing Tasks',
            content: 'Add tasks from the Tasks screen. When you start a work session, '
                'Goaly randomly picks an incomplete task for you to focus on. '
                'Tap the task card to mark it complete and move on, or let the timer run out.',
          ),
          _buildSection(
            context,
            icon: Icons.schedule,
            title: 'Time Estimates',
            content: 'Optionally add time estimates to your tasks (in minutes). '
                'Goaly tracks actual time spent so you can see how accurate your estimates are. '
                'Find these insights on the Stats screen.',
          ),
          _buildSection(
            context,
            icon: Icons.link,
            title: 'Task Dependencies',
            content: 'Some tasks need to wait for others. Set a dependency and that task '
                'will be locked (shown with a lock icon) until the prerequisite is complete. '
                'Blocked tasks won\'t be selected for work sessions.',
          ),
          _buildSection(
            context,
            icon: Icons.label,
            title: 'Tags',
            content: 'Organize tasks with colored tags. Create tags while adding or editing a task. '
                'Use tags to filter your completed tasks on the Stats screen.',
          ),
          _buildSection(
            context,
            icon: Icons.bar_chart,
            title: 'Statistics',
            content: 'Track your productivity on the Stats screen. See completed tasks, '
                'total time worked, and how often you beat your estimates. '
                'Filter by search or tags to analyze specific work.',
          ),
          _buildSection(
            context,
            icon: Icons.sync,
            title: 'Flow Mode',
            content: 'Enable Flow Mode to focus on a single task across multiple pomodoro cycles. '
                'When enabled, pick your focus task and it will persist through breaks '
                'until you complete it or turn off flow mode.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
