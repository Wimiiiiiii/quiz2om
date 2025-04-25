import 'package:cloud_firestore/cloud_firestore.dart';

class QuizCategory {
  final String id;
  final String name;
  final String? imageUrl;

  QuizCategory({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory QuizCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizCategory(
      id: doc.id,
      name: data['name'],
      imageUrl: data['imageUrl'],
    );
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String difficulty;
  final int timeLimit;
  final String categoryId;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
    required this.timeLimit,
    required this.categoryId,
  });

  factory QuizQuestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizQuestion(
      id: doc.id,
      question: data['question'],
      options: List<String>.from(data['options']),
      correctAnswer: data['correctAnswer'],
      difficulty: data['difficulty'],
      timeLimit: data['timeLimit'],
      categoryId: data['categoryId'],
    );
  }
}