import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MultiplayerWaitingScreen extends StatefulWidget {
  final String roomCode;

  const MultiplayerWaitingScreen({super.key, required this.roomCode});

  @override
  State<MultiplayerWaitingScreen> createState() => _MultiplayerWaitingScreenState();
}

class _MultiplayerWaitingScreenState extends State<MultiplayerWaitingScreen> {
  final user = FirebaseAuth.instance.currentUser;

  void _setReady(bool ready) {
    FirebaseFirestore.instance
        .collection('game_rooms')
        .doc(widget.roomCode)
        .update({'players.${user!.uid}.ready': ready});
  }

  void _startGameIfReady(Map<String, dynamic> players) {
    final allReady = players.values.every((p) => p['ready'] == true);
    if (allReady && players.length == 2) {
      FirebaseFirestore.instance
          .collection('game_rooms')
          .doc(widget.roomCode)
          .update({'status': 'started'});

      // TODO: Naviguer vers l’écran du quiz multijoueur
      Navigator.pushReplacementNamed(context, '/quiz_multiplayer', arguments: widget.roomCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Salle d'attente : ${widget.roomCode}")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('game_rooms')
            .doc(widget.roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final players = Map<String, dynamic>.from(data['players']);
          final isReady = players[user!.uid]['ready'] ?? false;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (data['status'] == 'started') {
              Navigator.pushReplacementNamed(context, '/quiz_multiplayer', arguments: widget.roomCode);
            } else {
              _startGameIfReady(players);
            }
          });

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text("Joueurs connectés :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...players.entries.map((entry) {
                  final isMe = entry.key == user?.uid;
                  final ready = entry.value['ready'];
                  return ListTile(
                    title: Text(isMe ? 'Moi (Vous)' : entry.key),
                    trailing: Icon(
                      ready ? Icons.check_circle : Icons.hourglass_empty,
                      color: ready ? Colors.green : Colors.orange,
                    ),
                  );
                }).toList(),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _setReady(!isReady),
                  child: Text(isReady ? 'Annuler Prêt' : 'Je suis prêt'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
