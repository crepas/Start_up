import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'MainScreen.dart';
import '../widgets/KakaoLogin.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'Find_Password.dart';
import 'Signup.dart';

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
      // 실제 백엔드 URL로 변경 필요
      final url = Uri.parse('http://localhost:8081/login');

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

        // 자동 로그인 설정 저장
        final prefs = await SharedPreferences.getInstance();

        // 토큰 저장 (실제 토큰으로 대체 필요)
        prefs.setString('token', 'sample_token');
        prefs.setString('email', _emailController.text);
        prefs.setString('username', responseData['user']['username']);

        // 자동 로그인 체크 여부에 따라 이메일 저장
        if (_rememberMe) {
          prefs.setString('savedEmail', _emailController.text);
        } else {
          prefs.remove('savedEmail');
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
                      style: TextStyle(fontSize: screenWidth * 0.03),
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
                        hintStyle: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Color(0xFFA4A4A4),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: Color(0xFFA0CC71)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
                      ),
                    ),

                    SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      style: TextStyle(fontSize: screenWidth * 0.03),
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
                        hintStyle: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Color(0xFFA4A4A4),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: Color(0xFFA0CC71)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
                      ),
                    ),

                    // 자동 로그인 체크박스 추가
                    Padding(
                      padding: EdgeInsets.only(top: 8.0, left: 8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                            activeColor: Color(0xFFA0CC71),
                          ),
                          Text(
                            '자동 로그인',
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 에러 메시지 표시
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                      ),

                    // 추가 링크: 비밀번호 찾기, 회원가입
                    SizedBox(height: screenHeight * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FindPasswordScreen()),
                            );
                          },
                          child: Text(
                            '비밀번호 찾기',
                            style: TextStyle(color: Color(0xFFA4A4A4), fontSize: screenWidth * 0.03),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Text('|', style: TextStyle(color: Color(0xFFA4A4A4), fontSize: screenWidth * 0.03)),
                        SizedBox(width: screenWidth * 0.02),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignupScreen()),
                            );
                          },
                          child: Text(
                            '회원가입',
                            style: TextStyle(color: Color(0xFFA4A4A4), fontSize: screenWidth * 0.03),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    SizedBox(
                      width: screenWidth * 0.8,
                      child: AspectRatio(
                        aspectRatio: 8.7 / 1,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFA0CC71),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? SizedBox(
                            width: screenWidth * 0.03,
                            height: screenWidth * 0.03,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            '로그인',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.005),

              SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Color(0xFFA4A4A4),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or',
                      style: TextStyle(
                        color: Color(0xFFA4A4A4),
                        fontSize: screenWidth * 0.03,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Color(0xFFA4A4A4),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),

              // 카카오 로그인 버튼
              Center(
                child: KakaoLoginButton(
                  onPressed: () async {
                    try {
                      final token = await UserApi.instance.loginWithKakaoAccount();

                      // 카카오 로그인 성공 시 자동 로그인 정보 저장
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setString('token', 'kakao_${token.accessToken}');

                      // 사용자 정보 가져오기
                      try {
                        final user = await UserApi.instance.me();
                        prefs.setString('email', user.kakaoAccount?.email ?? 'kakao_user@example.com');
                        prefs.setString('username', user.kakaoAccount?.profile?.nickname ?? 'kakao_user');
                      } catch (e) {
                        print('카카오 사용자 정보 가져오기 실패: $e');
                      }

                      // 홈 화면으로 이동
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen()),
                      );
                    } catch (error) {
                      print('카카오 로그인 실패 $error');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}