import 'package:flutter/material.dart';
import 'home.dart';
import 'main.dart';
import 'dart:async';
import 'login.dart'; // 다른 화면이나 로그인 로직이 포함된 파일
import 'KakaoLogin.dart';  // KakaoLoginButton import 추가
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';  // 카카오 SDK import 추가
import 'Find_Password.dart';
import 'Signup.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
                style: TextStyle(fontSize: screenWidth * 0.03),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 20, right: 10), // 왼쪽 여백 추가
                    child: SizedBox(
                      width: 20, // 원하는 너비
                      height: 20, // 원하는 높이
                      child: Image.asset(
                        'assets/Mail_Icon.png',
                        fit: BoxFit.contain, // 이미지가 사이즈 안에서 맞게 조정됨
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),


                    SizedBox(height: 20),
                    TextField(
                      style: TextStyle(fontSize: screenWidth * 0.04),
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 20, right: 10), // 왼쪽 여백 추가
                          child: SizedBox(
                            width: 20, // 아이콘 크기 동일
                            height: 20,
                            child: Image.asset(
                              'assets/Lock_Icon.png',
                              fit: BoxFit.contain, // 아이콘이 크기에 맞게 조정됨
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),

                    SizedBox(height: 20),

                    // 추가 링크: 비밀번호 찾기, 회원가입
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
                      width: double.infinity,
                      height: screenHeight * 0.05,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFA0CC71),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => HomeScreen()),
                          );
                        },
                        child: Text(
                          '로그인',
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
              SizedBox(height: screenHeight * 0.01),



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
              SizedBox(height: screenHeight * 0.01),

              // 카카오 로그인 버튼 추가
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
