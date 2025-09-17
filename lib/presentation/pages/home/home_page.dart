import 'package:flutter/material.dart';

// Home Page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CourSEVEN'),
        actions: [
          // Theme toggle placeholder
          IconButton(
            onPressed: () {
              // TODO: Implement theme toggle
            },
            icon: const Icon(Icons.brightness_6),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text('Página Principal', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text(
              'Funcionalidad en desarrollo...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
