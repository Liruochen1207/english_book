import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as cup;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordCard extends StatelessWidget {
  String word;

  WordCard({super.key, required this.word});
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Color.fromARGB(255, 238, 237, 237),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    word,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  )
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

  @override
  void initState() {
    super.initState();
    Set<String> allowList = <String>{widget.title};
  }

  void submitWord() {
    setState(() {
      _scollingList.add(WordCard(
        word: inputing,
      ));
      inputing = "";
      controller.text = "";
    });
  }

  Widget dialogManager(Widget child) {
    return _showDialog ? child : const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                color: Color.fromARGB(255, 232, 220, 90),
                child: Text("添加"),
              ),
            ),
          )),
          dialogManager(Divider()),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _scollingList,
              ),
            ),
          ),
          Container(
            height: 70,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }
}
