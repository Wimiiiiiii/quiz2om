import 'dart:async';

import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:com_quiz2om_app/models/quiz_models.dart';

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

class _QuizScreenState extends State<QuizScreen> {
  late Future<List<QuizQuestion>> _questionsFuture;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _timeLeft = 30;
  late Timer _timer;
  bool _answerSelected = false;
  String? _selectedAnswer;
  String? _correctAnswer;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _fetchQuestions();
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

  void _startTimer(QuizQuestion question) {
    _timeLeft = question.timeLimit;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer.cancel();
          _goToNextQuestion();
        }
      });
    });
  }

  void _goToNextQuestion() {
    _timer.cancel();
    setState(() {
      _currentQuestionIndex++;
      _answerSelected = false;
      _selectedAnswer = null;
      _correctAnswer = null;
    });
  }

  void _checkAnswer(String selectedAnswer, QuizQuestion question) {
    _timer.cancel();
    setState(() {
      _answerSelected = true;
      _selectedAnswer = selectedAnswer;
      _correctAnswer = question.correctAnswer;

      if (selectedAnswer == question.correctAnswer) {
        _score += _calculatePoints(question.timeLimit);
      }
    });
  }

  int _calculatePoints(int baseTime) {
    // Plus de points si réponse rapide
    final timeBonus = (_timeLeft / baseTime * 10).round();
    return 10 + timeBonus;
  }

  Color _getOptionColor(String option, QuizQuestion question) {
    if (!_answerSelected) return Colors.transparent;

    if (option == question.correctAnswer) {
      return Colors.green.withOpacity(0.3);
    } else if (option == _selectedAnswer && option != question.correctAnswer) {
      return Colors.red.withOpacity(0.3);
    }
    return Colors.transparent;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: ('${widget.category.name} - ${widget.difficulty}'),
      ),
      body: FutureBuilder<List<QuizQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(child: Text('Aucune question disponible'));
          }

          final questions = snapshot.data!;

          if (_currentQuestionIndex >= questions.length) {
            return _buildResults(questions.length);
          }

          final currentQuestion = questions[_currentQuestionIndex];
          _startTimer(currentQuestion);

          return Column(
            children: [
              LinearProgressIndicator(
                value: _timeLeft / currentQuestion.timeLimit,
                backgroundColor: Colors.grey[300],
                color: Colors.deepPurple,
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
                    const SizedBox(height: 10),
                    Text(
                      'Score: $_score',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentQuestion.question,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 30),
                    ...currentQuestion.options.map(
                      (option) => _buildOptionButton(option, currentQuestion),
                    ),
                    const SizedBox(height: 20),
                    if (_answerSelected)
                      ElevatedButton(
                        onPressed: _goToNextQuestion,
                        child: Text(
                          _currentQuestionIndex < questions.length - 1
                              ? 'Question suivante'
                              : 'Voir les résultats',
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
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(child: Text(option)),
              if (_answerSelected && option == _correctAnswer)
                const Icon(Icons.check, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _saveScore(int totalQuestions) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('user_scores').add({
        'userId': user.uid,
        'category': widget.category.name,
        'categoryId': widget.category.id,
        'difficulty': widget.difficulty,
        'score': _score,
        'maxPossible': totalQuestions * 15,
        'percentage': (_score / (totalQuestions * 15) * 100).round(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  } catch (e) {
    debugPrint('Erreur sauvegarde score: $e');
  }
}

  Widget _buildResults(int totalQuestions) {
    // Sauvegarde quand l'écran de résultats apparaît
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveScore(totalQuestions);
    });
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Quiz terminé !',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'Score final: $_score/${totalQuestions * 15}',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 10),
          Text(
            'Réussite: ${(_score / (totalQuestions * 15) * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    );
  }
}
