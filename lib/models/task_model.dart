class Task {
  final int? id;
  final int userId;
  final String title;
  final String subject;
  final String className;
  final String deadline;
  final String priority;
  final String description;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;

  Task({
    this.id,
    required this.userId,
    required this.title,
    required this.subject,
    this.className = '',
    required this.deadline,
    this.priority = 'medium',
    this.description = '',
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'subject': subject,
        'class_name': className,
        'deadline': deadline,
        'priority': priority,
        'description': description,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'completed_at': completedAt,
      };

  factory Task.fromRow(Map<String, dynamic> row) => Task(
        id: row['id'] as int,
        userId: row['user_id'] as int,
        title: row['title'] as String,
        subject: row['subject'] as String,
        className: row['class_name'] as String,
        deadline: row['deadline'] as String,
        priority: row['priority'] as String,
        description: row['description'] as String,
        status: row['status'] as String,
        createdAt: row['created_at'] as String,
        updatedAt: row['updated_at'] as String,
        completedAt: row['completed_at'] as String?,
      );
}
