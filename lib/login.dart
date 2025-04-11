import 'package:flutter/material.dart';
import 'dart:convert'; // JSON 처리를 위한 import
import 'package:http/http.dart' as http; // HTTP 요청을 위한 패키지 추가 필요
import 'home.dart';
import 'KakaoLogin.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'Find_Password.dart';
import 'Signup.dart';
import '../utils/api_config.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 이메일과 비밀번호 입력값을 관리할 컨트롤러 추가
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 로딩 상태 관리
  bool _isLoading = false;

  // 에러 메시지 관리
  String _errorMessage = '';

  // 로그인 함수 추가
  Future<void> _login() async {
    // 입력값 검증
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = '이메일과 비밀번호를 모두 입력해주세요.';
      });
      return;
    }

    // 로딩 시작
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 백엔드 API URL (실제 URL로 변경 필요)
      final url = Uri.parse('${getServerUrl()}/login');

      // 요청 데이터 준비
      final requestData = {
        'email': _emailController.text,
        'password': _passwordController.text
      };

      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      // 응답 처리
      if (response.statusCode == 200) {
        // 로그인 성공
        final responseData = jsonDecode(response.body);

        // 토큰이나 사용자 정보를 저장할 수 있음
        // 예: SharedPreferences를 사용하여 로컬에 저장
        // final prefs = await SharedPreferences.getInstance();
        // prefs.setString('token', responseData['token']);

        // 홈 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        // 로그인 실패
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? '로그인에 실패했습니다.';
        });
      }
    } catch (e) {
      // 네트워크 오류 등의 예외 처리
      setState(() {
        _errorMessage = '서버 연결에 실패했습니다. 다시 시도해주세요.';
      });
      print('로그인 오류: $e');
    } finally {
      // 로딩 종료
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // 컨트롤러 해제
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
                      controller: _emailController, // 컨트롤러 연결
                      style: TextStyle(fontSize: screenWidth * 0.03),
                      keyboardType: TextInputType.emailAddress, // 이메일 키보드 타입 설정
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
                      controller: _passwordController, // 컨트롤러 연결
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
                          onPressed: _isLoading ? null : _login, // 로그인 함수 연결
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
                      await UserApi.instance.loginWithKakaoAccount();
                      // 로그인 성공 시 홈 화면으로 이동
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
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