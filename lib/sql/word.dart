import 'package:mysql_client/mysql_client.dart';
import 'package:english_book/setting.dart';
import 'package:english_book/sql/client.dart';

Future<void> submitMeans(MySQLConnection? connection, int tableIndex,
    String word, String mean) async {
  if (mean != "") {
    if (connection != null) {
      var result = await connection.execute(
          "UPDATE word_table0$tableIndex SET mean='$mean' WHERE word='$word'");
      print("注入结果：");
      for (final row in result.rows) {
        print(row.colAt(0));
      }
    }
  }
}

Future<List<List<dynamic>>> getWords(MySQLConnection? connection) async {
  List<List<dynamic>> readyReturns = [];
  if (connection != null) {
    var tableIndex = 2;
    while (tableIndex <= 6) {
      var result =
          await connection.execute("SELECT word FROM word_table0$tableIndex");
      // print query result
      for (final row in result.rows) {
        // print(row.colAt(0));

        // print all rows as Map<String, String>
        readyReturns.add([
          tableIndex,
          row.assoc()['word']!,
          row.assoc()['mean']!,
          row.assoc()['other']!
        ]);
      }
      tableIndex += 1;
    }
  }

  return readyReturns;
}
