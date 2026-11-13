import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<void> downloadInvoicePdf(Uint8List bytes, String filename) async {
  await FilePicker.platform.saveFile(
    dialogTitle: 'Save invoice PDF',
    fileName: filename,
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
    bytes: bytes,
  );
}