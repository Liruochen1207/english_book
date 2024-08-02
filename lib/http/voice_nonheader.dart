// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:dio/dio.dart';
// import 'package:dio_cookie_manager/dio_cookie_manager.dart';
// import 'package:cookie_jar/cookie_jar.dart';
//
// class CustomCookie implements Cookie {
//   @override
//   String? domain;
//
//   @override
//   DateTime? expires;
//
//   @override
//   late bool httpOnly;
//
//   @override
//   int? maxAge;
//
//   @override
//   late String name;
//
//   @override
//   String? path;
//
//   @override
//   SameSite? sameSite;
//
//   @override
//   late bool secure;
//
//   @override
//   late String value;
//   CustomCookie(this.name, this.value, {this.domain, this.path, this.secure = false, this.httpOnly = false, this.sameSite, this.maxAge});
// }
//
// class Voice {
//   String? text;
//
//   Dio dio = Dio();
//   final cookieJar = CookieJar();
//   Map<String, String> headers = {
//     'Accept': '*/*',
//     'Accept-Encoding': 'identity;q=1, *;q=0',
//     'Accept-Language': 'zh-CN,zh;q=0.9',
//     'Cache-Control': 'no-cache',
//     'Connection': 'keep-alive',
//     'Cookie': 'OUTFOX_SEARCH_USER_ID=-1191369336@10.108.162.133; OUTFOX_SEARCH_USER_ID_NCOO=130331002.2899831; __yadk_uid=YQHg3ylnZXYJdjxO7QYDKy3Ge6QNvY2y',
//     'Host': 'dict.youdao.com',
//     'Pragma': 'no-cache',
//     'Range': 'bytes=0-',
//     'Referer': 'https://smartisandict.youdao.com/',
//     'Sec-Ch-Ua': '"Chromium";v="124", "Google Chrome";v="124", "Not-A.Brand";v="99"',
//     'Sec-Ch-Ua-Mobile': '?0',
//     'Sec-Ch-Ua-Platform': '"Windows"',
//     'Sec-Fetch-Dest': 'audio',
//     'Sec-Fetch-Mode': 'no-cors',
//     'Sec-Fetch-Site': 'same-site',
//     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1722.39',
//   };
//
//   Voice () {
//     cookieJar.saveFromResponse(Uri.parse("https://dict.youdao.com/dictvoice"), [
//       CustomCookie('OUTFOX_SEARCH_USER_ID', '-1191369336@10.108.162.133', domain: '.youdao.com', ),
//       CustomCookie('OUTFOX_SEARCH_USER_ID_NCOO', '130331002.2899831', domain:  '.youdao.com',),
//       CustomCookie('__yadk_uid', 'YQHg3ylnZXYJdjxO7QYDKy3Ge6QNvY2y',  domain:  'dict.youdao.com',),
//
//     ]);
//     dio.interceptors.add(CookieManager(cookieJar));
//   }
//
//   Future<List<int>> getAudioBytes() async {
//     if (text != null){
//       Map<String, dynamic> query = {
//         'audio': text,
//         'type': 2,
//       };
//
//       Response response = await dio.get('https://dict.youdao.com/dictvoice', queryParameters: query);
//
//       return (response.data as String).split('').map((e) => e.codeUnitAt(0)).toList();
//     } else {
//       print("text 参数未定义！");
//     }
//     return [];
//   }
// }
//
// Future<void> main() async {
//   print("输入文字，然后按回车");
//     var voice = Voice();
//     voice.text = "world";
//     var bytes = await voice.getAudioBytes();
//   print(bytes);
// }
