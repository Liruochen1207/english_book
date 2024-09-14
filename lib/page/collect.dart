import 'dart:convert';

import 'package:english_book/page/playing.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'listen.dart';

class CollectPage extends StatefulWidget {
  const CollectPage({super.key});

  @override
  State<CollectPage> createState() => _CollectPageState();
}

class _CollectPageState extends State<CollectPage> {
  List<Widget> _sectionCardList = [];
  final Future<SharedPreferencesWithCache> _group_prefs =
      SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
              // This cache will only accept the key 'counter'.
              allowList: <String>{'listenningGroup'}));

  List<String> _listenCardList = [];

  Future<void> getListeningList() async {
    await _group_prefs.then((SharedPreferencesWithCache prefs) {
      _listenCardList = prefs.getStringList("listenningGroup") ?? [];
      print(_listenCardList);
      for (var i = 0; i < _listenCardList.length; i++) {
        print("DEE => ${TitleTransformer.decode(_listenCardList[i])}");
        Map<String, dynamic> de = TitleTransformer.decode(_listenCardList[i]);
        print("DEE $de");
        print("First ${de.keys.first}");
        print("Second ${de.values.first}");
        String tit = de.keys.first;
        List<dynamic> li = de.values.first;
        _sectionCardList.add(SectionCard(
          fatherWidgetState: this,
          title: tit,
          li: li,
        ));
        setState(() {});
      }
    });
  }

  Future<void> commitListeningList() async {

  }

  @override
  void initState() {
    super.initState();
    getListeningList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("点击一个存入"),),
      body: SingleChildScrollView(
        child: Column(
          verticalDirection: VerticalDirection.up,
          children: _sectionCardList,
        ),
      ),
    );
  }
}

class SectionCard extends StatefulWidget {
  final String title;
  final List<dynamic> li;
  dynamic fatherWidgetState;

  SectionCard({super.key, required this.title, required this.li, required this.fatherWidgetState});

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: (){
          // widget.fatherWidgetState.
        },
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            widget.title,
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}
