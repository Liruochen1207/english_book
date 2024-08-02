import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

void main() async {
  // 发送HTTP GET请求获取音频数据
  String audioUrl = "https://dict.youdao.com/dictvoice?audio=gesture&type=2";
  Response response = await Dio().get(audioUrl);

  // 获取响应的内容
  List<int> responseBodyBytes = response.data as List<int>;

  // 将音频数据进行Base64编码
  String base64AudioData = base64Encode(responseBodyBytes);

  // 解码Base64编码的音频数据
  List<int> decodedAudioBytes = base64Decode(base64AudioData);

  // 将解码后的音频数据写入文件
  File audioFile = File("audio.mp3");
  await audioFile.writeAsBytes(decodedAudioBytes);
  print("音频文件已保存为 audio.mp3");
}
