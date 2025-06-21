import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _conversation = [];
  bool _isLoading = false;
  bool _isModelInitialized = false;
  late TabController _tabController;
  
  static const String _googleApiKey = 'YOUR_API_KEY';
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  @override
  void initState() {
    super.initState();
    //_tabController = TabController(length: 3, vsync: this);
    _tabController = TabController(length: 2, vsync: this);
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    try {
      print('Initializing AI with direct HTTP approach...');
      setState(() {
        _isModelInitialized = true;
      });
      print('AI model initialized successfully');
    } catch (e) {
      print('Error initializing AI: $e');
      _showErrorSnackBar('Error initializing AI: $e');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorSnackBar('Could not launch phone app');
    }
  }

  Future<void> _sendSMS(String phoneNumber, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      _showErrorSnackBar('Could not launch messaging app');
    }
  }

  Future<void> _launchWebsite(String url) async {
    final Uri websiteUri = Uri.parse(url);
    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri);
    } else {
      _showErrorSnackBar('Could not launch website');
    }
  }

  Future<void> _sendMessageToAI() async {
    print('Sending message to AI. Model initialized: $_isModelInitialized');
    
    if (!_isModelInitialized) {
      print('AI not initialized, showing error message');
      _showErrorSnackBar('AI service not configured. Please set up your API key in settings.');
      return;
    }

    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _isLoading = true;
      _conversation.add({'role': 'user', 'content': userMessage});
      _messageController.clear();
    });

    try {
      print('Generating AI response...');
      final prompt = '''
You are a supportive counselor bot designed to help Malaysian teenagers with emotional support and guidance. 
Be empathetic, understanding, and provide helpful advice while maintaining appropriate boundaries and respecting Malaysian cultural values.

Consider Malaysian cultural context:
- Respect for family values and traditions
- Understanding of multi-ethnic and multi-religious society
- Awareness of local educational and social pressures
- Sensitivity to cultural norms and expectations
- Support for both English and Bahasa Malaysia speakers

Keep responses concise but supportive, and be culturally sensitive to Malaysian teens' experiences.

User message: $userMessage
''';

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_googleApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      print('Gemini API status: ${response.statusCode}');
      print('Gemini API body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates[0]['content']['parts'][0]['text'] as String;
          print('AI response received: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');

          setState(() {
            _conversation.add({'role': 'assistant', 'content': text});
            _isLoading = false;
          });
        } else {
          throw Exception('No response from AI');
        }
      } else {
        print('Error in AI communication: ${response.body}');
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error communicating with AI: ${response.body}');
      }
    } catch (e) {
      print('Error in AI communication: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error communicating with AI: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Support & Resources'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.purple[600],
          tabs: const [
            Tab(
              icon: Icon(Icons.emergency, size: 20),
              text: 'Emergency',
            ),
            Tab(
              icon: Icon(Icons.favorite, size: 20),
              text: 'Resources',
            ),
            // Tab(
            //   icon: Icon(Icons.chat_bubble, size: 20),
            //   text: 'Counselor',
            // ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmergencyTab(),
          _buildMentalHealthTab(),
          //_buildCounselorTab(),
        ],
      ),
    );
  }

  Widget _buildEmergencyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencySection(),
        ],
      ),
    );
  }

  Widget _buildMentalHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            _buildMentalHealthResources(),
        ],
      ),
    );
  }

  // Widget _buildCounselorTab() {
  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(12.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //           _buildCounselorBot(),
  //         ],
  //     ),
  //   );
  // }

  Widget _buildEmergencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emergency, color: Colors.red[700], size: 20),
            const SizedBox(width: 6),
            Text(
              'Malaysian Emergency Support',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'If you\'re in immediate danger or experiencing severe distress:',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        
        // Emergency Calls Section
        Container(
          padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                  Icon(Icons.phone, color: Colors.red[700], size: 18),
                  const SizedBox(width: 6),
              Text(
                    'Emergency Calls',
                style: TextStyle(
                      fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
              const SizedBox(height: 8),
              _buildResourceCard(
                'Malaysian Emergency Services',
                '999',
                '24/7 emergency response for life-threatening situations',
                Icons.phone,
                Colors.red,
                () => _makePhoneCall('999'),
              ),
              const SizedBox(height: 6),
              _buildResourceCard(
                'Befrienders Malaysia',
                '03-7627 2929',
                '24/7 emotional support and suicide prevention',
                Icons.phone,
                Colors.orange,
                () => _makePhoneCall('0376272929'),
              ),
              const SizedBox(height: 6),
              _buildResourceCard(
                'Talian Kasih (Women & Children)',
                '15999',
                'Government helpline for women and children in crisis',
                Icons.phone,
                Colors.pink,
                () => _makePhoneCall('15999'),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Emergency SMS Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sms, color: Colors.red[700], size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Emergency SMS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildResourceCard(
                'Befrienders Malaysia (SMS)',
                'Text HELP to 03-7627 2929',
                'Text-based crisis intervention and support',
            Icons.sms,
            Colors.orange,
                () => _sendSMS('0376272929', 'HELP'),
              ),
              const SizedBox(height: 6),
              _buildResourceCard(
                'Talian Kasih (SMS)',
                'Text KASIH to 15999',
                'Text support for women and children',
                Icons.sms,
                Colors.pink,
                () => _sendSMS('15999', 'KASIH'),
          ),
        ],
      ),
        ),
      ],
    );
  }

  Widget _buildResourceCard(String title, String contact, String description, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13),
                  ),
                  Text(
                    contact,
                    style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildMentalHealthResources() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
            Icon(Icons.favorite, color: Colors.green[700], size: 20),
            const SizedBox(width: 6),
              Text(
              'Malaysian Mental Health Resources',
                style: TextStyle(
                fontSize: 16,
                  fontWeight: FontWeight.bold,
                color: Colors.green[700],
            ),
          ),
        ],
      ),
        const SizedBox(height: 8),
        Text(
          'Professional help and ongoing support resources available in Malaysia:',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        
        // Support Services Section
        Container(
          padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                  Icon(Icons.medical_services, color: Colors.green[700], size: 18),
                  const SizedBox(width: 6),
              Text(
                    'Support Services',
                style: TextStyle(
                      fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
              const SizedBox(height: 8),
              _buildResourceCard(
                'Befrienders Malaysia',
                '03-7627 2929',
                '24/7 emotional support, crisis intervention & ongoing counseling',
                Icons.phone,
                Colors.orange,
                () => _makePhoneCall('0376272929'),
              ),
              const SizedBox(height: 6),
          _buildResourceCard(
                'Talian Kasih',
                '15999',
                'Government helpline for women and children - crisis & support',
            Icons.phone,
                Colors.pink,
                () => _makePhoneCall('15999'),
          ),
              const SizedBox(height: 6),
          _buildResourceCard(
                'Malaysian Mental Health Association',
                '03-2780 6803',
                'Professional mental health support and counseling',
                Icons.phone,
            Colors.blue,
                () => _makePhoneCall('0327806803'),
          ),
              const SizedBox(height: 6),
          _buildResourceCard(
                'Klinik MENTARI',
                '03-2615 6565',
                'Government mental health clinics nationwide',
                Icons.local_hospital,
                Colors.green,
                () => _makePhoneCall('0326156565'),
              ),
              const SizedBox(height: 6),
          _buildResourceCard(
                'Pertubuhan Kebajikan Islam Malaysia',
                '03-4257 9999',
                'Islamic welfare organization support',
                Icons.mosque,
                Colors.teal,
                () => _makePhoneCall('0342579999'),
          ),
        ],
      ),
        ),
        
        const SizedBox(height: 12),
        
        // Online & Text Support Section
        Container(
          padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
          borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
        ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.computer, color: Colors.green[700], size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Online & Text Support',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildResourceCard(
                'Befrienders Malaysia (SMS)',
                'Text HELP to 03-7627 2929',
                'Text-based emotional support and crisis intervention',
                Icons.sms,
                Colors.orange,
                () => _sendSMS('0376272929', 'HELP'),
              ),
              const SizedBox(height: 6),
              _buildResourceCard(
                'Talian Kasih (SMS)',
                'Text KASIH to 15999',
                'Text support for women and children',
                Icons.sms,
                Colors.pink,
                () => _sendSMS('15999', 'KASIH'),
              ),
              const SizedBox(height: 6),
              _buildResourceCard(
                'Mental Health Support (SMS)',
                'Text SUPPORT to 03-2780 6803',
                'Text-based mental health guidance and referrals',
                Icons.sms,
                Colors.blue,
                () => _sendSMS('0327806803', 'SUPPORT'),
              ),
              const SizedBox(height: 6),
              _buildResourceCard(
                'Online Counseling Services',
                'Visit www.mmha.org.my',
                'Web-based counseling and mental health resources',
                Icons.language,
                Colors.purple,
                () => _launchWebsite('https://www.mmha.org.my'),
              ),
          ],
        ),
      ),
      ],
    );
  }

  Widget _buildCounselorBot() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
            Icon(Icons.chat_bubble, color: Colors.purple[700], size: 20),
            const SizedBox(width: 6),
              Text(
                'Talk to Counselor Bot',
                style: TextStyle(
                fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
          Text(
          'Get immediate emotional support and guidance from our AI counselor designed for Malaysian teens.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        const SizedBox(height: 12),
          Container(
          height: 250,
          padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
              // AI Status Indicator
              Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: _isModelInitialized ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isModelInitialized ? Colors.green[200]! : Colors.orange[200]!,
                  ),
                ),
                        child: Row(
                          children: [
                    Icon(
                      _isModelInitialized ? Icons.check_circle : Icons.warning,
                      color: _isModelInitialized ? Colors.green[700] : Colors.orange[700],
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isModelInitialized 
                          ? 'AI Counselor Ready' 
                          : 'AI Counselor Initializing...',
                      style: TextStyle(
                        color: _isModelInitialized ? Colors.green[700] : Colors.orange[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (!_isModelInitialized)
                      TextButton(
                        onPressed: _initializeAI,
                        child: const Text(
                          'Retry',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _conversation.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, 
                                 color: Colors.grey[400], size: 36),
                            const SizedBox(height: 6),
                            Text(
                              'Start a conversation with our Malaysian AI counselor',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _conversation.length,
                        itemBuilder: (context, index) {
                          final message = _conversation[index];
                          final isUser = message['role'] == 'user';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: isUser 
                                  ? MainAxisAlignment.end 
                                  : MainAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isUser ? Colors.purple[600] : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isUser ? Colors.transparent : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    message['content']!,
                                    style: TextStyle(
                                      color: isUser ? Colors.white : Colors.black87,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[600]!),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI is thinking...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        hintStyle: TextStyle(fontSize: 12),
                      ),
                      style: TextStyle(fontSize: 12),
                      onSubmitted: (_) => _sendMessageToAI(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: _isLoading ? null : _sendMessageToAI,
                    icon: Icon(
                      Icons.send,
                      color: _isLoading ? Colors.grey : Colors.purple[600],
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
                ),
              ],
            ),
          ),
        ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}  