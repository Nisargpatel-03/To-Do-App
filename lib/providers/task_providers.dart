import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_app/models/task.dart';
import 'package:task_manager_app/services/task_repository.dart';
import 'package:task_manager_app/providers/auth_providers.dart'; // To get the current user ID

// Provides the FirebaseFirestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Provides the TaskRepository instance
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(firestoreProvider));
});

// Provides a stream of tasks for the currently logged-in user
// We'll keep this as a raw stream and filter it in the filteredTasksProvider
final allTasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  final user = ref.watch(authStateChangesProvider).valueOrNull; // Get current user

  if (user != null) {
    // Only fetch tasks for the current user
    return taskRepository.getTasks(user.uid);
  }
  // Return an empty stream if no user is logged in
  return Stream.value([]);
});

// Providers for filtering
final taskFilterProvider = StateProvider<String>((ref) => 'All'); // 'All', 'Today', 'High', etc.
final taskSearchQueryProvider = StateProvider<String>((ref) => '');
// New: Provider for date filtering (e.g., 'All', 'Today', 'Upcoming')
final taskDateFilterProvider = StateProvider<String>((ref) => 'All');

// --- CHANGE IS HERE ---
// This provider now returns an AsyncValue<List<Task>>
final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  // Watch the raw stream which is already an AsyncValue<List<Task>>
  final tasksAsyncValue = ref.watch(allTasksStreamProvider);
  final priorityFilter = ref.watch(taskFilterProvider);
  final searchQuery = ref.watch(taskSearchQueryProvider).toLowerCase();
  final dateFilter = ref.watch(taskDateFilterProvider);

  // Use .when() to handle the states of tasksAsyncValue
  return tasksAsyncValue.when(
    data: (tasks) {
      List<Task> filtered = tasks;

      // Apply search query
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((task) {
          return task.title.toLowerCase().contains(searchQuery) ||
              task.description.toLowerCase().contains(searchQuery);
        }).toList();
      }

      // Apply date filter
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day); // Date only

      if (dateFilter == 'Today') {
        filtered = filtered.where((task) {
          final taskDueDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
          return taskDueDate.isAtSameMomentAs(today);
        }).toList();
      } else if (dateFilter == 'Upcoming') { // Using 'Upcoming' instead of 'Tomorrow' for broader utility
        filtered = filtered.where((task) {
          final taskDueDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
          // Check if due date is strictly after today (for "upcoming" tasks)
          return taskDueDate.isAfter(today);
        }).toList();
      }

      // Apply priority filter
      switch (priorityFilter) {
        case 'High':
          filtered = filtered.where((task) => task.priority == TaskPriority.high).toList();
          break;
        case 'Medium':
          filtered = filtered.where((task) => task.priority == TaskPriority.medium).toList();
          break;
        case 'Low':
          filtered = filtered.where((task) => task.priority == TaskPriority.low).toList();
          break;
      // 'All' or default case requires no additional filtering for priority
      }
      // Return the filtered list wrapped in AsyncValue.data
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(), // Propagate loading state
    error: (e, st) {
      // Propagate error state
      print('Error loading tasks: $e'); // Keep print for debugging
      return AsyncValue.error(e, st);
    },
  );
});