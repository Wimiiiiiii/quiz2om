class UserStats {
  final String userId;
  final int totalScore;
  final Map<String, CategoryStats> categories;

  UserStats({
    required this.userId,
    required this.totalScore,
    required this.categories,
  });

  factory UserStats.fromFirestore(Map<String, dynamic> data) {
    return UserStats(
      userId: data['userId'],
      totalScore: data['totalScore'] ?? 0,
      categories: (data['categories'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, CategoryStats.fromMap(value)),
      ) ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalScore': totalScore,
      'categories': categories.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}

class CategoryStats {
  final int totalAnswered;
  final int correctAnswers;
  final int totalScore;

  CategoryStats({
    required this.totalAnswered,
    required this.correctAnswers,
    required this.totalScore,
  });

  double get successRate => totalAnswered > 0
      ? (correctAnswers / totalAnswered * 100)
      : 0;

  factory CategoryStats.fromMap(Map<String, dynamic> map) {
    return CategoryStats(
      totalAnswered: map['totalAnswered'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      totalScore: map['totalScore'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalAnswered': totalAnswered,
      'correctAnswers': correctAnswers,
      'totalScore': totalScore,
    };
  }
}