import 'package:flutter/material.dart';

class MultiplayerQuizScreen extends StatefulWidget {
  final String roomCode;

  const MultiplayerQuizScreen({super.key, required this.roomCode});

  @override
  State<MultiplayerQuizScreen> createState() => _MultiplayerQuizScreenState();
}

class _MultiplayerQuizScreenState extends State<MultiplayerQuizScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz Multijoueur')),
      body: const Center(child: Text('Jeu en cours...')),
    );
  }
}