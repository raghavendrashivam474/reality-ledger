import '../models/task_model.dart';
import '../models/session_model.dart';
import 'package:intl/intl.dart';

enum IdentityTier {
  drifter,
  consistent,
  operator,
  elite
}

class IdentityService {
  static IdentityTier calculateTier(List<TaskModel> tasks) {
    if (tasks.isEmpty) return IdentityTier.drifter;

    // Filter tasks from the last 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentTasks = tasks.where((t) => t.createdAt.isAfter(sevenDaysAgo)).toList();

    if (recentTasks.isEmpty) return IdentityTier.drifter;

    // Calculate average score over active days in last 7 days
    final Map<String, List<TaskModel>> grouped = {};
    for (var task in recentTasks) {
       final key = DateFormat('yyyy-MM-dd').format(task.createdAt);
       grouped.putIfAbsent(key, () => []).add(task);
    }

    double totalScore = 0;
    for (var dayTasks in grouped.values) {
      if (dayTasks.isEmpty) continue;
      int completed = dayTasks.where((t) => t.isCompleted).length;
      totalScore += (completed / dayTasks.length) * 100;
    }

    final avgScore = totalScore / grouped.length;
    final activeDays = grouped.length;

    if (activeDays >= 7 && avgScore >= 90) return IdentityTier.elite;
    if (activeDays >= 5 && avgScore >= 70) return IdentityTier.operator;
    if (activeDays >= 3 && avgScore >= 50) return IdentityTier.consistent;
    
    return IdentityTier.drifter;
  }

  static String getTierTitle(IdentityTier tier) {
    switch (tier) {
      case IdentityTier.drifter: return "DRIFTER";
      case IdentityTier.consistent: return "CONSISTENT";
      case IdentityTier.operator: return "THE OPERATOR";
      case IdentityTier.elite: return "ELITE OPERATOR";
    }
  }

  static String getTierRequirement(IdentityTier tier) {
    switch (tier) {
      case IdentityTier.drifter: return "Log 3 days with >50% score to rank up.";
      case IdentityTier.consistent: return "Log 5 days with >70% score for Operator status.";
      case IdentityTier.operator: return "Log 7 perfect days (90%+) for Elite status.";
      case IdentityTier.elite: return "MAX LEVEL. PROTECT THE STREAK.";
    }
  }

  static List<String> detectPatterns(List<TaskModel> tasks, List<SessionModel> sessions) {
    List<String> insights = [];
    
    // Pattern 1: Overplanning (Many tasks, low completion)
    final recentTasks = _getRecent(tasks, 3);
    if (recentTasks.isNotEmpty && recentTasks.length > 5) {
      int completed = recentTasks.where((t) => t.isCompleted).length;
      if (completed / recentTasks.length < 0.5) {
        insights.add("High Task Volume, Low Execution. You are overplanning. Cut the fat.");
      }
    }

    // Pattern 2: Integrity Leak (Planned vs Actual time)
    if (sessions.isNotEmpty) {
      final recentSessions = sessions.take(5).toList();
      int totalPlanned = recentSessions.fold(0, (sum, s) => sum + s.plannedDurationMinutes);
      int totalActual = recentSessions.fold(0, (sum, s) => sum + s.actualFocusMinutes);
      
      if (totalPlanned > 0 && totalActual / totalPlanned < 0.6) {
        insights.add("Integrity Gap: You aren't showing up for the minutes you planned.");
      }
    }

    // Pattern 3: Early Quitting
    if (sessions.isNotEmpty) {
      final abandoned = sessions.where((s) => s.abandonReason != null).toList();
      if (abandoned.length >= 3) {
        insights.add("You've leaked reality ${abandoned.length} times recently. Stop quitting.");
      }
    }

    // Pattern 4: Category Mastery
    if (tasks.isNotEmpty) {
      final completed = tasks.where((t) => t.isCompleted).toList();
      if (completed.isNotEmpty) {
        final Map<String, int> counts = {};
        for (var t in completed) {
          counts[t.tag] = (counts[t.tag] ?? 0) + 1;
        }
        final topTag = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        insights.add("Your identity is rooted in $topTag. Pivot or double down.");
      }
    }

    return insights;
  }

  static List<TaskModel> _getRecent(List<TaskModel> tasks, int days) {
    final threshold = DateTime.now().subtract(Duration(days: days));
    return tasks.where((t) => t.createdAt.isAfter(threshold)).toList();
  }
}
