import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/MainScreen.dart';
import '../widgets/KakaoLogin.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'Find_Password.dart';
import 'Signup.dart';
import 'package:start_up/utils/api_config.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _rememberMe = false; // 자동 로그인 체크 상태

  @override
  void initState() {
    super.initState();
    // 이전에 저장된 이메일이 있으면 불러오기
    _loadSavedEmail();
  }

  // 저장된 이메일 불러오기
  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('savedEmail');

    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  // 로그인 함수
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = '이메일과 비밀번호를 모두 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url = Uri.parse('${getServerUrl()}/login');

      final requestData = {
        'usernameOrEmail': _emailController.text,
        'password': _passwordController.text
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('email', _emailController.text);
        await prefs.setString('username', responseData['user']['username']);

        if (_rememberMe) {
          await prefs.setString('savedEmail', _emailController.text);
        } else {
          await prefs.remove('savedEmail');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? '로그인에 실패했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '서버 연결에 실패했습니다. 다시 시도해주세요.';
      });
      print('로그인 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleKakaoLogin() async {
    try {
      if (await isKakaoTalkInstalled()) {
        await UserApi.instance.loginWithKakaoTalk();
      } else {
        await UserApi.instance.loginWithKakaoAccount();
      }
      
      final user = await UserApi.instance.me();
      if (user != null) {
        // 카카오 로그인 성공 시 서버에 토큰 전송
        final response = await http.post(
          Uri.parse('${getServerUrl()}/auth/kakao'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'kakaoId': user.id,
            'email': user.kakaoAccount?.email,
            'nickname': user.kakaoAccount?.profile?.nickname,
          }),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final token = responseData['token'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('email', user.kakaoAccount?.email ?? '');
          await prefs.setString('username', user.kakaoAccount?.profile?.nickname ?? '');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        } else {
          throw Exception('Failed to login with Kakao');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '카카오 로그인에 실패했습니다. 다시 시도해주세요.';
      });
      print('카카오 로그인 오류: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 로고 이미지
              Center(
                child: Container(
                  width: screenWidth * 0.6,
                  height: screenHeight * 0.15,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/title.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),

              // 이메일 입력 필드
              SizedBox(height: screenHeight * 0.01),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _emailController,
                      style: theme.textTheme.bodyLarge,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: screenWidth * 0.05, right: screenWidth * 0.02),
                          child: SizedBox(
                            width: screenWidth * 0.045,
                            height: screenHeight * 0.045,
                            child: Image.asset(
                              'assets/Mail_Icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        hintText: '이메일',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
                      ),
                    ),

                    SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      style: theme.textTheme.bodyLarge,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: screenWidth * 0.05, right: screenWidth * 0.02),
                          child: SizedBox(
                            width: screenWidth * 0.045,
                            height: screenHeight * 0.045,
                            child: Image.asset(
                              'assets/Lock_Icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        hintText: '비밀번호',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
                      ),
                    ),

                    // 자동 로그인 체크박스
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: colorScheme.primary,
                        ),
                        Text(
                          '자동 로그인',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),

                    // 에러 메시지
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),

                    SizedBox(height: 20),

                    // 로그인 버튼
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.06,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                              )
                            : Text(
                                '로그인',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // 소셜 로그인 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        KakaoLoginButton(
                          onPressed: _handleKakaoLogin,
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // 회원가입 및 비밀번호 찾기 링크
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignupScreen()),
                            );
                          },
                          child: Text(
                            '회원가입',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        Text(
                          ' | ',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FindPasswordScreen()),
                            );
                          },
                          child: Text(
                            '비밀번호 찾기',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}