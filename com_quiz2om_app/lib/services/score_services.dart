import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_stats.dart';

class ScoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Injection de dépendances pour la testabilité
  ScoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> updateUserStats({
    required String categoryId,
    required String categoryName,
    required String difficulty,
    required int score,
    required int maxPossible,
    required bool isCorrect,
    required List<String> answeredQuestionIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final statsRef = _firestore.collection('user_stats').doc(user.uid);

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Récupération des données existantes
        final statsDoc = await transaction.get(statsRef);
        final currentStats = statsDoc.exists
            ? UserStats.fromFirestore(statsDoc.data()! as Map<String, dynamic>)
            : UserStats(userId: user.uid, totalScore: 0, categories: {});

        // 2. Vérification des questions déjà répondues
        final questionsRef = _firestore.collection('user_answered_questions')
            .doc(user.uid)
            .collection('${categoryId}_$difficulty');

        final existingQuestions = await _getExistingQuestions(
          transaction,
          questionsRef,
          answeredQuestionIds,
        );

        // 3. Calcul des nouvelles statistiques
        final newQuestionsCount = answeredQuestionIds.length - existingQuestions.length;
        final shouldCountScore = newQuestionsCount > 0;
        final shouldCountCorrect = isCorrect && shouldCountScore;

        // 4. Mise à jour des stats de catégorie
        final categoryKey = '${categoryId}_$difficulty';
        final categoryStats = currentStats.categories[categoryKey] ??
            CategoryStats(totalAnswered: 0, correctAnswers: 0, totalScore: 0);

        final updatedCategoryStats = CategoryStats(
          totalAnswered: categoryStats.totalAnswered + newQuestionsCount,
          correctAnswers: categoryStats.correctAnswers + (shouldCountCorrect ? 1 : 0),
          totalScore: categoryStats.totalScore + (shouldCountScore ? score : 0),
        );

        // 5. Création de l'objet UserStats mis à jour
        final updatedStats = UserStats(
          userId: user.uid,
          totalScore: currentStats.totalScore + (shouldCountScore ? score : 0),
          categories: {
            ...currentStats.categories,
            categoryKey: updatedCategoryStats,
          },
        );

        // 6. Enregistrement des nouvelles questions
        await _recordNewQuestions(
          transaction,
          questionsRef,
          answeredQuestionIds,
          existingQuestions,
        );

        // 7. Sauvegarde des statistiques
        transaction.set(statsRef, updatedStats.toMap());

        // 8. Mise à jour du profil utilisateur
        transaction.update(userRef, {
          'totalScore': updatedStats.totalScore,
          'lastPlayed': FieldValue.serverTimestamp(),
        });
      });

      // 9. Enregistrement de l'historique (en dehors de la transaction)
      await _recordQuizHistory(
        userId: user.uid,
        categoryId: categoryId,
        categoryName: categoryName,
        difficulty: difficulty,
        score: score,
        maxPossible: maxPossible,
        answeredQuestionIds: answeredQuestionIds,
      );
    } catch (e) {
      print('Error updating user stats: $e');
      rethrow;
    }
  }

  Future<Set<String>> _getExistingQuestions(
      Transaction transaction,
      CollectionReference questionsRef,
      List<String> questionIds,
      ) async {
    final existingQuestions = <String>{};
    for (final questionId in questionIds) {
      final doc = await transaction.get(questionsRef.doc(questionId));
      if (doc.exists) {
        existingQuestions.add(questionId);
      }
    }
    return existingQuestions;
  }

  Future<void> _recordNewQuestions(
      Transaction transaction,
      CollectionReference questionsRef,
      List<String> answeredQuestionIds,
      Set<String> existingQuestions,
      ) async {
    for (final questionId in answeredQuestionIds) {
      if (!existingQuestions.contains(questionId)) {
        transaction.set(
          questionsRef.doc(questionId),
          {
            'questionId': questionId,
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
      }
    }
  }

  Future<void> _recordQuizHistory({
    required String userId,
    required String categoryId,
    required String categoryName,
    required String difficulty,
    required int score,
    required int maxPossible,
    required List<String> answeredQuestionIds,
  }) async {
    try {
      await _firestore.collection('quiz_history').add({
        'userId': userId,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'difficulty': difficulty,
        'score': score,
        'maxPossible': maxPossible,
        'percentage': maxPossible > 0 ? (score / maxPossible * 100).round() : 0,
        'timestamp': FieldValue.serverTimestamp(),
        'questionIds': answeredQuestionIds,
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error recording quiz history: $e');
    }
  }

  Future<UserStats> getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final doc = await _firestore.collection('user_stats').doc(user.uid).get();
      return doc.exists
          ? UserStats.fromFirestore(doc.data()! as Map<String, dynamic>)
          : UserStats(userId: user.uid, totalScore: 0, categories: {});
    } catch (e) {
      print('Error getting user stats: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final snapshot = await _firestore.collection('users')
          .orderBy('totalScore', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'name': data['name'] ?? 'Anonymous',
          'totalScore': data['totalScore'] ?? 0,
          'avatar': data['avatarUrl'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserRanking(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return {'rank': 0, 'totalUsers': 0};

      final userScore = userDoc.data()?['totalScore'] ?? 0;
      final higherUsers = await _firestore.collection('users')
          .where('totalScore', isGreaterThan: userScore)
          .count()
          .get();

      return {
        'rank': higherUsers.count! + 1,
        'totalUsers': (await _firestore.collection('users').count().get()).count,
      };
    } catch (e) {
      print('Error getting user ranking: $e');
      return {'rank': 0, 'totalUsers': 0};
    }
  }
}