import 'package:flutter/material.dart';
import 'widgets/ListView_RT.dart';
import '../screens/splash.dart';  // 경로 수정
import 'widgets/login.dart';   // 경로 수정
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';  // 수정
import 'widgets/KakaoLogin.dart'; // KakaoLoginButton이 정의된 파일
import '../widgets/ListView_AD.dart';
import 'screens/MainScreen.dart'; // 메인 화면 파일 추가
import 'screens/ListScreen.dart';
import '../widgets/Rt_information.dart';
import '../widgets/Rt_image.dart';
import '../widgets/Rt_ReviewList.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();  // 추가
  KakaoSdk.init(nativeAppKey: '4d02a171ef1f4a73e9fd405e022dc3b2');
  runApp(MyApp());
  //runApp(ListView_RT()); // runapp() 에 실행 시킬 화면 넣으면 됨
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
      home: ListScreen(),  // 로그인 화면 대신 메인 화면으로 바로 이동
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/main': (context) => MainScreen(),
      },
    );
  }
}