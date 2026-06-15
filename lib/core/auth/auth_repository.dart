import 'package:supabase_flutter/supabase_flutter.dart';

/// Cienka warstwa nad Supabase Auth (GoTrue). Reszta apki nie dotyka SDK
/// bezpośrednio — korzysta z tego repozytorium przez [authRepositoryProvider].
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  /// Strumień zmian stanu logowania (login, logout, odświeżenie tokena).
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  Session? get currentSession => _auth.currentSession;

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.id;

  /// Access token bieżącej sesji — wysyłany jako `Bearer` do Edge Functions.
  String? get accessToken => _auth.currentSession?.accessToken;

  bool get isLoggedIn => _auth.currentSession != null;

  /// Rejestracja kontem email + hasło.
  ///
  /// Gdy w projekcie włączone jest potwierdzanie maila, [AuthResponse.session]
  /// będzie `null` — user musi najpierw kliknąć link z wiadomości.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();
}
