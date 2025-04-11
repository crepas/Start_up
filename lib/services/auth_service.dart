import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoggedIn = false;
  String _username = '';
  String _email = '';

  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  String get email => _email;

  // 초기화 - 자동 로그인 체크
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // 저장된 로그인 정보 확인
    final savedUsername = prefs.getString('username');
    final savedEmail = prefs.getString('email');

    if (savedUsername != null && savedEmail != null) {
      _username = savedUsername;
      _email = savedEmail;
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  // 회원가입
  Future<Map<String, dynamic>> signup(String username, String email, String password, List<String> foodTypes, String priceRange) async {
    final response = await _apiService.signup(username, email, password, foodTypes, priceRange);
    return response;
  }

  // 로그인
  Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    final response = await _apiService.login(usernameOrEmail, password);

    if (response.containsKey('user')) {
      _username = response['user']['username'];
      _email = response['user']['email'];
      _isLoggedIn = true;

      // 자동 로그인을 위해 정보 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _username);
      await prefs.setString('email', _email);

      notifyListeners();
    }

    return response;
  }

  // 카카오 로그인
  Future<Map<String, dynamic>> kakaoLogin(String accessToken) async {
    final response = await _apiService.kakaoLogin(accessToken);

    if (response['message'] == '카카오 로그인 성공!') {
      // 성공 시 프로필 정보 가져오기
      final profileResponse = await _apiService.getProfile();

      if (profileResponse.containsKey('user')) {
        _username = profileResponse['user']['username'];
        _email = profileResponse['user']['email'];
        _isLoggedIn = true;

        // 자동 로그인을 위해 정보 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _username);
        await prefs.setString('email', _email);

        notifyListeners();
      }
    }

    return response;
  }

  // 로그아웃
  Future<Map<String, dynamic>> logout() async {
    final response = await _apiService.logout();

    _username = '';
    _email = '';
    _isLoggedIn = false;

    // 저장된 로그인 정보 삭제
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('email');

    notifyListeners();
    return response;
  }
}