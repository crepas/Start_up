import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login.dart';
import 'screens/MainScreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: '4d02a171ef1f4a73e9fd405e022dc3b2');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '나루나루',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFA0CC71),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFFA0CC71),
          secondary: Color(0xFFD2E6A9),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // 로그인 상태 확인
  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // 토큰이 있으면 로그인 상태로 간주
      if (token != null) {
        // 여기서 토큰 유효성 검사를 추가할 수 있음 (백엔드 API 호출)
        // 예: 서버에서 토큰 유효성 확인
        setState(() {
          _isLoggedIn = true;
        });
      }
    } catch (e) {
      print('로그인 상태 확인 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // 로딩 중 화면
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    } else {
      // 로그인 상태에 따라 화면 분기
      if (_isLoggedIn) {
        return MainScreen();
      } else {
        return LoginScreen();
      }
    }
  }
}