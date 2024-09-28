import 'dart:convert';
import 'dart:typed_data';

bool nBool (int num){
return num == 1;
}

String showSym(List synonym){
  String ready = "";
  int index = 0;
  synonym.forEach((e){
    ready += e;
    if (index < synonym.length - 1){
      ready += ", ";
    }

    index ++;
  });
  if (ready != ""){
    ready = "同义替换词：" + ready;
  }
  return ready;
}

Uint8List bytesFromBase64(String b64s){
  return base64Decode(b64s);
}

class WordDetails {
  bool? cet4;
  bool? cet6;
  bool? gre;
  bool? ielts;
  bool? toefl;
  bool? postgraduate;
  String? mean;
  String? synonym;
  Uint8List? voice;
  WordDetails({required this.cet4, required this.cet6, required this.gre, required this.ielts, required this.toefl, required this.postgraduate, required this.mean, required this.synonym, required this.voice });

}