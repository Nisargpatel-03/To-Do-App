import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum TaskPriority {
  low,
  medium,
  high,
}

class Task {
  final String id;
  final String userId; // To link tasks to specific users
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final bool isCompleted;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.priority = TaskPriority.low,
    this.isCompleted = false,
  });

  // Factory constructor to create a Task from a Firestore Document
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      priority: TaskPriority.values.firstWhere(
            (e) => e.toString() == 'TaskPriority.${data['priority']}',
        orElse: () => TaskPriority.low,
      ),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  // Convert Task object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority.name, // Store enum name as string
      'isCompleted': isCompleted,
      'createdAt': FieldValue.serverTimestamp(), // Optional: for sorting
    };
  }

  // Helper for copying with new values (for updates)
  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  String get formattedDueDate {
    return DateFormat('MMM dd, yyyy').format(dueDate);
  }
}