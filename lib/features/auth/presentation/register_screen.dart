import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/ambient_circle.dart';
import '../../../core/presentation/widgets/gradient_button.dart';
import '../../../core/utils/validation_constants.dart';
import '../application/auth_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pseudonimoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _pseudonimoFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? _pseudonimoError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  void _validate() {
    setState(() {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final confirm = _confirmPasswordController.text;
      final pseudonimo = _pseudonimoController.text.trim();

      _pseudonimoError =
          pseudonimo.isEmpty ? 'El nombre de usuario es obligatorio' : null;
      _emailError =
          email.isEmpty || !emailRegex.hasMatch(email) ? 'Correo inválido' : null;
      _passwordError =
          password.length < minPasswordLength ? 'Mínimo 6 caracteres' : null;
      _confirmError =
          confirm != password ? 'Las contraseñas no coinciden' : null;
    });
  }

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final pseudonimo = _pseudonimoController.text.trim();

    return pseudonimo.isNotEmpty &&
        emailRegex.hasMatch(email) &&
        password.length >= minPasswordLength &&
        confirm == password;
  }

  Future<void> _register() async {
    _validate();
    if (!_isFormValid) return;

    FocusScope.of(context).unfocus();
    await ref.read(authNotifierProvider.notifier).register(
          _emailController.text.trim(),
          _passwordController.text,
          _pseudonimoController.text.trim(),
        );
  }

  @override
  void dispose() {
    _pseudonimoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pseudonimoFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AsyncValue<bool>>(authNotifierProvider, (_, state) {
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${state.error}')),
        );
      }
    });

    final isLoading = authState.isLoading;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.surface, scheme.surfaceContainerLow],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -90,
              right: -80,
              child: AmbientCircle(
                color: scheme.surfaceContainerHigh,
                size: 300,
              ),
            ),
            Positioned(
              bottom: -120,
              left: -70,
              child: AmbientCircle(
                color: scheme.surfaceContainer,
                size: 280,
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Crear Cuenta',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Únete a Escritor',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            TextField(
                              controller: _pseudonimoController,
                              focusNode: _pseudonimoFocus,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              onSubmitted: (_) => _emailFocus.requestFocus(),
                              decoration: InputDecoration(
                                labelText: 'Nombre de usuario',
                                hintText: 'Tu pseudónimo',
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                errorText: _pseudonimoError,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              enabled: !isLoading,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                              onChanged: (_) => setState(() => _emailError = null),
                              decoration: InputDecoration(
                                labelText: 'Correo electrónico',
                                hintText: 'autor@ejemplo.com',
                                prefixIcon: const Icon(Icons.mail_outline_rounded),
                                errorText: _emailError,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              enabled: !isLoading,
                              onSubmitted: (_) => _confirmFocus.requestFocus(),
                              onChanged: (_) => setState(() => _passwordError = null),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                errorText: _passwordError,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmFocus,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              enabled: !isLoading,
                              onSubmitted: (_) => _register(),
                              onChanged: (_) => setState(() => _confirmError = null),
                              decoration: InputDecoration(
                                labelText: 'Confirmar contraseña',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                errorText: _confirmError,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            GradientButton(
                              label: 'Crear cuenta',
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _register,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.pop(),
                              child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}