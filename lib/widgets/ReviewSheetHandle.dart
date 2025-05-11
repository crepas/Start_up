import 'package:flutter/material.dart';

/// 리뷰 시트의 상단 손잡이 위젯
/// 
/// 모달 바텀 시트의 상단에 표시되는 드래그 가능한 손잡이를 구현합니다.
/// 사용자가 시트를 드래그할 수 있음을 시각적으로 표시합니다.
class ReviewSheetHandle extends StatelessWidget {
  /// 화면 너비를 기반으로 크기를 계산하기 위한 값
  final double screenWidth;

  const ReviewSheetHandle({
    Key? key,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 상하 패딩: 화면 너비의 2.5%
      padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.025
      ),
      child: Container(
        // 손잡이 크기 설정
        width: screenWidth * 0.1,  // 화면 너비의 10%
        height: screenWidth * 0.01,  // 화면 너비의 1%
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),  // 반투명 검정색 배경
          borderRadius: BorderRadius.circular(screenWidth * 0.005),  // 둥근 모서리
        ),
      ),
    );
  }
}