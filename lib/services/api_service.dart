import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 서버 주소 설정 (백엔드 서버 주소로 변경 필요)
  static const String baseUrl = 'http://10.0.2.2:8081'; // 안드로이드 에뮬레이터용
  // static const String baseUrl = 'http://localhost:8081'; // iOS 시뮬레이터용

  // HTTP 요청에 쿠키를 유지하기 위한 클라이언트
  static final http.Client _client = http.Client();

  // 회원가입 요청
  Future<Map<String, dynamic>> signup(String username, String email, String password, List<String> foodTypes, String priceRange) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'foodTypes': foodTypes,
          'priceRange': priceRange
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      print('회원가입 오류: $e');
      return {'message': '서버 연결 오류가 발생했습니다.'};
    }
  }

  // 로그인 요청
  Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'usernameOrEmail': usernameOrEmail,
          'password': password
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      print('로그인 오류: $e');
      return {'message': '서버 연결 오류가 발생했습니다.'};
    }
  }

  // 카카오 로그인 요청
  Future<Map<String, dynamic>> kakaoLogin(String accessToken) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/kakao'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accessToken': accessToken
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      print('카카오 로그인 오류: $e');
      return {'message': '서버 연결 오류가 발생했습니다.'};
    }
  }

  // 로그아웃 요청
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/logout'),
      );

      return json.decode(response.body);
    } catch (e) {
      print('로그아웃 오류: $e');
      return {'message': '서버 연결 오류가 발생했습니다.'};
    }
  }

  // 프로필 정보 요청
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/profile'),
      );

      return json.decode(response.body);
    } catch (e) {
      print('프로필 조회 오류: $e');
      return {'message': '서버 연결 오류가 발생했습니다.'};
    }
  }
}