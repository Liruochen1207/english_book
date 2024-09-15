class CustomCache {
  static List<String> waitForAdd = [];
  static void cleaner (){
    waitForAdd = [];
  }
}