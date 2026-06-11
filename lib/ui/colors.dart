// ignore_for_file: constant_identifier_names

part of carp_study_app;

class CACHET {
  static const Color BLUE = Color.fromRGBO(97, 195, 217, 1.0);
  static const Color TASK_BLUE = Color.fromRGBO(58, 130, 247, 1.0);
  static const Color TASK_INPUT_DATA = Color.fromRGBO(161, 97, 106, 1.0);
  static const Color TASK_COMPLETED_BLUE = Color.fromRGBO(0, 99, 152, 1.0);
  static const Color TASK_TO_EXPIRE_BACKGROUND = Color(0x1aFFA600);

  static const Color DEPLOYMENT_DEPLOYING = Color(0xff006398);
  static const Color DEPLOYMENT_RUNNING = Color(0xff67CE67);
  static const Color DEPLOYMENT_STOPPED = Color(0xfdf848484);
  static const Color DEPLOYMENT_INVITED = Color(0xffDF7801);

  static const Color ANONYMOUS = Color(0xffB25FEA);

  static const Color RED = Color.fromRGBO(213, 11, 51, 1.0);
  static const Color WHITE = Color.fromRGBO(255, 255, 255, 1.0);
  static const Color BLACK = Color.fromRGBO(1, 1, 1, 1.0);
  static const Color GREEN = Color.fromRGBO(103, 206, 103, 1.0);
  static const Color YELLOW = Color.fromRGBO(248, 209, 0, 1.0);
  static const Color ORANGE = Color.fromRGBO(236, 99, 48, 1.0);
  static const Color CYAN = Color.fromRGBO(79, 100, 50, 1.0);
  static const Color PURPLE = Color.fromRGBO(118, 30, 169, 1.0);
  static const Color CAQUI = Color.fromRGBO(126, 145, 70, 1.0);
  static const Color OCEAN = Color.fromRGBO(34, 139, 137, 1.0);

  static const Color LIGHT_2 = Color(0xffE5E5EA);
  static const Color LIGHT_GREY = Color.fromRGBO(100, 99, 99, .2);
  static const Color LIGHT_GREEN = Color.fromRGBO(175, 202, 11, 1.0);
  static const Color LIGHT_GREEN_1 = Color.fromRGBO(144, 216, 143, .2);
  static const Color LIGHT_PURPLE = Color.fromRGBO(178, 95, 234, 1.0);
  static const Color LIGHT_ORANGE = Color.fromRGBO(234, 91, 12, .2);
  static const Color LIGHT_BLUE = Color.fromRGBO(129, 207, 250, 1.0);
  static const Color LIGHT_BROWN = Color.fromRGBO(161, 97, 106, 1.0);

  static const Color DARK_BLUE = ui.Color.fromRGBO(50, 96, 164, 1);

  static const Color BLUE_1 = Color.fromRGBO(33, 146, 201, 1);
  static const Color BLUE_2 = Color.fromRGBO(130, 206, 233, 1);
  static const Color BLUE_3 = Color.fromRGBO(178, 225, 242, 1);
  static const Color BLUE_4 = Color.fromRGBO(225, 244, 250, 1);
  static const Color RED_1 = Color.fromRGBO(235, 75, 98, 1);
  static const Color RED_2 = Color.fromRGBO(228, 107, 119, 1);
  static const Color RED_3 = Color.fromRGBO(254, 202, 212, 1);

  static const Color GREEN_1 = Color.fromRGBO(144, 216, 143, 1);

  static const Color GREY_1 = Color.fromRGBO(100, 99, 99, 1.0);
  static const Color GREY_2 = Color.fromRGBO(146, 146, 146, 1.0);
  static const Color GREY_3 = Color.fromRGBO(178, 178, 178, 1.0);
  static const Color GREY_4 = Color.fromRGBO(218, 218, 218, 1.0);
  static const Color GREY_5 = Color.fromRGBO(112, 112, 112, 1.0);
  static const Color GREY_6 = Color.fromRGBO(132, 132, 132, 1.0);

  static const Color HEART_RATE_RED = Color.fromRGBO(235, 75, 98, 1.0);

  static Color pie = createMaterialColor(const Color.fromRGBO(225, 244, 250, 1));

  static const List<Color> COLOR_LIST = [
    Color(0xFF7FC9E3),
    RED_1,
    BLUE_1,
    Color(0xFF809AE5),
    Color(0xFF630A1A),
    Color(0xFF1282B0),
    Color(0xFFC052A2),
    Color(0xFFBA0022),
    Color(0xFF6FB4E9),
    Color(0xFFA379CE),
    Color(0xFFCA2366),
  ];
}

MaterialColor createMaterialColor(Color color) {
  var strengths = <double>[.05];
  var swatch = <int?, Color>{};
  final int r = color.r as int, g = color.g as int, b = color.b as int;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.toARGB32(), swatch as Map<int, Color>);
}
