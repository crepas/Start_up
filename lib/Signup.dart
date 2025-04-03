import 'package:flutter/material.dart';
import 'login.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
        ),
        title: Text(
          '회원가입',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: screenWidth,
            height: 844,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1E120F28),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: screenWidth * 0.05,
                  top: 20,
                  child: Container(
                    width: screenWidth * 0.9,
                    height: 322,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFBCC1CA)),
                    ),
                    child: Column(
                      children: List.generate(4, (index) {
                        List<String> placeholders = [
                          '이름을 입력해주세요',
                          '이메일을 입력해주세요',
                          '비밀번호를 입력해주세요',
                          '비밀번호를 재 입력 해주세요'
                        ];
                        return Padding(
                          padding: EdgeInsets.only(top: index == 0 ? 0 : 20),
                          child: Container(
                            width: screenWidth * 0.85,
                            height: 43,
                            decoration: BoxDecoration(
                              color: Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                SizedBox(width: 16),
                                Image.asset(
                                  'assets/Mail_Icon.png',
                                  width: screenWidth * 0.05,
                                  height: screenWidth * 0.05,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  placeholders[index],
                                  style: TextStyle(
                                    color: Color(0xFFBCC1CA),
                                    fontSize: screenWidth * 0.03,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Positioned(
                  left: screenWidth * 0.05,
                  top: 362,
                  child: Container(
                    width: screenWidth * 0.9,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(0xFF9FCC71),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Center(
                      child: Text(
                        '회원가입',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}