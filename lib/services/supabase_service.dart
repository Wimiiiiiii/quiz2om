import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  // 🔁 Charger toutes les catégories
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final response = await supabase.from('categories').select().execute();
      if (response.error != null) {
        throw response.error!;
      }
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      // Ajouter la gestion des erreurs
      print('Erreur lors du chargement des catégories : $e');
      return [];
    }
  }

  // 📥 Charger les quiz d'une catégorie
  Future<List<Map<String, dynamic>>> fetchQuizzes(String categoryId) async {
    try {
      final response = await supabase
          .from('quizzes')
          .select()
          .eq('category_id', categoryId)
          .execute();
      if (response.error != null) {
        throw response.error!;
      }
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      // Ajouter la gestion des erreurs
      print('Erreur lors du chargement des quiz : $e');
      return [];
    }
  }

  // ➕ Ajouter un quiz
  Future<void> addQuiz({
    required String question,
    required List<String> options,
    required String answer,
    required String categoryId,
  }) async {
    try {
      final response = await supabase.from('quizzes').insert({
        'question': question,
        'options': options,
        'answer': answer,
        'category_id': categoryId,
      }).execute();
      if (response.error != null) {
        throw response.error!;
      }
      print("Quiz ajouté avec succès !");
    } catch (e) {
      // Gestion des erreurs lors de l'insertion
      print('Erreur lors de l\'ajout du quiz : $e');
    }
  }

  // ➕ Ajouter une catégorie
  Future<void> addCategory(String name, String icon, String color) async {
    try {
      final response = await supabase.from('categories').insert({
        'name': name,
        'icon': icon,
        'color': color,
      }).execute();
      if (response.error != null) {
        throw response.error!;
      }
      print("Catégorie ajoutée avec succès !");
    } catch (e) {
      // Gestion des erreurs lors de l'insertion
      print('Erreur lors de l\'ajout de la catégorie : $e');
    }
  }
}

extension on PostgrestResponse {
  get error => null;
}
