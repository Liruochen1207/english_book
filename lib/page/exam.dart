import 'package:english_book/card/interface_controlableWidget.dart';
import 'package:english_book/card/template_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Exam extends StatefulWidget {
  late String word;
  Exam({super.key, required this.word});

  @override
  _ExamState createState() => _ExamState();
}

class _ExamState extends State<Exam> {
  get screenSize => MediaQuery.of(context).size;
  get screenWidth => screenSize.width;
  get screenHeight => screenSize.height;

  int length = 0;
  double letterWidth = 10;
  List<Widget> letterList = [];

  ListenerRegisterHandler registerHandler = ListenerRegisterHandler();
  List<EventRegisterHandler> eventHandlerList = [];
  FocusNode backgroundFocus = FocusNode();

  Widget letterBuilder(String letter, double letterWidth) {
    return Padding(
      padding: EdgeInsets.all(letterWidth / 10),
      child: Container(
        width: letterWidth,
        height: letterWidth,
        color: Color.fromARGB(141, 158, 158, 158),
        child: Text(
          letter,
          style: TextStyle(fontSize: letterWidth / 1.5),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    var inputHandler = EventRegisterHandler()
      ..setAnyKeyCanTrigger(true)
      ..setOnlyKeyUpAlive();
    inputHandler.setHandler(() {
      print(inputHandler.lastKey);
    });
    eventHandlerList.add(inputHandler);
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(backgroundFocus);
    length = widget.word.length;
    letterWidth = screenWidth / length;
    letterWidth /= 1.4;
    letterList = [];
    for (int i = 0; i < length; i++) {
      letterList.add(letterBuilder(widget.word[i], letterWidth));
    }
    setState(() {});
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
            children: [
              Row(
                children: letterList,
              )
            ],
          ),
        ),
      ),
    );
  }
}
