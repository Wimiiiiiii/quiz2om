import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'package:com_quiz2om_app/services/multiplayer_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'multiplayer_quiz_screen.dart';

class MultiplayerWaitingScreen extends StatefulWidget {
  final String gameId;
  final String roomName;
  final int maxPlayers;
  final bool isHost;

  const MultiplayerWaitingScreen({
    super.key,
    required this.gameId,
    required this.roomName,
    required this.maxPlayers,
    required this.isHost,
  });

  @override
  State<MultiplayerWaitingScreen> createState() => _MultiplayerWaitingScreenState();
}

class _MultiplayerWaitingScreenState extends State<MultiplayerWaitingScreen> {
  final MultiplayerService _service = MultiplayerService();
  late StreamSubscription<DatabaseEvent> _gameSubscription;
  Map<String, dynamic> _gameData = {};
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _joinGame();
    _setupGameListener();
  }

  Future<void> _joinGame() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userName = userDoc.data()?['username'];
    await _service.joinGame(widget.gameId, user.uid, userName);
  }

  void _setupGameListener() {
    _gameSubscription = _service.gameStream(widget.gameId).listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value;
        final convertedData = _convertToMap(data);
        setState(() {
          _gameData = convertedData;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partie introuvable')),
        );
        Navigator.pop(context);
      }
    });
  }

  dynamic _convertToMap(dynamic data) {
    if (data is Map) {
      final newMap = <String, dynamic>{};
      data.forEach((key, value) {
        newMap[key.toString()] = _convertToMap(value);
      });
      return newMap;
    } else if (data is List) {
      final listAsMap = <String, dynamic>{};
      for (int i = 0; i < data.length; i++) {
        listAsMap[i.toString()] = _convertToMap(data[i]);
      }
      return listAsMap;
    } else {
      return data;
    }
  }


  Future<void> _startGame() async {
    if (_isStarting) return;

    setState(() => _isStarting = true);

    try {
      // Utilisation de l'instance par défaut de Realtime Database
      final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
      await dbRef.child('games').child(widget.gameId).update({
        'status': 'started',
        'startedAt': ServerValue.timestamp,
      });

      if (!mounted) return;

      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MultiplayerQuizScreen(
          gameId: widget.gameId,
          isHost: true,
        ),
      ));
    } catch (e, stack) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du démarrage de la partie: $e')),
      );
      print('Erreur au startGame: $e');
      print('Stacktrace: $stack');
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }





  @override
  void dispose() {
    _gameSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Accède directement aux données de la partie actuelle
    final gameData = _gameData;

    // Accède aux données des joueurs en toute sécurité
    final players = gameData?['players'] as Map<String, dynamic>? ?? {};

    final maxPlayers = gameData?['maxPlayers'] as int? ?? widget.maxPlayers;

    print('Game Data: $gameData');
    print('Players: $players');
    print('Max Players: $maxPlayers');

    return Scaffold(
      appBar: CustomAppBar(title: 'Salle d\'attente'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Partie: ${widget.roomName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Code d\'invitation : ${widget.gameId}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.gameId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copié dans le presse-papiers !')),
                    );
                  },
                ),
              ],
            ),


            const SizedBox(height: 10),
            Text(
              'Joueurs: ${players.length}/$maxPlayers',
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 30),
            const Text(
              'Joueurs connectés:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: players.entries.map((entry) {
                  final playerData = entry.value as Map<String, dynamic>? ?? {}; // Accède aux données du joueur en toute sécurité
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(playerData['name'] ?? 'Joueur inconnu'),
                    trailing: playerData['ready'] == true
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.hourglass_bottom, color: Colors.orange),
                  );
                }).toList(),
              ),
            ),
            // Bouton SEULEMENT pour l'hôte
            if (widget.isHost)
              ElevatedButton(
                onPressed: players.length >= 2 ? _startGame : null,
                child: _isStarting
                    ? const CircularProgressIndicator()
                    : const Text('Commencer la partie'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
