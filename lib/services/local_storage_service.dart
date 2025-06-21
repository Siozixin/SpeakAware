import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  static Map<String, dynamic> _memoryStorage = {};
  static bool _initialized = false;
  static Directory? _appDir;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      _appDir = await getApplicationDocumentsDirectory();
      _initialized = true;
      print('File-based storage initialized at: ${_appDir?.path}');
    } catch (e) {
      print('FATAL: Could not initialize file storage. Using memory only. Data will not persist. Error: $e');
    }
  }

  static void clearMemoryStorage() {
    _memoryStorage.clear();
  }

  static File _getFile(String key) {
    if (_appDir == null) throw Exception('File storage not initialized.');
    return File('${_appDir!.path}/$key.json');
  }

  static Future<String?> _readFile(String key) async {
    try {
      final file = _getFile(key);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('Error reading file for key "$key": $e');
    }
    return null;
  }

  static Future<bool> _writeFile(String key, String value) async {
    try {
      final file = _getFile(key);
      await file.writeAsString(value);
      return true;
    } catch (e) {
      print('Error writing file for key "$key": $e');
      return false;
    }
  }

  static Future<String?> getString(String key) async {
    if (!_initialized) await initialize();
    if (_appDir == null) return _memoryStorage[key]?.toString();

    return await _readFile(key);
  }

  static Future<bool> setString(String key, String value) async {
    if (!_initialized) await initialize();
    if (_appDir == null) {
      _memoryStorage[key] = value;
      return true;
    }
    return await _writeFile(key, value);
  }

  static Future<List<Map<String, dynamic>>> getList(String key) async {
    final jsonString = await getString(key);
    if (jsonString != null) {
      try {
        final List<dynamic> list = json.decode(jsonString);
        return list.cast<Map<String, dynamic>>();
      } catch(e) {
        print('Error decoding JSON for key "$key": $e');
      }
    }
    return [];
  }

  static Future<bool> setList(String key, List<Map<String, dynamic>> list) async {
    final jsonString = json.encode(list);
    return await setString(key, jsonString);
  }

  static Future<bool> remove(String key) async {
    if (!_initialized) await initialize();
    _memoryStorage.remove(key);
    if (_appDir == null) return true;

    try {
      final file = _getFile(key);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      print('Error removing file for key "$key": $e');
      return false;
    }
  }

  static Future<bool> clear() async {
    if (!_initialized) await initialize();
    _memoryStorage.clear();
    if (_appDir == null) return true;

    try {
      final directory = _appDir!;
      if (await directory.exists()) {
        final files = directory.listSync();
        for (final file in files) {
          if (file is File && file.path.endsWith('.json')) {
            await file.delete();
          }
        }
      }
      return true;
    } catch (e) {
      print('Error clearing file storage: $e');
      return false;
    }
  }
} 