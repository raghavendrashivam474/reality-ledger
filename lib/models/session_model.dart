class SessionModel {
  final String id;
  final String taskId;
  final int plannedDurationMinutes;
  final int actualFocusMinutes;
  final int pauseCount;
  final DateTime date;
  final String? abandonReason;

  SessionModel({
    required this.id,
    required this.taskId,
    required this.plannedDurationMinutes,
    required this.actualFocusMinutes,
    required this.pauseCount,
    required this.date,
    this.abandonReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'plannedDurationMinutes': plannedDurationMinutes,
      'actualFocusMinutes': actualFocusMinutes,
      'pauseCount': pauseCount,
      'date': date.toIso8601String(),
      'abandonReason': abandonReason,
    };
  }

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] ?? '',
      taskId: json['taskId'] ?? '',
      plannedDurationMinutes: json['plannedDurationMinutes'] ?? 0,
      actualFocusMinutes: json['actualFocusMinutes'] ?? 0,
      pauseCount: json['pauseCount'] ?? 0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      abandonReason: json['abandonReason'],
    );
  }
}
