import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import 'package:flutter/services.dart';

class ListViewRt extends StatefulWidget {
  final Restaurant restaurant;
  final bool isExpanded;
  final VoidCallback onTap;

  const ListViewRt({
    Key? key,
    required this.restaurant,
    this.isExpanded = false,
    required this.onTap,
  }) : super(key: key);

  @override
  _ListViewRtState createState() => _ListViewRtState();
}

class _ListViewRtState extends State<ListViewRt> {
  bool isFavorite = false; // 좋아요 상태를 저장하는 변수

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: widget.onTap, // 항목 탭 이벤트
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: screenWidth * 0.01,
          horizontal: screenWidth * 0.02,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.015),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, screenWidth * 0.002),
              blurRadius: screenWidth * 0.01,
              spreadRadius: 0,
            ),
          ],
          // 선택된 항목 강조 표시
          border: widget.isExpanded
              ? Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5)
              : null,
        ),
        width: double.infinity,
        height: screenWidth * 0.14, // 기존 비율 유지
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.025,
            vertical: screenWidth * 0.018,
          ),
          child: Row(
            children: [
              // 음식점 이미지 - 데이터에서 가져옴
              ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.015),
                child: widget.restaurant.images.isNotEmpty
                    ? Image.asset(
                  widget.restaurant.images.first, // 첫 번째 이미지 사용
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: screenWidth * 0.12,
                      height: screenWidth * 0.12,
                      color: Colors.grey[300],
                      child: Icon(Icons.restaurant, color: Colors.grey[600]),
                    );
                  },
                )
                    : Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  color: Colors.grey[300],
                  child: Icon(Icons.restaurant, color: Colors.grey[600]),
                ),
              ),

              SizedBox(width: screenWidth * 0.02),

              // 음식점 정보 컬럼 - 데이터에서 가져옴
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 음식점 이름
                    Text(
                      widget.restaurant.name,
                      style: TextStyle(
                        color: const Color(0xFF151618),
                        fontSize: screenWidth * 0.033,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    // 거리 텍스트
                    Text(
                      widget.restaurant.distance,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.028,
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
                  HapticFeedback.lightImpact(); // 햅틱 피드백 추가
                  setState(() {
                    isFavorite = !isFavorite; // 상태 토글
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.01), // 터치 영역 확장
                  child: Image.asset(
                    isFavorite ? 'assets/Heart_P.png' : 'assets/Heart_G.png',
                    width: screenWidth * 0.06,
                    height: screenWidth * 0.06,
                    fit: BoxFit.contain,
                  ),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }
}