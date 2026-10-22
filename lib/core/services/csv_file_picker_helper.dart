import 'dart:typed_data';

import 'csv_file_picker_helper_stub.dart'
    if (dart.library.html) 'csv_file_picker_helper_web.dart'
    if (dart.library.io) 'csv_file_picker_helper_io.dart' as impl;

/// Holds metadata and binary payload of a user-selected CSV file.
class PickedCsvFile {
  final String name;
  final int size;
  final Uint8List bytes;

  const PickedCsvFile({
    required this.name,
    required this.size,
    required this.bytes,
  });
}

/// Cross-platform method to pick a CSV file on Web, Android, Desktop, and iOS.
Future<PickedCsvFile?> pickCsvFile() => impl.pickCsvFile();
