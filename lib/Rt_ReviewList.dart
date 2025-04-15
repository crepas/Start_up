import 'package:flutter/material.dart';
import 'models/restaurant.dart';

class RtReviewList extends StatefulWidget {
  final List<Review> reviews;

  const RtReviewList({Key? key, required this.reviews}) : super(key: key);

  @override
  _RtReviewListState createState() => _RtReviewListState();
}

class _RtReviewListState extends State<RtReviewList> {
  bool isExpanded = false;

  // 텍스트 잘라내기 헬퍼 함수 (단어 경계 존중)
  String truncateWithEllipsis(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }

    // 최대 길이까지 자른 다음 마지막 단어가 불완전하면 그 단어를 제거
    String truncated = text.substring(0, maxLength);
    if (text.length > maxLength && !text.substring(maxLength, maxLength + 1).contains(' ')) {
      // 마지막 공백 위치 찾기
      int lastSpaceIndex = truncated.lastIndexOf(' ');
      if (lastSpaceIndex != -1) {
        truncated = truncated.substring(0, lastSpaceIndex);
      }
    }

    return truncated + '...';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        ...widget.reviews.map((review) {
          final shortContent = truncateWithEllipsis(review.content, 40);

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
                      review.nickname,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.035,
                          color: Colors.black
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      child: Text(
                        shortContent,
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
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.8,
                    minChildSize: 0.3,
                    maxChildSize: 0.9,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(screenWidth * 0.05)
                          ),
                        ),
                        child: Column(
                          children: [
                            // 상단 손잡이
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: screenWidth * 0.025
                              ),
                              child: Container(
                                width: screenWidth * 0.1,
                                height: screenWidth * 0.01,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(screenWidth * 0.005),
                                ),
                              ),
                            ),
                            // 리스트
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: widget.reviews.length,
                                itemBuilder: (context, index) {
                                  final review = widget.reviews[index];
                                  return Padding(
                                    padding: EdgeInsets.all(screenWidth * 0.03),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          review.nickname,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: screenWidth * 0.035
                                          ),
                                        ),
                                        SizedBox(height: screenWidth * 0.01),
                                        Text(
                                          review.content,
                                          style: TextStyle(
                                              fontSize: screenWidth * 0.033
                                          ),
                                        ),
                                        if (review.images.isNotEmpty) ...[
                                          SizedBox(height: screenWidth * 0.02),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: review.images.map((img) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                      right: screenWidth * 0.02
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(
                                                        screenWidth * 0.02
                                                    ),
                                                    child: Image.asset(
                                                      img,
                                                      width: screenWidth * 0.5,
                                                      height: screenWidth * 0.5,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          width: screenWidth * 0.5,
                                                          height: screenWidth * 0.5,
                                                          color: Colors.grey[300],
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            color: Colors.grey[500],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                        Divider(thickness: 1, color: Colors.grey[300]),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
    );
  }
}