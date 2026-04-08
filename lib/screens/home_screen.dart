import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_bar, size: 48),
                  const SizedBox(width: 12),
                  Text(
                    'D4RTS',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Steel Darts Companion',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 48),
              _HomeButton(
                icon: Icons.people,
                label: 'Vs Mode',
                subtitle: 'Play a game against opponents',
                onTap: () => context.push('/game/setup'),
              ),
              const SizedBox(height: 16),
              _HomeButton(
                icon: Icons.emoji_events,
                label: 'Tournament',
                subtitle: 'Organize a group tournament',
                onTap: () => context.push('/tournament/setup'),
              ),
              const SizedBox(height: 16),
              _HomeButton(
                icon: Icons.bar_chart,
                label: 'Statistics',
                subtitle: 'View your performance stats',
                onTap: () => context.push('/stats'),
              ),
              const SizedBox(height: 16),
              _HomeButton(
                icon: Icons.settings,
                label: 'Settings',
                subtitle: 'Configure defaults & preferences',
                onTap: () => context.push('/settings'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.push('/import-export'),
                icon: const Icon(Icons.import_export),
                label: const Text('Import / Export Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
