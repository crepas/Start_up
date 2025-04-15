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
        'assets/food1.png',
      ],
    ),
  ];

  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        ...reviews.map((review) {
          final shortContent = review.content.length > 10
              ? review.content.substring(0, 10) + '...'
              : review.content;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        shortContent,
                        style: TextStyle(fontSize: 13, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 1.0),
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
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Column(
                          children: [
                            // 상단 손잡이
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            // 리스트
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: reviews.length,
                                itemBuilder: (context, index) {
                                  final review = reviews[index];
                                  return Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          review.nickname,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          review.content,
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        if (review.images.isNotEmpty) ...[
                                          SizedBox(height: 8),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: review.images.map((img) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(right: 8.0),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.asset(
                                                      img,
                                                      width: 200,
                                                      height: 200,
                                                      fit: BoxFit.cover,
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
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
