import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:dio/dio.dart';
import 'package:english_book/path.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart'; // 添加此行

import 'channels.dart';

enum AppType {
  apk,
  exe
}

class Apk {
  Uint8List content;
  String name;
  String version;
  Apk(this.content, this.name, this.version);
}

class Exe {
  Uint8List content;
  String name;
  String version;
  Exe(this.content, this.name, this.version);
}



Future<Map> getNewestAppMap(AppType appType) async {
  final dio = Dio();
  final response = await dio.post("http://47.108.91.180:5000/${appType.name}");
  var data = response.data;
  return data;
}

Future<String> getLatestAppVersion(String currentVersion, AppType appType) async {
  final dio = Dio();
  final response =
      await dio.post("http://47.108.91.180:5000/${appType.name}_latest_version");
  var data = response.data['version'];
  if (data.runtimeType == String && data != "No versions found.") {
    return data;
  }
  return currentVersion;
}

Future<Apk> getNewApk() async {
  Map data = await getNewestAppMap(AppType.apk);
  print(data);
  String name = data['name'];
  String version = data['version'];
  Uint8List content = base64Decode(data['content']);
  Apk apk = Apk(content, name, version);
  return apk;
}

Future<Exe> getNewExe() async {
  Map data = await getNewestAppMap(AppType.exe);
  print(data);
  String name = data['name'];
  String version = data['version'];
  Uint8List content = base64Decode(data['content']);
  Exe exe = Exe(content, name, version);
  return exe;
}

void runExe(String exePath) {
  // 请确保替换下面的路径为你的exe文件的实际路径
  print(exePath);
  final process = Process.start(exePath, []);

  process.then((Process proc) {
    // 可以监听输出流
    proc.stdout.transform(utf8.decoder).listen((data) {
      print(data);
    });

    // 监听错误流
    proc.stderr.transform(utf8.decoder).listen((data) {
      print(data);
    });
  }).catchError((e) {
    print('Error: $e');
  });
}


Future<void> installApk({
  required String apkPath,
  required bool Function() onCancel,
  required bool Function() onDownloadCached,
  required void Function() onDownloaded,
  required void Function(String msg) onDownloading,
  required void Function(String msg) onLoading,
  required void Function(String msg) onContrasting,
  required void Function(String msg) onDone,
  required void Function(String msg) onError,
}) async {
  try {
    print("准备安装在 => $apkPath");

    String filepath = '';

    if (Platform.isAndroid){
      filepath = "$apkPath/base.apk";
    }
    if (Platform.isWindows){
      filepath = "$apkPath/install.exe";
    }

    if (!onDownloadCached()) {
      onContrasting("准备对比版本");
      await Future.delayed(Duration(milliseconds: 800));
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      String latestApkVersion = currentVersion;
      switch (Platform.operatingSystem) {
        case "android":
          latestApkVersion = await getLatestAppVersion(currentVersion, AppType.apk);
          break;
        case "windows":
          latestApkVersion = await getLatestAppVersion(currentVersion, AppType.exe);
          break;
      }
      if (latestApkVersion.compareTo(currentVersion) > 0) {
        if (onCancel()) {
          return;
        }
        onDownloading("开始下载 点击取消");
        if (Platform.isAndroid){
          Apk apkInstance = await getNewApk();

          File apkWriter = File(filepath);
          await apkWriter.writeAsBytes(apkInstance.content);
        }
        if (Platform.isWindows){
          Exe exeInstance = await getNewExe();

          File exeWriter = File(filepath);
          await exeWriter.writeAsBytes(exeInstance.content);
        }

        onDownloaded();
        if (onCancel()) {
          if (onDownloadCached()) {
            onDone("安装包已下载，点击安装");
          }
          return;
        }
      } else {
        onDone("已经是最新版");
        return;
      }
    }
    onLoading("数据校验");
    await Future.delayed(Duration(milliseconds: 800));
    // 获取临时文件目录

    if (Platform.isAndroid) {
      // 使用FileProvider获取安全URI
      String fileUri = await FileProviderUtil.getFileUri(filepath);
      AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: fileUri,
        type: 'application/vnd.android.package-archive',
        flags: <int>[
          Flag.FLAG_ACTIVITY_NEW_TASK,
          Flag.FLAG_GRANT_READ_URI_PERMISSION
        ],
      );

      onDone("准备安装");
      await intent.launch();
    }

    if (Platform.isWindows){
      runExe(filepath);
      onDone("启动安装包");
    }


  } catch (e) {
    onError(e.runtimeType.toString());
    throw e;
  }
}
