import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSeedScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminSeedScreen({super.key});

  Future<void> _seedCategoriesAndQuestions() async {
    // 1. Catégories
    final categories = [
      {'name': 'Technologie', 'imageUrl': ''},
      {'name': 'Histoire', 'imageUrl': ''},
      {'name': 'Géographie', 'imageUrl': ''},
      {'name': 'Sciences', 'imageUrl': ''},
      {'name': 'Cinéma', 'imageUrl': ''},
    ];

    for (final cat in categories) {
      // 2. Ajouter la catégorie
      final docRef = await _firestore.collection('categories').add(cat);
      
      // 3. Ajouter les questions pour cette catégorie
      await _addQuestionsForCategory(docRef.id, cat['name']!);
    }
  }

  Future<void> _addQuestionsForCategory(String categoryId, String categoryName) async {
  if (categoryName == 'Technologie') {
    final questions = {
      'facile': [
        {
          'question': 'Quel langage est utilisé pour styliser les pages web?',
          'options': ['HTML', 'CSS', 'JavaScript', 'Python'],
          'correctAnswer': 'CSS',
          'timeLimit': 30,
        },
        {
          'question': 'Quel est le système d\'exploitation développé par Apple?',
          'options': ['Windows', 'macOS', 'Linux', 'Android'],
          'correctAnswer': 'macOS',
          'timeLimit': 30,
        },
        {
          'question': 'Quel composant est considéré comme le "cerveau" d\'un ordinateur?',
          'options': ['CPU', 'GPU', 'RAM', 'SSD'],
          'correctAnswer': 'CPU',
          'timeLimit': 30,
        },
        {
          'question': 'Quel réseau social appartient à Meta?',
          'options': ['Twitter', 'Instagram', 'LinkedIn', 'TikTok'],
          'correctAnswer': 'Instagram',
          'timeLimit': 30,
        },
        {
          'question': 'Quelle extension de fichier est utilisée pour les fichiers JavaScript?',
          'options': ['.js', '.java', '.py', '.html'],
          'correctAnswer': '.js',
          'timeLimit': 30,
        },
      ],
      'moyen': [
        {
          'question': 'Quel protocole est utilisé pour sécuriser les connexions HTTP?',
          'options': ['FTP', 'HTTPS', 'SMTP', 'TCP'],
          'correctAnswer': 'HTTPS',
          'timeLimit': 25,
        },
        {
          'question': 'Quel langage de programmation a été créé par Google?',
          'options': ['Kotlin', 'Dart', 'Swift', 'TypeScript'],
          'correctAnswer': 'Dart',
          'timeLimit': 25,
        },
        {
          'question': 'Quelle technologie est utilisée pour le développement d\'applications mobiles iOS?',
          'options': ['Flutter', 'React Native', 'Swift', 'Kotlin'],
          'correctAnswer': 'Swift',
          'timeLimit': 25,
        },
        {
          'question': 'Quel est le nom du premier ordinateur électronique programmable?',
          'options': ['ENIAC', 'UNIVAC', 'Colossus', 'IBM 701'],
          'correctAnswer': 'Colossus',
          'timeLimit': 25,
        },
        {
          'question': 'Quelle entreprise a développé le langage Python?',
          'options': ['Google', 'Microsoft', 'Facebook', 'Aucune de ces réponses'],
          'correctAnswer': 'Aucune de ces réponses',
          'timeLimit': 25,
        },
      ],
      'difficile': [
        {
          'question': 'Quelle structure de données utilise le principe LIFO?',
          'options': ['File', 'Pile', 'Arbre', 'Graphe'],
          'correctAnswer': 'Pile',
          'timeLimit': 20,
        },
        {
          'question': 'Quel algorithme de tri a une complexité temporelle dans le pire des cas de O(n log n)?',
          'options': ['Tri à bulles', 'Tri par insertion', 'Tri fusion', 'Tri rapide'],
          'correctAnswer': 'Tri fusion',
          'timeLimit': 20,
        },
        {
          'question': 'En quelle année a été créé le langage C++?',
          'options': ['1972', '1983', '1995', '2001'],
          'correctAnswer': '1983',
          'timeLimit': 20,
        },
        {
          'question': 'Quel paradigme de programmation est utilisé par React?',
          'options': ['Programmation orientée objet', 'Programmation fonctionnelle', 'Programmation logique', 'Programmation impérative'],
          'correctAnswer': 'Programmation fonctionnelle',
          'timeLimit': 20,
        },
        {
          'question': 'Quel est le nom du premier virus informatique?',
          'options': ['ILOVEYOU', 'Melissa', 'Creeper', 'MyDoom'],
          'correctAnswer': 'Creeper',
          'timeLimit': 20,
        },
      ],
    };

    for (final difficulty in questions.keys) {
      for (final q in questions[difficulty]!) {
        await _firestore.collection('questions').add({
          ...q,
          'categoryId': categoryId,
          'difficulty': difficulty,
        });
      }
    }
  }
  else if (categoryName == 'Géographie') {
    final questions = {
      'facile': [
        {
          'question': 'Quel est le plus grand océan du monde?',
          'options': ['Atlantique', 'Indien', 'Pacifique', 'Arctique'],
          'correctAnswer': 'Pacifique',
          'timeLimit': 30,
        },
        {
          'question': 'Quelle est la capitale de la France?',
          'options': ['Lyon', 'Marseille', 'Paris', 'Toulouse'],
          'correctAnswer': 'Paris',
          'timeLimit': 30,
        },
        {
          'question': 'Quel pays est surnommé "le pays du soleil levant"?',
          'options': ['Chine', 'Corée du Sud', 'Japon', 'Thaïlande'],
          'correctAnswer': 'Japon',
          'timeLimit': 30,
        },
        {
          'question': 'Quelle chaîne de montagnes sépare l\'Europe de l\'Asie?',
          'options': ['Les Alpes', 'L\'Himalaya', 'Les Andes', 'L\'Oural'],
          'correctAnswer': 'L\'Oural',
          'timeLimit': 30,
        },
        {
          'question': 'Quel est le plus grand désert chaud du monde?',
          'options': ['Gobi', 'Sahara', 'Kalahari', 'Arabie'],
          'correctAnswer': 'Sahara',
          'timeLimit': 30,
        },
      ],
      'moyen': [
        {
          'question': 'Quelle est la plus longue rivière d\'Afrique?',
          'options': ['Nil', 'Congo', 'Niger', 'Zambèze'],
          'correctAnswer': 'Nil',
          'timeLimit': 25,
        },
        {
          'question': 'Dans quel pays se trouve le monument Angkor Wat?',
          'options': ['Thaïlande', 'Cambodge', 'Vietnam', 'Laos'],
          'correctAnswer': 'Cambodge',
          'timeLimit': 25,
        },
        {
          'question': 'Quelle ville est située sur deux continents?',
          'options': ['Istanbul', 'Moscou', 'Le Caire', 'Dubai'],
          'correctAnswer': 'Istanbul',
          'timeLimit': 25,
        },
        {
          'question': 'Quel pays a la forme d\'une botte?',
          'options': ['Grèce', 'Espagne', 'Italie', 'Portugal'],
          'correctAnswer': 'Italie',
          'timeLimit': 25,
        },
        {
          'question': 'Quel est le plus petit pays du monde?',
          'options': ['Monaco', 'Nauru', 'Vatican', 'San Marin'],
          'correctAnswer': 'Vatican',
          'timeLimit': 25,
        },
      ],
      'difficile': [
        {
          'question': 'Quelle est la capitale de l\'Australie?',
          'options': ['Sydney', 'Melbourne', 'Canberra', 'Perth'],
          'correctAnswer': 'Canberra',
          'timeLimit': 20,
        },
        {
          'question': 'Quel pays n\'a pas de fleuve?',
          'options': ['Arabie Saoudite', 'Koweït', 'Malte', 'Maldives'],
          'correctAnswer': 'Arabie Saoudite',
          'timeLimit': 20,
        },
        {
          'question': 'Quelle mer baigne Saint-Pétersbourg?',
          'options': ['Mer Noire', 'Mer Baltique', 'Mer Caspienne', 'Mer Blanche'],
          'correctAnswer': 'Mer Baltique',
          'timeLimit': 20,
        },
        {
          'question': 'Quel est le seul continent traversé par tous les méridiens?',
          'options': ['Afrique', 'Asie', 'Amérique', 'Antarctique'],
          'correctAnswer': 'Antarctique',
          'timeLimit': 20,
        },
        {
          'question': 'Quel pays possède le plus de fuseaux horaires?',
          'options': ['États-Unis', 'Russie', 'Chine', 'France'],
          'correctAnswer': 'France',
          'timeLimit': 20,
        },
      ],
    };

    for (final difficulty in questions.keys) {
      for (final q in questions[difficulty]!) {
        await _firestore.collection('questions').add({
          ...q,
          'categoryId': categoryId,
          'difficulty': difficulty,
        });
      }
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title:  'Admin Seed'),
      body: Center(
        child: ElevatedButton(
          child: const Text('Peupler la base de données'),
          onPressed: () async {
            await _seedCategoriesAndQuestions();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Données ajoutées avec succès!')),
            );
          },
        ),
      ),
    );
  }
}