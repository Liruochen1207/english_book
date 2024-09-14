import 'dart:async';

import 'package:english_book/page/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as cup;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordCard extends StatefulWidget {
  String word;
  var fatherWidgetState;
  WordCard({super.key, required this.word, required this.fatherWidgetState});

  Future<List<List<dynamic>>> showWord() async {
    await Future.delayed(Duration.zero);
    return [
      [-1, word, null, null]
    ];
  }

  @override
  State<StatefulWidget> createState() {
    return _WordCardState();
  }
}

class _WordCardState extends State<WordCard> {
  bool _showingOptions = false;

  void cancelOptions() {
    print("CANCEL");
    widget.fatherWidgetState.delWordCard(widget);
    setState() {
      _showingOptions = !_showingOptions;
      widget.fatherWidgetState.refreshState();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkness =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Padding(
        padding: EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: isDarkness
                ? Colors.white12
                : Color.fromARGB(255, 238, 237, 237),
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return MyHomePage(
                      isDarkness: isDarkness, wordList: widget.showWord);
                }));
              },
              onLongPress: cancelOptions,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Text(
                          widget.word,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        )
                      ],
                    ),
                  ),
                  Visibility(
                    child: Container(
                      width: double.infinity,
                      height: 70,
                      color: Colors.black26,
                    ),
                    visible: _showingOptions,
                  ),
                  Visibility(
                      visible: _showingOptions,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(
                            child: Container(
                              width: 100,
                              height: 70,
                              alignment: Alignment.center,
                              color: Colors.red,
                              child: Text("删除"),
                            ),
                            onTap: () {
                              print("d");
                              widget.fatherWidgetState.delWordCard(widget);
                            },
                          ),
                          InkWell(
                              child: Container(
                                width: 100,
                                height: 70,
                                alignment: Alignment.center,
                                color: Colors.amber[800],
                                child: Text("取消"),
                              ),
                              onTap: cancelOptions),
                        ],
                      ))
                ],
              ),
            ),
          ),
        ));
  }
}

class Playing extends StatefulWidget {
  List<dynamic> wordList;
  Playing({super.key, required this.title, required this.wordList});
  String title;
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _PlayingState();
  }
}

class _PlayingState extends State<Playing> {
  bool isDisable = false;
  bool _showDialog = false;
  List<Widget> _scollingList = [];
  String inputing = "";
  TextEditingController controller = TextEditingController();
  Timer? timer;
  int index = 0;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Set<String> allowList = <String>{widget.title};
    widget.wordList.forEach((value) {
      _scollingList.add(WordCard(
        word: value.toString(),
        fatherWidgetState: this,
      ));
    });
  }

  void refreshState() {
    setState(() {});
  }

  void delWordCard(WordCard delCard) {
    _scollingList.remove(delCard);
    setState(() {});
  }

  void submitWord() {
    setState(() {
      _scollingList.add(WordCard(
        word: inputing,
        fatherWidgetState: this,
      ));
      inputing = "";
      controller.text = "";
    });
  }

  Future<bool> _onWillPop() async {
    List<String> words = [];
    for (var i = 0; i < _scollingList.length; i++) {
      words.add((_scollingList[i] as WordCard).word);
    }
    Navigator.pop(context, words);
    return false;
  }

  Widget dialogManager(Widget child) {
    return _showDialog ? child : const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkness =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.title,
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              IconButton(
                  onPressed: () {
                    setState(() {
                      _showDialog = !_showDialog;
                    });
                  },
                  icon: Icon(_showDialog ? Icons.close : Icons.add))
            ],
          ),
          body: Column(
            children: [
              const SizedBox(
                height: 30,
              ),
              const Divider(),
              dialogManager(Padding(
                padding: EdgeInsets.all(20),
                child: cup.CupertinoTextField(
                  placeholder: "请输入要添加的单词",
                  style:
                      TextStyle(color: isDarkness ? Colors.grey : Colors.black),
                  controller: controller,
                  onChanged: (value) {
                    inputing = value;
                  },
                  onSubmitted: (value) {
                    submitWord();
                  },
                ),
              )),
              dialogManager(ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    submitWord();
                  },
                  child: Container(
                    width: 250,
                    height: 40,
                    alignment: Alignment.center,
                    color: isDarkness
                        ? Colors.deepPurple
                        : Color.fromARGB(255, 232, 220, 90),
                    child: Text("添加"),
                  ),
                ),
              )),
              dialogManager(Divider()),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    verticalDirection: VerticalDirection.up,
                    children: _scollingList,
                  ),
                ),
              ),
              Container(
                height: 70,
                color: isDarkness ? Colors.deepPurple : Colors.amber,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                    ),
                    IconButton(
                        onPressed: () {
                          List<String> wordList = [];
                          for (var i = 0; i < _scollingList.length; i++) {
                            WordCard card = _scollingList[i] as WordCard;
                            wordList.add(card.word);
                          }
                          int repeatTimes = 2;
                          timer = Timer.periodic(Duration(milliseconds: 1500),
                              (timer) {
                            if (index < wordList.length) {
                              print(wordList[index]);
                              index++;
                            } else {
                              print('已完成打印所有列表项');
                              index = 0;
                              timer.cancel();
                            }
                          });
                        },
                        icon: Icon(
                          Icons.play_arrow,
                          size: 34,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        onWillPop: _onWillPop);
  }
}
