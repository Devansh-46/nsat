import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/result_model.dart';
import 'web_download_stub.dart' if (dart.library.html) 'web_download.dart';

/// Result of an export attempt, so the UI can show the right message.
class ExportResult {
  final bool success;
  final String message;
  ExportResult(this.success, this.message);
}

/// Builds a CSV of test results, saves it to the device, and opens the
/// system share sheet.
///
/// PLATFORM NOTE: this is a mobile feature (Android / iOS). On web it
/// returns a friendly "use the mobile app" message — saving to a real
/// file system and sharing are mobile capabilities. NIU staff use the
/// Android app for results, so this is the intended path.
class ResultsExporter {
  /// CSV column order. Keep stable — NIU staff may build on this.
  static const _baseHeaders = [
    'NIU ID',
    'Student Name',
    'Course',
    'Correct',
    'Wrong',
    'Skipped',
    'Net Score',
    'Max Score',
    'Submitted',
  ];

  /// Turns the results into CSV text.
  static String buildCsv(List<ResultModel> results) {
    // Collect all short answer question indices across all results
    final allShortIndices = <String>{};
    for (final r in results) {
      allShortIndices.addAll(r.shortAnswerResponses.keys);
    }
    final sortedShortIndices = allShortIndices.toList()..sort((a, b) {
      final ai = int.tryParse(a) ?? 0;
      final bi = int.tryParse(b) ?? 0;
      return ai.compareTo(bi);
    });

    final headers = <String>[
      ..._baseHeaders,
      for (final idx in sortedShortIndices)
        'Short Answer Q${(int.tryParse(idx) ?? 0) + 1}',
    ];

    final rows = <List<dynamic>>[
      headers,
      for (final r in results)
        [
          r.applicationNo,
          r.studentName,
          r.course,
          r.correctCount,
          r.wrongCount,
          r.skippedCount,
          r.netScore,
          r.maxScore,
          r.submittedAt != null ? _formatDateTime(r.submittedAt!) : '',
          for (final idx in sortedShortIndices)
            r.shortAnswerResponses[idx] ?? '',
        ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  /// Exports the results: builds the CSV, saves it to the app documents
  /// directory, and opens the share sheet. Returns an [ExportResult].
  static Future<ExportResult> export(List<ResultModel> results) async {
    if (results.isEmpty) {
      return ExportResult(false, 'There are no results to export.');
    }

    if (kIsWeb) {
      try {
        final csv = buildCsv(results);
        final fileName = 'nsat_results_${DateTime.now().millisecondsSinceEpoch}.csv';
        downloadCsvWeb(fileName, csv);
        return ExportResult(true, 'Downloading: $fileName');
      } catch (e) {
        return ExportResult(false, 'Export failed on web. Please try again.');
      }
    }

    try {
      final csv = buildCsv(results);
      final fileName =
          'nsat_results_${DateTime.now().millisecondsSinceEpoch}.csv';

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv);

      // Open the system share sheet (Gmail, Drive, etc.). The file is
      // already saved, so dismissing the sheet still leaves it on device.
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'NSAT results export',
      );

      return ExportResult(true, 'Saved: $fileName');
    } catch (e) {
      return ExportResult(false, 'Export failed. Please try again.');
    }
  }

  static String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m $ampm';
  }
}