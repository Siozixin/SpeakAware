// File: lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/message.dart';
import '../services/ai_hate_speech_filter.dart';
import '../widgets/message_bubble.dart';
import '../widgets/suggestion_box.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  List<String> _currentSuggestions = [];
  bool _showSuggestion = false;
  bool _isAnalyzing = false;
  Timer? _suggestionTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _messageController.addListener(_onMessageChanged);
  }

  void _loadInitialMessages() {
    setState(() {
      _messages = [
        Message(
          id: '1',
          text: 'Hey everyone! 👋',
          sender: 'Alex',
          timestamp: DateTime.now().subtract(Duration(minutes: 30)),
        ),
        Message(
          id: '2',
          text: 'What\'s up? Ready for the game tonight?',
          sender: 'Jordan',
          timestamp: DateTime.now().subtract(Duration(minutes: 25)),
        ),
        Message(
          id: '3',
          text: 'I\'m so excited! 🎮',
          sender: 'Sam',
          timestamp: DateTime.now().subtract(Duration(minutes: 20)),
        ),
      ];
    });
  }

  void _onMessageChanged() {
    final text = _messageController.text;
    _suggestionTimer?.cancel();
    
    if (text.isNotEmpty && text.length > 3) {
      _suggestionTimer = Timer(Duration(milliseconds: 1000), () async {
        setState(() {
          _isAnalyzing = true;
        });

        try {
          // Use AI to analyze the message
          final result = await AIHateSpeechFilter.analyzeMessage(text);
          
          if (mounted) {
            setState(() {
              if (result.hasHate && result.suggestions.isNotEmpty) {
                _currentSuggestions = result.suggestions;
                _showSuggestion = true;
              } else {
                _showSuggestion = false;
              }
              _isAnalyzing = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
              _showSuggestion = false;
            });
          }
        }
      });
    } else {
      setState(() {
        _showSuggestion = false;
        _isAnalyzing = false;
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Show loading state
    setState(() {
      _messageController.clear();
      _showSuggestion = false;
    });

    try {
      // Analyze message with AI
      final result = await AIHateSpeechFilter.analyzeMessage(text);
      
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: result.hasHate ? result.filteredText : text,
        sender: 'You',
        timestamp: DateTime.now(),
        isFiltered: result.hasHate,
        originalText: result.hasHate ? result.originalText : null,
        suggestion: result.suggestions.isNotEmpty ? result.suggestions.first : null,
      );

      setState(() {
        _messages.add(message);
      });

      _scrollToBottom();

      // Show a brief notification if message was filtered
      if (result.hasHate) {
        _showFilteredNotification(result.severity);
      }
    } catch (e) {
      // If AI fails, send message without filtering but show warning
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        sender: 'You',
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(message);
      });

      _scrollToBottom();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI filter temporarily unavailable'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFilteredNotification(String severity) {
    final messages = {
      'low': 'Message was lightly filtered for kindness',
      'medium': 'Message was filtered to promote respect',
      'high': 'Message was heavily filtered for safety',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.shield, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(messages[severity] ?? 'Message was filtered'),
          ],
        ),
        backgroundColor: severity == 'high' ? Colors.red[600] : Colors.blue[600],
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _applySuggestion(String suggestion) {
    _messageController.text = suggestion;
    setState(() {
      _showSuggestion = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield, color: Colors.white),
            SizedBox(width: 8),
            Text('HateShield Chat'),
            if (_isAnalyzing) ...[
              SizedBox(width: 12),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.psychology),
            onPressed: () {
              _showAIInfo();
            },
            tooltip: 'AI Protection Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // AI Status Banner
          if (_isAnalyzing)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI is analyzing your message...',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),
          
          // AI Suggestions
          if (_showSuggestion && _currentSuggestions.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _currentSuggestions.take(2).map((suggestion) {
                  return SuggestionBox(
                    suggestion: suggestion,
                    onApply: () => _applySuggestion(suggestion),
                  );
                }).toList(),
              ),
            ),
          
          // Message Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 10,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a kind message... (AI Protected)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      suffixIcon: _isAnalyzing 
                        ? Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Icon(Icons.psychology, color: Colors.blue[400]),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  child: Icon(Icons.send),
                  mini: true,
                  backgroundColor: Colors.blue[600],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAIInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.psychology, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text('AI Protection'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your messages are protected by AI that:'),
            SizedBox(height: 8),
            _buildInfoItem('🔍', 'Detects inappropriate language'),
            _buildInfoItem('✨', 'Suggests kinder alternatives'),
            _buildInfoItem('🛡️', 'Filters harmful content'),
            _buildInfoItem('📊', 'Learns to improve over time'),
            SizedBox(height: 12),
            Text(
              'All analysis happens securely and helps create a safer chat environment.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _suggestionTimer?.cancel();
    super.dispose();
  }
}