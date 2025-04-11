class Quiz {
  final String id;
  final String categoryId;
  final String title;
  final String description;
  final String difficulty;
  final int questionCount;
  final String imageUrl;

  Quiz({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.questionCount,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'questionCount': questionCount,
      'imageUrl': imageUrl,
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'],
      categoryId: map['categoryId'],
      title: map['title'],
      description: map['description'],
      difficulty: map['difficulty'],
      questionCount: map['questionCount'],
      imageUrl: map['imageUrl'],
    );
  }
}