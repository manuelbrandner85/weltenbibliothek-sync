import 'package:flutter/material.dart';
import '../services/telegram_service.dart';
import '../config/app_theme.dart';

/// Telegram Health Status Widget (Phase 2.1)
/// 
/// Zeigt den aktuellen Status der Telegram-Synchronisation:
/// - 🟢 Grün: Polling läuft perfekt
/// - 🟡 Gelb: Polling mit Problemen (Exponential Backoff aktiv)
/// - 🔴 Rot: Polling ausgefallen
class TelegramHealthWidget extends StatefulWidget {
  const TelegramHealthWidget({super.key});

  @override
  State<TelegramHealthWidget> createState() => _TelegramHealthWidgetState();
}

class _TelegramHealthWidgetState extends State<TelegramHealthWidget> {
  final TelegramService _telegramService = TelegramService();
  
  @override
  Widget build(BuildContext context) {
    final status = _telegramService.getPollingStatus();
    final isHealthy = status['isHealthy'] as bool;
    final isActive = status['isActive'] as bool;
    final interval = status['interval'] as int;
    final errors = status['consecutiveErrors'] as int;
    
    // Bestimme Status-Farbe
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (!isActive) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Inaktiv';
    } else if (!isHealthy) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Probleme';
    } else if (errors > 0 || interval > 2) {
      statusColor = Colors.yellow;
      statusIcon = Icons.info;
      statusText = 'Wiederherstellung';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Online';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Status-Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Status-Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Telegram-Synchronisation',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (interval > 2) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Polling-Intervall: ${interval}s',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Fehler-Badge (wenn vorhanden)
          if (errors > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$errors',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // Details-Button
          IconButton(
            icon: Icon(Icons.info_outline, color: AppTheme.accentBlue),
            onPressed: () => _showDetailsDialog(context, status),
          ),
        ],
      ),
    );
  }
  
  void _showDetailsDialog(BuildContext context, Map<String, dynamic> status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Row(
          children: [
            Icon(Icons.insights, color: AppTheme.accentBlue),
            const SizedBox(width: 8),
            Text(
              'Telegram Status',
              style: TextStyle(color: AppTheme.textWhite),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusRow('Initialisiert', status['isInitialized']),
              _buildStatusRow('Aktiv', status['isActive']),
              _buildStatusRow('Polling läuft', status['isPolling']),
              _buildStatusRow('Gesund', status['isHealthy']),
              const Divider(height: 24),
              _buildInfoRow('Polling-Intervall', '${status['interval']}s'),
              _buildInfoRow('Aufeinanderfolgende Fehler', '${status['consecutiveErrors']}'),
              _buildInfoRow('Letzte Update-ID', '${status['lastUpdateId']}'),
              if (status['lastSuccessfulPoll'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Letzter erfolgreicher Poll:',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatTimestamp(status['lastSuccessfulPoll']),
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen', style: TextStyle(color: AppTheme.accentBlue)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textGrey),
          ),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textGrey),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(String? iso8601) {
    if (iso8601 == null) return 'Nie';
    
    try {
      final dt = DateTime.parse(iso8601);
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inSeconds < 60) {
        return 'vor ${diff.inSeconds}s';
      } else if (diff.inMinutes < 60) {
        return 'vor ${diff.inMinutes}min';
      } else {
        return 'vor ${diff.inHours}h';
      }
    } catch (e) {
      return 'Unbekannt';
    }
  }
}
