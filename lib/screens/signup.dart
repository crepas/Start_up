import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/login.dart';
import '../widgets/TopAppbar.dart';
import '../utils/api_config.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 컨트롤러 추가
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // 오류 메시지 관리
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // 로딩 상태
  bool _isLoading = false;

  @override
  void dispose() {
    // 컨트롤러 해제
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 이메일 형식 검증 함수
  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  // 입력값 검증 함수
  bool _validateInputs() {
    bool isValid = true;

    // 이름 검증
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _nameError = '이름을 입력해주세요';
      });
      isValid = false;
    } else {
      setState(() {
        _nameError = null;
      });
    }

    // 이메일 검증
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = '이메일을 입력해주세요';
      });
      isValid = false;
    } else if (!_isValidEmail(_emailController.text.trim())) {
      setState(() {
        _emailError = '올바른 이메일 형식이 아닙니다';
      });
      isValid = false;
    } else {
      setState(() {
        _emailError = null;
      });
    }

    // 비밀번호 검증
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = '비밀번호를 입력해주세요';
      });
      isValid = false;
    } else {
      setState(() {
        _passwordError = null;
      });
    }

    // 비밀번호 확인 검증
    if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        _confirmPasswordError = '비밀번호를 재입력해주세요';
      });
      isValid = false;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = '비밀번호가 일치하지 않습니다';
      });
      isValid = false;
    } else {
      setState(() {
        _confirmPasswordError = null;
      });
    }

    return isValid;
  }

  // 회원가입 요청 함수
  Future<void> _signup() async {
    // 입력값 검증
    if (!_validateInputs()) {
      return;
    }

    // 로딩 시작
    setState(() {
      _isLoading = true;
    });

    try {
      // 백엔드 API URL (실제 URL로 변경 필요)
      final url = Uri.parse('${getServerUrl()}/signup');

      // 요청 데이터 준비
      final requestData = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      // POST 요청 보내기
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      // 응답 처리
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 회원가입 성공
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입이 완료되었습니다. 로그인해주세요.'),
            backgroundColor: Color(0xFFA0CC71),
          ),
        );

        // 로그인 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        // 회원가입 실패
        final responseData = jsonDecode(response.body);
        String errorMessage = responseData['message'] ?? '회원가입에 실패했습니다.';

        // 에러 메시지에 따라 처리 (이메일 중복 등)
        if (errorMessage.contains('email') || errorMessage.toLowerCase().contains('duplicate')) {
          setState(() {
            _emailError = '이미 사용 중인 이메일입니다';
          });
        } else {
          // 일반 에러 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 네트워크 오류 등의 예외 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('서버 연결에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      print('회원가입 오류: $e');
    } finally {
      // 로딩 종료
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CommonAppBar(
        title: '회원가입',
        onBackPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        },
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,
            vertical: screenHeight * 0.04,
          ),
          child: Column(
            children: [
              // 로고 이미지
              Center(
                child: Image.asset(
                  "assets/title.png",
                  width: screenWidth * 0.6,
                  height: screenHeight * 0.15,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: screenHeight * 0.04),

              // 입력 필드
              _buildTextFields(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.03),

              // 회원가입 버튼
              SizedBox(
                width: screenWidth * 0.8,
                child: AspectRatio(
                  aspectRatio: 8.7 / 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: _isLoading ? null : _signup,
                    child: _isLoading
                        ? SizedBox(
                            width: screenWidth * 0.03,
                            height: screenWidth * 0.03,
                            child: CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            '회원가입',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
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
      ),
    );
  }

  Widget _buildTextFields(double screenWidth, double screenHeight) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 입력 필드의 컨트롤러 및 에러 메시지
    List<Map<String, dynamic>> fieldData = [
      {
        'controller': _usernameController,
        'placeholder': '이름을 입력해주세요',
        'iconPath': "assets/User_Icon.png",
        'obscureText': false,
        'error': _nameError,
      },
      {
        'controller': _emailController,
        'placeholder': '이메일을 입력해주세요',
        'iconPath': "assets/Mail_Icon.png",
        'obscureText': false,
        'error': _emailError,
      },
      {
        'controller': _passwordController,
        'placeholder': '비밀번호를 입력해주세요',
        'iconPath': "assets/Lock_Icon.png",
        'obscureText': true,
        'error': _passwordError,
      },
      {
        'controller': _confirmPasswordController,
        'placeholder': '비밀번호를 재입력 해주세요',
        'iconPath': "assets/Lock_Icon.png",
        'obscureText': true,
        'error': _confirmPasswordError,
      }
    ];

    return Column(
      children: List.generate(fieldData.length, (index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: fieldData[index]['controller'],
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: theme.textTheme.bodyLarge?.color,
              ),
              obscureText: fieldData[index]['obscureText'],
              decoration: InputDecoration(
                prefixIcon: Container(
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  width: screenWidth * 0.045,
                  height: screenHeight * 0.015,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      theme.textTheme.bodyLarge?.color ?? Colors.black,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      fieldData[index]['iconPath'],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                hintText: fieldData[index]['placeholder'],
                hintStyle: TextStyle(
                  fontSize: screenWidth * 0.032,
                  color: theme.hintColor,
                ),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 16),
                errorText: fieldData[index]['error'],
                errorStyle: TextStyle(
                  color: colorScheme.error,
                  fontSize: screenWidth * 0.03,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
          ],
        );
      }),
    );
  }
}