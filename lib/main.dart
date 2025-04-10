import 'package:flutter/material.dart';
import 'splash.dart';  // 경로 수정
import 'login.dart';   // 경로 수정
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';  // 수정
import 'KakaoLogin.dart'; // KakaoLoginButton이 정의된 파일

void main() {
  WidgetsFlutterBinding.ensureInitialized();  // 추가
  KakaoSdk.init(nativeAppKey: '4d02a171ef1f4a73e9fd405e022dc3b2');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '나루나루',
      debugShowCheckedModeBanner: false,  // 디버그 배너 제거
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),  // 스플래시 스크린을 시작 화면으로 설정
    );
  }
}