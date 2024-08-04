import 'package:english_book/page/exam.dart';
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

List<List<dynamic>> words = [];

class MyHomePage extends StatefulWidget {
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late AudioPlayer player = AudioPlayer();
  var client = SqlClient();

  int _counter = 0;
  int _delta = 0;
  List<String> _searchResult = [];
  var _word = "";
  var _explain = "";
  var _other = "";
  Uint8List? _voice;
  int _tableIndex = 2;
  bool portalOpened = false;
  MySQLConnection? connection;

  ListenerRegisterHandler registerHandler = ListenerRegisterHandler();
  List<EventRegisterHandler> eventHandlerList = [];
  FocusNode backgroundFocus = FocusNode();

  get screenSize => MediaQuery.of(context).size;
  get screenWidth => screenSize.width;
  get screenHeight => screenSize.height;

  void pageDown() {
    if (_counter != 0) {
      _counter -= 1;
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
        );
      })).then((value) {
        print("VALUE => ${value.runtimeType}");
        if (value.runtimeType.toString() == "_Map<String, String>") {
          switch (value['result']) {
            case 'exam':
              print("SPEECH");
              speechWord(2);
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
      ),
      body: Stack(
        children: [
          TemplateCard(
            focusNode: backgroundFocus,
            listenerRegister: registerHandler,
            eventHandlerList: eventHandlerList,
            color: Color.fromARGB(0, 215, 223, 180),
          ),
          Center(
            child: Column(
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$_word',
                        style: TextStyle(fontSize: 30),
                      ),
                      SizedBox(
                        width: 1,
                      ),
                      // IconButton(onPressed: (){
                      //   speechWord(1);
                      // }, icon: Icon(Icons.volume_up, size: 20,)),
                      IconButton(
                          onPressed: () {
                            speechWord(2);
                          },
                          icon: Icon(
                            Icons.volume_up,
                            size: 20,
                          )),
                    ],
                  ),
                ),
                IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      '$_explain',
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      '$_other',
                    ),
                  ),
                ),
              ],
            ),
          ), // This trailing comma makes auto-formatting nicer for build methods.

          Positioned(
              bottom: 40,
              right: 40,
              child: FloatingActionButton(
                child: Icon(Icons.library_books),
                onPressed: () {
                  gatePortal();
                },
              )),
        ],
      ),
    );
  }

  Future<void> connectSQL() async {
    print("尝试连接");
    connection = await client.connect();
    print(connection);
    words = await getWords(connection);
    print(words);
    refreshWord();
  }

  Future<void> updateData() async {
    print("尝试注入单词 $_word");
    submitMeans(connection, _tableIndex, _word, _explain);
    submitOthers(connection, _tableIndex, _word, _other);
    submitVoice(connection, _tableIndex, _word, _voice);
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
    return ready;
  }

  @override
  void initState() {
    super.initState();
    connectSQL();
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
        refreshWord();
      }));

    eventHandlerList.add(EventRegisterHandler(LogicalKeyboardKey.arrowRight)
      ..setOnlyKeyUpAlive()
      ..setHandler(() {
        print("RIGHT");
        _counter += 1;
        refreshWord();
      }));

    eventHandlerList.add(EventRegisterHandler(LogicalKeyboardKey.space)
      ..setOnlyKeyUpAlive()
      ..setHandler(() {
        print("SPEECH");
        speechWord(2);
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
          _counter += 1;
        }

        refreshWord();
      } else {
        if (event.position.dx > (screenWidth - (screenWidth / 3))) {
          _counter += 1;
          refreshWord();
        } else if (event.position.dx <= screenWidth / 3) {
          pageDown();
          refreshWord();
        }
      }

      _delta = 0;
    });
  }

  String pickWord(int index) {
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
      print(voice);
      if (voice == null) {
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
    _word = pickWord(_counter);
    voiceManage(doPlaying: false);

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
        setState(() {});
      });
    }
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

  void _incrementCounter() {
    _counter++;
    refreshWord();
  }
}
