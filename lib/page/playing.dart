import 'dart:async';

import 'package:english_book/page/home.dart';
import 'package:english_book/theme/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as cup;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cache.dart';
import 'listen.dart';

class WordCard extends StatefulWidget {
  String word;
  var fatherWidgetState;
  void Function() refresh = () {};
  WordCard({super.key, required this.word, required this.fatherWidgetState});

  // List<dynamic> showWord()  {
  //   return [word];
  // }

  List<dynamic> args() {
    List<String> ready = [];
    int startIndex = 0;
    var cardList = (fatherWidgetState._scollingList as List<dynamic>);
    for (int i = cardList.length - 1; i >= 0; i--) {
      String word = cardList[i].word;
      if (cardList[i] == this) {
        startIndex = cardList.length - 1 - i;
      }
      ready.add(word);
    }
    return [startIndex, ready];
  }

  List<dynamic> showWord() {
    return args()[1];
  }

  int showIndex() {
    return args()[0];
  }

  @override
  State<StatefulWidget> createState() {
    return _WordCardState();
  }
}

class _WordCardState extends State<WordCard> {
  bool _showingOptions = false;
  bool _isOverflowing = false;
  ScrollController controller = ScrollController();

  void cancelOptions() {
    print("CANCEL");
    widget.fatherWidgetState.delWordCard(widget);
    setState() {
      _showingOptions = !_showingOptions;
      widget.fatherWidgetState.refreshState();
    }
  }

  void assertOverflowing() {
    setState(() {
      _isOverflowing = controller.position.maxScrollExtent > 0 &&
          (!(controller.offset == controller.position.maxScrollExtent));
    });
  }

  @override
  void initState() {
    super.initState();
    widget.refresh = () {
      assertOverflowing();
    };

    SchedulerBinding.instance.addPostFrameCallback((_) {
      assertOverflowing();
    });
  }

  @override
  void dispose() {
    _isOverflowing = false;
    setState(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkness =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Padding(
        padding: EdgeInsets.all(10),
        child: Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: isDarkness
                  ? Colors.white12
                  : Color.fromARGB(255, 238, 237, 237),
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    int index = widget.showIndex();
                    return MyHomePage(
                      isDarkness: isDarkness,
                      wordList: widget.showWord,
                      startIndex: index,
                    );
                  })).then((onValue) {
                    if (CustomCache.waitForAdd.hasCached()) {
                      widget.fatherWidgetState.initWordList();
                      setState(() {});
                    }
                  });
                },
                onLongPress: cancelOptions,
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 6 / 10,
                        child: Row(
                          children: [
                            Container(
                              width:
                                  MediaQuery.of(context).size.width * 5.5 / 10,
                              child: SingleChildScrollView(
                                controller: controller
                                  ..addListener(() {
                                    assertOverflowing();
                                  }),
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Text(
                                      widget.word,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            _isOverflowing
                                ? Container(
                                    child: Text(
                                      '...',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
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
          ),
        ));
  }
}

class Playing extends StatefulWidget {
  Playing({super.key, required this.title, required this.wordList});
  String title;
  dynamic wordList;

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
  List<String> _listenCardList = [];
  String inputing = "";
  TextEditingController controller = TextEditingController();
  int index = 0;

  final Future<SharedPreferencesWithCache> _group_prefs =
      SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
              // This cache will only accept the key 'counter'.
              allowList: <String>{'listenningGroup'}));

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Set<String> allowList = <String>{widget.title};
    initWordList();
  }

  Future<void> refreshListeningList(String title, String word) async {
    await _group_prefs.then((SharedPreferencesWithCache prefss) {
      String? waitRef;
      String? newList;
      var _rlistenCardList = prefss.getStringList("listenningGroup") ?? [];
      _rlistenCardList.forEach((value) {
        Map<String, dynamic> de = TitleTransformer.decode(value);
        String tit = de.keys.first;
        if (tit == title) {
          de.values.first.add(word);
          waitRef = value;
          newList = TitleTransformer.encode(tit, de.values.first);
        }
      });
      if (waitRef != null && newList != null) {
        _rlistenCardList.remove(waitRef);
        _rlistenCardList.add(newList!);
      }
      prefss.setStringList("listenningGroup", _rlistenCardList);
    });
  }

  Future<void> initWordList() async {
    _scollingList = [];
    int milliseconds = 200;
    await _group_prefs.then((SharedPreferencesWithCache prefss) {
      var _rlistenCardList = prefss.getStringList("listenningGroup") ?? [];
      _rlistenCardList.forEach((value) {
        Map<String, dynamic> de = TitleTransformer.decode(value);
        String tit = de.keys.first;
        if (tit == widget.title) {
          de.values.first.addAll(CustomCache.waitForAdd.get(tit));
          CustomCache.waitForAdd.clear(widget.title);

          // milliseconds = de.values.first.length * 5;
          de.values.first.forEach((value) {
            var dispos = 3;
            milliseconds + dispos >= 0 ? milliseconds += dispos : null;
            Future.delayed(Duration(milliseconds: milliseconds), () {
              _scollingList.add(WordCard(
                word: value.toString(),
                fatherWidgetState: this,
              ));
              setState(() {});
            });
          });
        }
      });
    });
  }

  void refreshState() {
    setState(() {});
  }

  Future<void> delWordCard(WordCard delCard) async {
    await _group_prefs.then((SharedPreferencesWithCache prefss) {
      String? waitRef;
      String? newList;
      var wordIndex = _scollingList.indexOf(delCard);
      var _rlistenCardList = prefss.getStringList("listenningGroup") ?? [];
      _rlistenCardList.forEach((value) {
        Map<String, dynamic> de = TitleTransformer.decode(value);
        String tit = de.keys.first;
        if (tit == widget.title) {
          de.values.first.removeAt(wordIndex);
          CustomCache.waitForAdd.remove(tit, delCard.word);
          waitRef = value;
          newList = TitleTransformer.encode(tit, de.values.first);
        }
      });
      if (waitRef != null && newList != null) {
        _rlistenCardList.remove(waitRef);
        _rlistenCardList.add(newList!);
      }
      prefss.setStringList("listenningGroup", _rlistenCardList);
      setState(() {
        _scollingList.remove(delCard);
      });
    });
  }

  void submitWord() {
    WordCard card = WordCard(
      word: inputing,
      fatherWidgetState: this,
    );
    // CustomCache.waitForAdd.add(widget.title, inputing);
    // CustomCache.waitForAdd.clearAll();
    refreshListeningList(widget.title, inputing).then((_) {
      _scollingList.add(card);
      inputing = "";
      controller.text = "";
      setState(() {});
    });
  }

  Future<bool> _onWillPop() async {
    // List<String> words = [];
    // for (var i = 0; i < _scollingList.length; i++) {
    //   words.add((_scollingList[i] as WordCard).word);
    // }
    // Navigator.pop(context, words);
    // return false;

    return true;
  }

  Widget dialogManager(Widget child) {
    return _showDialog ? child : const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    AutoColor autoColor = AutoColor(context);
    Color primaryColor = autoColor.primaryColor();
    Color textColor = autoColor.textColor();
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
                  style: TextStyle(color: textColor),
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
                    color: primaryColor,
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
            ],
          ),
        ),
        onWillPop: _onWillPop);
  }
}
