import 'package:flutter/material.dart';
import 'light_colors.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: lightPrimaryColor,
  scaffoldBackgroundColor: lightBackgroundColor,
  cardColor: lightCardColor,
  
  // 앱바 테마
  appBarTheme: AppBarTheme(
    backgroundColor: lightAppBarColor,
    foregroundColor: lightAppBarTextColor,
    elevation: 0,
  ),
  
  // 텍스트 테마
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: lightTextColor),
    bodyMedium: TextStyle(color: lightTextColor),
    bodySmall: TextStyle(color: lightSubTextColor),
  ),
  
  // 아이콘 테마
  iconTheme: IconThemeData(color: lightTextColor),
  
  // 스위치 테마
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return lightSwitchActiveColor;
      }
      return lightSwitchInactiveColor;
    }),
    trackColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return lightSwitchActiveColor.withOpacity(0.5);
      }
      return lightSwitchInactiveColor.withOpacity(0.5);
    }),
  ),
  
  // 플로팅 액션 버튼 테마
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: lightPrimaryColor,
    foregroundColor: Colors.white,
  ),
  
  // 색상 스키마
  colorScheme: ColorScheme.light(
    primary: lightPrimaryColor,
    secondary: lightSecondaryColor,
    background: lightBackgroundColor,
    error: lightErrorColor,
  ),
); 