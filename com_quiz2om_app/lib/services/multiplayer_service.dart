import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class MultiplayerService {
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://quiz2om-131a8-default-rtdb.europe-west1.firebasedatabase.app/',
  ).ref();

  // Créer une nouvelle partie
  Future<String> createGame(String roomName, int maxPlayers, String hostId, String userName) async {
    final gameRef = _dbRef.child('games').push();
    await gameRef.set({
      'name': roomName,
      'maxPlayers': maxPlayers,
      'host': hostId,
      'players': {
        hostId: {
          'name': userName,
          'ready': true,
          'isHost': true,
          'score': 0
        }
      },
      'status': 'waiting',
      'createdAt': ServerValue.timestamp,
      'playersCount': 1,
    });
    return gameRef.key!; // Retourne l'ID de la partie
  }

  // Rejoindre une partie existante
  Future<void> joinGame(String gameId, String playerId, String userName) async {
    await _dbRef.child('games/$gameId/players/$playerId').set({
      'name': userName,
      'ready': true,
      'isHost': false,
      'score': 0,
    });
    await _dbRef.child('games/$gameId/playersCount').set(ServerValue.increment(1));
  }





  // Stream pour écouter les changements d'une partie
  Stream<DatabaseEvent> gameStream(String gameId) {
    return _dbRef.child('games/$gameId').onValue;
  }

  // Vérifie si une partie existe
  Future<bool> gameExists(String gameId) async {
    final snapshot = await _dbRef.child('games/$gameId').get();
    return snapshot.exists;
  }


  // Récupère les joueurs actuels
  Future<int> getPlayerCount(String gameId) async {
    final snapshot = await _dbRef.child('games/$gameId/players').get();
    if (!snapshot.exists) return 0;
    return (snapshot.value as Map).length;
  }

}
