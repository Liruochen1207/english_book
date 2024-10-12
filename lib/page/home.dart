import 'dart:math';

import 'package:english_book/page/about.dart';
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
import 'package:english_book/http/word.dart';

import 'package:english_book/http/english_chinese.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:win32/win32.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:mysql_client/mysql_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apk.dart';
import '../cache.dart';
import '../custom_types.dart';
import '../path.dart';
import '../theme/color.dart';

class ClickableQuarterCircle extends StatelessWidget {
  void Function() onClick = () {};
  Color background = Colors.grey;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onClick();
      },
      child: Container(
        width: 60,
        height: 60,
        child: Stack(
          children: [
            Positioned(
              child: Container(
                color: background,
                width: 10,
                height: 50,
              ),
              left: 0,
            ),
            Positioned(
                top: -50,
                left: -40,
                child: CustomPaint(
                  painter: QuarterCirclePainter(background),
                  size: Size(100, 100),
                )),
            Positioned(
                top: 7,
                left: 17,
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                )),
          ],
        ),
      ),
    );
  }
}

class QuarterCirclePainter extends CustomPainter {
  late Color background;
  QuarterCirclePainter(this.background);
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = background
      ..style = PaintingStyle.fill;

    // Adjust the rect to start from the top left corner
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Start the arc from 0 (x-axis) to pi/2 (90 degrees clockwise from the x-axis)
    // which will draw the quarter circle in the bottom left quadrant
    canvas.drawArc(rect, 0, 3.14 / 2, true, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class MyHomePage extends StatefulWidget {
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  List<dynamic> words = [];
  List<dynamic> Function() wordList;
  int startIndex;
  MyHomePage(
      {super.key,
      required this.isDarkness,
      required this.wordList,
      required this.startIndex});

  bool isDarkness;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AudioPlayer? player;

  bool _isAndroid = Platform.isAndroid;

  int _wordIndex = 0;
  int _delta = 0;
  final int _speechType = 2;
  bool _tapingOnSearchBar = false;
  bool _typingInSearchBar = false;
  bool _canPop = false;
  List<String> _suggestions = []; //word search
  List _words = [];
  var _word = "";
  var _phonetic = "";
  var _explain = "";
  var _other = "";
  var _downloadMsg = "";
  bool _isDownloading = false;
  bool _apkCached = false;

  WordDetails? _wordDetails;
  Uint8List? _voice;
  int _tableIndex = 0;
  String _letters = "abcdefghijklmnopqrstuvwxyz";
  bool portalOpened = false;
  // MySQLConnection? connection;
  final TextEditingController _searchController = TextEditingController();
  ScrollController wordScrollController = ScrollController();
  bool isOverflowing = false;
  bool isEndScrolling = false;
  double textProportion = 15.6;

  bool _showAppbar = true;

  bool _isTheRoot = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ListenerRegisterHandler registerHandler = ListenerRegisterHandler();
  List<EventRegisterHandler> eventHandlerList = [];
  FocusNode backgroundFocus = FocusNode();

  ScrollController _longWordScrollController = ScrollController();
  ScrollController _longExplainScrollController = ScrollController();

  final Future<SharedPreferencesWithCache> _prefs =
      SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
              // This cache will only accept the key 'counter'.
              allowList: <String>{'wordIndex', 'tableIndex'}));

  get screenSize => MediaQuery.of(context).size;
  get screenWidth => screenSize.width;
  get screenHeight => screenSize.height;
  get minimumLength => screenWidth < screenHeight ? screenWidth : screenHeight;

  Future<void> _counterReset() async {
    _wordIndex = 0;
    setState(() {});
    final SharedPreferencesWithCache prefs = await _prefs;
    prefs.setInt('wordIndex', _wordIndex).then((_) {});
    prefs.setInt('tableIndex', _tableIndex).then((_) {});
  }

  Future<void> _counterMax() async {
    if (widget.wordList().isEmpty) {
      _wordIndex = _words.length - 1;
      setState(() {});
      final SharedPreferencesWithCache prefs = await _prefs;
      prefs.setInt('wordIndex', _wordIndex).then((_) {});
      prefs.setInt('tableIndex', _tableIndex).then((_) {});
    }
  }

