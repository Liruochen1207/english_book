import 'dart:math';

import 'package:english_book/page/collect.dart';
import 'package:english_book/page/conversation.dart';
import 'package:english_book/page/exam.dart';
import 'package:english_book/page/listen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:english_book/card/interface_controlableWidget.dart';
import 'package:english_book/card/template_card.dart';
import 'package:english_book/note_action.dart';
import 'package:english_book/sql/client.dart';
import 'package:english_book/sql/word.dart';

import 'package:english_book/http/english_chinese.dart';
import 'package:flutter/services.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cache.dart';

class MyHomePage extends StatefulWidget {
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  List<List<dynamic>> words = [[]];
  Future<List<List<dynamic>>> Function() wordList;
  MyHomePage({super.key, required this.isDarkness, required this.wordList});

  bool isDarkness;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late AudioPlayer player = AudioPlayer();
  var client = SqlClient();

  int _wordIndex = 0;
  int _delta = 0;
  final int _speechType = 2;
  List<String> _searchResult = [];
  var _word = "";
  var _phonetic = "";
  var _explain = "";
  var _other = "";
  Uint8List? _voice;
  int _tableIndex = 2;
  bool portalOpened = false;
  MySQLConnection? connection;
  ScrollController wordScrollController = ScrollController();
  bool isOverflowing = false;
  bool isEndScrolling = false;
  double textProportion = 15.6;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ListenerRegisterHandler registerHandler = ListenerRegisterHandler();
  List<EventRegisterHandler> eventHandlerList = [];
  FocusNode backgroundFocus = FocusNode();

