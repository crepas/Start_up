import 'package:flutter/material.dart';
import '../screens/splash.dart';  // 경로 수정
import '../screens/login.dart';   // 경로 수정
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';  // 수정
import '../widgets/KakaoLogin.dart'; // KakaoLoginButton이 정의된 파일
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'widgets/ADListView.dart';
import 'screens/MainScreen.dart'; // 메인 화면 파일 추가

void main() async{
  WidgetsFlutterBinding.ensureInitialized();  // 추가
  KakaoSdk.init(nativeAppKey: '4d02a171ef1f4a73e9fd405e022dc3b2');
  await NaverMapSdk.instance.initialize(
    clientId: 'h7w445azzw', // 발급받은 클라이언트 ID
    onAuthFailed: (e) => print("네이버 맵 인증 오류: $e"),
  );
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
