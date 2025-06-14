// lib/services/task_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_manager_app/models/task.dart'; // Make sure this import is correct

class TaskRepository { // <-- This class must be defined
  final FirebaseFirestore _firestore;

  TaskRepository(this._firestore);

  Stream<List<Task>> getTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  Future<void> addTask(Task task) async {
    await _firestore.collection('tasks').add(task.toFirestore());
  }

  Future<void> updateTask(Task task) async {
    await _firestore.collection('tasks').doc(task.id).update(task.toFirestore());
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }
}