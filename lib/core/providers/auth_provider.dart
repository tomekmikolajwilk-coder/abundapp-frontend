import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_repository.dart';

/// Repozytorium auth oparte o globalny singleton Supabase
/// (zainicjalizowany w main.dart przez Supabase.initialize).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

/// Strumień stanu logowania. AuthGate obserwuje go, by przełączać między
/// ekranem logowania a dashboardem. Emituje też zdarzenie startowe z bieżącą
/// (ewentualnie przywróconą z dysku) sesją.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

/// Bieżąca sesja (lub null). Wyliczana ze [authStateProvider], z fallbackiem do
/// sesji już obecnej w repozytorium na pierwszym buildzie.
final sessionProvider = Provider<Session?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (state) => state.session,
    orElse: () => repo.currentSession,
  );
});
