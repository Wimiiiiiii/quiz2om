import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizScreen extends StatefulWidget {
  final String categoryId;
  final String mode;

  const QuizScreen({super.key, required this.categoryId, required this.mode});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> quizzes = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool isAnswered = false;
  String selectedAnswer = '';

  // Subscription à Supabase Realtime
  late final RealtimeSubscription _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
    if (widget.mode == 'Multijoueur') {
      _setupRealtime();
    }
  }

  Future<void> _loadQuizzes() async {
    final response = await _supabase
        .from('quizzes')
        .select('*')
        .eq('category_id', widget.categoryId)
        .execute();
    if (response.error == null) {
      setState(() {
        quizzes = List<Map<String, dynamic>>.from(response.data);
      });
    } else {
      print("Erreur lors du chargement des quiz: ${response.error?.message}");
    }
  }

  // Configuration de la gestion en temps réel
  void _setupRealtime() {
    _realtimeSubscription = _supabase
        .from('scores') // Table que tu souhaites écouter
        .on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: 'INSERT'), (payload) {
      // Traite les changements en temps réel ici
      print('Changement en temps réel: $payload');
      // Par exemple, on pourrait mettre à jour l'UI en fonction des changements
    })
        .subscribe();
  }

  void _checkAnswer(String answer) {
    setState(() {
      selectedAnswer = answer;
      isAnswered = true;
      if (answer == quizzes[currentQuestionIndex]['answer']) {
        score++;
      }
      if (widget.mode == 'Multijoueur') {
        _sendScoreToServer();
      }
    });
  }

  void _sendScoreToServer() {
    _supabase.from('scores').insert([
      {
        'player_id': 'user_id', // Utiliser l'ID du joueur
        'score': score,
        'question_index': currentQuestionIndex
      }
    ]);
  }

  void _nextQuestion() {
    setState(() {
      currentQuestionIndex++;
      isAnswered = false;
      selectedAnswer = '';
    });
  }

  @override
  void dispose() {
    super.dispose();
    // N'oublie pas de désabonner du canal lorsque l'écran est fermé
    _realtimeSubscription.unsubscribe();
  }

  @override
  Widget build(BuildContext context) {
    if (quizzes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentQuestion = quizzes[currentQuestionIndex];
    final options = List<String>.from(currentQuestion['options']);

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz – ${widget.mode}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Question ${currentQuestionIndex + 1}/${quizzes.length}',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              currentQuestion['question'],
              style: const TextStyle(fontSize: 22),
            ),
          ),
          ...options.map((option) {
            return ListTile(
              title: Text(option),
              leading: Radio<String>(
                value: option,
                groupValue: selectedAnswer,
                onChanged: isAnswered
                    ? null
                    : (String? value) {
                  if (value != null) {
                    _checkAnswer(value);
                  }
                },
              ),
            );
          }).toList(),
          if (isAnswered)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    selectedAnswer == currentQuestion['answer']
                        ? 'Correct!'
                        : 'Incorrect!',
                    style: TextStyle(
                      color: selectedAnswer == currentQuestion['answer']
                          ? Colors.green
                          : Colors.red,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'La bonne réponse était : ${currentQuestion['answer']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: isAnswered
                  ? currentQuestionIndex + 1 < quizzes.length
                  ? _nextQuestion
                  : () {
                // Fin du quiz, afficher les résultats
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Fin du Quiz'),
                    content: Text('Votre score est $score/${quizzes.length}'),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context); // Retour à l'écran d'accueil
                        },
                      ),
                    ],
                  ),
                );
              }
                  : null,
              child: currentQuestionIndex + 1 < quizzes.length
                  ? const Text('Suivant')
                  : const Text('Terminer'),
            ),
          ),
        ],
      ),
    );
  }
}

extension on PostgrestResponse {
  get error => null;
}
