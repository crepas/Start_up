import 'package:flutter/material.dart';
import 'login.dart';
import 'TopAppbar.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
            horizontal: screenWidth * 0.08, // 좌우 패딩 증가
            vertical: screenHeight * 0.04,
          ),
          child: Column(
            children: [
              // 로고 이미지
              Center(
                child: Image.asset(
                  "assets/title.png",
                  width: screenWidth * 0.6,
                  height: screenHeight * 0.15, // 세로 크기 조절
                  fit: BoxFit.contain, // 원본 비율 유지
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
                  aspectRatio: 8.7 / 1, // 가로세로 비율 유지
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFA0CC71),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {
                      // 회원가입 로직 추가
                    },
                    child: Text(
                      '회원가입',
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
      ),
    );
  }

  Widget _buildTextFields(double screenWidth, double screenHeight) {
    List<String> placeholders = [
      '이름을 입력해주세요',
      '이메일을 입력해주세요',
      '비밀번호를 입력해주세요',
      '비밀번호를 재입력 해주세요'
    ];
    List<String> iconPaths = [
      "assets/User_Icon.png",
      "assets/Mail_Icon.png",
      "assets/Lock_Icon.png",
      "assets/Lock_Icon.png"
    ];

    return Column(
      children: List.generate(4, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.02),
          child: TextField(
            style: TextStyle(fontSize: screenWidth * 0.035),
            obscureText: index >= 2,
              decoration: InputDecoration(
                prefixIcon: Container(
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  width: screenWidth * 0.045,
                  height: screenHeight * 0.015,
                  child: Image.asset(
                    iconPaths[index],
                    fit: BoxFit.contain,
                  ),
                ),
                hintText: placeholders[index], // 힌트 텍스트
                hintStyle: TextStyle(
                  fontSize: screenWidth * 0.032,
                  color: Colors.grey[500], // 힌트 텍스트 색상
                ),
                filled: true,
                fillColor: Colors.grey[100], // 입력 필드 배경색
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50), // 모서리 둥글게
                  borderSide: BorderSide.none, // 기본 테두리 제거
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide(color: Colors.grey[300]!), // 기본 테두리 색상
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide(color: Color(0xFFA0CC71), width: 2), // 포커스 시 강조 색상
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 16), // 입력 필드 내부 패딩
              ),
          ),
        );
      }),
    );
  }
}
