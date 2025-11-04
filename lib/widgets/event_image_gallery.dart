import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/glass_card.dart';

/// Event image gallery widget with glassmorphism effect
/// Future: Connect to Firebase Storage for dynamic images
class EventImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final double height;

  const EventImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return _buildPlaceholder();
    }

    if (imageUrls.length == 1) {
      return _buildSingleImage(imageUrls.first);
    }

    return _buildGallery();
  }

  Widget _buildPlaceholder() {
    return GlassContainer(
      height: height,
      borderRadius: BorderRadius.circular(16),
      opacity: 0.1,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48,
              color: AppTheme.textWhite.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Keine Bilder verfügbar',
              style: TextStyle(
                color: AppTheme.textWhite.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Wird in einem künftigen Update hinzugefügt',
              style: TextStyle(
                color: AppTheme.textWhite.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: AppTheme.primaryPurple,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGallery() {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index < imageUrls.length - 1 ? 12 : 0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrls[index],
                height: height,
                width: height * 1.5,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: height,
                  width: height * 1.5,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.broken_image,
                    color: AppTheme.textWhite.withValues(alpha: 0.3),
                    size: 48,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Compact event image thumbnail for list views
class EventImageThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final EventCategory? category;

  const EventImageThumbnail({
    super.key,
    this.imageUrl,
    this.size = 80,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Icon(
        Icons.image,
        color: AppTheme.textWhite.withValues(alpha: 0.3),
        size: size * 0.4,
      ),
    );
  }
}

// Import EventCategory for thumbnail colors
enum EventCategory {
  lostCivilizations,
  alienContact,
  secretSocieties,
  techMysteries,
  dimensionalAnomalies,
  occultEvents,
  forbiddenKnowledge,
  ufoFleets,
  energyPhenomena,
  globalConspiracies,
}
