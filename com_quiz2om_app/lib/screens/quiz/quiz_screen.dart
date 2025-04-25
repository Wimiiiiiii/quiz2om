import 'dart:async';
import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:com_quiz2om_app/models/quiz_models.dart';

import '../../services/score_services.dart';
import '../home/home_screen.dart';

class QuizScreen extends StatefulWidget {
  final QuizCategory category;
  final String difficulty;



  const QuizScreen({
    super.key,
    required this.category,
    required this.difficulty,
  });


  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

final ScoreService _scoreService = ScoreService();
List<String> _answeredQuestionIds = [];

class _QuizScreenState extends State<QuizScreen> {
  late Future<List<QuizQuestion>> _questionsFuture;
  int _currentQuestionIndex = 0;
  int _score = 0;
  late int _timeLeft;
  late Timer _timer;
  bool _answerSelected = false;
  String? _selectedAnswer;
  String? _correctAnswer;
  bool _timerInitialized = false;
  List<QuizQuestion>? _questions;

  @override
  void initState() {
    super.initState();
    _timeLeft = _getTimeLimitForDifficulty();
    _questionsFuture = _fetchQuestions().then((questions) {
      _questions = questions;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && questions.isNotEmpty) {
          _startTimer();
        }
      });
      return questions;
    });
  }

  int _getTimeLimitForDifficulty() {
    switch (widget.difficulty.toLowerCase()) {
      case 'facile':
        return 15;
      case 'moyen':
        return 25;
      case 'difficile':
        return 30;
      default:
        return 30;
    }
  }

  Future<List<QuizQuestion>> _fetchQuestions() async {
    final query = FirebaseFirestore.instance
        .collection('questions')
        .where('categoryId', isEqualTo: widget.category.id)
        .where('difficulty', isEqualTo: widget.difficulty)
        .limit(10);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => QuizQuestion.fromFirestore(doc)).toList()
      ..shuffle();
  }

  void _startTimer() {
    if (_timerInitialized) _timer.cancel();

    _timerInitialized = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer.cancel();
          if (!_answerSelected) {
            _goToNextQuestion();
          }
        }
      });
    });
  }

  void _goToNextQuestion() {
    if (_timer.isActive) _timer.cancel();

    setState(() {
      _currentQuestionIndex++;
      _answerSelected = false;
      _selectedAnswer = null;
      _correctAnswer = null;
      _timerInitialized = false;
      _timeLeft = _getTimeLimitForDifficulty();
    });

    if (_currentQuestionIndex < (_questions?.length ?? 0)) {
      _startTimer();
    }
  }

  void _checkAnswer(String selectedAnswer, QuizQuestion question) {
    if (_timer.isActive) _timer.cancel();
    setState(() {
      _answerSelected = true;
      _selectedAnswer = selectedAnswer;
      _correctAnswer = question.correctAnswer;
      _answeredQuestionIds.add(question.id);

      if (selectedAnswer == question.correctAnswer) {
        _score += _calculatePoints();
      }
    });
  }

  int _calculatePoints() {
    final maxTime = _getTimeLimitForDifficulty();
    final timeBonus = (_timeLeft / maxTime * 10).clamp(0, 10).round();
    return 10 + timeBonus;
  }

  Color _getOptionColor(String option, QuizQuestion question) {
    if (!_answerSelected) return Colors.transparent;
    if (option == question.correctAnswer) return Colors.green.withOpacity(0.3);
    if (option == _selectedAnswer) return Colors.red.withOpacity(0.3);
    return Colors.transparent;
  }

  @override
  void dispose() {
    if (_timerInitialized) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '${widget.category.name} - ${widget.difficulty}',
      ),
      body: FutureBuilder<List<QuizQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune question disponible'));
          }

          final questions = snapshot.data!;
          _questions = questions;

          if (_currentQuestionIndex >= questions.length) {
            return _buildResults(questions.length);
          }

          final currentQuestion = questions[_currentQuestionIndex];

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Temps restant: $_timeLeft sec',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Score: $_score',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: _timeLeft / _getTimeLimitForDifficulty(),
                backgroundColor: Colors.grey[300],
                color: _timeLeft > 5 ? Colors.deepPurple : Colors.red,
                minHeight: 8,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1}/${questions.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentQuestion.question,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ...currentQuestion.options.map(
                          (option) => _buildOptionButton(option, currentQuestion),
                    ),
                    const SizedBox(height: 20),
                    if (_answerSelected)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.deepPurple,
                          ),
                          onPressed: _goToNextQuestion,
                          child: Text(
                            _currentQuestionIndex < questions.length - 1
                                ? 'Question suivante'
                                : 'Voir les résultats',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOptionButton(String option, QuizQuestion question) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: _answerSelected ? null : () => _checkAnswer(option, question),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getOptionColor(option, question),
            border: Border.all(
              color: _answerSelected && option == _correctAnswer
                  ? Colors.green
                  : Colors.grey,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
                    color: _answerSelected && option == _correctAnswer
                        ? Colors.green
                        : Colors.black,
                  ),
                ),
              ),
              if (_answerSelected && option == _correctAnswer)
                const Icon(Icons.check_circle, color: Colors.green),
              if (_answerSelected &&
                  option == _selectedAnswer &&
                  option != _correctAnswer)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveScore(int totalQuestions) async {
    try {
      await _scoreService.updateUserStats(
        categoryId: widget.category.id,
        categoryName: widget.category.name,
        difficulty: widget.difficulty,
        score: _score,
        maxPossible: totalQuestions * 20,
        isCorrect: _score > 0,
        answeredQuestionIds: _answeredQuestionIds,
      );
    } catch (e) {
      debugPrint('Erreur sauvegarde score: $e');
    }
  }


  Widget _buildResults(int totalQuestions) {
    final maxPossibleScore = totalQuestions * 20;
    final double percentage = (_score / maxPossibleScore * 100).clamp(0, 100);

    // Détermine le trophée en fonction du pourcentage
    Widget _buildTrophy() {
      if (percentage >= 90) {
        return const Icon(Icons.emoji_events, size: 80, color: Colors.amber);
      } else if (percentage >= 70) {
        return const Icon(Icons.workspace_premium, size: 80, color: Colors.blue);
      } else if (percentage >= 50) {
        return const Icon(Icons.star, size: 80, color: Colors.purple);
      } else {
        return const Icon(Icons.help_outline, size: 80, color: Colors.grey);
      }
    }


    String _getResultMessage() {
      if (percentage >= 90) {
        return 'Excellent !';
      } else if (percentage >= 70) {
        return 'Très bien !';
      } else if (percentage >= 50) {
        return 'Bon travail';
      } else {
        return 'Continuez à vous entraîner';
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveScore(totalQuestions);
    });

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTrophy(), // Trophée dynamique
            const SizedBox(height: 20),
            Text(
              'Quiz terminé !',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getResultMessage(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'Score final',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$_score/${totalQuestions * 20}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${percentage.toStringAsFixed(1)}% de réussite',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[300],
                    color: _getPercentageColor(percentage),
                    minHeight: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) =>  HomeScreen()),
                        (route) => false,
                  );
                },
                child: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),

              ),
            ),
          ],
        ),
      ),
    );
  }

// Fonction utilitaire pour la couleur de la barre de progression
  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.blue;
    return Colors.orange;
  }
}