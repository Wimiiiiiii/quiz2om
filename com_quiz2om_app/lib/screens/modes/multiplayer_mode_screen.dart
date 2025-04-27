import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import '../../services/multiplayer_service.dart';
import 'multiplayer/multiplayer_lobby_screen.dart';
import 'multiplayer/multiplayer_waiting_screen.dart';

class MultiplayerModeScreen extends StatelessWidget {
  const MultiplayerModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mode Multijoueur',
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
            // Bouton "Créer une partie"
            ElevatedButton.icon(
              onPressed: () => _navigateToLobby(context),
              icon: const Icon(Icons.add),
              label: const Text('Créer une Partie'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            // Bouton "Rejoindre une partie"
            ElevatedButton.icon(
                onPressed: () => _showJoinGameDialog(context),
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

  // Navigation vers le Lobby (création de partie)
  void _navigateToLobby(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MultiplayerLobbyScreen(),
      ),
    );
  }

  // Boîte de dialogue pour rejoindre une partie
  void _showJoinGameDialog(BuildContext context) {
    final TextEditingController _codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejoindre une partie'),
        content: TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Code de la partie',
            hintText: 'Entrez le code fourni par l\'hôte',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (_codeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un code valide')),
                );
                return;
              }

              final service = MultiplayerService();
              final gameId = _codeController.text.trim();

              final exists = await service.gameExists(gameId);
              if (!exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Partie introuvable.')),
                );
                return;
              }

              final playerCount = await service.getPlayerCount(gameId);
              if (playerCount >= 4) { // Ou maxPlayers dynamique
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La partie est pleine.')),
                );
                return;
              }
              final user = FirebaseAuth.instance.currentUser!;
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              final userName = userDoc.data()?['name'] ?? 'Joueur';

              // Ajoute le joueur
              await service.joinGame(gameId,  user.uid, userName);

              Navigator.pop(context); // Ferme la boîte de dialogue
              _navigateToWaitingScreen(context, gameId);
            },
            child: const Text('Rejoindre'),
          ),

        ],
      ),
    );
  }

  // Navigation vers l'écran d'attente (pour le joueur qui rejoint)
  void _navigateToWaitingScreen(context, String gameId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiplayerWaitingScreen(
          roomName: gameId, // ou mieux : récupérer le vrai room name depuis Firebase
          maxPlayers: 4, // à adapter
          isHost: false,
          gameId: gameId, // ici on passe le vrai code
        ),
      ),
    );
  }
}