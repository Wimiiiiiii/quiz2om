import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = 'quiz2om.db';
  static const _databaseVersion = 1;

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Création des tables
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE quizzes (
        id TEXT PRIMARY KEY,
        categoryId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        questionCount INTEGER NOT NULL,
        imageUrl TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        quizId TEXT NOT NULL,
        text TEXT NOT NULL,
        explanation TEXT,
        FOREIGN KEY (quizId) REFERENCES quizzes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE answers (
        id TEXT PRIMARY KEY,
        questionId TEXT NOT NULL,
        text TEXT NOT NULL,
        isCorrect INTEGER NOT NULL, -- 0 for false, 1 for true
        FOREIGN KEY (questionId) REFERENCES questions (id)
      )
    ''');

    // Insertion des données initiales
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // Insertion des catégories
    await db.insert('categories', {
      'id': '1',
      'name': 'Technologie',
      'icon': '💻',
      'color': Colors.blue.value,
      'description': 'Quiz sur les nouvelles technologies et programmation',
    });

    // Insertion des quiz
    await db.insert('quizzes', {
      'id': '1',
      'categoryId': '1',
      'title': 'Technologie Débutant',
      'description': 'Niveau facile pour commencer',
      'difficulty': 'Facile',
      'questionCount': 10,
      'imageUrl': '',
    });

    // Vous pouvez ajouter plus de données ici...
  }
}