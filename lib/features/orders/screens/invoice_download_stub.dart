import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

Future<void> downloadInvoicePdf(Uint8List bytes, String filename) async {
  debugPrint('[InvoiceDownload:stub] start | filename=$filename bytes=${bytes.length}');
  try {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save invoice PDF',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
    );
    debugPrint('[InvoiceDownload:stub] saveFile result=$result');
  } catch (e, st) {
    debugPrint('[InvoiceDownload:stub] saveFile threw: $e\n$st');
    rethrow;
  }
}
