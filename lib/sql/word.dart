import 'dart:convert';
import 'dart:typed_data';

import 'package:mysql_client/mysql_client.dart';
import 'package:english_book/setting.dart';
import 'package:english_book/sql/client.dart';

Future<void> submitMeans(MySQLConnection? connection, int tableIndex,
    String word, String mean) async {
  if (mean != "") {
    if (connection != null && connection!.connected) {
      var result = await connection.execute(
          "UPDATE word_table0$tableIndex SET mean='$mean' WHERE word='$word'");
      print("注入结果：");
      for (final row in result.rows) {
        print(row.colAt(0));
      }
    }
  }
}

Future<void> submitOthers(MySQLConnection? connection, int tableIndex,
    String word, String other) async {
  if (other != "") {
    // print("准备 => $other");
    if (connection != null && connection!.connected) {
      var result = await connection.execute(
          "UPDATE word_table0$tableIndex SET other='$other' WHERE word='$word'");
      print("注入结果：");
      for (final row in result.rows) {
        print(row.colAt(0));
      }
    }
  }
}

Future<void> submitVoice(MySQLConnection? connection, int tableIndex,
    String word, Uint8List? voice) async {
  // print("准备上传声音 => $voice");
  if (voice != null && connection!.connected && voice.isNotEmpty) {
    if (connection != null) {
      var result = await connection.execute(
          "UPDATE word_table0$tableIndex SET voice='${base64.encode(voice.toList())}' WHERE word='$word'");
      print("注入结果：");
      for (final row in result.rows) {
        print(row.colAt(0));
      }
    }
  }
}

Future<Uint8List?> getSQLVoice(
    MySQLConnection? connection, int tableIndex, String word) async {
  Uint8List? ready;
  String cache = "";
  print("从数据库搜索单词 $word 的发音");
  if (connection != null && connection!.connected) {
    var result = await connection.execute(
        "SELECT voice FROM word_table0$tableIndex WHERE word = '$word'");
    // print(result);
    for (final row in result.rows) {
      cache += row.assoc()['voice'] ?? '';
    }
  }
  // print("BASE64 SOUND => $cache");
  if (cache != "") {
    try {
      ready = Uint8List.fromList(base64Decode(cache));
    } catch (e) {
      print(e);
    }
  }
  return ready;
}

Future<List<List<dynamic>>> getWords(MySQLConnection? connection) async {
  List<List<dynamic>> readyReturns = [];
  if (connection != null && connection!.connected) {
    var tableIndex = 2;
    while (tableIndex <= 6) {
      var result = await connection
          .execute("SELECT word, mean, other FROM word_table0$tableIndex");
      // print query result
      for (final row in result.rows) {
        // print(row.colAt(0));

        // print all rows as Map<String, String>
        readyReturns.add([
          tableIndex,
          row.assoc()['word']!,
          row.assoc()['mean'],
          row.assoc()['other'],
        ]);
      }
      tableIndex += 1;
    }
  }

  return readyReturns;
}
