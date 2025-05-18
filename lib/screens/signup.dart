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
  String? _errorMessage;

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

  bool _validatePassword(String password) {
    // 비밀번호 길이 검사 (8-20자)
    if (password.length < 8 || password.length > 20) {
      return false;
    }

    // 영문, 숫자, 특수문자 포함 여부 검사
    bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasLetter && hasDigit && hasSpecial;
  }

  Future<bool> _checkEmailDuplicate(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${getServerUrl()}/auth/check-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isAvailable'] ?? false;
      }
      return false;
    } catch (e) {
      print('이메일 중복 확인 오류: $e');
      return false;
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
          Navigator.pop(context);
        },
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이름 입력 필드
              TextField(
                controller: _usernameController,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: '이름',
                  labelStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                  ),
                  errorText: _nameError,
                  errorStyle: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
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
                ),
              ),
              SizedBox(height: 20),

              // 이메일 입력 필드
              TextField(
                controller: _emailController,
                style: theme.textTheme.bodyLarge,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '이메일',
                  labelStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                  ),
                  errorText: _emailError,
                  errorStyle: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
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
                ),
              ),
              SizedBox(height: 20),

              // 비밀번호 입력 필드
              TextField(
                controller: _passwordController,
                style: theme.textTheme.bodyLarge,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  labelStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                  ),
                  errorText: _passwordError,
                  errorStyle: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
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
                ),
              ),
              SizedBox(height: 20),

              // 비밀번호 확인 입력 필드
              TextField(
                controller: _confirmPasswordController,
                style: theme.textTheme.bodyLarge,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호 확인',
                  labelStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                  ),
                  errorText: _confirmPasswordError,
                  errorStyle: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
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
                ),
              ),
              SizedBox(height: 30),

              // 회원가입 버튼
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.06,
                  child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
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
                      '회원가입',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimary,
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

  // 회원가입 요청 함수
  Future<void> _signup() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      setState(() {
        _errorMessage = '모든 필드를 입력해주세요.';
      });
      return;
    }

    if (!_validatePassword(_passwordController.text)) {
      setState(() {
        _errorMessage = '비밀번호는 8-20자의 영문, 숫자, 특수문자를 포함해야 합니다.';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = '비밀번호가 일치하지 않습니다.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 이메일 중복 확인
      final isEmailAvailable = await _checkEmailDuplicate(_emailController.text);
      if (!isEmailAvailable) {
        setState(() {
          _errorMessage = '이미 사용 중인 이메일입니다.';
        });
        return;
      }

      final url = Uri.parse('${getServerUrl()}/signup');
      final requestData = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'username': _usernameController.text,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 201) {
        // 회원가입 성공 시 로그인 화면으로 이동
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입이 완료되었습니다. 로그인해주세요.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? '회원가입에 실패했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '서버 연결에 실패했습니다. 다시 시도해주세요.';
      });
      print('회원가입 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}