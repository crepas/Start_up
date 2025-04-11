import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// 서버 URL을 가져오는 함수
String getServerUrl() {
  // 웹에서 실행될 때
  if (kIsWeb) {
    return 'http://localhost:8081';
  }
  // 안드로이드 에뮬레이터에서 실행될 때
  else if (Platform.isAndroid) {
    return 'http://10.0.2.2:8081';
  }
  // iOS 시뮬레이터에서 실행될 때
  else if (Platform.isIOS) {
    return 'http://localhost:8081';
  }
  // 기타 플랫폼
  else {
    return 'http://localhost:8081';
  }
}