import 'package:flutter/material.dart';
import '../widgets/stat_card.dart';
import '../widgets/activity_item.dart';

class ParentalDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parental Dashboard'),
        backgroundColor: Colors.purple[600],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Messages Filtered',
                    value: '12',
                    icon: Icons.shield,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Positive Suggestions',
                    value: '8',
                    icon: Icons.lightbulb,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Kindness Score',
                    value: '85%',
                    icon: Icons.favorite,
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Active Hours',
                    value: '2.5h',
                    icon: Icons.access_time,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Recent Activity
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            ActivityItem(
              title: 'Filtered inappropriate language',
              time: '2 minutes ago',
              icon: Icons.shield,
              color: Colors.blue,
            ),
            ActivityItem(
              title: 'Suggested positive alternative',
              time: '5 minutes ago',
              icon: Icons.lightbulb,
              color: Colors.orange,
            ),
            ActivityItem(
              title: 'Completed kindness challenge',
              time: '1 hour ago',
              icon: Icons.star,
              color: Colors.green,
            ),
            
            SizedBox(height: 24),
            
            // Weekly Trends
            Text(
              'Weekly Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Positive Communication'),
                      Text('+15%', style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.85,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}