import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:d4rts/app_state.dart';
import 'package:d4rts/utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final original = context.read<AppState>().settings;
    _settings = AppSettings(
      defaultStartingScore: original.defaultStartingScore,
      defaultLegsToWin: original.defaultLegsToWin,
      defaultCheckoutMode: original.defaultCheckoutMode,
      defaultTournamentGroups: original.defaultTournamentGroups,
      themeMode: original.themeMode,
    );
  }

  void _saveSettings() async {
    await context.read<AppState>().saveSettings(_settings);
    setState(() => _dirty = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all games, tournaments, and stats. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AppState>().clearAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_dirty)
            TextButton(
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Game Defaults', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),

          // Default starting score
          Text('Default Starting Score', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: startingScoreOptions
                .map((s) => ButtonSegment(value: s, label: Text('$s')))
                .toList(),
            selected: {_settings.defaultStartingScore},
            onSelectionChanged: (s) {
              setState(() {
                _settings.defaultStartingScore = s.first;
                _dirty = true;
              });
            },
          ),

          const SizedBox(height: 16),

          // Default legs to win
          Text('Default Legs to Win', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: legsToWinOptions
                .map((l) => ButtonSegment(value: l, label: Text('$l')))
                .toList(),
            selected: {_settings.defaultLegsToWin},
            onSelectionChanged: (s) {
              setState(() {
                _settings.defaultLegsToWin = s.first;
                _dirty = true;
              });
            },
          ),

          const SizedBox(height: 16),

          // Default checkout mode
          Text('Default Checkout Mode', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<CheckoutMode>(
            value: _settings.defaultCheckoutMode,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: CheckoutMode.values
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(checkoutModeName(m)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _settings.defaultCheckoutMode = v;
                  _dirty = true;
                });
              }
            },
          ),

          const SizedBox(height: 16),

          // Default tournament groups
          Text('Default Tournament Groups', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _settings.defaultTournamentGroups > 1
                    ? () => setState(() {
                          _settings.defaultTournamentGroups--;
                          _dirty = true;
                        })
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_settings.defaultTournamentGroups}',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ),
              IconButton(
                onPressed: _settings.defaultTournamentGroups < 8
                    ? () => setState(() {
                          _settings.defaultTournamentGroups++;
                          _dirty = true;
                        })
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),

          const Divider(height: 32),

          Text('Appearance', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),

          // Theme mode
          Text('Theme', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'system', label: Text('System')),
              ButtonSegment(value: 'light', label: Text('Light')),
              ButtonSegment(value: 'dark', label: Text('Dark')),
            ],
            selected: {_settings.themeMode},
            onSelectionChanged: (s) {
              setState(() {
                _settings.themeMode = s.first;
                _dirty = true;
              });
            },
          ),

          const Divider(height: 32),

          Text('Data', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _confirmClearAll,
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text(
              'Clear All Data',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size.fromHeight(48),
            ),
          ),

          if (_dirty) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
          ],
        ],
      ),
    );
  }
}
