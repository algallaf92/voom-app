import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final String username;
  final String gender;
  final String region;
  final String profilePictureUrl;
  final void Function(String, String, String, String) onSave;

  const EditProfileScreen({
    super.key,
    required this.username,
    required this.gender,
    required this.region,
    required this.profilePictureUrl,
    required this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController usernameController;
  late TextEditingController genderController;
  late TextEditingController regionController;
  String? profilePictureUrl;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.username);
    genderController = TextEditingController(text: widget.gender);
    regionController = TextEditingController(text: widget.region);
    profilePictureUrl = widget.profilePictureUrl;
  }

  @override
  void dispose() {
    usernameController.dispose();
    genderController.dispose();
    regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: GestureDetector(
                onTap: _changeProfilePicture,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.7),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.grey.shade900,
                      backgroundImage: CachedNetworkImageProvider(profilePictureUrl ?? ''),
                    ),
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: Icon(Icons.edit, color: Colors.cyanAccent, size: 28),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(controller: usernameController, label: 'Username'),
            const SizedBox(height: 16),
            _buildTextField(controller: genderController, label: 'Gender'),
            const SizedBox(height: 16),
            _buildTextField(controller: regionController, label: 'Region'),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.cyanAccent),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: isSaving ? null : _saveProfile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.6),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Center(
          child: isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.cyanAccent,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _changeProfilePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        profilePictureUrl = picked.path;
      });
    }
  }

  void _saveProfile() async {
    setState(() => isSaving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Only save fields that have cloud-accessible values.
      // profilePictureUrl is skipped here until Firebase Storage upload is implemented.
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': usernameController.text.trim(),
        'gender': genderController.text.trim(),
        'region': regionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    widget.onSave(
      usernameController.text,
      genderController.text,
      regionController.text,
      profilePictureUrl ?? '',
    );
    if (mounted) {
      setState(() => isSaving = false);
      Navigator.pop(context);
    }
  }
}
