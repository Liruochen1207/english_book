import 'package:audioplayers/audioplayers.dart';
import 'package:english_book/card/interface_controlableWidget.dart';
import 'package:english_book/card/template_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/services.dart';

import '../theme/color.dart';

class LetterCard extends StatefulWidget {
  late String letter;
  late double width;
  late List<void Function()> refresh = [];

  LetterCard(
      {super.key,
      required this.letter,
      required this.width});

  void change(String newLetter) {
    letter = newLetter;
    for (var i = 0; i < refresh.length; i++) {
      refresh[i].call();
    }
  }

  @override
  _LetterCardState createState() => _LetterCardState();
}

class _LetterCardState extends State<LetterCard> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.refresh.add(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var autoColor = AutoColor(context);
    // TODO: implement build
    double letterWidth = widget.width;
    return Padding(
      padding: EdgeInsets.all(letterWidth / 10),
      child: Container(
        width: letterWidth,
        height: letterWidth,
        color: autoColor.backgroundColor(),
        child: Text(
          widget.letter,
          style: TextStyle(fontSize: letterWidth / 1.5),
        ),
      ),
    );
  }
}

class Exam extends StatefulWidget {
  late String word;
  late Uint8List? voice;
  Exam(
      {super.key,
      required this.word,
      required this.voice});

  @override
  _ExamState createState() => _ExamState();
}

class _ExamState extends State<Exam> {
  get screenSize => MediaQuery.of(context).size;
  get screenWidth => screenSize.width;
  get screenHeight => screenSize.height;
  int listPointer = 0;
  int length = 0;
  double letterWidth = 10;
  List<Widget> letterList = [];

  bool lettersInited = false;
  bool isShowingKeyBoard = false;

  DateTime lastInputTime = DateTime.now();

  late AudioPlayer player = AudioPlayer();
  ListenerRegisterHandler registerHandler = ListenerRegisterHandler();
  List<EventRegisterHandler> eventHandlerList = [];
  FocusNode backgroundFocus = FocusNode();

  // Widget letterBuilder(String letter, double letterWidth) {
  //   return Padding(
  //     padding: EdgeInsets.all(letterWidth / 10),
  //     child: Container(
  //       width: letterWidth,
  //       height: letterWidth,
  //       color: widget.isDarkness
  //           ? Color.fromARGB(173, 105, 43, 116)
  //           : Color.fromARGB(121, 235, 219, 99),
  //       child: Text(
  //         letter,
  //         style: TextStyle(fontSize: letterWidth / 1.5),
  //       ),
  //     ),
  //   );
  // }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    // print("didChangeDependencies");
    FocusScope.of(context).requestFocus(backgroundFocus);
    if (!lettersInited) {
      length = widget.word.length;
      letterWidth = screenWidth / length;
      letterWidth /= 1.4;
      letterList = [];
      for (int i = 0; i < length; i++) {
        letterList.add(LetterCard(
          letter: "",
          width: letterWidth,
        ));
      }
      setState(() {});
      lettersInited = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // player = AudioPlayer();
    player.setReleaseMode(ReleaseMode.stop);
    var inputHandler = EventRegisterHandler();
    inputHandler.setOnlyKeyDownAlive();
    inputHandler.setHandler(() {
      // if (inputHandler.lastKey!.keyLabel == widget.word[listPointer]) {
      //   (letterList[listPointer] as LetterCard)
      //       .change(widget.word[listPointer]);
      //   listPointer += 1;
      // }

      var now = DateTime.now();

      bool canInput = true ||
          now.difference(lastInputTime).compareTo(Duration(milliseconds: 10)) ==
              1;
      lastInputTime = now;
      if ((letterList.last as LetterCard).letter == '✓' ||
          (letterList.last as LetterCard).letter == '✗') {
        cleanUp();
      }
      switch (inputHandler.lastKey?.keyLabel) {
        case "Escape":
          Navigator.pop(context, null);
          break;
        case "Enter":
          confirm();
          break;
        case "Shift Left":
        case "Shift Right":
          break;
        default:
          bool isCapital = inputHandler.isShiftPressed;
          String keyLabel = inputHandler.lastKey!.keyLabel;

          if (!isCapital) {
            keyLabel = keyLabel.toLowerCase();
          }
          if (keyLabel == "backspace") {
            if (listPointer - 1 >= 0 && canInput) {
              (letterList[listPointer - 1] as LetterCard).change('');
              listPointer -= 1;
            }
            break;
          }

          print(keyLabel);
          print(listPointer);
          if (listPointer + 1 <= length && canInput) {
            (letterList[listPointer] as LetterCard).change(keyLabel);
            listPointer += 1;
          }

          break;
      }
    });

    eventHandlerList.add(inputHandler);

    registerHandler.addListener(
        ListenerType.onPointerDown, ListenerAction.leftButton, (PointerEvent) {
      SystemChannels.textInput.invokeListMethod('TextInput.show');
      FocusScope.of(context).requestFocus(backgroundFocus);

      // if (isShowingKeyBoard) {
      //   SystemChannels.textInput.invokeListMethod('TextInput.hide');
      // } else {
      //   SystemChannels.textInput.invokeListMethod('TextInput.show');
      //   FocusScope.of(context).requestFocus(backgroundFocus);
      // }
      // isShowingKeyBoard = !isShowingKeyBoard;
    });
  }

