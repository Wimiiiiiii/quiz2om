import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService supabaseService = SupabaseService();
  List<Map<String, dynamic>> categories = [];
  String selectedMode = ''; // Solo ou Multijoueur

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await supabaseService.fetchCategories();
      if (mounted) {
        setState(() {
          categories = data;
        });
      }
    } catch (e) {
      // Affiche une erreur en cas de problème avec Supabase
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du chargement des catégories')),
      );
    }
  }

  // Afficher le dialogue pour choisir le mode (Solo ou Multijoueur)
  void _showModeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisir le mode de jeu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Solo'),
                value: 'Solo',
                groupValue: selectedMode,
                onChanged: (String? value) {
                  setState(() {
                    selectedMode = value!;
                  });
                  Navigator.pop(context); // Fermer le dialogue après la sélection
                },
              ),
              RadioListTile<String>(
                title: const Text('Multijoueur'),
                value: 'Multijoueur',
                groupValue: selectedMode,
                onChanged: (String? value) {
                  setState(() {
                    selectedMode = value!;
                  });
                  Navigator.pop(context); // Fermer le dialogue après la sélection
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.pop(context); // Fermer le dialogue sans sélection
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz2OM – Catégories'),
      ),
      body: categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Afficher le bouton pour choisir le mode
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _showModeDialog,
              child: const Text('Choisir le mode de jeu'),
            ),
          ),
          // Afficher la liste des catégories après la sélection du mode
          if (selectedMode.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return ListTile(
                    title: Text(cat['name'] ?? 'Inconnue'),
                    leading: Icon(Icons.category),
                    tileColor: Colors.grey[200],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            categoryId: cat['id'],
                            mode: selectedMode, // Passer le mode sélectionné
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          // Si aucun mode n'est sélectionné, afficher un message
          if (selectedMode.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Veuillez choisir un mode de jeu'),
              ),
            ),
        ],
      ),
    );
  }
}
