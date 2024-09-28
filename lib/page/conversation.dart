import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:english_book/http/english_chinese.dart';
import 'package:english_book/page/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ConversationPage extends StatefulWidget {
  String word;
  bool isDarkness;
  ConversationPage({super.key, required this.word, required this.isDarkness});
  @override
  _ConversationPageState createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  // 这里定义一个较长的文本字符串，用于展示对话内容
  String conversationText = "";
  String text = "";
  Stream<Uint8List>? conversationStream;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAiExplain();
    // getAiExplain(this, () {
    //   setState(() {});
    // });
  }

  List<dynamic> showWord()  {
    Future.delayed(Duration.zero);
    return [text];
  }

  Future<void> getAiExplain() async {
    final dio = Dio();
    String avengeSize = Platform.isWindows ? "大" : "小";
    var data = {
      'content': [
        {'role': 'system', 'content': '美观的markdown格式输出'},
        {
          'role': 'system',
          'content':
              '请为${Platform.operatingSystem}设备输出平均字体大小偏$avengeSize的严格markdown格式文本'
        },
        {'role': 'system', 'content': '每一个你给的英文句子需要翻译成中文写在它下面'},
        {'role': 'system', 'content': '你需要为用户提供同义替换词、单词造句、语境说明、英英牛津该词原文'},
        {'role': 'user', 'content': widget.word}
      ]
    };
    try {
      Response<ResponseBody> response = await dio.post(
          'http://47.108.91.180:5000/stream',
          data: data,
          options: Options(responseType: ResponseType.stream));
      conversationStream = response.data?.stream;
      conversationStream?.listen((data) {
        String received = utf8.decode(data);
        print(received);
        conversationText += received;
        setState(() {});
      }, onError: (error) {
        print("Stream error $error");
      }, onDone: () {
        print("Stream close");
      });
    } catch (e) {
      print(e);
    }
  }

  String extractSubstring(String str, int start, int end) {
    // 确保起始索引小于结束索引
    if (start < 0 || end > str.length || start > end) {
      throw RangeError('索引超出范围');
    }
    // 使用substring方法提取子字符串
    return str.substring(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI解释:${widget.word}'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: MarkdownBody(
          selectable: true,
          onSelectionChanged: (text, selection, cause) {
            this.text = text ?? "";
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return MyHomePage(
                  isDarkness: widget.isDarkness, wordList: showWord);
            }));
          },
          data: conversationText,
        ),
      ),
    );
  }
}
