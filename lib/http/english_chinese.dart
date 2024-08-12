import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:html/dom.dart';
import 'package:html/dom_parsing.dart';
import 'package:html/parser.dart';

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


Future<String> translateLanguage(String sentence) async {
  var ready = "";
  var query = {
    'inputtext': sentence,
    'type': 'AUTO',
  };
  await dioPost("https://smartisandict.youdao.com/translate", query)
      .then((value) {
    var htmlString = value.toString();
    var document = parse(htmlString);
    document.querySelectorAll("ul").forEach((element) {
      if (element.attributes['id'].toString() == 'translateResult') {
        element.children.forEach((element) {
          ready += element.text;
        });
      }
    });
  });
  return ready;
}

Future<List<String>> englishSearch(String word) async {
  List<String> ready = [];

  final dio = Dio();
  final response = await dio
      .get('https://fanyi.baidu.com/sug', queryParameters: {"kw": word});

  var data = response.data;
  print(response.statusCode);
  print(data);
  print(data['data']);
  print(data['data'].runtimeType);
  try {
    if (data is Map && (data['data'] as List<dynamic>).isNotEmpty) {
      for (var i = 0; i < (data['data'] as List<dynamic>).length; i++) {
        var cache = "";
        Map m = (data['data'] as List<dynamic>)[i];
        cache += "${m['k']} - ";
        cache += "${m['v']}\n";
        ready.add(cache);
      }
    }
  } catch (TypeError) {
    return [];
  }
  return ready; // 打印存储的字符串
}

Future<Uint8List> getSpeechBytes(String word) async {
  final dio = Dio();
  final response = await dio.get("https://dict.youdao.com/dictvoice/",
      options: Options(responseType: ResponseType.bytes),
      queryParameters: {"audio": word, "type": 2});
  print(response.data.runtimeType);
  return response.data;
}

Future<void> main() async {
  var word = await getSpeechBytes('hello');
}
