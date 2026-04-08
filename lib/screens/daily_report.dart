import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/task_model.dart';
import '../models/session_model.dart';
import '../data/local_storage.dart';
import '../data/repository.dart';
import '../data/supabase_repository.dart';
import '../config.dart';
import '../widgets/execution_heatmap.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final DatabaseRepository _storage = AppConfig.isCloudReady ? SupabaseRepository() : LocalStorage();
  bool _isLoading = true;
  
  List<TaskModel> _tasks = [];
  List<SessionModel> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tasks = await _storage.getTasks();
    final sessions = await _storage.getSessions();
    setState(() {
      _tasks = tasks;
      _sessions = sessions;
      _isLoading = false;
    });
  }

  String _getBrutalFeedback() {
    if (_tasks.isEmpty) return "You planned absolutely nothing today. At least you're honest about doing zero work.";
    
    int completed = _tasks.where((t) => t.isCompleted).length;
    double completionRate = completed / _tasks.length;
    
    int totalPauses = _sessions.fold(0, (sum, s) => sum + s.pauseCount);
    int plannedMinutes = _sessions.fold(0, (sum, s) => sum + s.plannedDurationMinutes);
    int actualMinutes = _sessions.fold(0, (sum, s) => sum + s.actualFocusMinutes);

    String feedback = "You planned ${_tasks.length} tasks. Completed $completed. ";
    
    if (completionRate == 0) {
      feedback += "A complete failure to execute today.";
    } else if (completionRate < 0.5) {
      feedback += "You vastly overestimate your capacity.";
    } else if (completionRate < 1.0) {
      feedback += "Average execution. Left meat on the bone.";
    } else {
      feedback += "You actually finished everything you said you would. Rare.";
    }

    if (totalPauses > 3) {
      feedback += "\n\nAlso, your focus is shot. You paused $totalPauses times during your work blocks. Stop leaking time.";
    }
    
    if (actualMinutes < plannedMinutes * 0.7 && _sessions.isNotEmpty) {
      feedback += "\n\nYou abandoned your deep work sessions way too early.";
    }

    return feedback;
  }

  double get _executionScore {
    if (_tasks.isEmpty) return 0.0;
    int completed = _tasks.where((t) => t.isCompleted).length;
    return (completed / _tasks.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    int totalActualMinutes = _sessions.fold(0, (sum, s) => sum + s.actualFocusMinutes);
    int totalPlannedMinutesPerTasks = _tasks.fold(0, (sum, t) => sum + t.estimatedMinutes);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          "REALITY REPORT",
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 20, color: Theme.of(context).colorScheme.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "BRUTAL FEEDBACK",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white54,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getBrutalFeedback(),
                style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "TIME LEAKAGE",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white54,
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      color: Theme.of(context).colorScheme.primary,
                      value: totalActualMinutes.toDouble(),
                      title: "Focused\n${totalActualMinutes}m",
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    PieChartSectionData(
                      color: const Color(0xFF333333),
                      value: (totalPlannedMinutesPerTasks - totalActualMinutes).clamp(0.0, double.infinity).toDouble(),
                      title: "Lost\n${(totalPlannedMinutesPerTasks - totalActualMinutes).clamp(0, 9999)}m",
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Column(
                children: [
                  Text(
                    "FINAL EXECUTION SCORE",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${_executionScore.toInt()}%",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 64,
                          color: _executionScore == 100
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ExecutionHeatmap(
              data: _generateMockHeatmapData(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Map<DateTime, double> _generateMockHeatmapData() {
    final Map<DateTime, double> mockData = {};
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      // Give some random scores to show the colors
      if (i % 3 == 0) mockData[day] = 85.0; // Green
      if (i % 4 == 0) mockData[day] = 55.0; // Dark Green
      if (i % 7 == 0) mockData[day] = 20.0; // Very Dark Green
    }
    // Set today score
    mockData[DateTime(now.year, now.month, now.day)] = _executionScore;
    return mockData;
  }
}
