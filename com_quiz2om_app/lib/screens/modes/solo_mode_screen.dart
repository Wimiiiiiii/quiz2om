import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:com_quiz2om_app/models/quiz_models.dart';
import '../quiz/quiz_screen.dart';

class SoloModeScreen extends StatefulWidget {
  const SoloModeScreen({super.key});

  @override
  State<SoloModeScreen> createState() => _SoloModeScreenState();
}

class _SoloModeScreenState extends State<SoloModeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Choisissez une catégorie',
      ),
      body: _buildCategoriesGrid(),
    );
  }

  Widget _buildCategoriesGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data!.docs
            .map((doc) => QuizCategory.fromFirestore(doc))
            .toList();

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.9,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(categories[index], context);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(QuizCategory category, BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectDifficulty(context, category),
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

  void _selectDifficulty(BuildContext context, QuizCategory category) {
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
            _buildDifficultyOption(context, category, 'facile', 'Facile', Colors.green),
            _buildDifficultyOption(context, category, 'moyen', 'Moyen', Colors.orange),
            _buildDifficultyOption(context, category, 'difficile', 'Difficile', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
      BuildContext context,
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
      onTap: () async {
        Navigator.pop(context); // Ferme le bottom sheet
        final shouldRefresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              category: category,
              difficulty: difficulty,
            ),
          ),
        );

        if (shouldRefresh == true && mounted) {
          setState(() {});
        }
      },
    );
  }
}