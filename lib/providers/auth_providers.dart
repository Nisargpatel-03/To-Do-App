// auth_providers.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Provides a stream of Firebase User changes (logged in/out)
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// A Notifier to handle authentication logic (login, signup, logout)
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(firebaseAuthProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final FirebaseAuth _auth;

  AuthNotifier(this._auth) : super(const AsyncValue.data(null)) {
    // Listen to auth state changes and update the state
    _auth.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(userCredential.user);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Login failed', StackTrace.current);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Keep this method as is, it briefly logs in the user after creation
  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(userCredential.user); // This line briefly sets the user
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Signup failed', StackTrace.current);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}