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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAiExplain(this, () {
      setState(() {});
    });
  }

  Future<List<List<dynamic>>> showWord() async {
    await Future.delayed(Duration.zero);
    return [
      [-1, text, null, null]
    ];
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
