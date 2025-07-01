import 'package:flutter/material.dart';
import 'package:vision_app/app_shell/app_shell.dart';

class SolutionsView extends StatelessWidget {
  final SolutionMode currentMode;
  final Function(SolutionMode) onModeChanged;
  final VoidCallback? onNavigateToCamera;

  const SolutionsView({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.onNavigateToCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Solutions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSolutionCard(
            context,
            SolutionMode.objectCounting,
            'Object Counting',
            'Count objects crossing a line in real-time',
            Icons.trending_up,
            Colors.blue,
          ),
          _buildSolutionCard(
            context,
            SolutionMode.distanceCalculation,
            'Distance Calculation',
            'Measure distances between objects',
            Icons.straighten,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionCard(
    BuildContext context,
    SolutionMode mode,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final bool isSelected = currentMode == mode;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 8 : 2,
      child: InkWell(
        onTap: () {
          onModeChanged(mode);
          // Show a snackbar to indicate the mode change
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched to $title mode'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
