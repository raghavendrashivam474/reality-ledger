import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/session_model.dart';
import 'repository.dart';

class SupabaseRepository implements DatabaseRepository {
  final _client = Supabase.instance.client;

  @override
  Future<List<TaskModel>> getTasks() async {
    final response = await _client
        .from('tasks')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  @override
  Future<void> saveTask(TaskModel task) async {
    await _client.from('tasks').upsert(task.toJson());
  }

  @override
  Future<List<SessionModel>> getSessions() async {
    final response = await _client
        .from('sessions')
        .select()
        .order('date', ascending: false);
    
    return (response as List).map((e) => SessionModel.fromJson(e)).toList();
  }

  @override
  Future<void> saveSession(SessionModel session) async {
    await _client.from('sessions').insert(session.toJson());
  }
}
