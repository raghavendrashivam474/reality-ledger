import '../models/task_model.dart';
import '../models/session_model.dart';

abstract class DatabaseRepository {
  Future<List<TaskModel>> getTasks();
  Future<void> saveTask(TaskModel task);
  Future<List<SessionModel>> getSessions();
  Future<void> saveSession(SessionModel session);
}
