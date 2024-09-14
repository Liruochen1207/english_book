import 'dart:convert';

import 'package:english_book/page/playing.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TitleTransformer {
  static String encode(String title, List<dynamic> wordList) {
    Map tw = {title: wordList};
    return json.encode(tw);
  }

  static Map<String, dynamic> decode(String jsonString) {
    return json.decode(jsonString) as Map<String, dynamic>;
  }
}

class ListenningCard extends StatefulWidget {
  ListenningCard(
      {super.key,
      required this.fatherWidgetState,
      required this.title,
      required this.wordList});
  String title = "";
  List<dynamic> wordList = [];
  var fatherWidgetState;

  @override
  _ListenningCardState createState() => _ListenningCardState();
}

class _ListenningCardState extends State<ListenningCard> {
  bool _isShowingPanel = false;
  late final Future<SharedPreferencesWithCache> _fatherPrefs;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fatherPrefs = widget.fatherWidgetState.prefs;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            child: InkWell(
              onTap: () async {
                var result = await Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return Playing(
                    wordList: widget.wordList,
                    title: widget.title,
                  );
                }));
                // print("${widget.title} Result ===> $result");
                // print("${widget.title} Result Type ===> ${result.runtimeType}");
                if (result.runtimeType == List<String>) {
                  widget.fatherWidgetState.refreshCard(widget, result);
                  setState(() {});
                }
              },
              onLongPress: () {
                setState(() {
                  _isShowingPanel = true;
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: EdgeInsets.all(15),
                    child: Text(
                      widget.title,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Divider(),
                ],
              ),
            ),
          ),
          Visibility(
            visible: _isShowingPanel,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isShowingPanel = false;
                });
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black26,
                child: Padding(
                  padding: EdgeInsets.all(10),
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
                          _isShowingPanel = false;
                          widget.fatherWidgetState.delCard(widget);
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
                        onTap: () {
                          print("c");
                          setState(() {
                            _isShowingPanel = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ListenEntrance extends StatefulWidget {
  ListenEntrance({super.key});

  @override
  _ListenEntranceState createState() => _ListenEntranceState();
}

class _ListenEntranceState extends State<ListenEntrance> {
  List<Widget> _listenningGroup = [];
  List<String> _listenCardList = [];

  final Future<SharedPreferencesWithCache> _prefs =
      SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
              // This cache will only accept the key 'counter'.
              allowList: <String>{'listenningGroup'}));

  get prefs => _prefs;

  Future<void> addLisCard() async {
    String title = DateTime.now().toString();
    _listenningGroup.add(ListenningCard(
      title: title,
      wordList: [],
      fatherWidgetState: this,
    ));
    _listenCardList.add(TitleTransformer.encode(title, []));
    final SharedPreferencesWithCache prefs = await _prefs;
    prefs.setStringList("listenningGroup", _listenCardList);
  }

  Future<void> refreshCard(
      ListenningCard deletingCard, List<dynamic> newList) async {
    String title = deletingCard.title;
    await delCard(deletingCard);
    _listenningGroup.add(ListenningCard(
      title: title,
      wordList: newList,
      fatherWidgetState: this,
    ));
    _listenCardList.add(TitleTransformer.encode(title, newList));
    final SharedPreferencesWithCache prefs = await _prefs;
    prefs.setStringList("listenningGroup", _listenCardList);
  }

  Future<void> delCard(ListenningCard deletingCard) async {
    String? waitDel;
    _listenCardList.forEach((value) {
      Map<String, dynamic> de = TitleTransformer.decode(value);
      String tit = de.keys.first;
      if (tit == deletingCard.title) {
        waitDel = value;
      }
    });

    _listenningGroup.remove(deletingCard);
    _listenCardList.remove(waitDel);
    final SharedPreferencesWithCache prefs = await _prefs;
    prefs.setStringList("listenningGroup", _listenCardList);
    setState(() {});
  }

  Future<void> setUp() async {
    await _prefs.then((SharedPreferencesWithCache prefs) {
      _listenCardList = prefs.getStringList("listenningGroup") ?? [];
      print(_listenCardList);
      for (var i = 0; i < _listenCardList.length; i++) {
        print("DEE => ${TitleTransformer.decode(_listenCardList[i])}");
        Map<String, dynamic> de = TitleTransformer.decode(_listenCardList[i]);
        print("DEE $de");
        print("First ${de.keys.first.runtimeType}");
        print("Second ${de.values.first.runtimeType}");
        String tit = de.keys.first;
        List<dynamic> li = de.values.first;
        _listenningGroup.add(ListenningCard(
          title: tit,
          wordList: li,
          fatherWidgetState: this,
        ));
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setUp();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("创建听写任务组"),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Column(
          verticalDirection: VerticalDirection.up,
          children: _listenningGroup,
        ),
      ),
      floatingActionButton: Transform.translate(
        offset: Offset(-20, -20),
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              addLisCard();
            });
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
