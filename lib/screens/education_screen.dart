// File: lib/screens/education_screen.dart
import 'package:flutter/material.dart';

class EducationScreen extends StatefulWidget {
  @override
  _EducationScreenState createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  int _currentTopicIndex = 0;
  PageController _pageController = PageController();

  final List<SecurityTopic> _securityTopics = [
    SecurityTopic(
      title: 'Education',
      icon: Icons.visibility,
      color: Colors.red,
      content: [
        SecurityContent(
          title: 'What is Hate Speech?',
          description: 'Understanding harmful online content',
          details: [
            '• Content targeting individuals based on race, religion, gender, or identity',
            '• Threats, harassment, or incitement to violence',
            '• Dehumanizing language or slurs',
            '• Content promoting discrimination or hatred',
            '• Coded language or symbols used to spread hatred'
          ],
          tip: 'Hate speech often escalates - early recognition helps prevent harm!',
        ),
        SecurityContent(
          title: 'Common Tactics Used',
          description: 'How hate speech spreads online',
          details: [
            '• Dog whistles - coded language that appears innocent',
            '• Memes and images to normalize harmful ideas',
            '• Brigading - coordinated harassment campaigns',
            '• Creating fake controversies to spread division',
            '• Using humor to mask serious harmful content'
          ],
          tip: 'Hate groups often test boundaries with seemingly harmless content first!',
        ),
      ],
    ),
    SecurityTopic(
      title: 'Platform Safety',
      icon: Icons.shield,
      color: Colors.blue,
      content: [
        SecurityContent(
          title: 'Reporting Mechanisms',
          description: 'How to report hate speech effectively',
          details: [
            '• Use platform-specific reporting tools',
            '• Screenshot evidence before reporting',
            '• Report to multiple platforms if content spreads',
            '• Follow up on reports when possible',
            '• Know the difference between reporting and blocking'
          ],
          tip: 'Quick reporting helps platforms remove harmful content faster!',
        ),
        SecurityContent(
          title: 'Privacy Protection',
          description: 'Protecting yourself from targeted harassment',
          details: [
            '• Limit personal information in public profiles',
            '• Use privacy settings to control who can contact you',
            '• Don\'t engage directly with hate speech posts',
            '• Create separate accounts for different purposes',
            '• Enable two-factor authentication on all accounts'
          ],
          tip: 'Your digital privacy is your first line of defense!',
        ),
      ],
    ),
    SecurityTopic(
      title: 'Content Moderation',
      icon: Icons.filter_alt,
      color: Colors.green,
      content: [
        SecurityContent(
          title: 'Filtering Tools',
          description: 'Using technology to reduce exposure',
          details: [
            '• Enable keyword filtering on social platforms',
            '• Use content filters in browsers and apps',
            '• Adjust algorithm preferences to reduce harmful content',
            '• Install browser extensions that block hate sites',
            '• Use parental controls for family protection'
          ],
          tip: 'Proactive filtering creates a safer online environment!',
        ),
        SecurityContent(
          title: 'Safe Spaces Online',
          description: 'Creating and maintaining positive communities',
          details: [
            '• Join moderated communities with clear guidelines',
            '• Participate in platforms with strong anti-hate policies',
            '• Support community moderators and their decisions',
            '• Help create inclusive online environments',
            '• Share positive content to counter negativity'
          ],
          tip: 'Building positive communities makes the internet safer for everyone!',
        ),
      ],
    ),
    SecurityTopic(
      title: 'Digital Wellness',
      icon: Icons.psychology,
      color: Colors.purple,
      content: [
        SecurityContent(
          title: 'Mental Health Protection',
          description: 'Protecting your psychological wellbeing',
          details: [
            '• Limit exposure to hateful content',
            '• Take regular breaks from social media',
            '• Seek support when feeling overwhelmed',
            '• Practice digital mindfulness',
            '• Focus on positive online interactions'
          ],
          tip: 'Your mental health is just as important as your digital security!',
        ),
        SecurityContent(
          title: 'Supporting Others',
          description: 'How to help those targeted by hate speech',
          details: [
            '• Offer support to those being harassed',
            '• Amplify positive voices and content',
            '• Educate others about the impact of hate speech',
            '• Don\'t share or engage with hateful content',
            '• Connect people with appropriate resources'
          ],
          tip: 'Supporting others creates a stronger, safer online community!',
        ),
      ],
    ),
    SecurityTopic(
      title: 'Legal Awareness',
      icon: Icons.gavel,
      color: Colors.orange,
      content: [
        SecurityContent(
          title: 'Understanding Laws',
          description: 'Know your rights and legal protections',
          details: [
            '• Learn about hate speech laws in your region',
            '• Understand the difference between free speech and hate speech',
            '• Know when to involve law enforcement',
            '• Document evidence of serious threats',
            '• Understand platform terms of service'
          ],
          tip: 'Knowledge of your legal rights empowers you to take appropriate action!',
        ),
        SecurityContent(
          title: 'Seeking Help',
          description: 'When and how to get professional assistance',
          details: [
            '• Contact authorities for credible threats',
            '• Reach out to anti-hate organizations',
            '• Consult with legal experts when needed',
            '• Use hotlines for immediate support',
            '• Keep records of harassment for evidence'
          ],
          tip: 'Don\'t hesitate to seek help - you don\'t have to face hate speech alone!',
        ),
      ],
    ),
    SecurityTopic(
      title: 'Counter-Messaging',
      icon: Icons.campaign,
      color: Colors.teal,
      content: [
        SecurityContent(
          title: 'Positive Messaging',
          description: 'Promoting inclusive and respectful communication',
          details: [
            '• Share content that celebrates diversity',
            '• Use inclusive language in your posts',
            '• Challenge misconceptions with factual information',
            '• Promote empathy and understanding',
            '• Lead by example in online interactions'
          ],
          tip: 'Positive messaging can help shift online culture toward inclusion!',
        ),
        SecurityContent(
          title: 'Education and Awareness',
          description: 'Helping others recognize and combat hate speech',
          details: [
            '• Share educational resources about hate speech',
            '• Teach others about digital literacy',
            '• Promote critical thinking about online content',
            '• Support media literacy programs',
            '• Encourage respectful dialogue and debate'
          ],
          tip: 'Education is one of the most powerful tools against hate speech!',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Education'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.quiz, color: Colors.grey[700]),
            onPressed: _showSecurityQuiz,
            tooltip: 'Awareness Quiz',
          ),
        ],
      ),
      body: Column(
        children: [
          // Topic Selection Grid
          Container(
            padding: EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _securityTopics.length,
              itemBuilder: (context, index) {
                final topic = _securityTopics[index];
                final isSelected = index == _currentTopicIndex;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTopicIndex = index;
                    });
                    _pageController.animateToPage(
                      index,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? topic.color : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? topic.color : topic.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            topic.icon,
                            color: isSelected ? Colors.white : topic.color,
                            size: 24,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            topic.title,
                            style: TextStyle(
                              color: isSelected ? topic.color : Colors.black87,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Content Area
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
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
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentTopicIndex = index;
                  });
                },
                itemCount: _securityTopics.length,
                itemBuilder: (context, index) {
                  return _buildTopicContent(_securityTopics[index]);
                },
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTopicContent(SecurityTopic topic) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: topic.content.length,
      itemBuilder: (context, index) {
        final content = topic.content[index];
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ExpansionTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: topic.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(topic.icon, color: topic.color),
            ),
            title: Text(
              content.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              content.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...content.details.map((detail) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        detail,
                        style: TextStyle(fontSize: 14),
                      ),
                    )).toList(),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: topic.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: topic.color.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, color: topic.color, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              content.tip,
                              style: TextStyle(
                                color: topic.color,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSecurityQuiz() {
    int? selectedAnswer;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.quiz, color: Colors.indigo[600]),
              SizedBox(width: 8),
              Text('Hate Speech Awareness', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Test your understanding of hate speech prevention!', style: TextStyle(fontStyle: FontStyle.italic)),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What should you do when you encounter hate speech online?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ...['Ignore it completely', 'Report it to the platform', 'Share it to expose it', 'Argue with the poster']
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    return RadioListTile<int>(
                      title: Text(option, style: TextStyle(fontSize: 12)),
                      value: index,
                      groupValue: selectedAnswer,
                      onChanged: (value) {
                        setState(() {
                          selectedAnswer = value;
                        });
                      },
                      dense: true,
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: selectedAnswer != null ? () {
                Navigator.pop(context);
                _showQuizResult();
              } : null,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuizResult() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Great Awareness!'),
          ],
        ),
        content: Text(
          'Continue learning about hate speech prevention to help create safer online spaces. Remember: reporting, supporting others, and promoting positive content are key to combating hate speech!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue Learning'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class SecurityTopic {
  final String title;
  final IconData icon;
  final Color color;
  final List<SecurityContent> content;

  SecurityTopic({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
  });
}

class SecurityContent {
  final String title;
  final String description;
  final List<String> details;
  final String tip;

  SecurityContent({
    required this.title,
    required this.description,
    required this.details,
    required this.tip,
  });
}