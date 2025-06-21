import 'dart:convert';
import 'local_storage_service.dart';

class MessageTracker {
  static const String _storageKey = 'daily_message_counts';
  
  /// Save a message count for today
  static Future<void> incrementTodayMessageCount() async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final countsJson = await LocalStorageService.getString(_storageKey);
      Map<String, int> counts = {};
      
      if (countsJson != null) {
        counts = Map<String, int>.from(json.decode(countsJson));
      }
      
      counts[dateKey] = (counts[dateKey] ?? 0) + 1;
      
      await LocalStorageService.setString(_storageKey, json.encode(counts));
    } catch (e) {
      print('Error saving message count: $e');
    }
  }
  
  /// Get message count for a specific date
  static Future<int> getMessageCountForDate(DateTime date) async {
    try {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final countsJson = await LocalStorageService.getString(_storageKey);
      if (countsJson != null) {
        final counts = Map<String, int>.from(json.decode(countsJson));
        return counts[dateKey] ?? 0;
      }
    } catch (e) {
      print('Error loading message count: $e');
    }
    return 0;
  }
  
  /// Get today's message count
  static Future<int> getTodayMessageCount() async {
    return getMessageCountForDate(DateTime.now());
  }
  
  /// Get all-time total message count
  static Future<int> getAllTimeMessageCount() async {
    try {
      final countsJson = await LocalStorageService.getString(_storageKey);
      if (countsJson != null) {
        final counts = Map<String, int>.from(json.decode(countsJson));
        return counts.values.reduce((sum, count) => sum + count);
      }
    } catch (e) {
      print('Error loading all-time message count: $e');
    }
    return 0;
  }
  
  /// Clear all message counts
  static Future<void> clearAllCounts() async {
    try {
      await LocalStorageService.remove(_storageKey);
      print('All message counts cleared');
    } catch (e) {
      print('Error clearing message counts: $e');
    }
  }
} 