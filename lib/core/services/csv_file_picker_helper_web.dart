// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'csv_file_picker_helper.dart';

Future<PickedCsvFile?> pickCsvFile() async {
  final completer = Completer<PickedCsvFile?>();

  final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
  uploadInput.accept = '.csv,text/csv,text/plain';

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files[0];
    final reader = html.FileReader();

    reader.onLoadEnd.listen((e) {
      final result = reader.result;
      if (result is Uint8List) {
        if (!completer.isCompleted) {
          completer.complete(
            PickedCsvFile(
              name: file.name,
              size: file.size,
              bytes: result,
            ),
          );
        }
      } else if (result is ByteBuffer) {
        if (!completer.isCompleted) {
          completer.complete(
            PickedCsvFile(
              name: file.name,
              size: file.size,
              bytes: Uint8List.view(result),
            ),
          );
        }
      } else {
        if (!completer.isCompleted) completer.complete(null);
      }
    });

    reader.onError.listen((e) {
      if (!completer.isCompleted) completer.complete(null);
    });

    reader.readAsArrayBuffer(file);
  });

  uploadInput.click();

  return completer.future;
}
