import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import 'ReviewListContent.dart';
import 'ReviewSheetHandle.dart';
import 'ReviewInputWidget.dart';

class RtReviewList extends StatefulWidget {
  final List<Review> reviews;

  const RtReviewList({Key? key, required this.reviews}) : super(key: key);

  @override
  _RtReviewListState createState() => _RtReviewListState();
}

class _RtReviewListState extends State<RtReviewList> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: screenWidth * 0.2,  // 리뷰 리스트 컨테이너의 전체 높이
      // 높이를 0.2로 설정하여 리뷰 모두보기와 다음 식당 리스트 사이의 여백을 최소화
      child: ListView(
        shrinkWrap: true,
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          ...widget.reviews.map((review) {
            return Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,  // 좌우 여백
                  vertical: screenWidth * 0.005    // 각 리뷰 항목의 상하 여백
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.username,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.035,
                            color: Colors.black
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: Text(
                          truncateWithEllipsis(review.comment, 40),
                          style: TextStyle(
                              fontSize: screenWidth * 0.033,
                              color: Colors.black
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),

          Padding(
            padding: EdgeInsets.only(
                left: screenWidth * 0.03,    // 좌측 여백
                right: screenWidth * 0.03,   // 우측 여백
                top: screenWidth * 0.02,     // 상단 여백 증가
                bottom: screenWidth * 0.002  // 하단 여백
            ),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,  // 화면 높이의 75%로 제한
                  ),
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final scrollController = ScrollController();
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 상단 손잡이
                          ReviewSheetHandle(screenWidth: screenWidth),
                          // 리뷰 리스트
                          Expanded(
                            child: ReviewListContent(
                              screenWidth: screenWidth,
                              reviews: widget.reviews,
                              scrollController: scrollController,
                            ),
                          ),
                          // 하단 리뷰 입력 위젯
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.03,
                                vertical: screenWidth * 0.02
                            ),
                            child: ReviewInputWidget(nickname: '사용자 닉네임'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Text(
                '리뷰 모두보기',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String truncateWithEllipsis(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  }
}