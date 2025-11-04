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
      print('📸 Opening image picker...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        print('✅ Image selected: ${image.path}');
        print('   File size: ${await image.length()} bytes');
        
        if (mounted) {
          setState(() => _selectedImage = File(image.path));
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Bild ausgewählt'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        print('ℹ️ No image selected (user cancelled)');
      }
    } catch (e, stackTrace) {
      print('❌ ERROR picking image:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Auswählen: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) return null;

    try {
      final userId = _authService.currentUserId!;
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      print('🔄 Uploading profile image...');
      print('   User ID: $userId');
      print('   File path: ${_selectedImage!.path}');
      print('   Storage path: profile_images/$userId/$fileName');
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/$userId/$fileName');

      print('📤 Starting upload...');
      final uploadTask = storageRef.putFile(_selectedImage!);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('   Upload progress: ${progress.toStringAsFixed(1)}%');
      });
      
      await uploadTask;
      print('✅ Upload completed!');
      
      final downloadURL = await storageRef.getDownloadURL();
      print('✅ Download URL: $downloadURL');
      
      return downloadURL;
    } catch (e, stackTrace) {
      print('❌ ERROR uploading profile image:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      
      if (mounted) {
        // Show detailed error message
        String errorMessage = 'Fehler beim Hochladen';
        
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Zugriff verweigert! Prüfe Firebase Storage Rules.';
        } else if (e.toString().contains('unauthorized')) {
          errorMessage = 'Nicht autorisiert! Bitte erneut anmelden.';
        } else if (e.toString().contains('object-not-found')) {
          errorMessage = 'Datei nicht gefunden! Wähle ein anderes Bild.';
        } else if (e.toString().contains('quota-exceeded')) {
          errorMessage = 'Speicherplatz voll! Kontaktiere den Administrator.';
        } else {
          errorMessage = 'Fehler: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('❌ Upload fehlgeschlagen', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(errorMessage),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      print('💾 Saving profile...');
      
      // Upload image if selected
      String? photoURL = _currentPhotoURL;
      if (_selectedImage != null) {
        print('📸 Image selected, starting upload...');
        photoURL = await _uploadProfileImage();
        
        if (photoURL == null) {
          print('❌ Image upload failed, aborting profile save');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Bild konnte nicht hochgeladen werden. Profil wurde nicht gespeichert.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return; // Don't save profile if image upload failed
        }
        print('✅ Image uploaded successfully: $photoURL');
      } else {
        print('ℹ️ No image selected, keeping current photo');
      }

      // Update profile
      print('📝 Updating Firestore profile...');
      await _authService.updateUserProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        photoURL: photoURL,
      );
      print('✅ Profile updated successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil erfolgreich gespeichert!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      print('❌ ERROR saving profile:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('❌ Fehler beim Speichern', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(e.toString()),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
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
