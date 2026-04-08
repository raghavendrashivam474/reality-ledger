import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task_model.dart';
import '../models/session_model.dart';
import '../data/local_storage.dart';
import '../data/repository.dart';
import '../data/supabase_repository.dart';
import '../config.dart';
import '../services/identity_service.dart';

class WeeklyTrendsScreen extends StatefulWidget {
  const WeeklyTrendsScreen({super.key});

  @override
  State<WeeklyTrendsScreen> createState() => _WeeklyTrendsScreenState();
}

class _WeeklyTrendsScreenState extends State<WeeklyTrendsScreen> {
  final DatabaseRepository _repository = AppConfig.isCloudReady ? SupabaseRepository() : LocalStorage();
  bool _isLoading = true;
  List<SessionModel> _sessions = [];
  List<TaskModel> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tasks = await _repository.getTasks();
    final sessions = await _repository.getSessions();
    setState(() {
      _tasks = tasks;
      _sessions = sessions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Calculate Leakage
    int totalPlannedMinutes = _tasks.fold(0, (sum, t) => sum + t.estimatedMinutes);
    int totalActualMinutes = _sessions.fold(0, (sum, s) => sum + s.actualFocusMinutes);
    int leakedMinutes = (totalPlannedMinutes - totalActualMinutes).clamp(0, 99999);
    
    double executionEfficiency = totalPlannedMinutes > 0 
        ? (totalActualMinutes / totalPlannedMinutes).clamp(0.0, 1.0) 
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          "WEEKLY LEAKAGE",
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareReport(executionEfficiency),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "7-DAY PERFORMANCE TREND",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white54,
                  ),
            ),
            const SizedBox(height: 16),
            _buildPerformanceChart(),
            const SizedBox(height: 40),
            _buildStatCard(
              "TOTAL LEAKED TIME",
              "${(leakedMinutes / 60).toStringAsFixed(1)} HOURS",
              "Minutes you planned but never executed.",
              Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 20),
            _buildStatCard(
              "EXECUTION EFFICIENCY",
              "${(executionEfficiency * 100).toInt()}%",
              "Actual focus vs. intended focus.",
              Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 40),
            Text(
              "LEAK ZONES",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white54,
                  ),
            ),
            const SizedBox(height: 16),
            _buildLeakZoneTile("Abandoned Sessions", "${_sessions.length} sessions ended early"),
            _buildLeakZoneTile("Overestimated Capacity", "${(leakedMinutes % 60)} minutes untracked"),
            const SizedBox(height: 40),
            Text(
              "CATEGORY SPLIT",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white54,
                  ),
            ),
            const SizedBox(height: 16),
            ..._buildCategorySplit(totalActualMinutes),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white38),
                  const SizedBox(height: 12),
                  const Text(
                    "Execution OS version 1.0 focuses on manual intent-to-reality gaps. V2 will automate leakage detection via screen-time hooks.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String subLabel, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  color: color,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subLabel,
            style: const TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLeakZoneTile(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
        ],
      ),
    );
  }

  List<Widget> _buildCategorySplit(int totalActual) {
    if (totalActual == 0) return [const Text("No data to split.", style: TextStyle(color: Colors.white24))];

    final Map<String, int> tagMinutes = {};
    for (var session in _sessions) {
      final task = _tasks.firstWhere((t) => t.id == session.taskId, 
          orElse: () => TaskModel(id: '', title: '', estimatedMinutes: 0, tag: 'UNKNOWN', createdAt: DateTime.now()));
      tagMinutes[task.tag] = (tagMinutes[task.tag] ?? 0) + session.actualFocusMinutes;
    }

    return tagMinutes.entries.map((entry) {
      final percentage = entry.value / totalActual;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("${entry.value}m", style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPerformanceChart() {
    // Generate scores for last 7 days
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final dayTasks = _tasks.where((t) => DateFormat('yyyy-MM-dd').format(t.createdAt) == dateStr).toList();
      double score = 0;
      if (dayTasks.isNotEmpty) {
        int completed = dayTasks.where((t) => t.isCompleted).length;
        score = (completed / dayTasks.length) * 100;
      }
      
      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: score,
              color: score > 70 ? Theme.of(context).colorScheme.primary : (score > 30 ? Colors.amber : Theme.of(context).colorScheme.secondary),
              width: 18,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: Colors.white10,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barGroups: barGroups,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = now.subtract(Duration(days: 6 - value.toInt()));
                  return Text(
                    DateFormat('E').format(date)[0],
                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _shareReport(double efficiency) {
    final tier = IdentityService.getTierTitle(IdentityService.calculateTier(_tasks));
    final report = """
[ EXECUTION OS :: WEEKLY REPORT ]
Identity: $tier
Efficiency: ${(efficiency * 100).toInt()}%

Reality is what you execute, not what you plan.
#ExecutionOS #RealityTracker
""";
    
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("REALITY REPORT COPIED TO CLIPBOARD.", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.white10,
      ),
    );
  }
}
