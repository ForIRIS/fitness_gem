import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a safety incident record
class IncidentRecord {
  final String id;
  final DateTime timestamp;
  final String type; // 'amber' or 'red'
  final String status; // 'triggered', 'dismissed', 'confirmed', 'sos_called'
  final String? notes;

  IncidentRecord({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'status': status,
      'notes': notes,
    };
  }

  factory IncidentRecord.fromMap(Map<String, dynamic> map) {
    return IncidentRecord(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
      status: map['status'],
      notes: map['notes'],
    );
  }
}

/// Service to log safety incidents locally
class IncidentLogService {
  static const String _storageKey = 'safety_incidents_log';

  Future<void> logIncident({
    required String type,
    required String status,
    String? notes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> logs = prefs.getStringList(_storageKey) ?? [];

      final newRecord = IncidentRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        type: type,
        status: status,
        notes: notes,
      );

      logs.add(json.encode(newRecord.toMap()));

      // Keep only last 50 logs
      if (logs.length > 50) {
        logs.removeRange(0, logs.length - 50);
      }

      await prefs.setStringList(_storageKey, logs);
      debugPrint('[IncidentLog] Logged: $type - $status');
    } catch (e) {
      debugPrint('[IncidentLog] Failed to log incident: $e');
    }
  }

  Future<List<IncidentRecord>> getLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> logs = prefs.getStringList(_storageKey) ?? [];

      return logs
          .map((e) => IncidentRecord.fromMap(json.decode(e)))
          .toList()
          .reversed
          .toList(); // Newest first
    } catch (e) {
      return [];
    }
  }
}
