import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:start_up/screens/HomeTab.dart';
import 'package:start_up/screens/ListScreen.dart';
import 'package:start_up/screens/MainScreen.dart';
import 'package:start_up/screens/MenuTab.dart';
import 'screens/splash.dart';
import 'screens/login.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
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

// 로그인 상태 체크를 위한 클래스 (최적화)
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

  // 로그인 상태 확인 (최적화)
  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (mounted) {
        setState(() {
          _isLoggedIn = token != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('로그인 상태 확인 오류: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return _isLoggedIn ? MainScreen() : LoginScreen();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오 SDK 초기화
  KakaoSdk.init(nativeAppKey: '4d02a171ef1f4a73e9fd405e022dc3b2');

  // 웹이 아닌 경우에만 네이버 지도 초기화 (성능 최적화)
  if (!kIsWeb) {
    try {
      await FlutterNaverMap().init(
        clientId: '5v4sw4ol63',
        onAuthFailed: (ex) {
          print('네이버 지도 인증 실패: ${ex.message}');
        },
      );
    } catch (e) {
      print('네이버 지도 초기화 실패: $e');
      // 실패해도 앱 실행은 계속
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('darkMode') ?? false;
      if (mounted) {
        setState(() {
          _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
        });
      }
    } catch (e) {
      print('테마 로드 오류: $e');
    }
  }

  void updateThemeMode(ThemeMode mode) {
    if (mounted) {
      setState(() {
        _themeMode = mode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '나루나루',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      // 기본 홈을 AuthCheck로 설정하여 로그인 상태 확인 후 적절한 화면 표시
      home: AuthCheck(),
      // 라우트 설정 간소화
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/main': (context) => MainScreen(),
      },
      // 성능 최적화를 위한 설정
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0, // 텍스트 크기 고정으로 레이아웃 안정성 확보
          ),
          child: child!,
        );
      },
    );
  }
}