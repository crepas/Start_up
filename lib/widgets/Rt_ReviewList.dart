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
      height: screenWidth * 0.8,
      child: ListView(
        shrinkWrap: true,
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          ...widget.reviews.map((review) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenWidth * 0.005
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
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenWidth * 0.002
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