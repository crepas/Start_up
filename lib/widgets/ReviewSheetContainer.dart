// lib/widgets/ReviewSheetContainer.dart
import 'package:flutter/material.dart';
import '../widgets/ReviewSheetHandle.dart';
import '../widgets/ReviewListContent.dart';
import '../widgets/ReviewInputWidget.dart';
import '../models/restaurant.dart';

/// 리뷰 시트의 전체 컨테이너 위젯
/// 
/// 리뷰 목록을 표시하는 모달 바텀 시트의 전체 레이아웃을 구성합니다.
/// 상단 손잡이, 리뷰 목록, 리뷰 입력 위젯을 포함합니다.
class ReviewSheetContainer extends StatelessWidget {
  /// 화면 너비를 기반으로 크기를 계산하기 위한 값
  final double screenWidth;
  
  /// 표시할 리뷰 목록
  final List<Review> reviews;
  
  /// 스크롤 컨트롤러
  final ScrollController scrollController;

  const ReviewSheetContainer({
    Key? key,
    required this.screenWidth,
    required this.reviews,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // 컨테이너 스타일 설정
      decoration: BoxDecoration(
        color: Colors.white,  // 흰색 배경
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(screenWidth * 0.05)  // 상단 모서리 둥글게
        ),
      ),
      child: Column(
        children: [
          // 상단 손잡이 위젯
          ReviewSheetHandle(screenWidth: screenWidth),
          
          // 리뷰 목록 위젯
          ReviewListContent(
            screenWidth: screenWidth,
            reviews: reviews,
            scrollController: scrollController,
          ),
          
          // 리뷰 입력 위젯
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,  // 좌우 패딩
                vertical: screenWidth * 0.02     // 상하 패딩
            ),
            child: ReviewInputWidget(nickname: '사용자 닉네임'),
          ),
        ],
      ),
    );
  }
}