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

class Apk {
  Uint8List content;
  String name;
  String version;
  Apk(this.content, this.name, this.version);
}

Future<Map> getNewestApk64() async {
  final dio = Dio();
  final response = await dio.post("http://47.108.91.180:5000/apk");
  var data = response.data;
  return data;
}

Future<String> getLatestApkVersion(String currentVersion) async {
  final dio = Dio();
  final response =
      await dio.post("http://47.108.91.180:5000/apk_latest_version");
  var data = response.data['version'];
  if (data.runtimeType == String) {
    return data;
  }
  return currentVersion;
}

Future<Apk> getNewApk() async {
  Map data = await getNewestApk64();
  print(data);
  String name = data['name'];
  String version = data['version'];
  Uint8List content = base64Decode(data['content']);
  Apk apk = Apk(content, name, version);
  return apk;
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
    String filepath = '$apkPath/base.apk';

    if (!onDownloadCached()) {
      onContrasting("准备对比版本");
      await Future.delayed(Duration(milliseconds: 800));
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      String latestApkVersion = await getLatestApkVersion(currentVersion);
      if (latestApkVersion.compareTo(currentVersion) > 0) {
        if (onCancel()) {
          return;
        }
        onDownloading("开始下载 点击取消");
        Apk apkInstance = await getNewApk();

        File apkWriter = File(filepath);
        await apkWriter.writeAsBytes(apkInstance.content);

        onDownloaded();
        if (onCancel()) {
          if (onDownloadCached()) {
            onDone("安装包已下载，点击安装");
          }
          return;
        }
      } else {
        onDone("已经是最新版");
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
  } catch (e) {
    onError(e.runtimeType.toString());
    throw e;
  }
}
