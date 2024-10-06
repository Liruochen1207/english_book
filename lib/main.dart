import 'package:english_book/page/home.dart';
import 'package:english_book/sql/client.dart';
import 'package:english_book/http/word.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestInstallPermission() async {
  // 检查安装未知应用的权限
  var status = await Permission.requestInstallPackages.status;
  if (!status.isGranted) {
    // 请求权限
    status = await Permission.requestInstallPackages.request();
    return status.isGranted;
  }
  return true;
}

Future<bool> requestStoragePermission() async {
  // 检查存储权限
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    // 请求权限
    status = await Permission.storage.request();
    return status.isGranted;
  }
  return true;
}


var client = SqlClient();
void main() {
  runApp(const MyApp());
  requestInstallPermission();
  requestStoragePermission();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    bool isDarkness =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return MaterialApp(
      theme: isDarkness
          ? ThemeData.dark()
          : ThemeData(
              // This is the theme of your application.
              //
              // TRY THIS: Try running your application with "flutter run". You'll see
              // the application has a purple toolbar. Then, without quitting the app,
              // try changing the seedColor in the colorScheme below to Colors.green
              // and then invoke "hot reload" (save your changes or press the "hot
              // reload" button in a Flutter-supported IDE, or press "r" if you used
              // the command line to start the app).
              //
              // Notice that the counter didn't reset back to zero; the application
              // state is not lost during the reload. To reset the state, use hot
              // restart instead.
              //
              // This works for code too, not just values: Most code changes can be
              // tested with just a hot reload.

              // colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
              useMaterial3: true,
            ),
      home: MyHomePage(
        isDarkness: isDarkness, wordList: () { return []; }, startIndex: 0,
      ),
    );
  }
}