  void doPlaying() {
    var voice = widget.voice;
    if (voice != null && voice.isNotEmpty) {
      player = AudioPlayer();
      player.setReleaseMode(ReleaseMode.stop);
      player.setSource(BytesSource(voice));
      player.resume();
    }
  }

  void cleanUp() {
    for (int i = 0; i < length; i++) {
      (letterList[i] as LetterCard).change('');
      listPointer = 0;
    }
  }

  void doRight() {
    for (int i = 0; i < length; i++) {
      (letterList[i] as LetterCard).change('✓');
      listPointer = 0;
    }
  }

  void doWrong() {
    doPlaying();
    for (int i = 0; i < length; i++) {
      (letterList[i] as LetterCard).change('✗');
      listPointer = 0;
    }
  }

  void confirm() {
    var cw = '';
    for (int i = 0; i < length; i++) {
      cw += (letterList[i] as LetterCard).letter;
    }
    print("检查 => $cw");
    if (cw == widget.word) {
      print("正确!");
      doRight();
      Future.delayed(Duration(milliseconds: 610)).then((value) {
        Navigator.pop(context, {'result': 'exam'});
      });
    } else {
      doWrong();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    player.dispose();
    SystemChannels.textInput.invokeListMethod('TextInput.hide');
    listPointer = 0;
    letterList = [];
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    var autoColor = AutoColor(context);
    Text label(String data){
      return Text(data, style: TextStyle(color: autoColor.labelColor()),);
    }

    // FocusScope.of(context).requestFocus(backgroundFocus);
    return Scaffold(
      appBar: AppBar(
        title: Text('背诵'),
      ),
      body: TemplateCard(
        focusNode: backgroundFocus,
        listenerRegister: registerHandler,
        eventHandlerList: eventHandlerList,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: letterList,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  cupertino.CupertinoButton(
                      onPressed: () {
                        cleanUp();
                      },
                      child: label('清空')),
                  cupertino.CupertinoButton(
                      onPressed: () {
                        confirm();
                      },
                      child: label('提交')),
                  cupertino.CupertinoButton(
                      onPressed: () {
                        doPlaying();
                      },
                      child: label('发音')),
                  IconButton(
                      onPressed: () {
                        if (listPointer - 1 >= 0) {
                          (letterList[listPointer - 1] as LetterCard)
                              .change('');
                          listPointer -= 1;
                        }
                      },
                      icon: Icon(Icons.backspace, color: autoColor.labelColor(),)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
