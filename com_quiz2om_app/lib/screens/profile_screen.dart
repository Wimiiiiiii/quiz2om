import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title:  'Mon Profil',
      ),
      body: _buildProfileBody(),
    );
  }

  Widget _buildProfileBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(_user?.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Profil non trouvé'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        return _buildProfileContent(userData);
      },
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> userData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildAvatarSection(userData),
          const SizedBox(height: 30),
          _buildActionButtons(userData),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(Map<String, dynamic> userData) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          child: Text(
            userData['avatarEmoji'] ?? '👤',
            style: const TextStyle(fontSize: 50),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          userData['username'] ?? 'Anonyme',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        Text(
          _obfuscateEmail(_user?.email),
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> userData) {
    return Column(
      children: [
        _buildListTileButton(
          icon: Icons.edit,
          color: Colors.deepPurple,
          text: 'Modifier le profil',
          onTap: () => _navigateToEditProfile(userData),
        ),
        _buildListTileButton(
          icon: Icons.lock,
          color: Colors.orange,
          text: 'Changer le mot de passe',
          onTap: _changePassword,
        ),
        _buildListTileButton(
          icon: Icons.logout,
          color: Colors.red,
          text: 'Se déconnecter',
          onTap: _signOut,
        ),
      ],
    );
  }

  Widget _buildListTileButton({
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(text),
        trailing: Icon(Icons.chevron_right, color: color),
        onTap: onTap,
      ),
    );
  }

  Future<void> _updateProfile(Map<String, dynamic> updates) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user?.uid)
          .update(updates);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToEditProfile(Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: userData),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _changePassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialisation'),
        content: const Text('Envoyer un lien de réinitialisation à votre email ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    if (confirmed == true && _user?.email != null) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: _user!.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email envoyé !')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  String _obfuscateEmail(String? email) {
    if (email == null || email.isEmpty) return 'Email non disponible';

    final parts = email.split('@');
    if (parts.length != 2) return email; // Format email invalide

    final username = parts[0];
    final domain = parts[1];

    // Garde les 2 premiers et derniers caractères du nom d'utilisateur
    final obscuredUsername = username.length > 4
        ? '${username.substring(0, 2)}...${username.substring(username.length - 2)}'
        : username;

    return '$obscuredUsername@$domain';
  }


}