import 'package:flutter/material.dart';
import '../models/restaurant.dart';

/// 리뷰 목록을 표시하는 위젯
/// 
/// 리뷰 목록을 스크롤 가능한 리스트로 표시합니다.
/// 각 리뷰는 작성자 이름과 내용을 포함합니다.
class ReviewListContent extends StatelessWidget {
  /// 화면 너비를 기반으로 크기를 계산하기 위한 값
  final double screenWidth;
  
  /// 표시할 리뷰 목록
  final List<Review> reviews;
  
  /// 스크롤 컨트롤러
  final ScrollController scrollController;

  const ReviewListContent({
    Key? key,
    required this.screenWidth,
    required this.reviews,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          return Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 작성자
                Text(
                  review.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.035
                  ),
                ),
                SizedBox(height: screenWidth * 0.01),
                // 내용
                Text(
                  review.comment,
                  style: TextStyle(
                    fontSize: screenWidth * 0.033,
                    color: Colors.black87
                  ),
                ),
                // 이미지 여러 장
                if (review.images != null && review.images!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: screenWidth * 0.01),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: review.images!.map((image) {
                          return Padding(
                            padding: EdgeInsets.only(right: screenWidth * 0.01),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                              child: Image.network(
                                image,
                                height: screenWidth * 0.45,
                                width: screenWidth * 0.45,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                Divider(
                  thickness: 1,
                  color: Colors.grey[300],
                  height: screenWidth * 0.03,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}