import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/admin_service.dart';

/// User Role Badge Widget
/// 
/// Zeigt Admin/Moderator Badge bei Usern an
class UserRoleBadge extends StatelessWidget {
  final String userId;
  final double fontSize;
  final EdgeInsets padding;

  const UserRoleBadge({
    super.key,
    required this.userId,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserRole>(
      stream: AdminService().streamUserRole(userId),
      builder: (context, snapshot) {
        final userRole = snapshot.data ?? UserRole.user;

        if (userRole == UserRole.user) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: userRole == UserRole.superAdmin
                ? AppTheme.secondaryGold
                : AppTheme.accentBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            userRole == UserRole.superAdmin ? '👑 ADMIN' : '🛡️ MOD',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

/// User Role Badge - Synchrone Version (wenn Rolle bereits bekannt)
class UserRoleBadgeSync extends StatelessWidget {
  final UserRole userRole;
  final double fontSize;
  final EdgeInsets padding;

  const UserRoleBadgeSync({
    super.key,
    required this.userRole,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    if (userRole == UserRole.user) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: userRole == UserRole.superAdmin
            ? AppTheme.secondaryGold
            : AppTheme.accentBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        userRole == UserRole.superAdmin ? '👑 ADMIN' : '🛡️ MOD',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
