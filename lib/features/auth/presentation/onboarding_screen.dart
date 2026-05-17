import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/ambient_circle.dart';
import '../../../core/presentation/widgets/gradient_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          _AmbientBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Escritor',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.surfaceContainerLow,
                          scheme.surfaceContainerHigh,
                        ],
                      ),
                    ),
                    child: const Icon(Icons.auto_stories_rounded, size: 92),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'The Zen Atelier\nfor Writers',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Una experiencia de escritura minimalista: cero ruido, foco total y Markdown listo para publicar.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.secondary,
                    ),
                  ),
                  const Spacer(),
                  GradientButton(
                    label: 'Get Started',
                    height: 56,
                    onPressed: () => context.go('/auth'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/auth'),
                    child: Text(
                      'Already have an account? Log in',
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
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
          right: -70,
          child: AmbientCircle(
            color: scheme.surfaceContainerHigh,
            size: 260,
            opacity: 0.6,
          ),
        ),
        Positioned(
          bottom: -120,
          left: -80,
          child: AmbientCircle(
            color: scheme.surfaceContainer,
            size: 320,
            opacity: 0.6,
          ),
        ),
      ],
    );
  }
}
