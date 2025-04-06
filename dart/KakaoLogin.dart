import 'package:flutter/material.dart';

class KakaoLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double widthFactor; // 너비 조절을 위한 변수

  const KakaoLoginButton({
    super.key,
    required this.onPressed,
    this.widthFactor = 0.8, // 기본 너비 비율
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * widthFactor;

    return SizedBox(
      width: buttonWidth,
      child: GestureDetector(
        onTap: onPressed,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100), // 둥근 모서리 유지
          child: AspectRatio(
            aspectRatio: 28 / 5, // 가로세로 비율 유지
            child: Image.asset(
              'assets/Kakao_Login.png',
              fit: BoxFit.contain, // 비율 유지하며 조절
            ),
          ),
        ),
      ),
    );
  }
}
