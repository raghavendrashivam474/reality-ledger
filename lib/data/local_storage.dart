import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/session_model.dart';
import 'repository.dart';

class LocalStorage implements DatabaseRepository {
  static const String _tasksKey = 'tasks';
  static const String _sessionsKey = 'sessions';

  Future<List<TaskModel>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString(_tasksKey);
    if (tasksString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(tasksString);
    return jsonList.map((e) => TaskModel.fromJson(e)).toList();
  }

  Future<void> saveTask(TaskModel task) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tasksKey, jsonEncode(tasks.map((e) => e.toJson()).toList()));
  }

  Future<List<SessionModel>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsString = prefs.getString(_sessionsKey);
    if (sessionsString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(sessionsString);
    return jsonList.map((e) => SessionModel.fromJson(e)).toList();
  }

  Future<void> saveSession(SessionModel session) async {
    final sessions = await getSessions();
    sessions.add(session);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionsKey, jsonEncode(sessions.map((e) => e.toJson()).toList()));
  }
}
