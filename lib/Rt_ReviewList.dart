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
      shrinkWrap: true, // 필수!
      physics: NeverScrollableScrollPhysics(),
      children: [
        // 간략한 리뷰 미리보기
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

        // 리뷰 모두보기 버튼
        // '리뷰 모두보기' 텍스트를 포함한 버튼 영역
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 1.0),
          child: GestureDetector(

            onTap: () {
              // 바텀 시트를 띄움
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // 전체 높이 제어 가능하게 함
                backgroundColor: Colors.transparent, // 모서리 둥글게 하기 위해 배경 투명 설정
                builder: (context) {
                  // 사용자가 아래로 드래그하면 닫히는 스크롤 시트
                  return DraggableScrollableSheet(
                    initialChildSize: 0.8, // 시작 높이 (화면의 50%)
                    minChildSize: 0.3, // 최소 높이 (화면의 30%)
                    maxChildSize: 0.9, // 최대 높이 (화면의 90%)
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // 상단만 둥글게
                        ),
                        child: ListView.builder(
                          controller: scrollController, // 드래그로 컨트롤되게 연결
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            return Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  // 닉네임 출력
                                  Text(

                                    review.nickname,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  SizedBox(height: 4),
                                  // 리뷰 전체 내용 출력
                                  Text(
                                    review.content,
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  // 이미지가 있을 경우 가로 스크롤로 출력
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
                                  // 항목 간 구분선
                                  Divider(thickness: 1, color: Colors.grey[300]),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
            // 텍스트 스타일 (리뷰 모두보기)
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
