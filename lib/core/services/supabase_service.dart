import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseClient? _client;

  SupabaseClient get client {
    _client ??= _getClient();
    return _client!;
  }

  SupabaseClient _getClient() {
    try {
      return Supabase.instance.client;
    } on AssertionError {
      throw Exception('Supabase is not initialized yet.');
    }
  }

  // Check if user is logged in
  User? get currentUser {
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Session? get currentSession {
    try {
      return client.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  Stream<AuthState> get authStateChanges {
    try {
      return client.auth.onAuthStateChange;
    } catch (_) {
      return const Stream.empty();
    }
  }

  // Log in with email & password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final client = this.client;
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected network error occurred.');
    }
  }

  // Sign up / Create Account
  Future<AuthResponse> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final client = this.client;
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name},
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected network error occurred.');
    }
  }

  // Sign Out / Logout
  Future<void> signOut() async {
    try {
      final client = this.client;
      await client.auth.signOut();
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Forgot Password / Reset Link
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final client = this.client;
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.lanspeech.app://reset-callback',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred while sending the link.');
    }
  }

  // Update Display Name (Profile → Edit Profile)
  //
  // New method — everything above this point is unchanged from the
  // existing file. Updates the user's display_name in Supabase Auth
  // metadata. The Profile screen calls ref.invalidate(authProvider)
  // afterward so the new name reflects immediately in the UI.
  Future<void> updateDisplayName(String name) async {
    try {
      final client = this.client;
      await client.auth.updateUser(
        UserAttributes(data: {'display_name': name}),
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception(
          'An unexpected error occurred while updating your profile.');
    }
  }

  // Map Supabase specific errors to friendly, friendly user-facing messages
  Exception _handleAuthException(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return Exception('The email or password you entered is incorrect.');
    } else if (message.contains('email already registered') ||
        message.contains('user already exists')) {
      return Exception(
          'This email is already registered. Try logging in instead.');
    } else if (message.contains('weak password')) {
      return Exception(
          'Your password is too weak. Please use at least 6 characters.');
    } else if (message.contains('invalid email')) {
      return Exception('Please enter a valid email address.');
    } else if (message.contains('email not confirmed')) {
      return Exception(
          'Please confirm your email before logging in. Check your inbox!');
    } else {
      return Exception(e.message);
    }
  }
}
