import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:d4rts/app_state.dart';
import 'package:d4rts/services/import_export_service.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final ImportExportService _service = ImportExportService();
  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isError = false;
    });
    try {
      final appState = context.read<AppState>();
      await _service.shareExport(
        appState.games.toList(),
        appState.tournaments.toList(),
        appState.settings.toJson(),
      );
      setState(() => _statusMessage = 'Export shared successfully!');
    } catch (e) {
      setState(() {
        _statusMessage = 'Export failed: $e';
        _isError = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isError = false;
    });
    try {
      final result = await _service.pickAndImport();
      if (result == null) {
        setState(() => _statusMessage = 'Import cancelled');
        return;
      }
      if (result.hasError) {
        setState(() {
          _statusMessage = result.error;
          _isError = true;
        });
        return;
      }

      // Show preview dialog
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Preview'),
          content: Text(
            'Found ${result.games.length} games and ${result.tournaments.length} tournaments.\n\nMerge with existing data?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() => _statusMessage = 'Import cancelled');
        return;
      }

      if (!mounted) return;
      await context.read<AppState>().importData(
            result.games,
            result.tournaments,
          );

      setState(() => _statusMessage =
          'Imported ${result.games.length} games and ${result.tournaments.length} tournaments.');
    } catch (e) {
      setState(() {
        _statusMessage = 'Import failed: $e';
        _isError = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Import / Export')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Export section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Export', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Export ${appState.games.length} games and ${appState.tournaments.length} tournaments as JSON.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _exportData,
                      icon: const Icon(Icons.upload),
                      label: const Text('Export & Share'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Import section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Import', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Import a previously exported D4RTS JSON file. Data will be merged with existing records.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _importData,
                      icon: const Icon(Icons.download),
                      label: const Text('Pick File & Import'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isError
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _isError
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
