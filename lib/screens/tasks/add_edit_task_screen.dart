import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_app/models/task.dart';
import 'package:task_manager_app/providers/auth_providers.dart';
import 'package:task_manager_app/providers/task_providers.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final Task? task; // Null if adding, not null if editing

  const AddEditTaskScreen({super.key, this.task});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDueDate = DateTime.now();
  TaskPriority _selectedPriority = TaskPriority.low;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      // Initialize for editing
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDueDate = widget.task!.dueDate;
      _selectedPriority = widget.task!.priority;
      _isCompleted = widget.task!.isCompleted;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.blue, // Use a primary swatch that adapts
              brightness: Theme.of(context).brightness,
            ).copyWith(
              primary: Theme.of(context).primaryColor, // Header background color
              onPrimary: Theme.of(context).appBarTheme.foregroundColor, // Header text color
              onSurface: Theme.of(context).textTheme.bodyLarge?.color, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _showPriorityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Make background transparent for rounded corners
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, // Match card background
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: TaskPriority.values.map((priority) {
              return ListTile(
                title: Text(
                  priority.name.capitalize(),
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color), // Use theme text color
                ),
                trailing: _selectedPriority == priority
                    ? const Icon(Icons.check, color: Colors.blueAccent)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedPriority = priority;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final taskRepository = ref.read(taskRepositoryProvider);
      final currentUser = ref.read(authStateChangesProvider).value;

      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No user logged in!')),
        );
        return;
      }

      if (widget.task == null) {
        // Add new task
        const uuid = Uuid();
        final newTask = Task(
          id: uuid.v4(), // Generate a unique ID
          userId: currentUser.uid,
          title: _titleController.text,
          description: _descriptionController.text,
          dueDate: _selectedDueDate,
          priority: _selectedPriority,
          isCompleted: _isCompleted,
        );
        await taskRepository.addTask(newTask);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully!')),
        );
      } else {
        // Edit existing task
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          dueDate: _selectedDueDate,
          priority: _selectedPriority,
          isCompleted: _isCompleted,
        );
        await taskRepository.updateTask(updatedTask);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully!')),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter task title',
                  labelStyle: Theme.of(context).inputDecorationTheme.labelStyle, // Use theme style
                  hintStyle: Theme.of(context).inputDecorationTheme.hintStyle, // Use theme style
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color), // Text input color
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Title cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter task description (optional)',
                  labelStyle: Theme.of(context).inputDecorationTheme.labelStyle, // Use theme style
                  hintStyle: Theme.of(context).inputDecorationTheme.hintStyle, // Use theme style
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color), // Text input color
              ),
              const SizedBox(height: 20),
              _buildDatePickerRow(context),
              const SizedBox(height: 20),
              _buildPriorityPickerRow(),
              const SizedBox(height: 20),
              if (widget.task != null) // Only show for existing tasks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completed',
                      style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color), // Use theme text color
                    ),
                    Switch(
                      value: _isCompleted,
                      onChanged: (value) {
                        setState(() {
                          _isCompleted = value;
                        });
                      },
                      activeColor: Colors.blueAccent,
                      inactiveTrackColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[300],
                      inactiveThumbColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF424242) : Colors.grey[400], // Grey for Cancel, adapts to theme
                        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, // Foreground color adapts
                      ),
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveTask,
                      child: const Text('SAVE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerRow(BuildContext context) {
    return InkWell(
      onTap: () => _selectDueDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Due Date',
                  style: Theme.of(context).inputDecorationTheme.labelStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDueDate),
                  style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color), // Use theme text color
                ),
              ],
            ),
            Icon(Icons.calendar_today, color: Theme.of(context).iconTheme.color),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityPickerRow() {
    return InkWell(
      onTap: _showPriorityPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Priority',
                  style: Theme.of(context).inputDecorationTheme.labelStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedPriority.name.capitalize(),
                  style: TextStyle(
                    fontSize: 16,
                    color: _getPriorityColor(_selectedPriority),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, size: 20, color: Theme.of(context).iconTheme.color),
          ],
        ),
      ),
    );
  }

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
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}