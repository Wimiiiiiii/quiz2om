import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      // Cherche si la catégorie existe déjà
      final existing = await _firestore
          .collection('categories')
          .where('name', isEqualTo: cat['name'])
          .get();

      String categoryId;
      if (existing.docs.isNotEmpty) {
        categoryId = existing.docs.first.id;
      } else {
        final docRef = await _firestore.collection('categories').add(cat);
        categoryId = docRef.id;
      }
      // Ajoute les questions pour cette catégorie
      await _addQuestionsForCategory(categoryId, cat['name']!);
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
          // Vérifie si la question existe déjà
          final existing = await _firestore
              .collection('questions')
              .where('question', isEqualTo: q['question'])
              .where('categoryId', isEqualTo: categoryId)
              .where('difficulty', isEqualTo: difficulty)
              .get();

          if (existing.docs.isEmpty) {
            await _firestore.collection('questions').add({
              ...q,
              'categoryId': categoryId,
              'difficulty': difficulty,
            });
          }
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
          // Vérifie si la question existe déjà
          final existing = await _firestore
              .collection('questions')
              .where('question', isEqualTo: q['question'])
              .where('categoryId', isEqualTo: categoryId)
              .where('difficulty', isEqualTo: difficulty)
              .get();

          if (existing.docs.isEmpty) {
            await _firestore.collection('questions').add({
              ...q,
              'categoryId': categoryId,
              'difficulty': difficulty,
            });
          }
        }
      }
    }
    else if (categoryName == 'Sciences') {
      final questions = {
        'facile': [
          {
            'question': 'Quel est l\'organe principal de la respiration chez l\'humain ?',
            'options': ['Le cœur', 'Le foie', 'Le poumon', 'Le rein'],
            'correctAnswer': 'Le poumon',
            'timeLimit': 30,
          },
          {
            'question': 'Combien de planètes composent le système solaire ?',
            'options': ['7', '8', '9', '10'],
            'correctAnswer': '8',
            'timeLimit': 30,
          },
          {
            'question': 'Quel est l\'état de l\'eau à 100°C sous pression normale ?',
            'options': ['Solide', 'Liquide', 'Gazeux', 'Plasma'],
            'correctAnswer': 'Gazeux',
            'timeLimit': 30,
          },
          {
            'question': 'Quel scientifique a découvert la gravité ?',
            'options': ['Newton', 'Einstein', 'Galilée', 'Curie'],
            'correctAnswer': 'Newton',
            'timeLimit': 30,
          },
          {
            'question': 'Quel est le symbole chimique de l\'oxygène ?',
            'options': ['O', 'Ox', 'Og', 'Oy'],
            'correctAnswer': 'O',
            'timeLimit': 30,
          },
        ],
        'moyen': [
          {
            'question': 'Quel est le plus grand organe du corps humain ?',
            'options': ['Le foie', 'La peau', 'Le cerveau', 'Le cœur'],
            'correctAnswer': 'La peau',
            'timeLimit': 25,
          },
          {
            'question': 'Quel est l\'atome le plus léger ?',
            'options': ['Hydrogène', 'Hélium', 'Oxygène', 'Carbone'],
            'correctAnswer': 'Hydrogène',
            'timeLimit': 25,
          },
          {
            'question': 'Quel est le point d\'ébullition de l\'eau (en °C) ?',
            'options': ['0', '50', '100', '212'],
            'correctAnswer': '100',
            'timeLimit': 25,
          },
          {
            'question': 'Quel est le nom du processus par lequel les plantes fabriquent leur nourriture ?',
            'options': ['Respiration', 'Photosynthèse', 'Fermentation', 'Transpiration'],
            'correctAnswer': 'Photosynthèse',
            'timeLimit': 25,
          },
          {
            'question': 'Quel est le plus grand os du corps humain ?',
            'options': ['Fémur', 'Tibia', 'Humérus', 'Radius'],
            'correctAnswer': 'Fémur',
            'timeLimit': 25,
          },
        ],
        'difficile': [
          {
            'question': 'Quel est le nom du physicien qui a proposé la théorie de la relativité ?',
            'options': ['Newton', 'Einstein', 'Bohr', 'Planck'],
            'correctAnswer': 'Einstein',
            'timeLimit': 20,
          },
          {
            'question': 'Quel est le pH neutre ?',
            'options': ['0', '7', '14', '1'],
            'correctAnswer': '7',
            'timeLimit': 20,
          },
          {
            'question': 'Quel est l\'élément chimique dont le symbole est Fe ?',
            'options': ['Fer', 'Fluor', 'Francium', 'Fermium'],
            'correctAnswer': 'Fer',
            'timeLimit': 20,
          },
          {
            'question': 'Quel est le nom du premier homme à avoir marché sur la Lune ?',
            'options': ['Neil Armstrong', 'Buzz Aldrin', 'Youri Gagarine', 'Michael Collins'],
            'correctAnswer': 'Neil Armstrong',
            'timeLimit': 20,
          },
          {
            'question': 'Quel est le plus petit os du corps humain ?',
            'options': ['Étrier', 'Fémur', 'Scapula', 'Coccyx'],
            'correctAnswer': 'Étrier',
            'timeLimit': 20,
          },
        ],
      };

      for (final difficulty in questions.keys) {
        for (final q in questions[difficulty]!) {
          // Vérifie si la question existe déjà
          final existing = await _firestore
              .collection('questions')
              .where('question', isEqualTo: q['question'])
              .where('categoryId', isEqualTo: categoryId)
              .where('difficulty', isEqualTo: difficulty)
              .get();

          if (existing.docs.isEmpty) {
            await _firestore.collection('questions').add({
              ...q,
              'categoryId': categoryId,
              'difficulty': difficulty,
            });
          }
        }
      }
    }
    else if (categoryName == 'Histoire') {
      final questions = {
        'facile': [
          {
            'question': 'Qui était le premier président de la République française ?',
            'options': ['Napoléon Bonaparte', 'Louis XVI', 'Charles de Gaulle', 'Louis-Napoléon Bonaparte'],
            'correctAnswer': 'Louis-Napoléon Bonaparte',
            'timeLimit': 30,
          },
          {
            'question': 'En quelle année a eu lieu la Révolution française ?',
            'options': ['1789', '1815', '1914', '1492'],
            'correctAnswer': '1789',
            'timeLimit': 30,
          },
          {
            'question': 'Qui a découvert l\'Amérique ?',
            'options': ['Vasco de Gama', 'Christophe Colomb', 'Magellan', 'Marco Polo'],
            'correctAnswer': 'Christophe Colomb',
            'timeLimit': 30,
          },
          {
            'question': 'Quel mur est tombé en 1989 ?',
            'options': ['Mur de Chine', 'Mur de Berlin', 'Mur d\'Hadrien', 'Mur des Lamentations'],
            'correctAnswer': 'Mur de Berlin',
            'timeLimit': 30,
          },
          {
            'question': 'Qui était le roi de France pendant la Révolution française ?',
            'options': ['Louis XIV', 'Louis XV', 'Louis XVI', 'Louis XVIII'],
            'correctAnswer': 'Louis XVI',
            'timeLimit': 30,
          },
        ],
        'moyen': [
          {
            'question': 'Quel empire a construit le Colisée ?',
            'options': ['Empire grec', 'Empire romain', 'Empire ottoman', 'Empire perse'],
            'correctAnswer': 'Empire romain',
            'timeLimit': 25,
          },
          {
            'question': 'Qui a écrit « Le Prince » ?',
            'options': ['Machiavel', 'Platon', 'Aristote', 'César'],
            'correctAnswer': 'Machiavel',
            'timeLimit': 25,
          },
          {
            'question': 'En quelle année a commencé la Première Guerre mondiale ?',
            'options': ['1914', '1939', '1945', '1929'],
            'correctAnswer': '1914',
            'timeLimit': 25,
          },
          {
            'question': 'Qui était le pharaon lors de la construction de la Grande Pyramide de Gizeh ?',
            'options': ['Toutankhamon', 'Khéops', 'Ramsès II', 'Akhenaton'],
            'correctAnswer': 'Khéops',
            'timeLimit': 25,
          },
          {
            'question': 'Quel traité a mis fin à la Première Guerre mondiale ?',
            'options': ['Traité de Versailles', 'Traité de Paris', 'Traité de Rome', 'Traité de Tordesillas'],
            'correctAnswer': 'Traité de Versailles',
            'timeLimit': 25,
          },
        ],
        'difficile': [
          {
            'question': 'Qui a été le premier empereur romain ?',
            'options': ['Jules César', 'Auguste', 'Néron', 'Caligula'],
            'correctAnswer': 'Auguste',
            'timeLimit': 20,
          },
          {
            'question': 'En quelle année l\'Empire byzantin est-il tombé ?',
            'options': ['1204', '1453', '1492', '1683'],
            'correctAnswer': '1453',
            'timeLimit': 20,
          },
          {
            'question': 'Qui a mené la conquête de la Gaule ?',
            'options': ['Vercingétorix', 'Jules César', 'Charlemagne', 'Attila'],
            'correctAnswer': 'Jules César',
            'timeLimit': 20,
          },
          {
            'question': 'Quel roi anglais a signé la Magna Carta ?',
            'options': ['Henri VIII', 'Jean sans Terre', 'Richard Cœur de Lion', 'Édouard Ier'],
            'correctAnswer': 'Jean sans Terre',
            'timeLimit': 20,
          },
          {
            'question': 'Qui était le chef de l\'URSS pendant la Seconde Guerre mondiale ?',
            'options': ['Lénine', 'Staline', 'Krouchtchev', 'Gorbatchev'],
            'correctAnswer': 'Staline',
            'timeLimit': 20,
          },
        ],
      };

      for (final difficulty in questions.keys) {
        for (final q in questions[difficulty]!) {
          // Vérifie si la question existe déjà
          final existing = await _firestore
              .collection('questions')
              .where('question', isEqualTo: q['question'])
              .where('categoryId', isEqualTo: categoryId)
              .where('difficulty', isEqualTo: difficulty)
              .get();

          if (existing.docs.isEmpty) {
            await _firestore.collection('questions').add({
              ...q,
              'categoryId': categoryId,
              'difficulty': difficulty,
            });
          }
        }
      }
    }
    else if (categoryName == 'Cinéma') {
      final questions = {
        'facile': [
          {
            'question': 'Qui a réalisé le film « Titanic » ?',
            'options': ['James Cameron', 'Steven Spielberg', 'Christopher Nolan', 'Quentin Tarantino'],
            'correctAnswer': 'James Cameron',
            'timeLimit': 30,
          },
          {
            'question': 'Quel est le nom du sorcier dans « Harry Potter » ?',
            'options': ['Harry Potter', 'Frodon', 'Luke Skywalker', 'Bilbo'],
            'correctAnswer': 'Harry Potter',
            'timeLimit': 30,
          },
          {
            'question': 'Dans quel film trouve-t-on le personnage « Darth Vader » ?',
            'options': ['Star Wars', 'Matrix', 'Le Seigneur des Anneaux', 'Avatar'],
            'correctAnswer': 'Star Wars',
            'timeLimit': 30,
          },
          {
            'question': 'Quel film d\'animation met en scène un poisson clown nommé Nemo ?',
            'options': ['Le Monde de Nemo', 'Shrek', 'Toy Story', 'Cars'],
            'correctAnswer': 'Le Monde de Nemo',
            'timeLimit': 30,
          },
          {
            'question': 'Quel acteur incarne Iron Man ?',
            'options': ['Chris Evans', 'Robert Downey Jr.', 'Chris Hemsworth', 'Mark Ruffalo'],
            'correctAnswer': 'Robert Downey Jr.',
            'timeLimit': 30,
          },
        ],
        'moyen': [
          {
            'question': 'Quel film a remporté l\'Oscar du meilleur film en 2020 ?',
            'options': ['1917', 'Joker', 'Parasite', 'Once Upon a Time in Hollywood'],
            'correctAnswer': 'Parasite',
            'timeLimit': 25,
          },
          {
            'question': 'Qui a composé la musique du film « Le Roi Lion » ?',
            'options': ['Hans Zimmer', 'John Williams', 'Ennio Morricone', 'James Horner'],
            'correctAnswer': 'Hans Zimmer',
            'timeLimit': 25,
          },
          {
            'question': 'Dans quel film Leonardo DiCaprio gagne-t-il enfin un Oscar ?',
            'options': ['Titanic', 'Inception', 'The Revenant', 'Le Loup de Wall Street'],
            'correctAnswer': 'The Revenant',
            'timeLimit': 25,
          },
          {
            'question': 'Quel film français a remporté l\'Oscar du meilleur film étranger en 2012 ?',
            'options': ['Intouchables', 'The Artist', 'Amélie', 'La Vie d\'Adèle'],
            'correctAnswer': 'The Artist',
            'timeLimit': 25,
          },
          {
            'question': 'Quel est le prénom du personnage principal dans « Matrix » ?',
            'options': ['Neo', 'Morpheus', 'Trinity', 'Smith'],
            'correctAnswer': 'Neo',
            'timeLimit': 25,
          },
        ],
        'difficile': [
          {
            'question': 'Quel réalisateur a remporté la Palme d\'Or à Cannes en 2019 ?',
            'options': ['Bong Joon-ho', 'Pedro Almodóvar', 'Quentin Tarantino', 'Ken Loach'],
            'correctAnswer': 'Bong Joon-ho',
            'timeLimit': 20,
          },
          {
            'question': 'Dans quel film trouve-t-on le personnage de « Norman Bates » ?',
            'options': ['Psychose', 'Shining', 'Seven', 'Le Silence des Agneaux'],
            'correctAnswer': 'Psychose',
            'timeLimit': 20,
          },
          {
            'question': 'Quel film d\'animation a pour héros un robot nommé WALL-E ?',
            'options': ['WALL-E', 'Ratatouille', 'Toy Story', 'Monstres & Cie'],
            'correctAnswer': 'WALL-E',
            'timeLimit': 20,
          },
          {
            'question': 'Quel est le vrai nom de l\'acteur qui joue Gollum dans « Le Seigneur des Anneaux » ?',
            'options': ['Andy Serkis', 'Ian McKellen', 'Elijah Wood', 'Sean Astin'],
            'correctAnswer': 'Andy Serkis',
            'timeLimit': 20,
          },
          {
            'question': 'Quel film a popularisé la réplique « Hasta la vista, baby » ?',
            'options': ['Terminator 2', 'Predator', 'Rambo', 'Die Hard'],
            'correctAnswer': 'Terminator 2',
            'timeLimit': 20,
          },
        ],
      };

      for (final difficulty in questions.keys) {
        for (final q in questions[difficulty]!) {
          // Vérifie si la question existe déjà
          final existing = await _firestore
              .collection('questions')
              .where('question', isEqualTo: q['question'])
              .where('categoryId', isEqualTo: categoryId)
              .where('difficulty', isEqualTo: difficulty)
              .get();

          if (existing.docs.isEmpty) {
            await _firestore.collection('questions').add({
              ...q,
              'categoryId': categoryId,
              'difficulty': difficulty,
            });
          }
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