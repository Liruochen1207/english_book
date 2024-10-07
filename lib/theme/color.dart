import 'package:flutter/material.dart';

typedef Cls = CustomColors;

class CustomColors {
  static Color label_1 = Colors.amber;
  static Color label_4 = Color(0xffdc870a);
  static Color label_5 = Color(0xff3979ce);
  static Color label_2 = Color(0xff07203d);
  static Color label_3 = Color(0xff0d4073);
}

class AutoColor {
  late BuildContext context;
  bool? isDarkness;

  bool getIsDarkness() {
    return (isDarkness ?? false);
  }

  AutoColor(this.context) {
    isDarkness = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
  Color primaryColor() {
    return (isDarkness ?? false) ? Cls.label_2 : Cls.label_1;
  }

  Color textColor() {
    return (isDarkness ?? false) ? Colors.white54 : Colors.black87;
  }

  Color labelColor() {
    return (isDarkness ?? false) ? Cls.label_5 : Cls.label_4;
  }

  Color starColor() {
    return (isDarkness ?? false) ? Colors.amber : Colors.black87;
  }

  Color backgroundColor() {
    return (isDarkness ?? false) ? Cls.label_3 : Cls.label_1.withOpacity(0.87);
  }
}
