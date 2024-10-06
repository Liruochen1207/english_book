import 'package:flutter/services.dart';

class FileProviderUtil {
  static const MethodChannel _channel = MethodChannel('com.example.fileprovider');

  static Future<String> getFileUri(String filePath) async {
    final String uri = await _channel.invokeMethod('getFileUri', {'filePath': filePath});
    return uri;
  }
}