  final Future<SharedPreferencesWithCache> _prefs =
      SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
              // This cache will only accept the key 'counter'.
              allowList: <String>{'wordIndex'}));

  get screenSize => MediaQuery.of(context).size;
  get screenWidth => screenSize.width;
  get screenHeight => screenSize.height;

  Future<void> _incrementCounter(int delta) async {
    _wordIndex = _wordIndex + delta;
    setState(() {});
    final SharedPreferencesWithCache prefs = await _prefs;
    if (_tableIndex == -1) {
      return;
    }
    prefs.setInt('wordIndex', _wordIndex).then((_) {});
  }

  void pageDown() {
    if (_wordIndex > widget.words.length) {
      return;
    }
    if (_wordIndex != 0) {
      _incrementCounter(-1);
      refreshWord();
    }
  }

  void pageUp() {
    if (_wordIndex < (widget.words.length - 1)) {
      _incrementCounter(1);
      refreshWord();
    }
  }

  Future<void> gatePortal() async {
    if (!portalOpened) {
      portalOpened = true;
      backgroundFocus.unfocus();
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return Exam(
          word: _word,
          voice: _voice,
          isDarkness: widget.isDarkness,
        );
      })).then((value) {
        print("VALUE => ${value.runtimeType}");
        if (value.runtimeType.toString() == "_Map<String, String>") {
          switch (value['result']) {
            case 'exam':
              FocusScope.of(context).requestFocus(backgroundFocus);
              print("SPEECH");
              speechWord(_speechType);
              break;
          }
        }

        portalOpened = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    try {
      if (!Platform.isAndroid) {
        isOverflowing = wordScrollController.position.maxScrollExtent > 0;
      }
    } catch (e) {}
    bool isLongWord = _word.contains(" ") || _word.length > 10;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor:
            widget.isDarkness ? Color.fromARGB(255, 82, 46, 145) : Colors.amber,
        leading: _tableIndex == -1
            ? null
            : IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ListenEntrance();
                  }));
                },
                icon: Icon(Icons.headphones)),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState!.openDrawer();
              setState(() {});
            },
          ),
          IconButton(
              onPressed: () {
                randomWord();
              },
              icon: Icon(Icons.sync)),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('工具栏'),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
            ),
            ListTile(
              title: Text('收藏夹'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ListenEntrance();
                }));
              },
            ),
            Divider(),
            ListTile(
              title: Text('AI解释'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ConversationPage(
                    isDarkness: widget.isDarkness,
                    word: _word,
                  );
                }));
              },
            ),
            Divider(),
            ListTile(
              title: Text('默写该词'),
              onTap: () {
                gatePortal();
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          TemplateCard(
            focusNode: backgroundFocus,
            listenerRegister: registerHandler,
            eventHandlerList: eventHandlerList,
            color: Color.fromARGB(0, 215, 223, 180),
          ),
          Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            //
            // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
            // action in the IDE, or press "p" in the console), to see the
            // wireframe for each widget.
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isLongWord
                      ? const SizedBox()
                      : Padding(
                          padding: EdgeInsets.only(left: 0, bottom: 40),
                          child: Center(
                            child: Text(
                              '$_word',
                              style: TextStyle(
                                  fontSize: Platform.isAndroid ? 32 : 35),
                            ),
                          ),
                        ),
                  isLongWord
                      ? Padding(
                          padding:
                              EdgeInsets.only(left: 24, right: 30, bottom: 20),
                          child: Container(
                            alignment: Alignment.center,
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 16),
                                  child: Text(
                                    '$_word',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                ),
                              ),
                            ),
                            height: 200,
                          ),
                        )
                      : const SizedBox(),
                  isLongWord
                      ? const IgnorePointer(
                          child: Divider(),
                        )
                      : const SizedBox(),
                  IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(),
                      child: Center(
                        child: Text(_phonetic),
                      ),
                    ),
                  ),
                ],
              ),

              // Padding(
              //     padding: EdgeInsets.only(left: 30),
              //     child: Row(
              //       children: [
              //         GestureDetector(
              //           child: Container(
              //             width: screenWidth / 1.37,
              //             child: SingleChildScrollView(
              //               controller: wordScrollController,
              //               scrollDirection: Axis.horizontal,
              //               child: Text(
              //                 '$_word',
              //                 style: TextStyle(
              //                     fontSize: Platform.isAndroid ? 32 : 35),
              //               ),
              //             ),
              //           ),
              //           onHorizontalDragUpdate: (value) {
              //             if (!Platform.isAndroid) {
              //               double maxPos = wordScrollController
              //                   .position.maxScrollExtent;
              //               double lastPos = wordScrollController.offset;
              //               wordScrollController
              //                   .jumpTo(lastPos -= value.delta.dx);
              //               double nowPos = wordScrollController.offset;
              //               isEndScrolling = nowPos >= maxPos;
              //               print(nowPos);
              //               setState(() {});
              //             }
              //           },
              //         ),
              //         (isOverflowing && (!isEndScrolling))
              //             ? Transform.translate(
              //                 offset: Offset(4, 0),
              //                 child: Text(
              //                   '...',
              //                   style: TextStyle(fontSize: 35),
              //                 ),
              //               )
              //             : const SizedBox(),
              //       ],
              //     ),
              //   ),

              isLongWord
                  ? const IgnorePointer(
                      child: SizedBox(
                        height: 20,
                      ),
                    )
                  : const SizedBox(),
              Column(
                children: [
                  IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(left: 30, right: 30),
                      child: Text(
                        '$_explain',
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(left: 30, right: 30),
                      child: Text(
                        '$_other',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ), // This trailing comma makes auto-formatting nicer for build methods.
          Positioned(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    onPressed: () {
                      speechWord(_speechType);
                    },
                    icon: Icon(
                      Icons.volume_up,
                      size: 26,
                    )),
                IconButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return CollectPage(
                          word: _word,
                        );
                      })).then((onValue) {
                        if (!Navigator.canPop(context)) {
                          CustomCache.waitForAdd.clearAll();
                        }
                      });
                    },
                    icon: Icon(
                      Icons.star_border,
                      size: 26,
                      color: Colors.amber,
                    )),
              ],
            ),
          ),
          // Positioned(
          //     bottom: 40,
          //     right: 40,
          //     child: FloatingActionButton(
          //       child: Icon(Icons.library_books),
          //       onPressed: () {
          //         gatePortal();
          //       },
          //     )),
          // Positioned(
          //     bottom: 40,
          //     right: 120,
          //     child: FloatingActionButton(
          //       child: const Center(
          //         child: Text(
          //           "AI",
          //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          //         ),
          //       ),
          //       onPressed: () {
          //         Navigator.push(context, MaterialPageRoute(builder: (context) {
          //           return ConversationPage(
          //             isDarkness: widget.isDarkness,
          //             word: _word,
          //           );
          //         }));
          //       },
          //     )),
        ],
      ),
    );
  }

  Future<void> updateData() async {
    print("尝试注入单词 $_word");
    if (_tableIndex == -1) {
      return;
    }
    var words = widget.words;
    if (words.isNotEmpty) {
      List args = words[_wordIndex];
      if (args[2] == "") {
        submitMeans(connection, _tableIndex, _word, _explain);
      }
      if (args[3] == "") {
        submitOthers(connection, _tableIndex, _word, _other);
      }

      submitVoice(connection, _tableIndex, _word, _voice);
    }
  }

  Future<void> randomWord() async {
    _wordIndex = Random().nextInt(widget.words.length);
    refreshWord();
    final SharedPreferencesWithCache prefs = await _prefs;
    prefs.setInt('wordIndex', _wordIndex).then((_) {});
  }

  @override
  void dispose() {
    // Release all sources and dispose the player.
    player.dispose();
    backgroundFocus.unfocus();
    backgroundFocus.dispose();
    super.dispose();
  }

  Future<List<String>> explainWord(String word) async {
    List<String> ready = [];
    if (word != "") {
      ready = await englishSearch(word);
    }
    if (ready.isEmpty) {
      ready = [await translateLanguage(word)];
    }
    setState(() {});
    return ready;
  }

  Future<void> connectSQL() async {
    print("尝试连接");
    connection = await client.connect();
    print(connection);
    // widget.words = await getWords(connection);
    // refreshWord();
  }

  @override
  void initState() {
    super.initState();
    _prefs.then((SharedPreferencesWithCache prefs) {
      _wordIndex = prefs.getInt('wordIndex') ?? 0;
    });
    widget.wordList().then((onValue) {
      widget.words = onValue;
      // print(widget.words);
      connectSQL();
      refreshWord();

      setState(() {});
    });
    if (Platform.isAndroid) {
      wordScrollController.addListener(() {
        isEndScrolling = wordScrollController.offset >=
            wordScrollController.position.maxScrollExtent;
        if (!isEndScrolling) {
          isOverflowing = true;
        }
        setState(() {});
        print(isEndScrolling);
      });
    }
    // refreshWord();
    // Create the audio player.
    player = AudioPlayer();

    // Set the release mode to keep the source after playback has completed.
    player.setReleaseMode(ReleaseMode.stop);
    eventHandlerList.add(EventRegisterHandler(LogicalKeyboardKey.arrowLeft)
      ..setOnlyKeyUpAlive()
      ..setHandler(() {
        print("LEFT");
        pageDown();
      }));

    eventHandlerList.add(EventRegisterHandler(LogicalKeyboardKey.arrowRight)
      ..setOnlyKeyUpAlive()
      ..setHandler(() {
        print("RIGHT");
        pageUp();
      }));

    player.setReleaseMode(ReleaseMode.stop);
    eventHandlerList.add(EventRegisterHandler(LogicalKeyboardKey.pageUp)
      ..setHandler(() {
        print("LEFT");
        double maxPos = wordScrollController.position.maxScrollExtent;
        double lastPos = wordScrollController.offset;
        wordScrollController.jumpTo(lastPos -= 12);
        double nowPos = wordScrollController.offset;
        isEndScrolling = nowPos >= maxPos;
        setState(() {});
      }));

    eventHandlerList.add(EventRegisterHandler(LogicalKeyboardKey.pageDown)
      ..setHandler(() {
        print("RIGHT");
        double maxPos = wordScrollController.position.maxScrollExtent;
        double lastPos = wordScrollController.offset;
        wordScrollController.jumpTo(lastPos += 12);
        double nowPos = wordScrollController.offset;
        isEndScrolling = nowPos >= maxPos;
        setState(() {});
      }));

    eventHandlerList.add(EventRegisterHandler(LogicalKeyboardKey.space)
      ..setOnlyKeyUpAlive()
      ..setHandler(() {
        print("SPEECH");
        speechWord(_speechType);
      }));

    eventHandlerList.add(EventRegisterHandler(LogicalKeyboardKey.enter)
      ..setOnlyKeyUpAlive()
      ..setHandler(() {
        print("EXAM");
        gatePortal();
      }));

    registerHandler.addListener(
        ListenerType.onPointerMove, NoteButtonAction.leftButton, (event) {
      print("DRAGING => ${event.delta}");
      if (event.delta.dx < 0) {
        _delta += 1;
      }
      if (event.delta.dx > 0) {
        _delta -= 1;
      }
    });

    registerHandler.addListener(
        ListenerType.onPointerMove, NoteButtonAction.leftButton, (event) {
      if (event.delta.dx < 0) {
        _delta += 1;
      }
      if (event.delta.dx > 0) {
        _delta -= 1;
      }
    });
    registerHandler.addListener(
        ListenerType.onPointerUp, NoteButtonAction.leftButton, (event) {
      if (_delta.abs() > 7) {
        if (_delta < 0) {
          print("page -");
          pageDown();
        } else {
          print("page +");
          pageUp();
        }
      } else {
        if (event.position.dx > (screenWidth - (screenWidth / 3))) {
          pageUp();
        } else if (event.position.dx <= screenWidth / 3) {
          pageDown();
        } else {
          speechWord(_speechType);
        }
      }

      _delta = 0;
    });
    setState(() {});
  }

  String pickWord(int index) {
    var words = widget.words;
    if (words.length == 0) {
      return "";
    } else {
      var result = [];
      if (index > words.length) {
        result = words.last;
      } else {
        result = words[index];
      }

      _tableIndex = result[0];
      _explain = result[2] ?? '';
      _other = result[3] ?? '';
      // words[_counter][2] = _explain;
      // words[_counter][3] = _other;

      return result[1];
    }
  }

  void voiceManage({required bool doPlaying}) {
    getSQLVoice(connection, _tableIndex, _word).then((voice) {
      // print(voice);
      if (true || voice == null) {
        print("需要从互联网补充音频");
        getSpeechBytes(_word).then((onValue) {
          _voice = onValue;
          submitVoice(connection, _tableIndex, _word, onValue);
          if (doPlaying) {
            player = AudioPlayer();
            player.setReleaseMode(ReleaseMode.stop);
            player.setSource(BytesSource(onValue));
            player.resume();
          }
        });
      } else {
        print("需要从数据库读取音频");
        _voice = voice;
        if (doPlaying) {
          player = AudioPlayer();
          player.setReleaseMode(ReleaseMode.stop);
          player.setSource(BytesSource(voice));
          player.resume();
        }
      }
    });
  }

  void refreshWord() {
    print("需要刷新当前单词的时间 => ${DateTime.now()}");
    _word = pickWord(_wordIndex);
    // voiceManage(doPlaying: false);

    getEnglishWordPhonetic(_word).then((onValue) {
      _phonetic = onValue;
      setState(() {});
    });

    // _word = "curve";
    if (_explain == '' || _other == '') {
      print("需要搜索");
      explainWord(_word).then((value) {
        print("搜索结果 => $value");
        _searchResult = value;
        _explain = value.first;
        _other = '';
        for (var i = 0; i < value.length; i++) {
          if (value[i] != value.first) {
            _other += value[i];
          }
        }

        updateData();
        if (Platform.isAndroid) {
          isOverflowing = wordScrollController.position.maxScrollExtent > 0;
          isEndScrolling = false;
        }
        setState(() {});
      });
    }
    isOverflowing = _word.length * textProportion > screenWidth / 2;
    isEndScrolling = false;
    setState(() {});
  }

  Future<void> speechWord(int type) async {
    if (type < 1) {
      type = 1;
    }
    if (type > 2) {
      type = 2;
    }
    voiceManage(doPlaying: true);

    // await player.setSource(
    //     UrlSource("https://dict.youdao.com/dictvoice?audio=$_word&type=$type"));
    // await player.resume();
  }
}
