import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

/// Ekran logowania / rejestracji (email + hasło).
///
/// Po zalogowaniu nie nawiguje sam — AuthGate w app.dart reaguje na zmianę
/// sesji i podmienia widok na dashboard.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isRegister = false;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    try {
      if (_isRegister) {
        final res = await repo.signUp(email: email, password: password);
        // Gdy projekt wymaga potwierdzenia maila, sesja jest null —
        // logowanie nastąpi dopiero po kliknięciu linku z wiadomości.
        if (res.session == null && mounted) {
          setState(() {
            _info = 'Konto utworzone. Sprawdź email, aby je potwierdzić, '
                'a potem zaloguj się.';
            _isRegister = false;
          });
        }
      } else {
        await repo.signIn(email: email, password: password);
      }
      // Sukces z aktywną sesją: AuthGate sam przełączy widok.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Coś poszło nie tak. Spróbuj ponownie.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _error = null;
      _info = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isRegister ? 'Załóż konto' : 'Zaloguj się';
    final cta = _isRegister ? 'Zarejestruj' : 'Zaloguj';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Abundapp', style: theme.textTheme.displayLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Twój majątek w jednym miejscu.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 40),
                    Text(title, style: theme.textTheme.displayMedium),
                    const SizedBox(height: 24),
                    _EmailField(controller: _emailCtrl),
                    const SizedBox(height: 16),
                    _PasswordField(controller: _passwordCtrl),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _Banner(text: _error!, color: AppColors.negative),
                    ],
                    if (_info != null) ...[
                      const SizedBox(height: 16),
                      _Banner(text: _info!, color: AppColors.positive),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              cta,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _loading ? null : _toggleMode,
                      child: Text(
                        _isRegister
                            ? 'Masz już konto? Zaloguj się'
                            : 'Nie masz konta? Zarejestruj się',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration('Email', Icons.alternate_email),
      validator: (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) return 'Podaj email';
        if (!value.contains('@') || !value.contains('.')) {
          return 'Nieprawidłowy email';
        }
        return null;
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      autofillHints: const [AutofillHints.password],
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration('Hasło', Icons.lock_outline),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Podaj hasło';
        if (v.length < 6) return 'Hasło min. 6 znaków';
        return null;
      },
    );
  }
}

InputDecoration _inputDecoration(String label, IconData icon) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    prefixIcon: Icon(icon, color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.surface,
    enabledBorder: border(AppColors.surfaceElevated),
    focusedBorder: border(AppColors.accent),
    errorBorder: border(AppColors.negative),
    focusedErrorBorder: border(AppColors.negative),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 13)),
    );
  }
}
