import 'package:flutter/material.dart';
import 'dark_colors.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: darkPrimaryColor,
  scaffoldBackgroundColor: darkBackgroundColor,
  cardColor: darkCardColor,
  
  // 앱바 테마
  appBarTheme: AppBarTheme(
    backgroundColor: darkAppBarColor,
    foregroundColor: darkAppBarTextColor,
    elevation: 0,
  ),
  
  // 텍스트 테마
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: darkTextColor),
    bodyMedium: TextStyle(color: darkTextColor),
    bodySmall: TextStyle(color: darkSubTextColor),
  ),
  
  // 아이콘 테마
  iconTheme: IconThemeData(color: darkTextColor),
  
  // 스위치 테마
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return darkSwitchActiveColor;
      }
      return darkSwitchInactiveColor;
    }),
    trackColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return darkSwitchActiveColor.withOpacity(0.5);
      }
      return darkSwitchInactiveColor.withOpacity(0.5);
    }),
  ),
  
  // 플로팅 액션 버튼 테마
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: darkPrimaryColor,
    foregroundColor: Colors.white,
  ),
  
  // 색상 스키마
  colorScheme: ColorScheme.dark(
    primary: darkPrimaryColor,
    secondary: darkSecondaryColor,
    background: darkBackgroundColor,
    error: darkErrorColor,
  ),
); 