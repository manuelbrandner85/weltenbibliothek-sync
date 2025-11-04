import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/imgbb_service.dart';

/// Beispiel-Implementierung: Profilbild-Upload mit ImgBB
/// 
/// Zeigt wie man:
/// 1. Bild auswählt (Galerie/Kamera)
/// 2. Zu ImgBB hochlädt
/// 3. URL in Firestore speichert
/// 4. Bild aus Firestore lädt und anzeigt
class ImgBBProfileImageExample extends StatefulWidget {
  final String userId;
  
  const ImgBBProfileImageExample({
    super.key,
    required this.userId,
  });

  @override
  State<ImgBBProfileImageExample> createState() => _ImgBBProfileImageExampleState();
}

class _ImgBBProfileImageExampleState extends State<ImgBBProfileImageExample> {
  bool _isUploading = false;
  String? _uploadError;

  /// Bild auswählen und hochladen
  Future<void> _pickAndUploadImage(ImageSource source) async {
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      // 1. Bild auswählen
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() => _isUploading = false);
        return;
      }

      // 2. Zu ImgBB hochladen
      final imageFile = File(pickedFile.path);
      final imageUrl = await ImgBBService.uploadImage(
        imageFile: imageFile,
        name: 'profile_${widget.userId}',
      );

      if (imageUrl != null) {
        // 3. URL in Firestore speichern
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({
          'profileImageUrl': imageUrl,
          'hasProfileImage': true,
          'profileImageUpdatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profilbild erfolgreich hochgeladen!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Upload fehlgeschlagen');
      }
    } catch (e) {
      setState(() => _uploadError = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Upload-Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilbild hochladen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aktuelles Profilbild anzeigen
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final imageUrl = userData?['profileImageUrl'] as String?;

                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.error,
                                size: 50,
                                color: Colors.red,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.grey,
                        ),
                );
              },
            ),
            
            const SizedBox(height: 40),

            // Upload-Status
            if (_isUploading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Bild wird hochgeladen...'),
                ],
              )
            else ...[
              // Galerie Button
              ElevatedButton.icon(
                onPressed: () => _pickAndUploadImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Aus Galerie wählen'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Kamera Button
              ElevatedButton.icon(
                onPressed: () => _pickAndUploadImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Foto aufnehmen'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
            ],

            // Fehler-Anzeige
            if (_uploadError != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Fehler: $_uploadError',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Beispiel-Implementierung: Post mit Bildern erstellen
/// 
/// Zeigt wie man:
/// 1. Mehrere Bilder auswählt
/// 2. Parallel zu ImgBB hochlädt
/// 3. Post mit Bild-URLs in Firestore speichert
class ImgBBPostWithImagesExample extends StatefulWidget {
  final String userId;
  
  const ImgBBPostWithImagesExample({
    super.key,
    required this.userId,
  });

  @override
  State<ImgBBPostWithImagesExample> createState() => _ImgBBPostWithImagesExampleState();
}

class _ImgBBPostWithImagesExampleState extends State<ImgBBPostWithImagesExample> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isUploading = false;

  /// Mehrere Bilder auswählen
  Future<void> _pickMultipleImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((xFile) => File(xFile.path)));
      });
    }
  }

  /// Post mit Bildern erstellen
  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Text oder Bilder hinzufügen'),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Alle Bilder parallel zu ImgBB hochladen
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        final uploadFutures = _selectedImages.map(
          (file) => ImgBBService.uploadImage(imageFile: file),
        );
        final results = await Future.wait(uploadFutures);
        
        // Nur erfolgreiche Uploads verwenden
        imageUrls = results.whereType<String>().toList();
        
        if (imageUrls.isEmpty && _selectedImages.isNotEmpty) {
          throw Exception('Keines der Bilder konnte hochgeladen werden');
        }
      }

      // 2. Post in Firestore erstellen
      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': widget.userId,
        'content': _contentController.text.trim(),
        'imageUrls': imageUrls,
        'hasImages': imageUrls.isNotEmpty,
        'imageCount': imageUrls.length,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Post mit ${imageUrls.length} Bild(ern) erstellt!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset
        _contentController.clear();
        setState(() => _selectedImages.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post mit Bildern erstellen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Text-Eingabe
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Was möchtest du teilen?',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            
            const SizedBox(height: 16),

            // Bild-Auswahl Button
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickMultipleImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text('Bilder hinzufügen (${_selectedImages.length})'),
            ),
            
            const SizedBox(height: 16),

            // Vorschau der ausgewählten Bilder
            if (_selectedImages.isNotEmpty)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          _selectedImages[index],
                          fit: BoxFit.cover,
                        ),
                        // Löschen-Button
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 16),

            // Post-Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _createPost,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Post veröffentlichen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
