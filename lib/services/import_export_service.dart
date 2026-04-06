import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:d4rts/models/game.dart';
import 'package:d4rts/models/tournament.dart';

class ImportResult {
  final List<Game> games;
  final List<Tournament> tournaments;
  final String? error;

  const ImportResult({
    required this.games,
    required this.tournaments,
    this.error,
  });

  bool get hasError => error != null;
}

class ImportExportService {
  /// Export games and tournaments to a JSON string
  String exportToJson(
    List<Game> games,
    List<Tournament> tournaments,
    Map<String, dynamic> settings,
  ) {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'games': games.map((g) => g.toJson()).toList(),
      'tournaments': tournaments.map((t) => t.toJson()).toList(),
      'settings': settings,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Import from a JSON string
  ImportResult importFromJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final games = (data['games'] as List?)
              ?.map((g) => Game.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [];
      final tournaments = (data['tournaments'] as List?)
              ?.map((t) =>
                  Tournament.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [];
      return ImportResult(games: games, tournaments: tournaments);
    } catch (e) {
      return ImportResult(
        games: [],
        tournaments: [],
        error: 'Failed to parse import file: $e',
      );
    }
  }

  /// Share (export) data as a JSON file
  Future<void> shareExport(
    List<Game> games,
    List<Tournament> tournaments,
    Map<String, dynamic> settings,
  ) async {
    final json = exportToJson(games, tournaments, settings);
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')[0];
    await Share.shareXFiles(
      [
        XFile.fromData(
          utf8.encode(json),
          name: 'd4rts_backup_$timestamp.json',
          mimeType: 'application/json',
        ),
      ],
      subject: 'D4RTS Data Export',
    );
  }

  /// Pick and import a JSON file
  Future<ImportResult?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      return ImportResult(
        games: [],
        tournaments: [],
        error: 'Could not read file',
      );
    }

    final content = utf8.decode(bytes);
    return importFromJson(content);
  }
}
