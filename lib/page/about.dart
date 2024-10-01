import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

final Uri _power_url = Uri.parse('https://flutter.dev');
final Uri _bili_url = Uri.parse('https://space.bilibili.com/178065252');

class AboutPage extends StatefulWidget {
  static String version = "";
  @override
  State<StatefulWidget> createState() {
    return _AboutPageState();
  }
}

class _AboutPageState extends State<AboutPage> {
  Future<void> _openBili() async {
    if (!await launchUrl(_bili_url)) {
      throw Exception('Could not launch $_bili_url');
    }
  }

  Future<void> _openPower() async {
    if (!await launchUrl(_power_url)) {
      throw Exception('Could not launch $_power_url');
    }
  }

  Future<void> _initPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      AboutPage.version = packageInfo.version;
    });
  }

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('关于作者'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            GestureDetector(
              child: Column(
                children: [
                  CircleAvatar(
                    radius:
                        160.0, // You can adjust the radius to fit your needs
                    backgroundImage: AssetImage(
                        'lib/images/pika.jpg'), // Replace with your image path
                    // backgroundColor: Colors.transparent,
                  ),
                  SizedBox(
                      height:
                          20.0), // Adds some space between the image and text
                  Text(
                    'Archer Lee',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              onTap: () {
                _openBili();
              },
            ),

            SizedBox(
                height:
                    10.0), // Adds some space between the title and description
            Text(
              'Version: ${AboutPage.version}',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.0),
            GestureDetector(
              child: Text(
                'Powered by Flutter',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 24.0,
                ),
              ),
              onTap: () {
                _openPower();
              },
            )
          ],
        ),
      ),
    );
  }
}
