import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  verificationSent,
  error,
}

class CustomAuthState {
  final AuthStatus status;
  final User? user;
  final String? demoEmail;
  final String? errorMessage;

  CustomAuthState({
    required this.status,
    this.user,
    this.demoEmail,
    this.errorMessage,
  });

  factory CustomAuthState.initial() =>
      CustomAuthState(status: AuthStatus.initial);
  factory CustomAuthState.loading() =>
      CustomAuthState(status: AuthStatus.loading);
  factory CustomAuthState.authenticated(User user) =>
      CustomAuthState(status: AuthStatus.authenticated, user: user);
  factory CustomAuthState.demoAuthenticated(String email) =>
      CustomAuthState(status: AuthStatus.authenticated, demoEmail: email);
  factory CustomAuthState.unauthenticated() =>
      CustomAuthState(status: AuthStatus.unauthenticated);
  factory CustomAuthState.verificationSent() =>
      CustomAuthState(status: AuthStatus.verificationSent);
  factory CustomAuthState.error(String message) =>
      CustomAuthState(status: AuthStatus.error, errorMessage: message);

  CustomAuthState copyWith({
    AuthStatus? status,
    User? user,
    String? demoEmail,
    String? errorMessage,
  }) {
    return CustomAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      demoEmail: demoEmail ?? this.demoEmail,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
