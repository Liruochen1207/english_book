import 'package:flutter/material.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    length = widget.word.length;
    letterWidth = screenWidth / length / 1.2;
    for (int i = 0; i < length; i++) {
      letterList.add(letterBuilder(widget.word[i], letterWidth));
    }
    setState(() {});
    return Scaffold(
      appBar: AppBar(
        title: Text('背诵'),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              children: letterList,
            )
          ],
        ),
      ),
    );
  }
}
