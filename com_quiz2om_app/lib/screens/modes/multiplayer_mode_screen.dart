import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'package:flutter/material.dart';

import 'multiplayer/multiplayer_lobby_screen.dart';

class MultiplayerModeScreen extends StatelessWidget {
  const MultiplayerModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title:  'Mode Multijoueur',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choisissez une option',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MultiplayerLobbyScreen(),
                  ),
                );
              }
              ,
              icon: const Icon(Icons.add),
              label: const Text('Créer une Partie'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),

            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Naviguer vers l’écran pour rejoindre une partie
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rejoindre une partie')),
                );
              },
              icon: const Icon(Icons.input),
              label: const Text('Rejoindre une Partie'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
