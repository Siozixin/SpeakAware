import 'package:flutter/material.dart';
import 'support_screen.dart';
import 'chat_screen.dart';
import 'parental_dashboard.dart';
import 'education_screen.dart';
import 'politeness_check_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    ChatScreen(),
    ParentalDashboard(),
    SupportScreen(),
    PolitenessCheckScreen(),
    EducationScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.chat, 'label': 'Chat'},
    {'icon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.phone, 'label': 'Support'},
    {'icon': Icons.check_circle, 'label': 'Politeness'},
    {'icon': Icons.school, 'label': 'Education'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isSelected = _selectedIndex == index;
            
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = index);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'],
                        color: isSelected ? Colors.blue : Colors.grey,
                        size: 24,
                      ),
                      SizedBox(height: 4),
                      Text(
                        item['label'],
                        style: TextStyle(
                          color: isSelected ? Colors.blue : Colors.grey,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}