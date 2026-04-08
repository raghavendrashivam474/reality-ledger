import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../data/repository.dart';
import '../data/local_storage.dart';
import '../data/repository.dart';
import '../data/supabase_repository.dart';
import '../config.dart';
import 'package:intl/intl.dart';
import '../widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseRepository _repository = AppConfig.isCloudReady ? SupabaseRepository() : LocalStorage();
  bool _isLoading = true;
  List<TaskModel> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tasks = await _repository.getTasks();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Group tasks by date string
    final Map<String, List<TaskModel>> grouped = {};
    for (var task in _tasks) {
      final dateKey = DateFormat('yyyy-MM-dd').format(task.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(task);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          "HISTORY LEDGER",
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 20) ?? 
                 const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: sortedDates.isEmpty
          ? const BrutalistEmptyState(
              title: "THE VOID",
              subtitle: "No history found. Your past is a blank canvas. Start executing to build your legacy.",
              icon: Icons.history_toggle_off_rounded,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final dateKey = sortedDates[index];
                final tasks = grouped[dateKey] ?? [];
                return _buildHistoryCard(dateKey, tasks);
              },
            ),
    );
  }

  Widget _buildHistoryCard(String date, List<TaskModel> tasks) {
    final completed = tasks.where((t) => t.isCompleted).length;
    final score = (tasks.isEmpty) ? 0 : (completed / tasks.length) * 100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.parse(date)),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "${score.toInt()}%",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: score >= 70 ? Theme.of(context).colorScheme.primary : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "$completed / ${tasks.length} TASKS COMPLETED",
            style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(
                score >= 70 ? Theme.of(context).colorScheme.primary : Colors.white24),
          ),
        ],
      ),
    );
  }
}
