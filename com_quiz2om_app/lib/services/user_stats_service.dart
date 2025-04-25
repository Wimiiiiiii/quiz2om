import 'package:com_quiz2om_app/models/user_stats.dart';
import 'package:com_quiz2om_app/services/score_services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserStatsService {
  final ScoreService _scoreService;
  final FirebaseAuth _firebaseAuth;

  // Injection de dépendances pour une meilleure testabilité
  UserStatsService({
    ScoreService? scoreService,
    FirebaseAuth? firebaseAuth,
  })  : _scoreService = scoreService ?? ScoreService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<int> getGlobalRanking() async {
    final leaderboard = await _scoreService.getLeaderboard();
    final userId = _firebaseAuth.currentUser?.uid;

    if (userId == null) return 0;
    if (leaderboard.isEmpty) return 0;

    final index = leaderboard.indexWhere((user) => user['userId'] == userId);
    return index != -1 ? index + 1 : 0;
  }

  Future<Map<String, double>> getCategorySuccessRates() async {
    final stats = await getUserStats();
    final Map<String, List<CategoryStats>> categoryGroups = {};

    // Grouper les stats par catégorie (en ignorant la difficulté)
    stats.categories.forEach((compositeKey, categoryStats) {
      final categoryId = compositeKey.split('_')[0]; // Extrait juste l'ID de catégorie
      categoryGroups.update(
        categoryId,
            (existing) => [...existing, categoryStats],
        ifAbsent: () => [categoryStats],
      );
    });

    // Calculer les taux de réussite agrégés
    return categoryGroups.map((categoryId, statsList) {
      final totalAnswered = statsList.fold<int>(
          0,
              (sum, stat) => sum + stat.totalAnswered
      );

      final correctAnswers = statsList.fold<int>(
          0,
              (sum, stat) => sum + stat.correctAnswers
      );

      final successRate = totalAnswered > 0
          ? (correctAnswers / totalAnswered * 100)
          : 0.0;

      return MapEntry(categoryId, successRate);
    });
  }

  Future<UserStats> getUserStats() => _scoreService.getUserStats();
}