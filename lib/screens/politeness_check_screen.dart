import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PolitenessCheckScreen extends StatefulWidget {
  @override
  _PolitenessCheckScreenState createState() => _PolitenessCheckScreenState();
}

class _PolitenessCheckScreenState extends State<PolitenessCheckScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  String _result = '';
  bool _isPolite = true;
  String _reason = '';
  String _alternative = '';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkPoliteness() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a message to check')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyAB4Al1e54CsYiXKwifmF2MR8Ncc0OlsG8'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''Analyze this message for politeness and provide a polite alternative if needed. 
                  
Message: "${_messageController.text.trim()}"

Please respond in this exact format:
POLITE: [true/false]
REASON: [brief explanation]
ALTERNATIVE: [polite version if needed, or "No change needed" if already polite]

Keep the response concise and helpful.'''
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Parse the response
        final lines = text.split('\n');
        bool isPolite = true;
        String reason = '';
        String alternative = '';
        
        for (String line in lines) {
          if (line.startsWith('POLITE:')) {
            isPolite = line.contains('true');
          } else if (line.startsWith('REASON:')) {
            reason = line.substring(7).trim();
          } else if (line.startsWith('ALTERNATIVE:')) {
            alternative = line.substring(12).trim();
          }
        }

        setState(() {
          _isPolite = isPolite;
          _result = text;
          _reason = reason;
          _alternative = alternative;
        });
      } else {
        setState(() {
          _result = 'Error: Unable to check politeness. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearAll() {
    setState(() {
      _messageController.clear();
      _result = '';
      _isPolite = true;
      _reason = '';
      _alternative = '';
    });
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.purple[600],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: Colors.purple[800],
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Politeness Check',
          style: TextStyle(
            color: Colors.black87,

          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          if (_messageController.text.isNotEmpty || _result.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[700]),
              onPressed: _clearAll,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Input Section
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.blue[600], size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Check Your Message',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 2,
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Type your message here...',
                      hintStyle: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue[600]!),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _checkPoliteness,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        padding: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Checking...'),
                              ],
                            )
                          : Text(
                              'Check Politeness',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 8),
            
            // Result Section
            if (_result.isNotEmpty)
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with status
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isPolite ? Colors.green[50] : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isPolite ? Colors.green[200]! : Colors.orange[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isPolite ? Icons.check_circle : Icons.warning,
                                color: _isPolite ? Colors.green[600] : Colors.orange[600],
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _isPolite ? 'Message is Polite' : 'Message Needs Improvement',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: _isPolite ? Colors.green[700] : Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14),
                        
                        // Reason section (only show if not polite)
                        if (!_isPolite && _reason.isNotEmpty) ...[
                          Text(
                            'Why this needs improvement:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              _reason,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.3,
                              ),
                            ),
                          ),
                          SizedBox(height: 14),
                        ],
                        
                        // Alternative section
                        if (_alternative.isNotEmpty && _alternative != 'No change needed') ...[
                          Text(
                            'Polite Alternative:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.blue[600],
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _alternative,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[800],
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 14),
                        ],
                        
                        // Tips section
                        if (!_isPolite) ...[
                          Text(
                            'Tips for Polite Communication:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTip('Use "I" statements instead of "you" statements'),
                                _buildTip('Express feelings without blaming others'),
                                _buildTip('Ask questions instead of making demands'),
                                _buildTip('Use respectful language even when disagreeing'),
                              ],
                            ),
                          ),
                        ],
                        
                        // Raw result (for debugging, can be removed)
                        if (_result.contains('Error')) ...[
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Text(
                              _result,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 