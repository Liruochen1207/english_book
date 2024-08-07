import 'package:english_book/page/playing.dart';
import 'package:flutter/material.dart';

class ListenningCard extends StatefulWidget {
  ListenningCard({super.key, required this.fatherWidgetState}) {
    title = DateTime.now().toString();
  }
  String title = "";
  var fatherWidgetState;

  @override
  _ListenningCardState createState() => _ListenningCardState();
}

class _ListenningCardState extends State<ListenningCard> {
  bool _isShowingPanel = false;

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
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return Playing(
                    title: widget.title,
                  );
                }));
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
                          color: Colors.amber,
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

  void addLisCard() {
    _listenningGroup.add(ListenningCard(
      fatherWidgetState: this,
    ));
  }

  void delCard(ListenningCard deletingCard) {
    _listenningGroup.remove(deletingCard);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("创建听写任务组"),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  addLisCard();
                });
              },
              icon: Icon(Icons.add))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          verticalDirection: VerticalDirection.up,
          children: _listenningGroup,
        ),
      ),
    );
  }
}
