// File: lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/message.dart';
import '../models/filter_result.dart';
import '../models/hate_pattern.dart';
import '../services/ai_hate_speech_filter.dart';
import '../services/hate_speech_tracker.dart';
import '../services/message_tracker.dart';
import '../services/local_storage_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/suggestion_box.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _showSuggestion = false;
  List<String> _currentSuggestions = [];
  int _currentSuggestionIndex = 0;
  String? _lastHatefulMessage;
  bool _isAnalyzing = false;
  Timer? _suggestionTimer;
  bool _showChangeButton = false;
  List<Message> _memoryChatHistory = []; // Fallback in-memory storage
  bool _disposed = false; // Track if widget is disposed
  bool _isProcessingMessage = false; // Prevent multiple processing of same message

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  void _loadChatHistory() async {
    try {
      final chatHistoryJson = await LocalStorageService.getString('chat_history');
      if (chatHistoryJson != null) {
        final List<dynamic> chatHistory = json.decode(chatHistoryJson);
        setState(() {
          _messages = chatHistory.map((json) => Message.fromJson(json)).toList();
        });
      } else {
        // Load initial messages if no history exists
        _loadInitialMessages();
      }
    } catch (e) {
      print('Error loading chat history: $e');
      // Fallback to in-memory storage or initial messages
      if (_memoryChatHistory.isNotEmpty) {
        setState(() {
          _messages = _memoryChatHistory;
        });
      } else {
        _loadInitialMessages();
      }
    }
  }

  void _saveChatHistory() async {
    try {
      final chatHistoryJson = json.encode(_messages.map((msg) => msg.toJson()).toList());
      await LocalStorageService.setString('chat_history', chatHistoryJson);
      // Also update in-memory cache
      _memoryChatHistory = List.from(_messages);
    } catch (e) {
      print('Error saving chat history: $e');
      // Fallback to in-memory storage
      _memoryChatHistory = List.from(_messages);
    }
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

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isProcessingMessage) return;
    
    _isProcessingMessage = true;
    
    setState(() {
      _showSuggestion = false;
    });
    
    try {
      final result = await GoogleAIHateSpeechFilter.analyzeWithGoogle(text);
      final wordCount = text.trim().split(' ').where((word) => word.isNotEmpty).length;
      print('AI Result - hasHate: ${result.hasHate}, shouldCensor: ${result.shouldCensor}, wordCount: $wordCount');
      print('AI Result - suggestions: ${result.suggestions}');
      print('AI Result - filteredText: ${result.filteredText}');
      
      if (result.hasHate) {
        // Track the hate speech incident for parental dashboard
        _trackHateSpeechIncident(result);
        
        // Override AI decision: if it's long hate speech (>3 words), always show suggestions
        final shouldShowSuggestions = wordCount > 3;
        
        if (result.shouldCensor && !shouldShowSuggestions) {
          // For short hate speech, send censored version to chat (other users see nothing)
          print('Short hate speech detected - censoring');
          _lastHatefulMessage = text;
          _sendCensoredMessage(result.filteredText);
        } else {
          // For long hate speech, show suggestions popup
          print('Long hate speech detected - showing suggestions: ${result.suggestions}');
          
          // If AI didn't provide suggestions, we'll generate them immediately
          List<String> suggestions = result.suggestions;
          if (suggestions.isEmpty) {
            print('No suggestions from AI, will generate immediately');
            // Generate suggestions immediately
            try {
              final generatedSuggestions = await Future.wait([
                GoogleAIHateSpeechFilter.generatePoliteAlternative(text, tone: 'friendly'),
                GoogleAIHateSpeechFilter.generatePoliteAlternative(text, tone: 'supportive'),
                GoogleAIHateSpeechFilter.generatePoliteAlternative(text, tone: 'humorous'),
              ]);
              // Strip quotes from suggestions
              suggestions = generatedSuggestions.map((s) => s.replaceAll(RegExp(r'^"|"$'), '')).toList();
            } catch (e) {
              print('Error generating initial suggestions: $e');
              suggestions = [];
            }
          } else {
            // Strip quotes from AI suggestions
            suggestions = suggestions.map((s) => s.replaceAll(RegExp(r'^"|"$'), '')).toList();
          }
          
          setState(() {
            _currentSuggestions = suggestions;
            _showSuggestion = true;
            _lastHatefulMessage = text;
            _currentSuggestionIndex = 0;
          });
        }
        _isProcessingMessage = false;
        return; // Don't send the original message
      }
      
      // If no hate speech, send the message normally
      _sendActualMessage(text);
    } catch (e) {
      // If AI fails, send the message anyway
      _sendActualMessage(text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI filter temporarily unavailable'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    _isProcessingMessage = false;
  }

  void _trackHateSpeechIncident(FilterResult result) async {
    // Create hate speech incident for tracking
    final incident = HateSpeechIncident(
      originalText: result.originalText,
      category: result.category,
      severity: result.severity,
      timestamp: DateTime.now(),
      transformedText: result.shouldCensor ? result.filteredText : null,
      suggestions: result.suggestions,
      reason: result.reason,
    );
    
    // Save incident to local storage for parental dashboard
    await HateSpeechTracker.saveIncident(incident);
  }

  void _sendActualMessage(String text) async {
    // Track message count for dashboard
    await MessageTracker.incrementTodayMessageCount();
    
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: 'You',
      timestamp: DateTime.now(),
      isFiltered: false,
      originalText: null,
      suggestion: null,
    );
    setState(() {
      _messages.add(message);
      _textController.clear();
      _showSuggestion = false;
      _currentSuggestions = [];
      _lastHatefulMessage = null;
    });
    _saveChatHistory();
    _scrollToBottom();
    _simulateAIReply(text);
  }

  void _sendCensoredMessage(String censoredText) async {
    // Track message count for dashboard
    await MessageTracker.incrementTodayMessageCount();
    
    // Send censored message to chat - other users won't see it
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: censoredText,
      sender: 'You',
      timestamp: DateTime.now(),
      isFiltered: true,
      originalText: _lastHatefulMessage,
      suggestion: null,
    );
    setState(() {
      _messages.add(message);
      _textController.clear();
      _showSuggestion = false;
      _currentSuggestions = [];
      _lastHatefulMessage = null;
      _currentSuggestionIndex = 0;
    });
    _saveChatHistory();
    _scrollToBottom();
    // Don't simulate AI reply for censored messages since other users can't see them
  }

  void _sendSuggestion(String suggestion) async {
    // Track message count for dashboard
    await MessageTracker.incrementTodayMessageCount();
    
    // Replace the last hateful message with the suggestion
    if (_messages.isNotEmpty) {
      final lastMessage = _messages.last;
      if (lastMessage.isFiltered && lastMessage.originalText == _lastHatefulMessage) {
        setState(() {
          _messages[_messages.length - 1] = Message(
            id: lastMessage.id,
            text: suggestion,
            sender: lastMessage.sender,
            timestamp: lastMessage.timestamp,
            isFiltered: false,
            originalText: null,
            suggestion: suggestion,
          );
        });
      }
    }
    
    setState(() {
      _showSuggestion = false;
      _currentSuggestions = [];
      _lastHatefulMessage = null;
      _currentSuggestionIndex = 0;
    });
    _saveChatHistory();
    _scrollToBottom();
  }

  void _selectSuggestion(String suggestion) {
    setState(() {
      _textController.text = suggestion;
      _showSuggestion = false;
      _currentSuggestions = [];
      _currentSuggestionIndex = 0;
    });
  }

  void _getNextSuggestion() async {
    if (_lastHatefulMessage == null) return;
    
    // If no suggestions yet, generate them
    if (_currentSuggestions.isEmpty) {
      try {
        print('Generating initial suggestions for long hate speech');
        final suggestions = await Future.wait([
          GoogleAIHateSpeechFilter.generatePoliteAlternative(_lastHatefulMessage!, tone: 'friendly'),
          GoogleAIHateSpeechFilter.generatePoliteAlternative(_lastHatefulMessage!, tone: 'supportive'),
          GoogleAIHateSpeechFilter.generatePoliteAlternative(_lastHatefulMessage!, tone: 'humorous'),
        ]);
        // Strip quotes from suggestions
        final cleanSuggestions = suggestions.map((s) => s.replaceAll(RegExp(r'^"|"$'), '')).toList();
        
        if (!_disposed) {
          setState(() {
            _currentSuggestions = cleanSuggestions;
            _currentSuggestionIndex = 0;
          });
        }
        return;
      } catch (e) {
        print('Error generating initial suggestions: $e');
        return;
      }
    }
    
    // Cycle through existing suggestions
    if (!_disposed) {
      setState(() {
        _currentSuggestionIndex = (_currentSuggestionIndex + 1) % _currentSuggestions.length;
      });
    }
    
    // If we've shown all existing suggestions, generate a new one
    if (_currentSuggestionIndex == 0 && _currentSuggestions.length >= 3) {
      try {
        // Determine tone based on suggestion index
        String tone;
        switch (_currentSuggestionIndex) {
          case 0:
            tone = 'friendly';
            break;
          case 1:
            tone = 'supportive';
            break;
          case 2:
            tone = 'humorous';
            break;
          default:
            tone = 'friendly';
        }
        
        final newSuggestion = await GoogleAIHateSpeechFilter.generatePoliteAlternative(_lastHatefulMessage!, tone: tone);
        final cleanSuggestion = newSuggestion.replaceAll(RegExp(r'^"|"$'), '');
        
        if (!_disposed) {
          setState(() {
            _currentSuggestions[_currentSuggestionIndex] = cleanSuggestion;
          });
        }
      } catch (e) {
        print('Error generating new suggestion: $e');
      }
    }
  }

  void _simulateAIReply(String userMessage) async {
    final otherUsers = ['Alex', 'Jordan', 'Sam'];
    final random = DateTime.now().millisecondsSinceEpoch;
    final user = otherUsers[random % otherUsers.length];
    await Future.delayed(Duration(seconds: 2 + (random % 3)));
    
    // Check if widget is still mounted before updating UI
    if (_disposed) return;
    
    try {
      final replyText = await GoogleAIHateSpeechFilter.generateChatReply(userName: user, userMessage: userMessage);
      
      // Check again after async operation
      if (_disposed) return;
      
      _safeSetState(() {
        _messages.add(Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: replyText,
          sender: user,
          timestamp: DateTime.now(),
        ));
      });
      _saveChatHistory();
      _scrollToBottom();
    } catch (e) {
      // Check if widget is still mounted before updating UI
      if (_disposed) return;
      
      _safeSetState(() {
        _messages.add(Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Sorry, I couldn\'t generate a reply right now.',
          sender: user,
          timestamp: DateTime.now(),
        ));
      });
      _saveChatHistory();
      _scrollToBottom();
    }
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('HateShield Chat'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.psychology, color: Colors.grey[700]),
            onPressed: () {
              _showAIInfo();
            },
            tooltip: 'AI Protection Info',
          ),
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _clearChatHistory,
            tooltip: 'Clear Chat History',
          ),
        ],
      ),
      body: Column(
        children: [
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
          
          // Message Input
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(16),
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
              children: [
                // Suggestions Popup
                if (_showSuggestion)
                  Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.orange[600], size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Consider this kinder alternative:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[300]!),
                          ),
                          child: Text(
                            _currentSuggestions.isNotEmpty 
                                ? _currentSuggestions[_currentSuggestionIndex]
                                : 'Generating suggestions...',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: _getNextSuggestion,
                                child: Text(
                                  'Change',
                                  style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            if (_currentSuggestions.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _sendActualMessage(_currentSuggestions[_currentSuggestionIndex]);
                                },
                                child: Text(
                                  'Send',
                                  style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.bold),
                                ),
                              ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showSuggestion = false;
                                  _currentSuggestions = [];
                                  _currentSuggestionIndex = 0;
                                });
                              },
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // Text Input Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_showSuggestion, // Disable when popup is open
                      ),
                    ),
                    SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: _showSuggestion ? null : _sendMessage, // Disable when popup is open
                      child: Icon(Icons.send),
                      mini: true,
                      backgroundColor: _showSuggestion ? Colors.grey[400] : Colors.blue[600],
                    ),
                  ],
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
            _buildInfoItem('✨', 'Transforms hateful messages into respectful versions'),
            _buildInfoItem('🛡️', 'Maintains your intent while promoting kindness'),
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
    _disposed = true;
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // Safe setState method that checks if widget is still mounted
  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }

  void _clearChatHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Chat History'),
        content: Text('Are you sure you want to clear all chat messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages = [];
                _memoryChatHistory = [];
              });
              // Reload default messages after clearing
              _loadInitialMessages();
              // Save the default messages to storage
              _saveChatHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Chat history cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text('Clear All'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}