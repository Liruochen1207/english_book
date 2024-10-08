import 'package:english_book/page/home.dart';
import 'package:english_book/sql/client.dart';
import 'package:english_book/sql/word.dart';
import 'package:flutter/material.dart';

var client = SqlClient();
void main() {
  runApp(const MyApp());
}

Future<List<List<dynamic>>> sqlWords() async {
  var connection = await client.connect();
  return await getWords(connection);
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

              colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
              useMaterial3: true,
            ),
      home: MyHomePage(
        isDarkness: isDarkness,
        wordList: sqlWords,
      ),
    );
  }
}
