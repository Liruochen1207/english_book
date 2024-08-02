import 'package:mysql_client/mysql_client.dart';
import 'package:english_book/setting.dart';
import 'package:english_book/sql/client.dart';


Future<List<String>> getWords(MySQLConnection? connection) async {
  List<String> readyReturns = [];
  if (connection != null){
    var tableIndex = 2;
    while (tableIndex <= 6){
      var result = await connection.execute("SELECT word FROM word_table0$tableIndex");
      // print query result
      for (final row in result.rows) {
        // print(row.colAt(0));

        // print all rows as Map<String, String>
        readyReturns.add(row.assoc()['word']!);
      }
      tableIndex += 1;
    }
  }

  return readyReturns;
}
