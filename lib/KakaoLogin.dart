import 'package:flutter/material.dart';

class KakaoLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double widthFactor; // 너비 조절을 위한 변수

  const KakaoLoginButton({
    super.key,
    required this.onPressed,
    this.widthFactor = 0.8, // 기본 너비 비율 (90%)
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonWidth = screenWidth * widthFactor; // 비율 조정 가능
    final buttonHeight = screenHeight * 0.05;

    return SizedBox(
      width: buttonWidth, // 조절 가능한 너비
      height: buttonHeight,
      child: GestureDetector(
        onTap: onPressed,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100), // 둥근 모서리 유지
          child: FittedBox(
            fit: BoxFit.fill, // 버튼 크기에 맞게 이미지 채우기
            child: Image.asset('assets/Kakao_Login.png'),
          ),
        ),
      ),
    );
  }
}
