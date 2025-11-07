import 'package:flutter/foundation.dart';

/// v2.28.0 - Content Categorizer Service
/// 
/// Smart Kategorisierung und Episode-Sortierung für Telegram-Inhalte
class ContentCategorizer {
  // 9 Themen-Kategorien mit Keyword-Matching
  final Map<String, List<String>> _categoryKeywords = {
    'Verschwörung': ['illuminati', '911', 'deepstate', 'geheim', 'verschwörung', 'conspiracy', 'nwo', 'new world order'],
    'Geschichte': ['antike', 'ägypten', 'geschichte', 'historisch', 'römer', 'history', 'mittelalter', 'ancient'],
    'UFO & Aliens': ['ufo', 'alien', 'roswell', 'area51', 'außerirdisch', 'extraterrestrial', 'grey', 'abduction'],
    'Spiritualität': ['meditation', 'energie', 'bewusstsein', 'chakra', 'spiritual', 'erleuchtung', 'awakening'],
    'Mythen & Legenden': ['atlantis', 'legende', 'mythos', 'mythologie', 'drache', 'dragon', 'legend', 'mythical'],
    'Rätsel & Geheimnisse': ['rätsel', 'mysterium', 'bermuda', 'geheimnis', 'mystery', 'puzzle', 'enigma', 'unsolved'],
    'Paranormales': ['geist', 'paranormal', 'jenseits', 'ghost', 'haunted', 'poltergeist', 'spuk'],
    'Wissenschaft & Grenzwissen': ['wissenschaft', 'physik', 'quantenphysik', 'science', 'quantum', 'einstein', 'tesla'],
  };

  final String _defaultCategory = 'Allgemein';

  /// Gruppiere Items nach Kategorie und sortiere innerhalb der Kategorien
  Map<String, List<Map<String, dynamic>>> groupByCategory(List<Map<String, dynamic>> items) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in items) {
      // Kategorisiere basierend auf Inhalt
      final fileName = item['file_name'] ?? item['title'] ?? '';
      final caption = item['caption'] ?? item['description'] ?? '';
      final category = categorizeContent(fileName, caption);

      // Extrahiere Episode-Nummer
      final episodeNumber = extractEpisodeNumber(fileName);
      item['_episode_number'] = episodeNumber;

      // Füge zu entsprechender Kategorie hinzu
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(item);
    }

    // Sortiere Items innerhalb jeder Kategorie nach Episode-Nummer
    for (final category in grouped.keys) {
      grouped[category] = sortByEpisode(grouped[category]!);
    }

    return grouped;
  }

  /// Kategorisiere Content basierend auf Keywords in Filename und Caption
  String categorizeContent(String fileName, String caption) {
    final combinedText = '${fileName.toLowerCase()} ${caption.toLowerCase()}';
    
    // Zähle Keyword-Matches für jede Kategorie
    final scores = <String, int>{};
    
    for (final entry in _categoryKeywords.entries) {
      final category = entry.key;
      final keywords = entry.value;
      
      int score = 0;
      for (final keyword in keywords) {
        if (combinedText.contains(keyword)) {
          score++;
        }
      }
      
      if (score > 0) {
        scores[category] = score;
      }
    }

    // Gebe Kategorie mit höchstem Score zurück
    if (scores.isEmpty) {
      return _defaultCategory;
    }

    String bestCategory = _defaultCategory;
    int maxScore = 0;
    
    for (final entry in scores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        bestCategory = entry.key;
      }
    }

    return bestCategory;
  }

  /// Extrahiere Episode-Nummer aus Dateinamen
  int? extractEpisodeNumber(String fileName) {
    if (fileName.isEmpty) return null;

    final patterns = [
      RegExp(r'folge\s*(\d+)', caseSensitive: false),
      RegExp(r'episode\s*(\d+)', caseSensitive: false),
      RegExp(r'ep\.?\s*(\d+)', caseSensitive: false),
      RegExp(r'teil\s*(\d+)', caseSensitive: false),
      RegExp(r'[-_\s](\d{1,3})[-_\s.]'),
      RegExp(r'^(\d{1,3})[_\s-]'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(fileName);
      if (match != null) {
        try {
          return int.parse(match.group(1)!);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Fehler beim Parsen der Episode-Nummer: $e');
          }
        }
      }
    }

    return null;
  }

  /// Sortiere Items nach Episode-Nummer
  List<Map<String, dynamic>> sortByEpisode(List<Map<String, dynamic>> items) {
    // Trenne Items mit und ohne Episode-Nummer
    final withEpisode = items.where((item) => item['_episode_number'] != null).toList();
    final withoutEpisode = items.where((item) => item['_episode_number'] == null).toList();

    // Sortiere Items mit Episode numerisch
    withEpisode.sort((a, b) {
      final aNum = a['_episode_number'] as int;
      final bNum = b['_episode_number'] as int;
      return aNum.compareTo(bNum);
    });

    // Sortiere Items ohne Episode alphabetisch
    withoutEpisode.sort((a, b) {
      final aName = a['file_name'] ?? a['title'] ?? '';
      final bName = b['file_name'] ?? b['title'] ?? '';
      return aName.toString().compareTo(bName.toString());
    });

    // Kombiniere: Zuerst mit Episoden, dann ohne
    return [...withEpisode, ...withoutEpisode];
  }

  /// Hole Icon-Emoji für Kategorie
  String getCategoryIcon(String category) {
    const icons = {
      'Verschwörung': '🔍',
      'Geschichte': '📜',
      'UFO & Aliens': '👽',
      'Spiritualität': '✨',
      'Mythen & Legenden': '🏛️',
      'Rätsel & Geheimnisse': '🧩',
      'Paranormales': '👻',
      'Wissenschaft & Grenzwissen': '🔬',
      'Allgemein': '📂',
    };

    return icons[category] ?? '📂';
  }
}