  Future<void> _incrementCounter(int delta) async {
    _wordIndex = _wordIndex + delta;
    setState(() {});
    final SharedPreferencesWithCache prefs = await _prefs;
    if (_tableIndex == -1 || _tableIndex == 26) {
      return;
    }
    if (widget.wordList().isEmpty) {
      prefs.setInt('wordIndex', _wordIndex).then((_) {});
      prefs.setInt('tableIndex', _tableIndex).then((_) {});
    }
  }

  void pageDown() {
    if (_wordIndex > 0) {
      _incrementCounter(-1);
      refreshWord();
    } else {
      if (_tableIndex - 1 >= 0) {
        _tableIndex -= 1;
      } else {
        _tableIndex = 25;
      }
      refreshTable(() {
        _counterMax();
      });
    }
  }

  void pageUp() {
    if (_wordIndex < (_words.length - 1)) {
      _incrementCounter(1);
      refreshWord();
    } else {
      if (_tableIndex > 24) {
        _tableIndex = 0;
      } else {
        _tableIndex += 1;
      }

      refreshTable(() {
        _counterReset();
      });
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

  // 模拟联想词的生成
  void _updateSuggestions(String query) {
    setState(() {
      _typingInSearchBar = true;
      if (query.isEmpty) {
        _suggestions = [];
      } else {
        Future.delayed(Duration(milliseconds: 300), () {
          _typingInSearchBar = false;
        });
        // 这里可以替换为从你的数据源获取联想词的逻辑
        Future.delayed(Duration(milliseconds: 500), () {
          if (!_typingInSearchBar) {
            getCustomSearch(query).then((values) {
              setState(() {
                _suggestions = values!;
              });
            });
          }
        });
      }
    });
  }

  Widget ExamTypeText(String msg) {
    return Row(
      children: [
        Text(
          msg,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(
          width: 5,
        ),
      ],
    );
  }

  Widget ExamTypeIeltsText() {
    var wd = _wordDetails;
    if (wd != null) {
      if (wd.ielts ?? false) {
        return ExamTypeText("雅思");
      }
    }
    return const SizedBox();
  }

  Widget ExamTypeToeflText() {
    var wd = _wordDetails;
    if (wd != null) {
      if (wd.toefl ?? false) {
        return ExamTypeText("托福");
      }
    }
    return const SizedBox();
  }

  Widget ExamTypePostgraduateText() {
    var wd = _wordDetails;
    if (wd != null) {
      if (wd.postgraduate ?? false) {
        return ExamTypeText("考研");
      }
    }
    return const SizedBox();
  }

  Widget ExamTypeGREText() {
    var wd = _wordDetails;
    if (wd != null) {
      if (wd.gre ?? false) {
        return ExamTypeText("GRE");
      }
    }
    return const SizedBox();
  }

  Widget ExamTypeCET4Text() {
    var wd = _wordDetails;
    if (wd != null) {
      if (wd.cet4 ?? false) {
        return ExamTypeText("四级");
      }
    }
    return const SizedBox();
  }

  Widget ExamTypeCET6Text() {
    var wd = _wordDetails;
    if (wd != null) {
      if (wd.cet6 ?? false) {
        return ExamTypeText("六级");
      }
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    var autoColor = AutoColor(context);
    Color textColor = autoColor.textColor();
    try {
      if (!Platform.isAndroid) {
        isOverflowing = wordScrollController.position.maxScrollExtent > 0;
      }
    } catch (e) {}
    bool isLongWord = _word.contains(" ") || _word.length > 14;
    return Scaffold(
      key: _scaffoldKey,
      appBar: _showAppbar &&
              (MediaQuery.of(context).orientation == Orientation.portrait || (!_isAndroid))
          ? AppBar(
              iconTheme: IconThemeData(
                color: textColor, // 设置leading图标颜色
              ),
              toolbarHeight: screenHeight * 1 / 12,
              backgroundColor: autoColor.primaryColor(),
              title: Center(
                // 使用TextField作为搜索框
                child: Container(
                  // 设置搜索框的宽度
                  width: screenWidth * 1 / 1.7,
                  // 使用装饰器来给搜索框添加边框
                  decoration: BoxDecoration(
                    color: _tapingOnSearchBar
                        ? (widget.isDarkness ? Colors.black12 : Colors.white24)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  // 搜索框内的内容
                  child: PopScope(
                      canPop: _canPop,
                      onPopInvoked: (value) {
                        if (!_canPop) {
                          setState(() {
                            _canPop = Navigator.canPop(context);
                            _searchController.clear();
                            _suggestions = [];
                            _tapingOnSearchBar = false;
                            backgroundFocus.requestFocus();
                          });
                        }
                      },
                      child: TextField(
                        cursorColor: textColor,
                        style: TextStyle(
                          color: textColor,
                        ),
                        controller: _searchController,
                        onChanged: _updateSuggestions,
                        onTap: () {
                          setState(() {
                            _canPop = false;
                            _tapingOnSearchBar = true;
                          });
                        },
                        onTapOutside: (value) {
                          setState(() {
                            _canPop = Navigator.canPop(context);
                            _tapingOnSearchBar = false;
                          });
                        },
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return MyHomePage(
                                isDarkness: widget.isDarkness,
                                wordList: () {
                                  return [value];
                                },
                                startIndex: 0,
                              );
                            }));
                          }
                        },
                        decoration: InputDecoration(
                          hintStyle: TextStyle(
                            color: textColor,
                          ),
                          contentPadding: EdgeInsets.all(10),
                          // 设置搜索框的图标
                          prefixIcon: Icon(
                            Icons.search,
                            color: textColor,
                          ),
                          suffixIcon: _suggestions.isNotEmpty ||
                                  _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _canPop = Navigator.canPop(context);
                                      _searchController.clear();
                                      _suggestions = [];
                                      _tapingOnSearchBar = false;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    color: textColor,
                                  ))
                              : null,
                          // 设置搜索框的提示文字
                          hintText: '搜索',
                          // 移除搜索框的边框
                          border: InputBorder.none,
                        ),
                      )),
                ),
              ),
              // leading: _tapingOnSearchBar ? const SizedBox() : null,
              actions:
                  // _tapingOnSearchBar
                  //     ? []:
                  [
                // IconButton(
                //   icon: Icon(Icons.menu),
                //   onPressed: () {
                //     _scaffoldKey.currentState!.openDrawer();
                //     setState(() {});
                //   },
                // ),
                IconButton(
                  onPressed: () {
                    // randomWord();
                    if (_tableIndex - 1 >= 0) {
                      _tableIndex -= 1;
                    } else {
                      _tableIndex = 25;
                    }
                    refreshTable(() {
                      _counterReset();
                    });
                  },
                  icon: Icon(
                    Icons.keyboard_double_arrow_left,
                    color: textColor,
                  ),
                  iconSize: 30,
                ),
                IconButton(
                  onPressed: () {
                    if (_tableIndex > 24) {
                      _tableIndex = 0;
                    } else {
                      _tableIndex += 1;
                    }
                    refreshTable(() {
                      _counterReset();
                    });
                  },
                  icon: Icon(
                    Icons.keyboard_double_arrow_right,
                    color: textColor,
                  ),
                  iconSize: 30,
                ),
              ],
            )
          : null,
      drawer: Drawer(
        width: double.infinity,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                          setState(() {});
                        }
                      },
                      icon: Icon(Icons.arrow_back)),
                  Text('工具栏'),
                ],
              ),
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
            _isTheRoot
                ? Column(
                    children: [
                      Divider(),
                      ListTile(
                        title: Text('关于'),
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return AboutPage();
                          }));
                        },
                      )
                    ],
                  )
                : const SizedBox(),
            _isTheRoot
                ? Column(
                    children: [
                      Divider(),
                      ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('检查更新'),
                            Row(
                              children: [
                                Text(
                                  _downloadMsg,
                                  style: TextStyle(fontSize: 12),
                                ),
                                _isDownloading
                                    ? CircularProgressIndicator()
                                    : const SizedBox(),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          _isDownloading = !_isDownloading;
                          setState(() {
                            if (_isDownloading) {
                              _downloadMsg = "正在获取数据";
                              externalDir().then((dir) {
                                installApk(
                                  apkPath: dir.path,
                                  onDownloading: (String msg) {
                                    setState(() {
                                      _downloadMsg = msg;
                                    });
                                  },
                                  onLoading: (String msg) {
                                    setState(() {
                                      _downloadMsg = msg;
                                    });
                                  },
                                  onContrasting: (String msg) {
                                    setState(() {
                                      _downloadMsg = msg;
                                    });
                                  },
                                  onDone: (String msg) {
                                    setState(() {
                                      _downloadMsg = msg;
                                      _isDownloading = false;
                                    });
                                  },
                                  onError: (String msg) {
                                    setState(() {
                                      _downloadMsg = msg;
                                      _isDownloading = false;
                                    });
                                  },
                                  onCancel: () {
                                    if (!_isDownloading) {
                                      return true;
                                    }
                                    return false;
                                  },
                                  onDownloadCached: () {
                                    return _apkCached;
                                  },
                                  onDownloaded: () {
                                    _apkCached = true;
                                  },
                                );
                              });
                            } else {
                              _downloadMsg = "已取消 点击重试";
                            }
                          });
                        },
                      )
                    ],
                  )
                : const SizedBox(),
          ],
        ),
      ),
      body: _suggestions.isEmpty
          ? Stack(
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
                  mainAxisAlignment: isLongWord
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(
                      height: 1,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isLongWord
                            ? const SizedBox()
                            : Padding(
                                padding: EdgeInsets.only(left: 0, bottom: 40),
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      speechWord(_speechType);
                                    },
                                    child: Text(
                                      '$_word',
                                      style: TextStyle(
                                          color: textColor,
                                          fontSize:
                                              Platform.isAndroid ? 32 : 35),
                                    ),
                                  ),
                                ),
                              ),
                        isLongWord
                            ? Padding(
                                padding: EdgeInsets.only(
                                    top: _showAppbar ? 50 : 120,
                                    left: 24,
                                    right: 30,
                                    bottom: _showAppbar ? 0 : 100),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      controller: _longWordScrollController
                                        ..addListener(() {
                                          setState(() {
                                            _longExplainScrollController
                                                .position
                                                .moveTo(
                                                    _longWordScrollController
                                                        .offset);
                                          });
                                        }),
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            left: 30, right: 30),
                                        child: MarkdownBody(
                                          selectable: true,
                                          onSelectionChanged:
                                              (text, selection, cause) {
                                            if (text != _word) {
                                              Navigator.push(context,
                                                  MaterialPageRoute(
                                                      builder: (context) {
                                                return MyHomePage(
                                                  isDarkness: widget.isDarkness,
                                                  wordList: () {
                                                    return [text];
                                                  },
                                                  startIndex: 0,
                                                );
                                              }));
                                            }
                                          },
                                          data: _word.contains("#")
                                              ? _word
                                              : "## " + _word,
                                        ),
                                      ),
                                    ),
                                  ),
                                  height: _showAppbar
                                      ? 300
                                      : screenHeight * 1 / 1.29,
                                ),
                              )
                            : const SizedBox(),
                        isLongWord && !_showAppbar
                            ? const IgnorePointer(
                                child: SizedBox(
                                  height: 100,
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
                            padding: EdgeInsets.only(left: 40, right: 40),
                            child: Center(
                              child: Text(
                                _phonetic,
                                style: TextStyle(
                                  color: textColor,
                                ),
                              ),
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
                          ignoring: !isLongWord,
                          child: SingleChildScrollView(
                              controller: _longExplainScrollController,
                              child: Container(
                                // height: isLongWord ? screenHeight - 420 : null,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 30, right: 30),
                                  child: Center(
                                    child: Text(
                                      '$_explain',
                                      style: TextStyle(
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                        ),
                      ],
                    ),
                    isLongWord
                        ? const IgnorePointer(
                            child: SizedBox(
                              height: 20,
                            ),
                          )
                        : const SizedBox(),
                    IgnorePointer(
                      child: Padding(
                          padding: EdgeInsets.only(left: 30, right: 30),
                          child: Center(
                            child: Text(
                              style: TextStyle(
                                color: textColor,
                              ),
                              '$_other',
                            ),
                          )),
                    ),
                    !isLongWord
                        ? IgnorePointer(
                            child: Padding(
                              padding: EdgeInsets.only(left: 30, right: 30),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ExamTypeIeltsText(),
                                  ExamTypeToeflText(),
                                  ExamTypePostgraduateText(),
                                  ExamTypeGREText(),
                                  ExamTypeCET4Text(),
                                  ExamTypeCET6Text(),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox(),
                    IgnorePointer(
                      child: Padding(
                          padding: EdgeInsets.only(left: 30, right: 30),
                          child: Center(
                            child: Text(
                              _wordDetails?.synonym ?? '',
                              style: TextStyle(
                                color: textColor,
                              ),
                            ),
                          )),
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                  ],
                ), // This trailing comma makes auto-formatting nicer for build methods.
                Positioned(
                  top: _showAppbar &&
                          MediaQuery.of(context).orientation ==
                              Orientation.portrait
                      ? 0
                      : null,
                  right: _showAppbar &&
                          MediaQuery.of(context).orientation ==
                              Orientation.portrait
                      ? 0
                      : null,
                  left: _showAppbar &&
                          MediaQuery.of(context).orientation ==
                              Orientation.portrait
                      ? null
                      : 20,
                  bottom: _showAppbar &&
                          MediaQuery.of(context).orientation ==
                              Orientation.portrait
                      ? null
                      : 20,
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
                            color: textColor,
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
                        icon: Icon(Icons.star_border,
                            size: 26,
                            color: Colors.amber.withOpacity(
                                autoColor.getIsDarkness() ? 0.6 : 1.0)),
                      ),
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
                // Positioned(
                //   bottom: 20,
                //   left: 1,
                //   right: 1,
                //   child: !isLongWord
                //       ? Padding(
                //           padding: EdgeInsets.only(left: 30, right: 30),
                //           child: Row(
                //             mainAxisAlignment: MainAxisAlignment.center,
                //             children: [
                //               ExamTypeText(
                //                   (_wordDetails!.ielts) ?? false ? "雅思" : ""),
                //               ExamTypeText(
                //                   (_wordDetails!.toefl) ?? false ? "托福" : ""),
                //               ExamTypeText((_wordDetails!.postgraduate) ?? false
                //                   ? "考研"
                //                   : ""),
                //               ExamTypeText(
                //                   (_wordDetails!.gre) ?? false ? "GRE" : ""),
                //               ExamTypeText(
                //                   (_wordDetails!.cet4) ?? false ? "四级" : ""),
                //               ExamTypeText(
                //                   (_wordDetails!.cet6) ?? false ? "六级" : ""),
                //             ],
                //           ),
                //         )
                //       : const SizedBox(),
                // ),

                Positioned(
                    bottom: 10,
                    right: 10,
                    child: IconButton(
                      icon: Icon(
                        Icons.circle_outlined,
                        color: widget.isDarkness && !_showAppbar
                            ? const Color.fromARGB(255, 95, 94, 94)
                            : null,
                      ),
                      onPressed: () {
                        setState(() {
                          _showAppbar = !_showAppbar;
                        });
                      },
                    )),

                !_isTheRoot
                    ? Positioned(
                        // top: -50,
                        top: !_showAppbar &&
                                MediaQuery.of(context).orientation ==
                                    Orientation.portrait
                            ? 40
                            : null,
                        child: ClickableQuarterCircle()
                          ..background = (widget.isDarkness
                              ? Colors.red.withOpacity(_showAppbar ? 1 : 0.4)
                              : const Color.fromARGB(255, 239, 154, 154)
                                  .withOpacity(_showAppbar ? 1 : 0.4))!
                          ..onClick = () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          })
                    : const SizedBox(),
              ],
            )
          : ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _suggestions[index],
                    style: TextStyle(
                      color: textColor,
                    ),
                  ),
                  onTap: () {
                    // 处理搜索联想词的点击事件
                    _searchController.text = _suggestions[index];
                    if (_searchController.text.isNotEmpty) {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return MyHomePage(
                          isDarkness: widget.isDarkness,
                          wordList: () {
                            return [_searchController.text];
                          },
                          startIndex: 0,
                        );
                      }));
                    }
                    // 可以在这里添加跳转到搜索结果页面的逻辑
                  },
                );
              },
            ),
    );
  }

  Future<void> updateData() async {
    print("尝试注入单词 $_word");
    submitOthers(_word, _other);
  }

  Future<void> randomWord() async {
    _wordIndex = Random().nextInt(widget.words.length);
    refreshWord();
    final SharedPreferencesWithCache prefs = await _prefs;
    prefs.setInt('wordIndex', _wordIndex).then((_) {});
    prefs.setInt('tableIndex', _tableIndex).then((_) {});
  }

  @override
  void dispose() {
    // Release all sources and dispose the player.
    player?.dispose();
    backgroundFocus.unfocus();
    backgroundFocus.dispose();
    super.dispose();
  }

  Future<List<String>> explainWord(String word) async {
    List<String> ready = [];
    if (word != "") {
      _wordDetails = await getWordDetails(word);
      ready = await englishSearch(word);
    }
    if (ready.isEmpty) {
      ready = [await translateLanguage(word)];
    }
    setState(() {});
    return ready;
  }

  // Future<void> connectSQL() async {
  //   print("尝试连接");
  //   connection = await client.connect();
  //   print(connection);
  //   // widget.words = await getWords(connection);
  //   // refreshWord();
  // }
  void refreshTable(void Function() d) {
    getWords(_letters[_tableIndex]).then((words) {
      _words = words;
      d();
      refreshWord();
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _prefs.then((SharedPreferencesWithCache prefs) {
      _wordIndex = widget.wordList().isEmpty
          ? prefs.getInt('wordIndex') ?? 0
          : widget.startIndex;
    });
    _prefs.then((SharedPreferencesWithCache prefs) {
      _tableIndex = prefs.getInt('tableIndex') ?? 0;
      refreshTable(() {});
    });
    // widget.words = widget.wordList();
    // print(widget.words);
    // connectSQL();

    // if (Platform.isAndroid) {
    //   wordScrollController.addListener(() {
    //     isEndScrolling = wordScrollController.offset >=
    //         wordScrollController.position.maxScrollExtent;
    //     if (!isEndScrolling) {
    //       isOverflowing = true;
    //     }
    //     setState(() {});
    //     print(isEndScrolling);
    //   });
    // }
    // refreshWord();
    // Create the audio player.
    _isTheRoot = !Navigator.canPop(context);
    // Set the release mode to keep the source after playback has completed.
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

    player?.setReleaseMode(ReleaseMode.stop);
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
      if (_delta.abs() > screenWidth / 6.7) {
        if (_delta < 0) {
          print("page -");
          pageDown();
        } else {
          print("page +");
          pageUp();
        }
      } else if (_delta.abs() <= 0.22) {
        if (event.position.dx > (screenWidth - (screenWidth / 3))) {
          pageUp();
        } else if (event.position.dx <= screenWidth / 3) {
          pageDown();
        } else if (event.position.dy < screenHeight / 2) {
          _scaffoldKey.currentState!.openDrawer();
        } else {
          speechWord(_speechType);
        }
      }

      _delta = 0;
    });
    setState(() {});
  }

  String pickWord(int index) {
    List wl = widget.wordList();
    if (wl.isEmpty) {
      return _words[index];
    }
    if (wl.isNotEmpty) {
      if (_wordIndex >= wl.length) {
        index = 0;
        _wordIndex = 0;
      }
      if (_wordIndex < 0) {
        index = wl.length - 1;
        _wordIndex = wl.length - 1;
      }
    }

    saveNewWord(wl[index]);
    return wl[index];
  }

  Future<void> voiceManage() async {
    if (_wordDetails != null && _wordDetails?.voice != null) {
      _voice = _wordDetails?.voice;
    }
    if (_voice == null) {
      await getSpeechBytes(_word).then((onValue) {
        _voice = onValue;
      });
    }
    player ??= AudioPlayer();
    player?.setReleaseMode(ReleaseMode.release);
    player?.setSource(BytesSource(_voice!));

    var currentPos = await player?.getCurrentPosition();
    var dPos = await player?.getDuration();
    if (currentPos == dPos) {
      player?.resume();
    } else if (currentPos == Duration.zero) {
      player?.play(BytesSource(_voice!));
    }
  }

  void refreshWord() {
    print("需要刷新当前单词的时间 => ${DateTime.now()}");
    _voice = null;
    _word = pickWord(_wordIndex);

    getEnglishWordPhonetic(_word).then((onValue) {
      _phonetic = onValue;
      setState(() {});
    });
    _explain = "";
    _other = "";
    setState(() {});
    explainWord(_word).then((value) {
      print("搜索结果 => $value");
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

    setState(() {});
  }

  Future<void> speechWord(int type) async {
    if (type < 1) {
      type = 1;
    }
    if (type > 2) {
      type = 2;
    }
    voiceManage();

    // await player.setSource(
    //     UrlSource("https://dict.youdao.com/dictvoice?audio=$_word&type=$type"));
    // await player.resume();
  }
}
