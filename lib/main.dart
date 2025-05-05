import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:start_up/screens/HomeTab.dart';
import 'screens/splash.dart';
import 'screens/login.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/visit_history_screen.dart';

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
      return _isLoggedIn ? HomeTab() : LoginScreen();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: '4d02a171ef1f4a73e9fd405e022dc3b2');

  await FlutterNaverMap().init(
    clientId: '5v4sw4ol63',
    onAuthFailed: (ex) {
      print('인증 실패: ${ex.message}');
    },
  );

  runApp(MyApp());
  //runApp(ListView_RT()); // runapp() 에 실행 시킬 화면 넣으면 됨
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '나루나루',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFFA0CC71),
        // AppCompat 테마를 사용하도록 설정
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFA0CC71),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFFA0CC71),
          secondary: Color(0xFFD2E6A9),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeTab(),  // 로그인 화면 대신 메인 화면으로 바로 이동
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/main': (context) => HomeTab(),
      },
    );
  }
}