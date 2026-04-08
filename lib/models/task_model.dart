class TaskModel {
  final String id;
  final String title;
  final int estimatedMinutes;
  final String tag;
  final bool isCompleted;
  final DateTime createdAt;
  final int difficulty; // 1: Low, 2: Medium, 3: High
  final bool isNonNegotiable; // MVD: Minimum Viable Day indicator

  TaskModel({
    required this.id,
    required this.title,
    required this.estimatedMinutes,
    required this.tag,
    this.isCompleted = false,
    required this.createdAt,
    this.difficulty = 1,
    this.isNonNegotiable = false,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    int? estimatedMinutes,
    String? tag,
    bool? isCompleted,
    DateTime? createdAt,
    int? difficulty,
    bool? isNonNegotiable,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      tag: tag ?? this.tag,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      difficulty: difficulty ?? this.difficulty,
      isNonNegotiable: isNonNegotiable ?? this.isNonNegotiable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'estimatedMinutes': estimatedMinutes,
      'tag': tag,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'difficulty': difficulty,
      'isNonNegotiable': isNonNegotiable,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      estimatedMinutes: json['estimatedMinutes'] ?? 0,
      tag: json['tag'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      difficulty: json['difficulty'] ?? 1,
      isNonNegotiable: json['isNonNegotiable'] ?? false,
    );
  }
}
