import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/ambient_circle.dart';
import '../../../core/presentation/widgets/gradient_button.dart';
import '../../../core/utils/validation_constants.dart';
import '../application/auth_notifier.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _emailValid = true;
  bool _passwordValid = true;

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    return emailRegex.hasMatch(email) && password.length >= minPasswordLength;
  }

  void _validateFields() {
    setState(() {
      _emailValid = emailRegex.hasMatch(_emailController.text.trim());
      _passwordValid = _passwordController.text.length >= minPasswordLength;
    });
  }

  Future<void> _login() async {
    _validateFields();
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifica tu email y contraseña (min. 6 caracteres)'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    await ref.read(authNotifierProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
                              'Escritor',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'THE ZEN ATELIER',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 28),
                            TextField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              enabled: !isLoading,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                              onChanged: (_) => setState(() => _emailValid = true),
                              decoration: InputDecoration(
                                labelText: 'Correo electrónico',
                                hintText: 'autor@ejemplo.com',
                                prefixIcon: const Icon(Icons.mail_outline_rounded),
                                errorText: _emailValid
                                    ? null
                                    : 'Ingresa un correo válido',
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              enabled: !isLoading,
                              onSubmitted: (_) => _login(),
                              onChanged: (_) => setState(() => _passwordValid = true),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                errorText: _passwordValid
                                    ? null
                                    : 'Mínimo 6 caracteres',
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
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Recuperación de contraseña no disponible aún',
                                            ),
                                          ),
                                        );
                                      },
                                child: const Text('¿Olvidaste tu contraseña?'),
                              ),
                            ),
                            const SizedBox(height: 4),
                            GradientButton(
                              label: 'Continuar',
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _login,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.push('/register'),
                              child: const Text('¿No tienes cuenta? Crear una'),
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
  }}
