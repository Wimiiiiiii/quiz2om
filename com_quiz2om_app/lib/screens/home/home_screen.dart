import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:com_quiz2om_app/screens/admin_seed_screen.dart';
import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'package:com_quiz2om_app/screens/profile/profile_screen.dart';
import 'package:com_quiz2om_app/screens/modes/solo_mode_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:com_quiz2om_app/services/user_stats_service.dart';

import '../../models/user_stats.dart';
import '../modes/multiplayer_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CategoryService _categoryService = CategoryService();

  final GlobalKey _refreshKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final UserStatsService _statsService = UserStatsService();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Accueil',
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Statistiques
            FutureBuilder(
              key: _refreshKey,
              future: Future.wait([
                _statsService.getGlobalRanking(),
                _statsService.getCategorySuccessRates(),
                _statsService.getUserStats(),
                _categoryService.getAllCategoryNames(),
              ]),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Text('Erreur de chargement des statistiques');
                }

                final rank = snapshot.data?[0] as int;
                final categoryRates = snapshot.data?[1] as Map<String, double>;
                final userStats = snapshot.data?[2] as UserStats;
                final categoryNames = snapshot.data?[3] as Map<String, String>;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Vos Statistiques',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            _buildTrophyBadge(rank),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatCard(
                              context,
                              'Classement',
                              '#$rank',
                              Icons.leaderboard,
                              Colors.amber,
                            ),
                            const SizedBox(width: 10),
                            _buildStatCard(
                              context,
                              'Score Total',
                              '${userStats.totalScore}',
                              Icons.star,
                              Colors.blue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (categoryRates.isNotEmpty) ...[
                          Text(
                            'Performance par catégorie:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                categoryRates.entries.map((entry) {
                                  final categoryName =
                                      categoryNames[entry.key] ?? entry.key;
                                  return Chip(
                                    backgroundColor: _getCategoryColor(
                                      entry.value,
                                    ),
                                    label: Text(
                                      '$categoryName: ${entry.value.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    avatar: Icon(
                                      entry.value > 70
                                          ? Icons.check_circle
                                          : Icons.trending_up,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Choisissez un mode',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1,
                ),
                children: [
                  _buildModeCard(
                    context,
                    'Solo',
                    Icons.person,
                    Colors.blue,
                    () async {
                      final shouldRefresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SoloModeScreen(),
                        ),
                      );
                      if (shouldRefresh == true) {
                        _refreshKey.currentState?.setState(() {});
                      }
                    },
                  ),
                  _buildModeCard(
                    context,
                    'Multijoueur',
                    Icons.people,
                    Colors.green,
                    () async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MultiplayerModeScreen(),
                          ),
                        );

                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophyBadge(int rank) {
    IconData icon;
    Color color;
    String label;

    if (rank <= 3) {
      icon = Icons.emoji_events;
      color = Colors.amber;
      label = 'Top $rank';
    } else if (rank <= 10) {
      icon = Icons.workspace_premium;
      color = Colors.blue;
      label = 'Top 10';
    } else {
      icon = Icons.star;
      color = Colors.purple;
      label = 'Top 100';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.blue;
    return Colors.orange;
  }

  Widget _buildModeCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Jouer maintenant',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getCategoryName(String categoryId) async {
    try {
      final doc =
          await _firestore.collection('categories').doc(categoryId).get();
      return doc['name'] ?? categoryId; // Retourne l'ID si le nom n'existe pas
    } catch (e) {
      print('Erreur récupération catégorie: $e');
      return categoryId;
    }
  }

  Future<Map<String, String>> getAllCategoryNames() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      return {for (var doc in snapshot.docs) doc.id: doc['name']};
    } catch (e) {
      print('Erreur récupération catégories: $e');
      return {};
    }
  }
}
