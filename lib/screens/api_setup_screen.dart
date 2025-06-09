// File: lib/screens/api_setup_screen.dart
import 'package:flutter/material.dart';
import '../services/secure_config_service.dart';

class APISetupScreen extends StatefulWidget {
  @override
  _APISetupScreenState createState() => _APISetupScreenState();
}

class _APISetupScreenState extends State<APISetupScreen> {
  final _openaiController = TextEditingController();
  bool _isLoading = false;
  bool _hasExistingKey = false;

  @override
  void initState() {
    super.initState();
    _checkExistingKey();
  }

  Future<void> _checkExistingKey() async {
    final hasKey = await SecureConfigService.hasOpenAIKey();
    setState(() {
      _hasExistingKey = hasKey;
    });
  }

  Future<void> _saveApiKey() async {
    final key = _openaiController.text.trim();
    if (key.isEmpty) {
      _showError('Please enter an API key');
      return;
    }

    if (!key.startsWith('sk-')) {
      _showError('OpenAI API keys should start with "sk-"');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await SecureConfigService.updateOpenAIKey(key);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check, color: Colors.white),
                SizedBox(width: 8),
                Text('API key saved securely!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {
          _hasExistingKey = true;
          _openaiController.clear();
        });
      }
    } catch (e) {
      _showError('Failed to save API key: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _removeApiKey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove API Key?'),
        content: Text('This will disable AI-powered filtering. You can add it back anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SecureConfigService.clearAllKeys();
      setState(() {
        _hasExistingKey = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API key removed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Configuration'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _hasExistingKey ? Colors.green[50] : Colors.orange[50],
                border: Border.all(
                  color: _hasExistingKey ? Colors.green[200]! : Colors.orange[200]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    _hasExistingKey ? Icons.check_circle : Icons.warning,
                    color: _hasExistingKey ? Colors.green[600] : Colors.orange[600],
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _hasExistingKey ? 'AI Protection Active' : 'AI Protection Inactive',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _hasExistingKey ? Colors.green[800] : Colors.orange[800],
                    ),
                  ),
                  Text(
                    _hasExistingKey 
                      ? 'Your chat is protected by AI filtering'
                      : 'Add an API key to enable AI protection',
                    style: TextStyle(
                      color: _hasExistingKey ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Instructions
            Text(
              'OpenAI API Setup',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'To enable AI-powered hate speech detection and suggestions, you\'ll need an OpenAI API key.',
              style: TextStyle(color: Colors.grey[600]),
            ),

            SizedBox(height: 16),

            // Steps
            _buildStep('1', 'Visit platform.openai.com', 'Create an account or sign in'),
            _buildStep('2', 'Go to API Keys section', 'Click "Create new secret key"'),
            _buildStep('3', 'Copy your API key', 'It starts with "sk-"'),
            _buildStep('4', 'Paste it below', 'We\'ll store it securely on your device'),

            SizedBox(height: 24),

            // API Key Input
            Text(
              'API Key',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _openaiController,
              decoration: InputDecoration(
                hintText: 'sk-...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.key),
                suffixIcon: _isLoading
                  ? Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              ),
              obscureText: true,
              enabled: !_isLoading,
            ),

            SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveApiKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_hasExistingKey ? 'Update Key' : 'Save Key'),
                  ),
                ),
                if (_hasExistingKey) ...[
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _removeApiKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Remove'),
                  ),
                ],
              ],
            ),

            SizedBox(height: 24),

            // Security Note
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your API key is encrypted and stored securely on your device. It\'s never shared or sent anywhere except to OpenAI.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _openaiController.dispose();
    super.dispose();
  }
}