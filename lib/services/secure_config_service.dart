import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureConfigService {
  static final _storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Keys for different API services
  static const String _openaiKeyName = 'openai_api_key';
  static const String _googleKeyName = 'YOUR_API_KEY';
  static const String _azureKeyName = 'azure_api_key';

  /// Initialize API keys (call this once when app starts or in settings)
  static Future<void> initializeKeys({
    String? openaiKey,
    String? googleKey,
    String? azureKey,
  }) async {
    if (openaiKey != null) {
      await _storage.write(key: _openaiKeyName, value: openaiKey);
    }
    if (googleKey != null) {
      await _storage.write(key: _googleKeyName, value: googleKey);
    }
    if (azureKey != null) {
      await _storage.write(key: _azureKeyName, value: azureKey);
    }
  }

  /// Get OpenAI API Key
  static Future<String?> getOpenAIKey() async {
    return await _storage.read(key: _openaiKeyName);
  }

  /// Get Google API Key
  static Future<String?> getGoogleKey() async {
    return await _storage.read(key: _googleKeyName);
  }

  /// Get Azure API Key
  static Future<String?> getAzureKey() async {
    return await _storage.read(key: _azureKeyName);
  }

  /// Check if OpenAI key exists
  static Future<bool> hasOpenAIKey() async {
    final key = await getOpenAIKey();
    return key != null && key.isNotEmpty;
  }

  /// Remove all API keys (for logout/reset)
  static Future<void> clearAllKeys() async {
    await _storage.delete(key: _openaiKeyName);
    await _storage.delete(key: _googleKeyName);
    await _storage.delete(key: _azureKeyName);
  }

  /// Update OpenAI key
  static Future<void> updateOpenAIKey(String newKey) async {
    await _storage.write(key: _openaiKeyName, value: newKey);
  }
}