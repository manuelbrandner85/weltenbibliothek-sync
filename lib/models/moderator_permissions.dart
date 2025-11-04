/// Moderatoren-Berechtigungen Modell
/// 
/// Definiert granulare Rechte für Moderatoren
class ModeratorPermissions {
  final bool canDeleteMessages;    // 🗑️ Nachrichten löschen
  final bool canBlockUsers;         // 🚫 User blockieren
  final bool canMuteUsers;          // 🔇 User muten
  final bool canDeleteUsers;        // 👤 User löschen
  final bool canViewLogs;           // 📋 Logs einsehen
  final bool canManageModerators;   // 🛡️ Andere Moderatoren verwalten (nur Super-Admin)

  const ModeratorPermissions({
    this.canDeleteMessages = false,
    this.canBlockUsers = false,
    this.canMuteUsers = false,
    this.canDeleteUsers = false,
    this.canViewLogs = false,
    this.canManageModerators = false,
  });

  /// Standard-Moderator-Rechte (mittlere Berechtigungen)
  factory ModeratorPermissions.standard() {
    return const ModeratorPermissions(
      canDeleteMessages: true,
      canBlockUsers: false,
      canMuteUsers: true,
      canDeleteUsers: false,
      canViewLogs: true,
      canManageModerators: false,
    );
  }

  /// Erweiterte Moderator-Rechte (mehr Berechtigungen)
  factory ModeratorPermissions.extended() {
    return const ModeratorPermissions(
      canDeleteMessages: true,
      canBlockUsers: true,
      canMuteUsers: true,
      canDeleteUsers: false,
      canViewLogs: true,
      canManageModerators: false,
    );
  }

  /// Vollständige Moderator-Rechte (alle Berechtigungen außer Moderator-Verwaltung)
  factory ModeratorPermissions.full() {
    return const ModeratorPermissions(
      canDeleteMessages: true,
      canBlockUsers: true,
      canMuteUsers: true,
      canDeleteUsers: true,
      canViewLogs: true,
      canManageModerators: false,
    );
  }

  /// Super-Admin-Rechte (alle Berechtigungen)
  factory ModeratorPermissions.superAdmin() {
    return const ModeratorPermissions(
      canDeleteMessages: true,
      canBlockUsers: true,
      canMuteUsers: true,
      canDeleteUsers: true,
      canViewLogs: true,
      canManageModerators: true,
    );
  }

  /// Keine Rechte (nur Lesen)
  factory ModeratorPermissions.none() {
    return const ModeratorPermissions();
  }

  /// Von Firestore Map erstellen
  factory ModeratorPermissions.fromMap(Map<String, dynamic> map) {
    return ModeratorPermissions(
      canDeleteMessages: map['canDeleteMessages'] as bool? ?? false,
      canBlockUsers: map['canBlockUsers'] as bool? ?? false,
      canMuteUsers: map['canMuteUsers'] as bool? ?? false,
      canDeleteUsers: map['canDeleteUsers'] as bool? ?? false,
      canViewLogs: map['canViewLogs'] as bool? ?? false,
      canManageModerators: map['canManageModerators'] as bool? ?? false,
    );
  }

  /// Zu Firestore Map konvertieren
  Map<String, dynamic> toMap() {
    return {
      'canDeleteMessages': canDeleteMessages,
      'canBlockUsers': canBlockUsers,
      'canMuteUsers': canMuteUsers,
      'canDeleteUsers': canDeleteUsers,
      'canViewLogs': canViewLogs,
      'canManageModerators': canManageModerators,
    };
  }

  /// Prüfe ob mindestens eine Berechtigung vorhanden ist
  bool get hasAnyPermission {
    return canDeleteMessages ||
        canBlockUsers ||
        canMuteUsers ||
        canDeleteUsers ||
        canViewLogs ||
        canManageModerators;
  }

  /// Anzahl der erteilten Berechtigungen
  int get permissionCount {
    int count = 0;
    if (canDeleteMessages) count++;
    if (canBlockUsers) count++;
    if (canMuteUsers) count++;
    if (canDeleteUsers) count++;
    if (canViewLogs) count++;
    if (canManageModerators) count++;
    return count;
  }

  /// Beschreibung der Berechtigungen als Liste
  List<String> get permissionsList {
    final List<String> permissions = [];
    if (canDeleteMessages) permissions.add('🗑️ Nachrichten löschen');
    if (canMuteUsers) permissions.add('🔇 User muten');
    if (canBlockUsers) permissions.add('🚫 User blockieren');
    if (canDeleteUsers) permissions.add('👤 User löschen');
    if (canViewLogs) permissions.add('📋 Logs einsehen');
    if (canManageModerators) permissions.add('🛡️ Moderatoren verwalten');
    return permissions;
  }

  @override
  String toString() {
    return 'ModeratorPermissions(${permissionsList.join(', ')})';
  }

  /// Copy-With Methode für Änderungen
  ModeratorPermissions copyWith({
    bool? canDeleteMessages,
    bool? canBlockUsers,
    bool? canMuteUsers,
    bool? canDeleteUsers,
    bool? canViewLogs,
    bool? canManageModerators,
  }) {
    return ModeratorPermissions(
      canDeleteMessages: canDeleteMessages ?? this.canDeleteMessages,
      canBlockUsers: canBlockUsers ?? this.canBlockUsers,
      canMuteUsers: canMuteUsers ?? this.canMuteUsers,
      canDeleteUsers: canDeleteUsers ?? this.canDeleteUsers,
      canViewLogs: canViewLogs ?? this.canViewLogs,
      canManageModerators: canManageModerators ?? this.canManageModerators,
    );
  }
}
