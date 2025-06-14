import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_app/models/task.dart'; // Ensure this path is correct

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool?> onToggleComplete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.redAccent;
      case TaskPriority.medium:
        return Colors.orangeAccent;
      case TaskPriority.low:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor, // Use the themed card color
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      color: Theme.of(context).textTheme.bodyLarge?.color, // Use theme text color
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Checkbox(
                  value: task.isCompleted,
                  onChanged: onToggleComplete,
                  activeColor: Colors.blueAccent,
                  checkColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                color: Theme.of(context).textTheme.bodyMedium?.color, // Use theme text color
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Theme.of(context).iconTheme.color),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(task.dueDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color, // Use theme text color
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.flag, size: 16, color: _getPriorityColor(task.priority)),
                const SizedBox(width: 4),
                Text(
                  task.priority.name.capitalize(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getPriorityColor(task.priority),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Theme.of(context).iconTheme.color),
                  onPressed: onEdit,
                  tooltip: 'Edit Task',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Theme.of(context).iconTheme.color),
                  onPressed: onDelete,
                  tooltip: 'Delete Task',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}