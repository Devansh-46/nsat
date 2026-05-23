import 'dart:convert';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

void downloadCsvWeb(String fileName, String csvData) {
  final bytes = utf8.encode(csvData);
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
    
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
