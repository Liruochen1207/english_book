import 'package:mysql_client/mysql_client.dart';
import 'package:english_book/setting.dart';

typedef Sql = MysqlSetting;

class SqlClient{

  MySQLConnection? connection;

  Future<MySQLConnection?> connect() async {
    if (connection == null || !connection!.connected){
      connection = await getCon();
      await connection?.connect();
    }
    return connection;

  }

  Future<MySQLConnection> getCon() async {
    final conn = await MySQLConnection.createConnection(
      host: Sql.host,
      port: Sql.port,
      userName: Sql.userName,
      password: Sql.passWord,
      databaseName: Sql.databaseName, // optional
      secure: Sql.secure,
    );

// actually connect to database
    return conn;
  }



}