import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz2om/screens/quiz_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Quiz2OM',
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn().scale(),
                const SizedBox(height: 40),
                Text(
                  'Testez vos connaissances sur différents sujets',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 60),
                _buildModeButton(
                  context,
                  'Mode Solo',
                  Icons.person,
                  Colors.amber,
                      () => _navigateToQuizSelection(context, 'solo'),
                ),
                const SizedBox(height: 20),
                _buildModeButton(
                  context,
                  'Mode Multijoueur',
                  Icons.people,
                  Colors.green,
                      () => _navigateToQuizSelection(context, 'multi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(
      BuildContext context,
      String text,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 20),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.9),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
        minimumSize: const Size(double.infinity, 60),
      ),
      onPressed: onPressed,
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5);
  }

  void _navigateToQuizSelection(BuildContext context, String mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizSelectionScreen(gameMode: mode),
      ),
    );
  }
}