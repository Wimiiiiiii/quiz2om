import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'multiplayer_waiting_screen.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  final TextEditingController _roomCodeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _joinRoom(String roomCode) async {
    if (_user == null) return;

    setState(() => _isLoading = true);
    try {
      // Vérifier si la salle existe
      final roomDoc = await _firestore.collection('game_rooms').doc(roomCode).get();
      
      if (!roomDoc.exists) {
        throw Exception('Code de partie invalide');
      }

      final roomData = roomDoc.data()!;
      
      // Vérifier si la partie est en attente
      if (roomData['status'] != 'waiting') {
        throw Exception('Cette partie a déjà commencé ou est terminée');
      }

      // Vérifier si la partie est pleine
      final players = Map<String, dynamic>.from(roomData['players']);
      if (players.length >= roomData['maxPlayers']) {
        throw Exception('Cette partie est pleine');
      }

      // Vérifier si le joueur n'est pas déjà dans la partie
      if (players.containsKey(_user!.uid)) {
        throw Exception('Vous êtes déjà dans cette partie');
      }

      // Ajouter le joueur à la partie et mettre à jour lastActivity
      await _firestore.collection('game_rooms').doc(roomCode).update({
        'players.${_user!.uid}': {
          'score': 0,
          'ready': false,
        },
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // Naviguer vers l'écran d'attente
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MultiplayerWaitingScreen(roomCode: roomCode),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Rejoindre une partie'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section pour entrer le code
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Entrez le code de la partie',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _roomCodeController,
                      decoration: InputDecoration(
                        hintText: 'Ex: ABC123',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.games),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _joinRoom(_roomCodeController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Rejoindre la partie',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Section pour les parties en attente
              const Text(
                'Parties en attente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('game_rooms')
                      .where('status', isEqualTo: 'waiting')
                      .where('lastActivity', isGreaterThan: Timestamp.fromDate(
                        DateTime.now().subtract(const Duration(minutes: 5)),
                      ))
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Erreur: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final rooms = snapshot.data!.docs;
                    if (rooms.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucune partie en attente',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index].data() as Map<String, dynamic>;
                        final players = Map<String, dynamic>.from(room['players']);
                        final isFull = players.length >= room['maxPlayers'];
                        final isInRoom = _user != null && players.containsKey(_user!.uid);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              room['roomName'] ?? 'Partie sans nom',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  'Catégorie: ${room['categoryId']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'Difficulté: ${room['difficulty']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'Joueurs: ${players.length}/${room['maxPlayers']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: isFull || isInRoom
                                  ? null
                                  : () => _joinRoom(rooms[index].id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                isFull
                                    ? 'Plein'
                                    : isInRoom
                                        ? 'Déjà dans'
                                        : 'Rejoindre',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }
} 