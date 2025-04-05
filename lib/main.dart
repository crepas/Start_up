import 'package:flutter/material.dart';
import 'splash.dart';  // 경로 수정
import 'login.dart';   // 경로 수정
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';  // 수정
import 'KakaoLogin.dart'; // KakaoLoginButton이 정의된 파일
import 'ADListView.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();  // 추가
  KakaoSdk.init(nativeAppKey: '4d02a171ef1f4a73e9fd405e022dc3b2');
  // runApp(MyApp());
  runApp(RestaurantCard()); // runapp() 에 실행 기킬 화면 넣으면 됨
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
