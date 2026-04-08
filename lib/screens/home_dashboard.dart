import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/session_model.dart';
import '../data/local_storage.dart';
import 'add_task_screen.dart';
import 'focus_session.dart';
import 'daily_report.dart';
import 'weekly_trends.dart';
import 'history_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/sync_indicator.dart';
import '../data/repository.dart';
import '../data/supabase_repository.dart';
import '../config.dart';
import '../services/identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final DatabaseRepository _storage = AppConfig.isCloudReady ? SupabaseRepository() : LocalStorage();
  List<TaskModel> _todayTasks = [];
  List<SessionModel> _sessions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  
  IdentityTier _currentTier = IdentityTier.drifter;
  IdentityTier? _previousTier;
  List<String> _insights = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tasks = await _storage.getTasks();
    final sessions = await _storage.getSessions();
    
    // Calculate Today's tasks specifically
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayTasks = tasks.where((t) => DateFormat('yyyy-MM-dd').format(t.createdAt) == today).toList();

    final newTier = IdentityService.calculateTier(tasks);
    
    if (_previousTier != null && newTier.index > _previousTier!.index) {
      _showLevelUpAlert(newTier);
    }
    
    _previousTier = newTier;

    setState(() {
      _todayTasks = todayTasks;
      _sessions = sessions;
      _currentTier = newTier;
      _insights = IdentityService.detectPatterns(tasks, sessions);
      _isLoading = false;
    });

    _checkDailyTriggers();
  }

  Future<void> _checkDailyTriggers() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpen = prefs.getString('last_open_date') ?? '';
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastOpen != today) {
      await prefs.setString('last_open_date', today);
      if (mounted) _showDailyBriefing();
    }
  }

  void _showDailyBriefing() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "PRE-COMBAT BRIEFING",
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24, letterSpacing: 2) ?? 
                     const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            Text(
              "Status: ${IdentityService.getTierTitle(_currentTier)}",
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              "One non-negotiable task today. That is all it takes to keep the identity alive. What is it going to be?",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              child: const Text("I AM READY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLevelUpAlert(IdentityTier tier) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.military_tech, color: Colors.black),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("IDENTITY UPGRADE DETECTED", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text("YOU ARE NOW: ${IdentityService.getTierTitle(tier)}", style: const TextStyle(color: Colors.black, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  double get _executionScore {
    if (_todayTasks.isEmpty) return 0.0;
    try {
      int completed = _todayTasks.where((t) => t.isCompleted).length;
      return (completed / _todayTasks.length) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  String _getHeroText() {
    double score = _executionScore;
    bool mvdSuccess = _todayTasks.isNotEmpty && _todayTasks.any((t) => t.isNonNegotiable && t.isCompleted);
    
    if (_todayTasks.isEmpty) return "PLAN YOUR DAY OR WASTE IT.";
    if (mvdSuccess && score < 100) return "MINIMUM WIN SECURED. DAY SAVED.";
    if (score <= 0) return "ZERO EXECUTION DETECTED. DO SOMETHING.";
    if (score < 30) return "YOU ARE FALLING BEHIND REALITY.";
    if (score < 70) return "AVERAGE EFFORT. YOU CAN DO BETTER.";
    if (score < 100) return "ALMOST THERE. DON'T QUIT NOW.";
    return "TOTAL EXECUTION. RARE.";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int completedCount = _todayTasks.where((t) => t.isCompleted).length;

    final List<Widget> screens = [
      _buildDashboardBody(completedCount),
      const WeeklyTrendsScreen(),
      const HistoryScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              IdentityService.getTierTitle(_currentTier),
              style: TextStyle(
                fontSize: 12, 
                color: Theme.of(context).colorScheme.primary, 
                fontWeight: FontWeight.w900,
                letterSpacing: 2
              ),
            ),
            Text(
              IdentityService.getTierRequirement(_currentTier),
              style: const TextStyle(fontSize: 8, color: Colors.white24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _currentIndex == 0 
                  ? "TODAY'S TRUTH" 
                  : (_currentIndex == 1 ? "WEEKLY TRENDS" : "HISTORY LEDGER"),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 20) ?? 
                     const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          const SyncIndicator(),
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.bar_chart, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyReportScreen()));
              },
            )
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey<int>(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        backgroundColor: const Color(0xFF0F0F0F),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: "TODAY"),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: "TRENDS"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "HISTORY"),
        ],
      ),
      floatingActionButton: _currentIndex == 1 ? null : FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  Widget _buildDashboardBody(int completedCount) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      children: [
        _buildRealityHero(),
        const SizedBox(height: 20),
        _buildScoreCard(completedCount),
        const SizedBox(height: 20),
        if (_insights.isNotEmpty) _buildCommanderInsights(),
        const SizedBox(height: 30),
        Text(
          "ACTION LIST",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white54,
              ) ?? const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white54),
        ),
        const SizedBox(height: 10),
        if (_todayTasks.isEmpty)
          const BrutalistEmptyState(
            title: "PLAN YOUR ATTACK",
            subtitle: "No tasks detected for today. Are you intending to drift through the day or execute on it?",
            icon: Icons.checklist_rtl_rounded,
          )
        else
          ..._todayTasks.map((task) => _buildTaskTile(task)).toList(),
        const SizedBox(height: 40),
        const Center(
          child: Text(
            "EXECUTION OS v1.0.0",
            style: TextStyle(
              fontSize: 10,
              color: Colors.white10,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 100), // Extra space for FAB and bottom nav
      ],
    );
  }

  Widget _buildCommanderInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _insights.map((insight) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: const Border(left: BorderSide(color: Colors.white24, width: 4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.psychology_outlined, color: Colors.white38, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                insight,
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildRealityHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getHeroText(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildScoreCard(int completedCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        children: [
          Text(
            "EXECUTION SCORE",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(letterSpacing: 1.5) ?? 
                   const TextStyle(letterSpacing: 1.5, color: Colors.white54),
          ),
          const SizedBox(height: 10),
          Text(
            "${_executionScore.toInt()}%",
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 64,
                  color: _executionScore == 100
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                ) ?? const TextStyle(fontSize: 64, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _todayTasks.isEmpty ? 0 : (_executionScore / 100),
            backgroundColor: const Color(0xFF2A2A2A),
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text(
            "$completedCount / ${_todayTasks.length} COMPLETED",
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(
          color: task.isCompleted ? Theme.of(context).colorScheme.primary : const Color(0xFF2A2A2A),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: () async {
            final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
            await _storage.saveTask(updatedTask);
            HapticFeedback.lightImpact();
            _loadData();
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: task.isCompleted ? Theme.of(context).colorScheme.primary : Colors.transparent,
              border: Border.all(
                color: task.isNonNegotiable ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary, 
                width: 2
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: task.isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.black)
                : null,
          ),
        ),
        title: Row(
          children: [
            if (task.isNonNegotiable)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(Icons.warning_amber_rounded, size: 16, color: Theme.of(context).colorScheme.secondary),
              ),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? Colors.white54 : Colors.white,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "${task.estimatedMinutes}m • ${task.tag.toUpperCase()}",
            style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold),
          ),
        ),
        trailing: task.isCompleted
            ? null
            : IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FocusSessionScreen(task: task),
                    ),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
              ),
      ),
    );
  }
}
