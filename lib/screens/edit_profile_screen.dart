import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';

/// Edit Profile Screen - Benutzername, Bio, Profilbild
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  String? _currentPhotoURL;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getUserProfile(_authService.currentUserId!);
    
    if (profile != null && mounted) {
      setState(() {
        _usernameController.text = profile['username'] ?? '';
        _bioController.text = profile['bio'] ?? '';
        _currentPhotoURL = profile['photoURL'];
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Auswählen des Bildes: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) return null;

    try {
      final userId = _authService.currentUserId!;
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/$userId/$fileName');

      await storageRef.putFile(_selectedImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Hochladen: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      // Upload image if selected
      String? photoURL = _currentPhotoURL;
      if (_selectedImage != null) {
        photoURL = await _uploadProfileImage();
      }

      // Update profile
      await _authService.updateUserProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        photoURL: photoURL,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profil gespeichert'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.secondaryGold)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Profil bearbeiten', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Speichern',
                    style: TextStyle(
                      color: AppTheme.secondaryGold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Image
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.secondaryGold, width: 3),
                    ),
                    child: ClipOval(
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : _currentPhotoURL != null && _currentPhotoURL!.isNotEmpty
                              ? Image.network(_currentPhotoURL!, fit: BoxFit.cover)
                              : Container(
                                  color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                                  child: const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppTheme.secondaryGold,
                                  ),
                                ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.backgroundDark, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Username Field
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Benutzername',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.person, color: AppTheme.secondaryGold),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bio Field
            TextField(
              controller: _bioController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: 'Bio',
                labelStyle: const TextStyle(color: Colors.grey),
                alignLabelWithHint: true,
                hintText: 'Erzähle etwas über dich...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.secondaryGold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dein Profil wird anderen Nutzern in Chats angezeigt',
                      style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
