import 'package:flutter/material.dart';
import '../widgets/stat_card.dart';
import '../widgets/activity_item.dart';
import '../services/hate_speech_tracker.dart';
import '../services/message_tracker.dart';
import '../models/hate_pattern.dart';
import 'dart:async';
import '../services/local_storage_service.dart';

class ParentalDashboard extends StatefulWidget {
  @override
  _ParentalDashboardState createState() => _ParentalDashboardState();
}

class _ParentalDashboardState extends State<ParentalDashboard> with WidgetsBindingObserver {
  List<HateSpeechIncident> _todayIncidents = [];
  Map<String, int> _categoryStats = {};
  Map<String, Map<String, int>> _weeklyStats = {};
  int _todayMessageCount = 0;
  double _safetyScore = 0.0;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
    // Refresh data every 30 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app becomes visible
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all data in parallel
      final results = await Future.wait([
        HateSpeechTracker.getTodayIncidents(),
        HateSpeechTracker.getCategoryStats(),
        HateSpeechTracker.getWeeklyStats(),
        MessageTracker.getTodayMessageCount(),
        _calculateSafetyScore(),
      ]);

      if (mounted) {
        setState(() {
          _todayIncidents = results[0] as List<HateSpeechIncident>;
          _categoryStats = results[1] as Map<String, int>;
          _weeklyStats = results[2] as Map<String, Map<String, int>>;
          _todayMessageCount = results[3] as int;
          _safetyScore = results[4] as double;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<double> _calculateSafetyScore() async {
    try {
      final totalMessages = await MessageTracker.getAllTimeMessageCount();
      final totalIncidents = await HateSpeechTracker.getIncidents();
      
      if (totalMessages == 0) return 100.0;
      
      final safeMessages = totalMessages - totalIncidents.length;
      return ((safeMessages / totalMessages) * 100).clamp(0.0, 100.0);
    } catch (e) {
      print('Error calculating safety score: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Parental Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[700]),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Dashboard',
          ),
          IconButton(
            icon: Icon(Icons.clear_all, color: Colors.grey[700]),
            onPressed: _clearAllData,
            tooltip: 'Clear All Data',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricsGrid(),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.category, color: Colors.grey[700]),
                      SizedBox(width: 8),
                      Text(
                        'Hate Speech Categories',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildCategoryChart(),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.grey[700]),
                      SizedBox(width: 8),
                      Text(
                        'Weekly Trend',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildWeeklyChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          // First row
          Row(
            children: [
              // Left side - narrower
              Expanded(
                flex: 2,
                child: StatCard(
                  title: 'Hate Speeches (Today)',
                  value: _todayIncidents.length.toString(),
                  icon: Icons.shield,
                  color: Colors.red,
                  isCompact: true,
                ),
              ),
              SizedBox(width: 16),
              // Right side - wider
              Expanded(
                flex: 3,
                child: StatCard(
                  title: 'Safety Score (Overall)',
                  value: '${_safetyScore.round()}%',
                  icon: Icons.safety_check,
                  color: Colors.green,
                  isCompact: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Second row
          Row(
            children: [
              // Left side - narrower
              Expanded(
                flex: 2,
                child: StatCard(
                  title: 'Messages (Today)',
                  value: _todayMessageCount.toString(),
                  icon: Icons.message,
                  color: Colors.blue,
                  isCompact: true,
                ),
              ),
              SizedBox(width: 16),
              // Right side - wider
              Expanded(
                flex: 3,
                child: StatCard(
                  title: 'Top Category',
                  value: _getMostCommonCategory(),
                  icon: Icons.category,
                  color: Colors.orange,
                  isCompact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMostCommonCategory() {
    if (_categoryStats.isEmpty) return 'None';
    final sorted = _categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key.toUpperCase();
  }

  Widget _buildCategoryChart() {
    if (_categoryStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
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
        child: Center(child: Text('No hate speech incidents recorded yet.')),
      );
    }

    final totalIncidents = _categoryStats.values.fold<int>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
        children: _categoryStats.entries.map((entry) {
          final percentage = (totalIncidents == 0) ? 0.0 : (entry.value) / totalIncidents;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entry.key.toUpperCase()} (${entry.value})',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text('${(percentage * 100).toInt()}%'),
                  ],
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(entry.key)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyStats.isEmpty) {
      return Container(
        height: 180,
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
        child: Center(child: Text('No weekly data available yet.')),
      );
    }

    const dayAbbreviations = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      height: 180,
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
        child: Row(
          children: _weeklyStats.entries.map((entry) {
            final date = DateTime.parse(entry.key);
            final dayLabel = dayAbbreviations[date.weekday - 1];
            final dayStats = entry.value;
            final totalForDay = dayStats.values.fold<int>(0, (sum, count) => sum + count);
            final now = DateTime.now();
            final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

            return Expanded(
              child: GestureDetector(
                onTap: () => _showDayDetails(entry.key),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (totalForDay > 0)
                      Text(totalForDay.toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: totalForDay == 0
                            ? null
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: dayStats.entries.map((categoryEntry) {
                                  final count = categoryEntry.value;
                                  final proportion = totalForDay > 0 ? (count) / totalForDay : 0.0;
                                  return Flexible(
                                    flex: (proportion * 100).toInt(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(categoryEntry.key),
                                        borderRadius: BorderRadius.circular(totalForDay == count ? 4 : 0),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? Colors.purple : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDayDetails(String dateKey) async {
    final dateParts = dateKey.split('-');
    final date = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
    final incidents = await HateSpeechTracker.getIncidentsForDate(date);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hate Speech Log - ${dateKey}'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: incidents.isEmpty
              ? Center(child: Text('No incidents on this day'))
              : ListView.builder(
                  itemCount: incidents.length,
                  itemBuilder: (context, index) {
                    final incident = incidents[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          _getCategoryIcon(incident.category),
                          color: _getCategoryColor(incident.category),
                        ),
                        title: Text(
                          '${incident.category.toUpperCase()} (${incident.severity})',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Original: "${incident.originalText}"'),
                            Text('Time: ${_formatTime(incident.timestamp)}'),
                            if (incident.reason != null && incident.reason!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Reason: " ${incident.reason!}" ',
                                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'racist': return Colors.black;
      case 'misogynist': return Colors.pink;
      case 'homophobic': return Colors.purple;
      case 'ableist': return Colors.orange;
      case 'religious': return Colors.brown;
      case 'threatening': return Colors.red[700]!;
      case 'profanity': return Colors.grey;
      default: return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'racist': return Icons.people;
      case 'misogynist': return Icons.woman;
      case 'homophobic': return Icons.favorite;
      case 'ableist': return Icons.accessibility;
      case 'religious': return Icons.church;
      case 'threatening': return Icons.warning;
      case 'profanity': return Icons.block;
      default: return Icons.shield;
    }
  }

  void _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data'),
        content: Text('Are you sure you want to clear all hate speech incident data and message counts? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear All'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Clear all data
      await HateSpeechTracker.clearAllIncidents();
      await MessageTracker.clearAllCounts();
      
      // Clear in-memory storage
      LocalStorageService.clearMemoryStorage();
      
      // Reload the dashboard
      _loadDashboardData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All data cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}