import 'package:flutter/material.dart';

class Review {
  final String nickname;
  final String content;
  final List<String> images;

  Review({required this.nickname, required this.content, required this.images});
}

class ReviewList extends StatefulWidget {
  @override
  _ReviewListState createState() => _ReviewListState();
}

class _ReviewListState extends State<ReviewList> {
  final List<Review> reviews = [
    Review(
      nickname: '맛집헌터',
      content: '정말 맛있었어요! 추천! 다음에도 또 가고 싶어요! 고기 부드럽고 밑반찬도 굿굿굿!',
      images: [],
    ),
    Review(
      nickname: '배불곰',
      content: '양도 많고 분위기도 좋아요. 직원도 친절하고 음식도 빠르게 나왔어요.',
      images: [
        'assets/food1.png',
        'assets/food2.png',
      ],
    ),
  ];

  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // 각 리뷰 항목
        ...reviews.map((review) {
          final shortContent = review.content.length > 10
              ? review.content.substring(0, 10) + '...'
              : review.content;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0), // 살짝 여백 주기
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 닉네임과 리뷰 내용 나란히 표시
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.nickname,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isExpanded ? review.content : shortContent,
                        style: TextStyle(fontSize: 13, color: Colors.black),
                      ),
                    ),
                  ],
                ),

                // 이미지 (확장됐을 때만)
                if (isExpanded && review.images.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: review.images.map((img) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(img,
                                width: 80, height: 80, fit: BoxFit.cover),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // 구분선 (확장됐을 때만)
                if (isExpanded)
                  Divider(thickness: 1, color: Colors.grey[300]),
              ],
            ),
          );
        }).toList(),

        // 리뷰 모두보기 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
          child: GestureDetector(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Text(
              isExpanded ? '리뷰 간단히 보기' : '리뷰 모두보기',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey, // '리뷰 모두보기'를 회색으로 설정
              ),
            ),
          ),
        ),
      ],
    );
  }
}
