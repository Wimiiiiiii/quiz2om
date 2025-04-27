import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../custom_app_bar.dart';

class MultiplayerQuizScreen extends StatefulWidget {
  final String gameId;
  final bool isHost;

  const MultiplayerQuizScreen({
    super.key,
    required this.gameId,
    required this.isHost,
  });

  @override
  State<MultiplayerQuizScreen> createState() => _MultiplayerQuizScreenState();
}

class _MultiplayerQuizScreenState extends State<MultiplayerQuizScreen> {
  late DatabaseReference _gameRef;
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _questions = [];
  late StreamSubscription<DatabaseEvent> _gameSubscription;

  @override
  void initState() {
    super.initState();
    _gameRef = FirebaseDatabase.instance.ref('games/${widget.gameId}');
    _loadQuestions();
    _setupGameListener();
  }

  Future<void> _submitAnswer(bool isCorrect) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _gameRef.child('players/$userId').update({
      'score': ServerValue.increment(isCorrect ? 10 : 0),
      'lastAnswer': isCorrect,
    });
  }

  Future<void> _loadQuestions() async {
    final snapshot = await _gameRef.child('questions').get();
    if (snapshot.exists) {
      final data = snapshot.value as List<dynamic>;
      setState(() {
        _questions = data.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  void _setupGameListener() {
    _gameSubscription = _gameRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _currentQuestionIndex = data['currentQuestion'] ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _gameSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final answers = List<Map<String, dynamic>>.from(currentQuestion['answers'] ?? []);

    return Scaffold(
      appBar: CustomAppBar(title: 'Question ${_currentQuestionIndex + 1}'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  currentQuestion['text'] ?? 'Question',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Réponses
            Expanded(
              child: ListView.builder(
                itemCount: answers.length,
                itemBuilder: (context, index) {
                  final answer = answers[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton(
                      onPressed: () => _submitAnswer(answer['isCorrect'] == true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(answer['text'] ?? 'Réponse'),
                    ),
                  );
                },
              ),
            ),

            // Scores
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text('Classement', style: TextStyle(fontWeight: FontWeight.bold)),
                    StreamBuilder(
                      stream: _gameRef.child('players').onValue,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final players = <Map<String, dynamic>>[];
                        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
                        if (data != null) {
                          data.forEach((key, value) {
                            players.add({
                              'id': key,
                              ...Map<String, dynamic>.from(value),
                            });
                          });
                        }
                        players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

                        return Column(
                          children: players.map((player) => ListTile(
                            leading: CircleAvatar(
                              child: Text((players.indexOf(player) + 1).toString()),
                            ),
                            title: Text(player['name'] ?? 'Joueur'),
                            trailing: Text('${player['score'] ?? 0} pts'),
                          )).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}