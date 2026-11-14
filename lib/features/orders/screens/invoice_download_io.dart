import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

Future<void> downloadInvoicePdf(Uint8List bytes, String filename) async {
  debugPrint('[InvoiceDownload:io] start | filename=$filename bytes=${bytes.length}');
  String? path;
  try {
    path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save invoice PDF',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
  } catch (e, st) {
    debugPrint('[InvoiceDownload:io] saveFile threw: $e\n$st');
    rethrow;
  }
  debugPrint('[InvoiceDownload:io] saveFile path=$path');
  if (path == null) {
    debugPrint('[InvoiceDownload:io] cancelled by user');
    return; // user cancelled
  }
  final file = File(path);
  try {
    await file.writeAsBytes(bytes, flush: true);
    final exists = await file.exists();
    final size = exists ? await file.length() : -1;
    debugPrint('[InvoiceDownload:io] wrote file exists=$exists size=$size path=$path');
  } catch (e, st) {
    debugPrint('[InvoiceDownload:io] write failed: $e\n$st');
    rethrow;
  }
}
