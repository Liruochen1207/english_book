import 'dart:convert';
import 'dart:typed_data';

import 'package:mysql_client/mysql_client.dart';

import 'package:dio/dio.dart';

Future<dynamic> dioGet(String url, [query]) async {
  final dio = Dio();
  final response = await dio.get(url, queryParameters: query);
  return response.data; // 打印存储的字符串
}

Future<dynamic> dioPost(String url, [query]) async {
  final dio = Dio();
  final response = await dio.post(url, queryParameters: query);
  return response.data; // 打印存储的字符串
}

Future<void> submitMeans(MySQLConnection? connection, int tableIndex,
    String word, String mean) async {
  if (tableIndex == -1) {
    return;
  }
  if (mean != "") {
    if (connection != null && connection!.connected) {
      var result = await connection.execute(
          "UPDATE word_table0$tableIndex SET mean='$mean' WHERE word='$word'");
      print("注入结果：");
      // for (final row in result.rows) {
      //   print(row.colAt(0));
      // }
    }
  }
}

Future<void> submitOthers(String word, String other) async {
  if (generateAlphabet().contains(word[0])) {
    if (other != "") {
      var result = await dioPost("http://47.108.91.180:5000/update_other", {
        "word": word,
        "other": other,
      });
      print(result);
    }
  }
}



// Future<void> submitVoice(MySQLConnection? connection, int tableIndex,
//     String word, Uint8List? voice) async {
//   if (tableIndex == -1) {
//     return;
//   }
//   // print("准备上传声音 => $voice");
//   if (voice != null && connection!.connected && voice.isNotEmpty) {
//     if (connection != null) {
//       var result = await connection.execute(
//           "UPDATE word_table0$tableIndex SET voice='${base64.encode(voice.toList())}' WHERE word='$word'");
//       print("注入结果：");
//       for (final row in result.rows) {
//         print(row.colAt(0));
//       }
//     }
//   }
// }

Future<List<dynamic>> getWords(String letter) async {
  var data = await dioPost("http://47.108.91.180:5000/table", {
    "letter": letter,
  });
  if (data.containsKey('words')) {
    return data['words'];
  }
  return [];
}

Future<bool> getWordExist(String word) async {
  var data = await dioPost("http://47.108.91.180:5000/exist", {
    "word": word,
  });
  if (data.containsKey('exist')) {
    print(data['exist'] == true);
    return data['exist'] == true;
  }

  return false;
}

Future<void> saveNewWord(String word) async {
  if (generateAlphabet().contains(word[0])) {
    getWordExist(word).then((value) {
      print(word);
      print("EXIST $value");
      if (!value && !word.contains(" ")) {
        dioPost("http://47.108.91.180:5000/new_word", {
          "word": word,
        }).then((onValue) {
          print(onValue);
        });
      }
    });
  }
}

String generateAlphabet() {
  final List<String> alphabet = [];
  for (int i = 'a'.codeUnitAt(0); i <= 'z'.codeUnitAt(0); i++) {
    alphabet.add(String.fromCharCode(i));
  }
  print(alphabet);
  return alphabet.join();
}

// Future<List<List<dynamic>>> getWords(MySQLConnection? connection) async {
//   List<List<dynamic>> readyReturns = [];
//   if (connection != null && connection!.connected) {
//     var tableIndex = 2;
//     while (tableIndex <= 6) {
//       var result = await connection
//           .execute("SELECT word, mean, other FROM word_table0$tableIndex");
//       // print query result
//       for (final row in result.rows) {
//         // print(row.colAt(0));
//
//         // print all rows as Map<String, String>
//         readyReturns.add([
//           tableIndex,
//           row.assoc()['word']!,
//           row.assoc()['mean'],
//           row.assoc()['other'],
//         ]);
//       }
//       tableIndex += 1;
//     }
//   }
//
//   return readyReturns;
// }
