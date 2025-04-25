import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _createRoom() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    final roomCode = _generateRoomCode();

    final roomData = {
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
      'categoryId': null,
      'difficulty': null,
      'questions': [],
      'players': {
        user!.uid: {
          'score': 0,
          'ready': false,
        },
      },
    };

    await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).set(roomData);

    setState(() => _isLoading = false);
    _navigateToRoom(roomCode);
  }

  Future<void> _joinRoom() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    final code = _codeController.text.trim().toUpperCase();

    final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(code);
    final snapshot = await roomRef.get();

    if (!snapshot.exists) {
      _showError('Room not found');
      setState(() => _isLoading = false);
      return;
    }

    final data = snapshot.data();
    final players = Map<String, dynamic>.from(data?['players'] ?? {});

    if (players.length >= 2) {
      _showError('Room is full');
      setState(() => _isLoading = false);
      return;
    }

    if (!players.containsKey(user!.uid)) {
      players[user.uid] = {'score': 0, 'ready': false};
      await roomRef.update({'players': players});
    }

    setState(() => _isLoading = false);
    _navigateToRoom(code);
  }

  void _navigateToRoom(String roomCode) {
    Navigator.pushNamed(context, '/multiplayer_waiting', arguments: roomCode);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mode Multijoueur')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _createRoom,
              child: const Text('Créer une Partie'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Code de la Partie',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _joinRoom,
              child: const Text('Rejoindre une Partie'),
            ),
          ],
        ),
      ),
    );
  }
}
