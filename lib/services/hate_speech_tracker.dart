import 'dart:convert';
import 'local_storage_service.dart';
import '../models/hate_pattern.dart';

class HateSpeechTracker {
  static const String _storageKey = 'hate_speech_incidents';
  static List<HateSpeechIncident> _memoryCache = []; // Fallback in-memory storage
  
  /// Save a hate speech incident to local storage
  static Future<void> saveIncident(HateSpeechIncident incident) async {
    try {
      final incidents = await getIncidents();
      print('=== SAVING INCIDENT ===');
      print('Current incidents count: ${incidents.length}');
      print('Adding incident: "${incident.originalText}"');
      
      incidents.add(incident);
      
      // Keep only last 100 incidents to prevent storage overflow
      if (incidents.length > 100) {
        incidents.removeRange(0, incidents.length - 100);
      }
      
      final incidentsJson = incidents.map((i) => i.toJson()).toList();
      await LocalStorageService.setList(_storageKey, incidentsJson);
      print('New incidents count: ${incidents.length}');
      print('=======================');
    } catch (e) {
      print('Error saving hate speech incident: $e');
      // Fallback to in-memory storage
      _memoryCache.add(incident);
      if (_memoryCache.length > 100) {
        _memoryCache.removeRange(0, _memoryCache.length - 100);
      }
    }
  }
  
  /// Get all hate speech incidents from local storage
  static Future<List<HateSpeechIncident>> getIncidents() async {
    try {
      final incidentsJson = await LocalStorageService.getList(_storageKey);
      return incidentsJson.map((json) => HateSpeechIncident.fromJson(json)).toList();
    } catch (e) {
      print('Error loading hate speech incidents: $e');
      // Return in-memory cache if LocalStorageService fails
      return _memoryCache;
    }
  }
  
  /// Get incidents for a specific date
  static Future<List<HateSpeechIncident>> getIncidentsForDate(DateTime date) async {
    final allIncidents = await getIncidents();
    return allIncidents.where((incident) {
      return incident.timestamp.year == date.year &&
             incident.timestamp.month == date.month &&
             incident.timestamp.day == date.day;
    }).toList();
  }
  
  /// Get incidents for today
  static Future<List<HateSpeechIncident>> getTodayIncidents() async {
    return getIncidentsForDate(DateTime.now());
  }
  
  /// Get category statistics
  static Future<Map<String, int>> getCategoryStats() async {
    final incidents = await getIncidents();
    final stats = <String, int>{};
    
    for (final incident in incidents) {
      stats[incident.category] = (stats[incident.category] ?? 0) + 1;
    }
    
    return stats;
  }
  
  /// Get daily statistics for the last 7 days, broken down by category.
  static Future<Map<String, Map<String, int>>> getWeeklyStats() async {
    final incidents = await getIncidents();
    // The key of the outer map is the date string 'YYYY-MM-DD'
    // The value is another map where the key is the category and value is the count.
    final stats = <String, Map<String, int>>{};

    final now = DateTime.now();
    // Initialize the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      stats[dateKey] = {};
    }

    for (final incident in incidents) {
      final incidentDate = incident.timestamp;
      final dateKey = '${incidentDate.year}-${incidentDate.month.toString().padLeft(2, '0')}-${incidentDate.day.toString().padLeft(2, '0')}';
      
      // Check if the incident falls within our 7-day window
      if (stats.containsKey(dateKey)) {
        final dayStats = stats[dateKey]!;
        // Increment the count for the specific category on that day
        dayStats[incident.category] = (dayStats[incident.category] ?? 0) + 1;
      }
    }

    return stats;
  }
  
  /// Clear all incidents (for testing or privacy)
  static Future<void> clearAllIncidents() async {
    try {
      await LocalStorageService.remove(_storageKey);
      // Also clear in-memory cache
      _memoryCache.clear();
      print('All hate speech incidents cleared');
    } catch (e) {
      print('Error clearing hate speech incidents: $e');
      // Clear in-memory cache as fallback
      _memoryCache.clear();
    }
  }
} 