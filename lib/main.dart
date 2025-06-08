import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:start_up/screens/ListScreen.dart';
import 'package:start_up/screens/MainScreen.dart';
import 'package:start_up/screens/MenuTab.dart';
import 'screens/splash.dart';
import 'screens/login.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
// import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/visit_history_screen.dart';
import '../screens/review_management.dart';
import '../screens/app_settings.dart';
import '../screens/EditProfileScreen.dart';
import '../screens/ListScreen.dart';
import '../widgets/Rt_ReviewList.dart';
import '../screens/favorites_Screen.dart';
import '../screens/signup.dart';
import '../widgets/ReviewInputWidget.dart';
import '../widgets/Filter.dart';
import 'theme/light_theme.dart';
import 'theme/dark_theme.dart';
// 로그인 상태 체크를 위한 클래스
class AuthCheck extends StatefulWidget {
  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // 로그인 상태 확인
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      setState(() {
        _isLoggedIn = true;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      return _isLoggedIn ? MainScreen() : LoginScreen();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: '4d02a171ef1f4a73e9fd405e022dc3b2');

  // 웹이 아닌 경우에만 네이버 지도 초기화
  if (!kIsWeb) {
    try {
      await FlutterNaverMap().init(
        clientId: '5v4sw4ol63',
        onAuthFailed: (ex) {
          print('인증 실패: ${ex.message}');
        },
      );
    } catch (e) {
      print('네이버 지도 초기화 실패: $e');
    }
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('darkMode') ?? false;
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void updateThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '나루나루',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: ListScreen(),
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/main': (context) => MainScreen(),
        '/list': (context) => ListScreen(),
      },
    );
  }
}