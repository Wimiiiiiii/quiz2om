import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:com_quiz2om_app/models/quiz_models.dart';
import 'multiplayer_waiting_screen.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  bool _isLoading = false;
  final TextEditingController _roomNameController = TextEditingController();
  int _maxPlayers = 2;
  QuizCategory? _selectedCategory;
  String? _selectedDifficulty;
  List<QuizCategory> _categories = [];
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('categories').get();

      setState(() {
        _categories = snapshot.docs
            .map((doc) => QuizCategory.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement des catégories: $e')),
      );
    }
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _createRoom() async {
    if (_roomNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom de partie')),
      );
      return;
    }

    if (_selectedCategory == null || _selectedDifficulty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Veuillez sélectionner une catégorie et une difficulté')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    final roomCode = _generateRoomCode();

    final roomData = {
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
      'roomName': _roomNameController.text.trim(),
      'maxPlayers': _maxPlayers,
      'creatorId': user!.uid,
      'categoryId': _selectedCategory!.id,
      'difficulty': _selectedDifficulty,
      'questions': [],
      'players': {
        user.uid: {
          'score': 0,
          'ready': false,
        },
      },
    };

    await FirebaseFirestore.instance
        .collection('game_rooms')
        .doc(roomCode)
        .set(roomData);

    setState(() => _isLoading = false);
    _navigateToRoom(roomCode);
  }

  void _navigateToRoom(String roomCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiplayerWaitingScreen(
          roomCode: roomCode,
        ),
      ),
    );
  }

  void _selectCategory(QuizCategory category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Difficulté pour ${category.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDifficultyOption(category, 'facile', 'Facile', Colors.green),
            _buildDifficultyOption(category, 'moyen', 'Moyen', Colors.orange),
            _buildDifficultyOption(
                category, 'difficile', 'Difficile', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
    QuizCategory category,
    String difficulty,
    String displayName,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        displayName,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _selectedDifficulty = difficulty;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCategoryCard(QuizCategory category) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectCategory(category),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple[100]!,
                Colors.deepPurple[200]!,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNetworkImage(category),
              const SizedBox(height: 10),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkImage(QuizCategory category) {
    return SizedBox(
      width: 60,
      height: 60,
      child: category.imageUrl != null && category.imageUrl!.isNotEmpty
          ? FadeInImage.assetNetwork(
              placeholder: 'assets/images/placeholder.png',
              image: category.imageUrl!,
              fit: BoxFit.contain,
              imageErrorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.category, size: 50, color: Colors.deepPurple[800]),
            )
          : Icon(Icons.category, size: 50, color: Colors.deepPurple[800]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Créer une Partie'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Nom de la partie',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _roomNameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Soirée Quiz',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nombre de joueurs maximum',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _maxPlayers,
                      items: List.generate(9, (index) => index + 2)
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('$e joueurs'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _maxPlayers = value;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Catégorie sélectionnée',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _selectedCategory != null
                        ? ListTile(
                            leading: _buildNetworkImage(_selectedCategory!),
                            title: Text(_selectedCategory!.name),
                            subtitle: Text('Difficulté: $_selectedDifficulty'),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = null;
                                  _selectedDifficulty = null;
                                });
                              },
                            ),
                          )
                        : const Text('Aucune catégorie sélectionnée'),
                    const SizedBox(height: 20),
                    const Text(
                      'Choisissez une catégorie',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          return _buildCategoryCard(_categories[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _createRoom,
                      child: const Text('Créer la Partie'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    // Si l'utilisateur quitte l'écran de création sans créer de partie
    if (_user != null) {
      FirebaseFirestore.instance
          .collection('game_rooms')
          .where('creatorId', isEqualTo: _user!.uid)
          .where('status', isEqualTo: 'waiting')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
    }
    super.dispose();
  }
}
