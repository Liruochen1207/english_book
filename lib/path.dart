import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path_provider_windows/path_provider_windows.dart' as win_provider;

Future<Directory> tempDir() async {
  return await getTemporaryDirectory();
}

Future<Directory> appDocumentsDir() async {
  return await getApplicationDocumentsDirectory();
}

Future<Directory> externalDir() async {
  if (Platform.isWindows){
    String path = await win_provider.PathProviderWindows().getDownloadsPath() ?? '';
    return Directory(path);
  }
  return await getExternalStorageDirectory() ?? await tempDir();
}
