import 'package:flutter/material.dart';

class ScoreDisplay extends StatelessWidget {
  final String playerName;
  final int remainingScore;
  final int legWins;
  final bool isActive;

  const ScoreDisplay({
    super.key,
    required this.playerName,
    required this.remainingScore,
    required this.legWins,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isActive ? 6 : 1,
      color: isActive ? colorScheme.primaryContainer : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              playerName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? colorScheme.onPrimaryContainer : null,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              '$remainingScore',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
            ),
            if (legWins > 0) ...[
              const SizedBox(height: 2),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 3,
                runSpacing: 2,
                children: List.generate(
                  legWins,
                  (i) => Icon(
                    Icons.circle,
                    size: 8,
                    color: isActive ? colorScheme.primary : colorScheme.outline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
