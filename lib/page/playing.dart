import 'package:flutter/material.dart';

class WordCard extends StatelessWidget {
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
                    "Test",
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
  Playing({super.key, required this.title});
  String title;
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _PlayingState();
  }
}

class _PlayingState extends State<Playing> {
  bool isDisable = false;
  List<Widget> _scollingList = [];
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
                  _scollingList.add(WordCard());
                });
              },
              icon: Icon(Icons.add))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _scollingList,
              ),
            ),
          ),
          Container(
            height: 40,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }
}
