import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/quiz.dart';
import '../services/database_helper.dart';

class QuizService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Category>> getAllCategories() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('categories');
      return List.generate(maps.length, (i) {
        return Category(
          id: maps[i]['id'],
          name: maps[i]['name'],
          icon: maps[i]['icon'],
          color: Color(maps[i]['color']),
          description: maps[i]['description'],
        );
      });
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }

  Future<List<Quiz>> getQuizzesByCategory(String categoryId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'quizzes',
        where: 'categoryId = ?',
        whereArgs: [categoryId],
      );
      return List.generate(maps.length, (i) {
        return Quiz(
          id: maps[i]['id'],
          categoryId: maps[i]['categoryId'],
          title: maps[i]['title'],
          description: maps[i]['description'],
          difficulty: maps[i]['difficulty'],
          questionCount: maps[i]['questionCount'],
          imageUrl: maps[i]['imageUrl'] ?? '',
        );
      });
    } catch (e) {
      debugPrint('Error getting quizzes: $e');
      return [];
    }
  }

  Future<int> addCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> addQuiz(Quiz quiz) async {
    final db = await _dbHelper.database;
    return await db.insert('quizzes', quiz.toMap());
  }
}