import 'package:flutter/material.dart';
import '../core/theme.dart';

class ThreeSixtyScreen extends StatelessWidget {
  const ThreeSixtyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Location')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 80, color: AppTheme.slate.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('360° Live View coming soon', style: TextStyle(fontSize: 18, color: AppTheme.slate)),
          ],
        ),
      ),
    );
  }
}
