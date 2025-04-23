import 'package:com_quiz2om_app/screens/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  String? _selectedEmoji;
  bool _isLoading = false;
  final List<String> _emojis = [
    '😀', '😎', '🤠', '🧑', '👩', '🦸', '🐶', '🌈',
    '🎮', '⚽', '🎸', '🍕', '🚀', '❤️', '👍'
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.userData['username'] ?? '',
    );
    _selectedEmoji = widget.userData['avatarEmoji'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title:  'Modifier le profil',
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Aperçu de l'avatar
              CircleAvatar(
                radius: 40,
                child: Text(
                  _selectedEmoji ?? '👤',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(height: 20),

              // Champ nom d'utilisateur
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  if (value.length < 3) {
                    return '3 caractères minimum';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Sélecteur d'emoji
              const Text('Choisissez un emoji:'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _emojis.map((emoji) {
                  return ChoiceChip(
                    label: Text(emoji, style: const TextStyle(fontSize: 24)),
                    selected: _selectedEmoji == emoji,
                    onSelected: (selected) {
                      setState(() {
                        _selectedEmoji = selected ? emoji : null;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          'username': _usernameController.text.trim(),
          'avatarEmoji': _selectedEmoji ?? '👤',
        });
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}