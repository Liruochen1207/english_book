import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Directory> tempDir() async {
  return await getTemporaryDirectory();
}

Future<Directory> appDocumentsDir() async {
  return await getApplicationDocumentsDirectory();
}

Future<Directory> externalDir() async {
  return await getExternalStorageDirectory() ?? await tempDir();
}
