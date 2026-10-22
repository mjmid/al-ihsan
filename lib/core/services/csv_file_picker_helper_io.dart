import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'csv_file_picker_helper.dart';

Future<PickedCsvFile?> pickCsvFile() async {
  try {
    FilePicker.platform;
  } catch (_) {
    FilePickerIO.registerWith();
  }

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv', 'txt'],
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;

  final picked = result.files.first;
  Uint8List? bytes = picked.bytes;
  if (bytes == null && picked.path != null) {
    final file = File(picked.path!);
    if (await file.exists()) {
      bytes = await file.readAsBytes();
    }
  }

  if (bytes == null) return null;

  return PickedCsvFile(
    name: picked.name,
    size: picked.size,
    bytes: bytes,
  );
}
