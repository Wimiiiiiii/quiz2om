import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'package:com_quiz2om_app/services/multiplayer_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'multiplayer_waiting_screen.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _maxPlayersController = TextEditingController();
  final MultiplayerService _multiplayerService = MultiplayerService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isCreating = false;

  @override
  void dispose() {
    _roomNameController.dispose();
    _maxPlayersController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    if (_roomNameController.text.isEmpty || _maxPlayersController.text.isEmpty || _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    final int? maxPlayers = int.tryParse(_maxPlayersController.text);
    if (maxPlayers == null || maxPlayers <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nombre de joueurs valide.')),
      );
      return;
    }

    if (maxPlayers == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pour jouer seul, veuillez choisir le mode Solo.')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();

      final userName = userDoc.data()?['username'];
      final gameId = await _multiplayerService.createGame(
        _roomNameController.text,
        maxPlayers,
        _currentUser.uid,
        userName,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MultiplayerWaitingScreen(
            gameId: gameId,
            roomName: _roomNameController.text,
            maxPlayers: maxPlayers,
            isHost: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Créer une partie'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _roomNameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la partie',
                border: OutlineInputBorder(),
              ),
              maxLength: 30,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _maxPlayersController,
              decoration: const InputDecoration(
                labelText: 'Nombre de joueurs max',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isCreating ? null : _createGame,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: _isCreating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'Créer la partie',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white, // Texte en blanc
                  fontWeight: FontWeight.bold, // Optionnel : pour plus de visibilité
                ),
              ),
            ),
            if (_currentUser == null)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'Vous devez être connecté pour créer une partie',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}