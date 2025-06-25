import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'multiplayer_quiz_screen.dart';

class MultiplayerWaitingScreen extends StatefulWidget {
  final String roomCode;

  const MultiplayerWaitingScreen({super.key, required this.roomCode});

  @override
  State<MultiplayerWaitingScreen> createState() =>
      _MultiplayerWaitingScreenState();
}

class _MultiplayerWaitingScreenState extends State<MultiplayerWaitingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  bool _isStartingGame = false;
  Map<String, String> _usernames = {};

  @override
  void initState() {
    super.initState();
    // Mettre à jour lastActivity quand le joueur rejoint la salle d'attente
    _updateLastActivity();
  }

  // Nouvelle méthode pour afficher l'erreur
  void _showPlayersNotReadyError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partie en attente',
            style: TextStyle(color: Colors.deepPurple)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_empty, color: Colors.orange, size: 50),
            const SizedBox(height: 15),
            const Text(
              'Tous les joueurs ne sont pas prêts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              'Attendez que tous les participants soient prêts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadQuestions(
      String categoryId, String difficulty) async {
    try {
      final query = await _firestore
          .collection('questions')
          .where('categoryId', isEqualTo: categoryId)
          .where('difficulty', isEqualTo: difficulty)
          .limit(10)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'question': data['question'],
          'options': List<String>.from(data['options']),
          'correctAnswer': data['correctAnswer'],
        };
      }).toList()
        ..shuffle();
    } catch (e) {
      throw Exception('Erreur de chargement des questions: $e');
    }
  }

  Future<void> _updateLastActivity() async {
    await _firestore.collection('game_rooms').doc(widget.roomCode).update({
      'lastActivity': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _setReady(bool ready) async {
    if (_user == null) return;

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('game_rooms').doc(widget.roomCode).update({
        'players.${_user?.uid}.ready': ready,
        'lastActivity': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUsernames(List<String> userIds) async {
    try {
      final userDocs = await Future.wait(
        userIds.map((uid) => _firestore.collection('users').doc(uid).get()),
      );

      final Map<String, String> loadedUsernames = {};
      for (var doc in userDocs) {
        if (doc.exists) {
          loadedUsernames[doc.id] = doc.data()?['username'] ?? 'Inconnu';
        }
      }

      setState(() {
        _usernames = loadedUsernames;
      });
    } catch (e) {
      // Optionnel: afficher une erreur
      print('Erreur lors du chargement des usernames: $e');
    }
  }

  Future<void> _startGame() async {
    if (_user == null) return;

    setState(() => _isStartingGame = true);
    try {
      final roomDoc =
          await _firestore.collection('game_rooms').doc(widget.roomCode).get();
      final roomData = roomDoc.data() as Map<String, dynamic>;

      // Vérifier que les deux joueurs sont prêts
      final players = Map<String, dynamic>.from(roomData['players']);
      final maxPlayers = roomData['maxPlayers'];
      if (players.length < maxPlayers ||
          !players.values.every((p) => p['ready'] == true)) {
        throw Exception('Les joueurs ne sont pas tous prêts');
      }

      // Charger les questions
      final questions = await _loadQuestions(
        roomData['categoryId'],
        roomData['difficulty'],
      );

      // Mettre à jour la salle avec les questions et démarrer le jeu
      await _firestore.collection('game_rooms').doc(widget.roomCode).update({
        'status': 'started',
        'questions': questions,
        'currentQuestionIndex': 0,
        'currentPlayerTurn': roomData['creatorId'],
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Naviguer vers l'écran de jeu
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MultiplayerQuizScreen(roomCode: widget.roomCode),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Remplacer le SnackBar par la boîte de dialogue
      _showPlayersNotReadyError(context);
    } finally {
      setState(() => _isStartingGame = false);
    }
  }

  @override
  void dispose() {
    // Si le créateur quitte la salle d'attente, supprimer la partie
    if (_user != null) {
      _firestore
          .collection('game_rooms')
          .doc(widget.roomCode)
          .get()
          .then((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          if (data['creatorId'] == _user!.uid && data['status'] == 'waiting') {
            doc.reference.delete();
          }
        }
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Code de la partie: ${widget.roomCode}",
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('game_rooms')
            .doc(widget.roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final players = Map<String, dynamic>.from(roomData['players']);
          if (_usernames.length != players.length) {
            _loadUsernames(players.keys.toList());
          }

          final userData = _user != null ? players[_user!.uid] : null;
          final isReady = userData is Map && userData['ready'] == true;
          final isCreator =
              _user != null && roomData['creatorId'] == _user!.uid;
          final allPlayersReady = players.length == roomData['maxPlayers'] &&
              players.values.every((p) => p['ready'] == true);

          if (roomData['status'] == 'started') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MultiplayerQuizScreen(roomCode: widget.roomCode),
                ),
              );
            });
          }

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'En attente des joueurs...',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Joueurs connectés:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            ...players.entries.map((entry) {
                              final isCurrentUser = entry.key == _user?.uid;
                              final username =
                                  _usernames[entry.key] ?? 'Joueur';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isCurrentUser
                                      ? Colors.deepPurple
                                      : Colors.grey,
                                  child: Text(
                                    username.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  isCurrentUser ? '$username (Vous)' : username,
                                ),
                                trailing: entry.value['ready']
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : const Icon(Icons.hourglass_empty,
                                        color: Colors.orange),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Afficher le bouton "Je suis prêt" seulement si le joueur n'est pas encore prêt
                    if (!isReady)
                      ElevatedButton(
                        onPressed: _isLoading ? null : () => _setReady(true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Je suis prêt',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    // Afficher le bouton "Commencer le jeu" seulement pour le créateur quand tous sont prêts
                    if (isCreator)
                      ElevatedButton(
                        onPressed: _isStartingGame ? null : _startGame,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.deepPurple,
                        ),
                        child: const Text(
                          'Commencer le jeu',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              if (_isStartingGame)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }
}
