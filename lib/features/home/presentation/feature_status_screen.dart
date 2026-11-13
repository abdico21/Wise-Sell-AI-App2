import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class FeatureStatusScreen extends StatelessWidget {
  const FeatureStatusScreen({
    required this.title,
    required this.description,
    required this.plannedItems,
    super.key,
  });

  final String title;
  final String description;
  final List<String> plannedItems;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.construction_rounded, size: 64, color: AppTheme.blue),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(description, textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade700, height: 1.5)),
            const SizedBox(height: 28),
            const Text('Planned capabilities', style: TextStyle(
              color: AppTheme.navy, fontSize: 18, fontWeight: FontWeight.w800,
            )),
            const SizedBox(height: 10),
            ...plannedItems.map((item) => Card(
              child: ListTile(
                leading: const Icon(Icons.radio_button_unchecked, color: AppTheme.blue),
                title: Text(item),
              ),
            )),
            const SizedBox(height: 18),
            const Text(
              'This screen is a navigation placeholder, not a completed or connected service.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
