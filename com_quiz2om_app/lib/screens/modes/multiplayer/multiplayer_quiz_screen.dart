import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../../models/quiz_models.dart';
import '../../custom_app_bar.dart';

class MultiplayerQuizScreen extends StatefulWidget {
  final String roomCode;

  const MultiplayerQuizScreen({super.key, required this.roomCode});

  @override
  State<MultiplayerQuizScreen> createState() => _MultiplayerQuizScreenState();
}

class _MultiplayerQuizScreenState extends State<MultiplayerQuizScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  late int _timeLeft;
  Timer? _timer;
  bool _answerSelected = false;
  String? _selectedAnswer;
  String? _correctAnswer;
  Map<String, int> _playerScores = {};
  bool _gameEnded = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      // Récupérer les données de la room
      final roomDoc = await _firestore.collection('game_rooms').doc(widget.roomCode).get();
      final roomData = roomDoc.data()!;
      
      // Récupérer les questions
      final questionsQuery = await _firestore
          .collection('questions')
          .where('categoryId', isEqualTo: roomData['categoryId'])
          .where('difficulty', isEqualTo: roomData['difficulty'])
          .limit(10)
          .get();

      setState(() {
        _questions = questionsQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'question': data['question'],
            'options': List<String>.from(data['options']),
            'correctAnswer': data['correctAnswer'],
            'timeLimit': data['timeLimit'] ?? 30,
          };
        }).toList()..shuffle();
        
        _timeLeft = _questions.isNotEmpty ? _questions[0]['timeLimit'] : 30;
        _playerScores = Map<String, int>.from(roomData['scores'] ?? {});
      });

      // Démarrer le timer
      _startTimer();

      // Écouter les mises à jour des scores
      _firestore.collection('game_rooms').doc(widget.roomCode)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          if (data['status'] == 'ended') {
            _endGame();
          } else {
            setState(() {
              _playerScores = Map<String, int>.from(data['scores'] ?? {});
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Erreur d\'initialisation: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          if (!_answerSelected) {
            _goToNextQuestion();
          }
        }
      });
    });
  }

  void _checkAnswer(String selectedAnswer) async {
    if (_answerSelected || _user == null) return;

    _timer?.cancel();
    setState(() {
      _answerSelected = true;
      _selectedAnswer = selectedAnswer;
      _correctAnswer = _questions[_currentQuestionIndex]['correctAnswer'];
    });

    // Calculer les points
    final points = selectedAnswer == _correctAnswer ? _calculatePoints() : 0;
    
    // Mettre à jour le score
    await _firestore.collection('game_rooms').doc(widget.roomCode).update({
      'scores.${_user?.uid}': FieldValue.increment(points),
    });

    // Attendre un peu avant de passer à la question suivante
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _goToNextQuestion();
      }
    });
  }

  int _calculatePoints() {
    final maxTime = _questions[_currentQuestionIndex]['timeLimit'];
    final timeBonus = (_timeLeft / maxTime * 10).clamp(0, 10).round();
    return 10 + timeBonus;
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answerSelected = false;
        _selectedAnswer = null;
        _correctAnswer = null;
        _timeLeft = _questions[_currentQuestionIndex]['timeLimit'];
      });
      _startTimer();
    } else {
      _endGame();
    }
  }

  void _endGame() async {
    _timer?.cancel();
    setState(() {
      _gameEnded = true;
    });

    // Marquer la partie comme terminée
    await _firestore.collection('game_rooms').doc(widget.roomCode).update({
      'status': 'ended',
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gameEnded) {
      return _buildResultsScreen();
    }

    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Question ${_currentQuestionIndex + 1}/${_questions.length}',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildScoresBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTimer(),
                    const SizedBox(height: 20),
                    _buildQuestion(currentQuestion),
                    const SizedBox(height: 20),
                    ...currentQuestion['options'].map<Widget>((option) =>
                      _buildOptionButton(option, currentQuestion),
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

  Widget _buildScoresBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple[100]!,
            Colors.deepPurple[200]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _playerScores.entries.map((entry) {
          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(entry.key).get(),
            builder: (context, snapshot) {
              final username = snapshot.data?.get('username') ?? 'Joueur';
              return Column(
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.value} points',
                      style: TextStyle(
                        color: entry.key == _user?.uid ? Colors.deepPurple : Colors.black87,
                        fontWeight: entry.key == _user?.uid ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: _timeLeft <= 5 ? Colors.red[100] : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'Temps restant: $_timeLeft s',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _timeLeft <= 5 ? Colors.red : Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildQuestion(Map<String, dynamic> question) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        question['question'],
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 22,
          color: Colors.deepPurple[900],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option, Map<String, dynamic> question) {
    final isSelected = option == _selectedAnswer;
    final isCorrect = option == _correctAnswer;
    Color? backgroundColor;
    Color? borderColor;
    
    if (_answerSelected) {
      if (isCorrect) {
        backgroundColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
      } else if (isSelected) {
        backgroundColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: _answerSelected ? null : () => _checkAnswer(option),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            border: Border.all(
              color: borderColor ?? Colors.deepPurple[200]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
                    color: _answerSelected && isCorrect ? Colors.green : Colors.deepPurple[900],
                    fontWeight: _answerSelected && isCorrect ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (_answerSelected && isCorrect)
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
              if (_answerSelected && isSelected && !isCorrect)
                const Icon(Icons.cancel, color: Colors.red, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final sortedScores = _playerScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Résultats',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Classement final',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedScores.length,
                  itemBuilder: (context, index) {
                    final entry = sortedScores[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(entry.key).get(),
                      builder: (context, snapshot) {
                        final username = snapshot.data?.get('username') ?? 'Joueur';
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: index == 0 
                                  ? Colors.amber 
                                  : index == 1 
                                      ? Colors.grey[400] 
                                      : Colors.brown[300],
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${entry.value} points',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}