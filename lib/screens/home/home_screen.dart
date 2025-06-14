import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_app/providers/auth_providers.dart';
import 'package:task_manager_app/providers/task_providers.dart';
import 'package:task_manager_app/screens/tasks/add_edit_task_screen.dart';
import 'package:task_manager_app/widgets/task_card.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTasksAsyncValue = ref.watch(filteredTasksProvider);
    final currentPriorityFilter = ref.watch(taskFilterProvider);
    final currentDateFilter = ref.watch(taskDateFilterProvider); // New
    final searchQuery = ref.watch(taskSearchQueryProvider);
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'), // Matching the image
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddEditTaskScreen()),
              );
            },
            tooltip: 'Add Task',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                hintText: 'Search tasks...',
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color),
                  onPressed: () {
                    ref.read(taskSearchQueryProvider.notifier).state = '';
                  },
                )
                    : null,
              ),
              onChanged: (query) {
                ref.read(taskSearchQueryProvider.notifier).state = query;
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Daily Task', // As seen in the image
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color, // Use theme text color
              ),
            ),
          ),
          // Date Filter Chips (Today, Upcoming, All)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDateFilterChip(context, ref, 'All', currentDateFilter),
                  _buildDateFilterChip(context, ref, 'Today', currentDateFilter),
                  _buildDateFilterChip(context, ref, 'Upcoming', currentDateFilter),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Priority Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPriorityFilterChip(context, ref, 'All', currentPriorityFilter),
                  _buildPriorityFilterChip(context, ref, 'High', currentPriorityFilter),
                  _buildPriorityFilterChip(context, ref, 'Medium', currentPriorityFilter),
                  _buildPriorityFilterChip(context, ref, 'Low', currentPriorityFilter),
                ],
              ),
            ),
          ),
          Expanded(
            child: filteredTasksAsyncValue.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 80, color: Theme.of(context).iconTheme.color),
                        SizedBox(height: 10),
                        Text('No tasks found for the current filter.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)), // Use theme text color
                        Text('Try adding a new task!', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)), // Use theme text color
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskCard(
                      task: task,
                      onEdit: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddEditTaskScreen(task: task),
                          ),
                        );
                      },
                      onDelete: () async {
                        // Show a confirmation dialog before deleting
                        final confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              backgroundColor: Theme.of(context).cardTheme.color,
                              title: Text('Delete Task', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)), // Use theme text color
                              content: Text('Are you sure you want to delete this task?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)), // Use theme text color
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(false),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.blueAccent)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmDelete == true) {
                          final taskId = task.id;
                          final taskRepository = ref.read(taskRepositoryProvider);
                          await taskRepository.deleteTask(taskId);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task deleted!')),
                          );
                        }
                      },
                      onToggleComplete: (bool? isCompleted) async {
                        if (isCompleted != null && user != null) {
                          final updatedTask = task.copyWith(isCompleted: isCompleted);
                          final taskRepository = ref.read(taskRepositoryProvider);
                          await taskRepository.updateTask(updatedTask);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading tasks: $error', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityFilterChip(
      BuildContext context, WidgetRef ref, String filterText, String currentFilter) {
    final isSelected = currentFilter == filterText;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(filterText),
        selected: isSelected,
        selectedColor: Colors.blueAccent,
        onSelected: (selected) {
          if (selected) {
            ref.read(taskFilterProvider.notifier).state = filterText;
          } else {
            ref.read(taskFilterProvider.notifier).state = 'All';
          }
        },
        backgroundColor: Theme.of(context).cardColor, // Use card color for background
        labelStyle: TextStyle(color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color), // Use theme text color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.blueAccent : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey[300]!), // Adjust border color based on theme
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterChip(
      BuildContext context, WidgetRef ref, String filterText, String currentFilter) {
    final isSelected = currentFilter == filterText;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(filterText),
        selected: isSelected,
        selectedColor: Colors.deepPurpleAccent, // Slightly different color for date filters
        onSelected: (selected) {
          if (selected) {
            ref.read(taskDateFilterProvider.notifier).state = filterText;
          } else {
            ref.read(taskDateFilterProvider.notifier).state = 'All';
          }
        },
        backgroundColor: Theme.of(context).cardColor, // Use card color for background
        labelStyle: TextStyle(color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color), // Use theme text color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.deepPurpleAccent : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey[300]!), // Adjust border color based on theme
          ),
        ),
      ),
    );
  }
}