// ListView_RT.dart 수정
import 'package:flutter/material.dart';

class ListView_RT extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  ListView_RT({
    this.isExpanded = false,
    required this.onTap,
  });

  @override
  _ListView_RTState createState() => _ListView_RTState();
}

class _ListView_RTState extends State<ListView_RT> {
  bool isFavorite = false; // 좋아요 상태를 저장하는 변수

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseUnit = screenWidth / 360; // 기준 단위 (360은 디자인 기준 너비)

    return GestureDetector(
      onTap: widget.onTap, // 항목 탭 이벤트
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: baseUnit * 4, // 4.0
          horizontal: baseUnit * 8, // 8.0
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(baseUnit * 5), // 5
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, baseUnit * 0.8), // 0.8
              blurRadius: baseUnit * 4, // 4
              spreadRadius: 0,
            ),
          ],
          // 선택된 항목 강조 표시 (원하지 않으면 제거)
          border: widget.isExpanded
              ? Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5)
              : null,
        ),
        width: double.infinity,
        height: screenWidth * 0.14, // 기존 비율 유지
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.025, // 기존 비율 유지
            vertical: screenWidth * 0.018, // 기존 비율 유지
          ),
          child: Row(
            children: [
              // 음식점 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(baseUnit * 5), // 5
                child: Image.asset(
                  'assets/restaurant.png', // 가게 사진
                  width: screenWidth * 0.12, // 기존 비율 유지
                  height: screenWidth * 0.12, // 기존 비율 유지
                  fit: BoxFit.cover, // 이미지가 컨테이너에 맞게 채워지도록 설정
                ),
              ),

              // 이미지와 텍스트 사이 간격
              SizedBox(width: screenWidth * 0.02), // 기존 비율 유지

              // 음식점 정보 컬럼
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 음식점 이름
                    Text(
                      '신촌설렁탕',
                      style: TextStyle(
                        color: const Color(0xFF151618),
                        fontSize: screenWidth * 0.033, // 기존 비율 유지
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    // 거리 텍스트
                    Text(
                      '350m 이내',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.028, // 기존 비율 유지
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // 좋아요 버튼 (이벤트 버블링 방지)
              GestureDetector(
                onTap: () {
                  // 이 이벤트가 부모 위젯으로 전파되지 않도록 함
                  setState(() {
                    isFavorite = !isFavorite; // 상태 토글
                  });
                },
                // 이벤트 버블링 방지를 위해 behavior 설정
                behavior: HitTestBehavior.opaque,
                child: Image.asset(
                  isFavorite ? 'assets/Heart_P.png' : 'assets/Heart_G.png',
                  width: screenWidth * 0.073, // 기존 비율 유지
                  height: screenWidth * 0.063, // 기존 비율 유지
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}