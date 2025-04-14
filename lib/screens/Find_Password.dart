import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';
import '../widgets/TopAppbar.dart';

class FindPasswordScreen extends StatefulWidget {
  @override
  _FindPasswordScreenState createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  // 이메일 형식 검증 함수
  bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // 사용자 입력 유효성 검사 함수
  bool validateUserInput() {
    final String email = emailController.text.trim();

    // 빈칸 검사
    if (email.isEmpty) {
      _showErrorMessage('이메일을 입력해주세요.');
      return false;
    }

    // 이메일 형식 검사
    if (!isValidEmail(email)) {
      _showErrorMessage('유효한 이메일 주소를 입력해주세요.');
      return false;
    }

    return true;
  }

  // 에러 메시지 표시 함수
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 비밀번호 재설정 이메일 전송 함수
  Future<void> sendPasswordResetLink() async {
    // 먼저 입력 유효성 검사 수행
    if (!validateUserInput()) {
      return;
    }

    // 로딩 상태 시작
    setState(() {
      isLoading = true;
    });

    final String email = emailController.text.trim();
    final String apiUrl = 'http://10.0.2.2:8081/auth/forgot-password';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      // 로딩 상태 종료
      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseBody['message']),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showErrorMessage('이메일 전송 실패. 다시 시도해주세요.');
      }
    } catch (e) {
      // 로딩 상태 종료
      setState(() {
        isLoading = false;
      });
      _showErrorMessage('네트워크 연결 오류. 인터넷 연결을 확인한 후 다시 시도해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: CommonAppBar(
        title: '비밀번호 찾기',
        onBackPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이메일을 입력하시면\n비밀번호 재설정 링크를 보내드립니다.',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(fontSize: screenWidth * 0.03),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 20, right: 10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Image.asset(
                      'assets/Mail_Icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                hintText: '이메일',
                hintStyle: TextStyle(fontSize: screenWidth * 0.03, color: Color(0xFFA4A4A4)),
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
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
            SizedBox(
              width: double.infinity,
              height: screenHeight * 0.05,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFA0CC71),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                onPressed: isLoading ? null : sendPasswordResetLink,
                child: isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  '비밀번호 재설정 링크 전송',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}