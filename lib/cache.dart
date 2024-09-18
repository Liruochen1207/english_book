class Cake {
  Map<String, List<String>> cacheMap = {};
  bool cached = false;

  bool hasCached() {
    if (!cached) {
      return false;
    } else {
      for (var i = 0; i < cacheMap.values.length; i++) {
        if (cacheMap.values.elementAt(i).isNotEmpty) {
          return true;
        }
      }
      cached = false;
      return false;
    }
  }

  void add(String title, String word) {
    if (cacheMap.containsKey(title)) {
      var changed = cacheMap[title] as List<String>;
      changed.add(word);
      cacheMap[title] = changed;
    } else {
      cacheMap[title] = [word];
    }
    print("CacheMap $cacheMap");
    cached = true;
  }

  List<String> get(String title) {
    print("CacheMap $cacheMap");
    return cacheMap[title] ?? [];
  }

  void remove(String title, String word) {
    var changed = cacheMap[title] as List<String>;
    changed.remove(word);
    cacheMap[title] = changed;
  }

  void clear(String title) {
    cacheMap[title] = [];
    cached = true;
  }

  void clearAll() {
    cacheMap = {};
  }
}

class CustomCache {
  static final Cake waitForAdd = Cake();
}
