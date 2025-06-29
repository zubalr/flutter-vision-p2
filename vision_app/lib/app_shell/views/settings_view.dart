import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vision_app/app_shell/services/settings_service.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        if (!settingsService.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(context, 'Camera Settings'),
              _buildCameraResolutionSetting(context, settingsService),
              const SizedBox(height: 16),

              _buildSectionHeader(context, 'Overlay Settings'),
              _buildOverlayOpacitySetting(context, settingsService),
              _buildToggleSetting(
                context,
                'Show Confidence Scores',
                'Display confidence percentages on detections',
                settingsService.showConfidenceScores,
                settingsService.setShowConfidenceScores,
              ),
              const SizedBox(height: 16),

              _buildSectionHeader(context, 'Model Settings'),
              _buildConfidenceThresholdSetting(context, settingsService),
              _buildToggleSetting(
                context,
                'GPU Acceleration',
                'Use GPU for faster inference (if available)',
                settingsService.enableGPUAcceleration,
                settingsService.setEnableGPUAcceleration,
              ),
              _buildToggleSetting(
                context,
                'Model Optimization',
                'Enable optimizations for better performance',
                settingsService.enableModelOptimization,
                settingsService.setEnableModelOptimization,
              ),
              const SizedBox(height: 32),

              _buildSectionHeader(context, 'About'),
              _buildInfoCard(context, settingsService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildCameraResolutionSetting(
    BuildContext context,
    SettingsService settingsService,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.camera_alt),
        title: const Text('Camera Resolution'),
        subtitle: Text('Current: ${settingsService.cameraResolution}'),
        trailing: DropdownButton<String>(
          value: settingsService.cameraResolution,
          onChanged: (String? newValue) {
            if (newValue != null) {
              settingsService.setCameraResolution(newValue);
            }
          },
          items: ['Low', 'Medium', 'High', 'Ultra']
              .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              })
              .toList(),
        ),
      ),
    );
  }

  Widget _buildOverlayOpacitySetting(
    BuildContext context,
    SettingsService settingsService,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.opacity),
                const SizedBox(width: 16),
                Text(
                  'Overlay Opacity',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: settingsService.overlayOpacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: '${(settingsService.overlayOpacity * 100).round()}%',
              onChanged: (double value) {
                settingsService.setOverlayOpacity(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceThresholdSetting(
    BuildContext context,
    SettingsService settingsService,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune),
                const SizedBox(width: 16),
                Text(
                  'Confidence Threshold',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: settingsService.confidenceThreshold,
              min: 0.1,
              max: 0.9,
              divisions: 8,
              label: '${(settingsService.confidenceThreshold * 100).round()}%',
              onChanged: (double value) {
                settingsService.setConfidenceThreshold(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSetting(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Icon(_getIconForSetting(title)),
      ),
    );
  }

  IconData _getIconForSetting(String title) {
    switch (title) {
      case 'Show Confidence Scores':
        return Icons.percent;
      case 'GPU Acceleration':
        return Icons.speed;
      case 'Model Optimization':
        return Icons.tune;
      default:
        return Icons.settings;
    }
  }

  Widget _buildInfoCard(BuildContext context, SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vision App',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Version: 1.0.0'),
            const SizedBox(height: 4),
            const Text('Powered by YOLOv11 and TensorFlow Lite'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await settingsService.resetToDefaults();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings reset to defaults'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset to Defaults'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
