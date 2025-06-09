import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _filterEnabled = true;
  bool _suggestionsEnabled = true;
  bool _parentalNotifications = true;
  double _filterSensitivity = 2.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.green[600],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Filter Settings
          Text(
            'Filter Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          SwitchListTile(
            title: Text('Enable Hate Speech Filter'),
            subtitle: Text('Automatically filter inappropriate content'),
            value: _filterEnabled,
            onChanged: (value) {
              setState(() {
                _filterEnabled = value;
              });
            },
          ),
          
          SwitchListTile(
            title: Text('Enable Positive Suggestions'),
            subtitle: Text('Suggest kinder alternatives when typing'),
            value: _suggestionsEnabled,
            onChanged: (value) {
              setState(() {
                _suggestionsEnabled = value;
              });
            },
          ),
          
          // Filter Sensitivity Slider
          if (_filterEnabled) ...[
            SizedBox(height: 16),
            Text(
              'Filter Sensitivity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Slider(
              value: _filterSensitivity,
              min: 1.0,
              max: 3.0,
              divisions: 2,
              onChanged: (value) {
                setState(() {
                  _filterSensitivity = value;
                });
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _getSensitivityLabel(_filterSensitivity),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
          
          SizedBox(height: 16),
          
          ListTile(
            title: Text('AI Configuration'),
            subtitle: Text('Setup OpenAI API for enhanced protection'),
            leading: Icon(Icons.psychology),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => APISetupScreen()),
              );
            },
          ),
          
          Divider(height: 32),
          
          // Parental Controls
          Text(
            'Parental Controls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          SwitchListTile(
            title: Text('Parental Notifications'),
            subtitle: Text('Notify parents of filtered content'),
            value: _parentalNotifications,
            onChanged: (value) {
              setState(() {
                _parentalNotifications = value;
              });
            },
          ),
          
          ListTile(
            title: Text('View Dashboard'),
            subtitle: Text('Access detailed analytics and trends'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            },
          ),
          
          Divider(height: 32),
          
          // About Section
          Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          ListTile(
            title: Text('Privacy Policy'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showInfoDialog(context, 'Privacy Policy', 'Privacy policy content goes here.');
            },
          ),
          
          ListTile(
            title: Text('Terms of Service'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showInfoDialog(context, 'Terms of Service', 'Terms of service content goes here.');
            },
          ),
          
          ListTile(
            title: Text('Contact Support'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showInfoDialog(context, 'Contact Support', 'Email: support@hateshield.com\nPhone: 1-800-SHIELD');
            },
          ),
          
          SizedBox(height: 32),
          
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'HateShield Chat helps create a safer, kinder online environment for teens through AI-powered content filtering and positive communication suggestions.',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSensitivityLabel(double value) {
    switch (value.round()) {
      case 1:
        return 'Lenient - Only filters severe content';
      case 2:
        return 'Moderate - Balanced filtering';
      case 3:
        return 'Strict - Filters most negative content';
      default:
        return 'Moderate';
    }
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// Placeholder screens - you'll need to implement these
class APISetupScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Configuration'),
        backgroundColor: Colors.green[600],
      ),
      body: Center(
        child: Text('API Setup Screen - Implement your configuration here'),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.green[600],
      ),
      body: Center(
        child: Text('Dashboard Screen - Implement your analytics here'),
      ),
    );
  }
}