import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:english_book/page/conversation.dart';

import 'package:html/dom.dart';
import 'package:html/dom_parsing.dart';
import 'package:html/parser.dart';

import '../custom_types.dart';

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

Future<String> getEnglishWordPhonetic(String word) async {
  String ready = "";
  if (!word.contains(" ")) {
    await dioGet("https://www.youdao.com/result?word=$word&lang=en")
        .then((onValue) {
      var document = parse(onValue.toString());
      document.querySelectorAll("div").forEach((element) {
        if (element.attributes['class'].toString().contains('per-phone')) {
          ready += element.text;
          ready += " ";
        }
      });
    });
  }
  // print(ready);
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

Future<WordDetails?> getWordDetails(String word) async {
  final dio = Dio();
  try {
    final response  = await dio.post("http://47.108.91.180:5000/word?word=$word");
    Map result  = response.data;
    WordDetails wd = WordDetails(cet4: nBool(result["cet4"]), cet6: nBool(result["cet6"]),
        gre: nBool(result["gre"]), ielts: nBool(result["ielts"]), toefl: nBool(result["toefl"]),
        postgraduate: nBool(result["postgraduate"]), mean: result["mean"], synonym: showSym(result["synonym"]),
        voice: bytesFromBase64(result["voice"]));
    return wd;
  } catch (e) {
    print(e);
  }
  return null;
}



Future<List<String>?> getCustomSearch(String word) async {
  final dio = Dio();
  try {
    final response  = await dio.post("http://47.108.91.180:5000/search?word=$word&type=0");
    List<String> ready = [];
    List<dynamic> results = response.data['results'];
    results.forEach((element){
      ready.add(element);
    });
    return ready;
  } catch (e) {
    print(e);
  }
  return null;
}

Future<Uint8List> getSpeechBytes(String word) async {
  final dio = Dio();
  final response = await dio.get("https://dict.youdao.com/dictvoice/",
      options: Options(responseType: ResponseType.bytes),
      queryParameters: {"audio": word, "type": 2});
  print(response.data.runtimeType);
  return response.data;
}

// Future<void> getAiExplain(
//     dynamic conversationPageState, void Function() onRefresh) async {
//   final dio = Dio();
//   String avengeSize = Platform.isWindows ? "大" : "小";
//   var data = {
//     'content': [
//       {'role': 'system', 'content': '美观的markdown格式输出'},
//       {
//         'role': 'system',
//         'content': '请为${Platform.operatingSystem}设备输出平均字体大小偏$avengeSize的严格markdown格式文本'
//       },
//       {'role': 'system', 'content': '每一个你给的英文句子需要翻译成中文写在它下面'},
//       {'role': 'system', 'content': '你需要为用户提供同义替换词、单词造句、语境说明、英英牛津该词原文'},
//       {'role': 'user', 'content': conversationPageState.widget.word}
//     ]
//   };
//   try {
//     Response<ResponseBody> response = await dio.post(
//         'http://47.108.91.180:5000/stream',
//         data: data,
//         options: Options(responseType: ResponseType.stream));
//     response.data?.stream.listen((data) {
//       String received = utf8.decode(data);
//       print(received);
//       conversationPageState.conversationText += received;
//       onRefresh();
//     }, onError: (error) {
//       print("Stream error $error");
//     }, onDone: () {
//       print("Stream close");
//     });
//   } catch (e) {
//     print(e);
//   }
// }

Future<void> main() async {
  var word = await getEnglishWordPhonetic('hello');
}
