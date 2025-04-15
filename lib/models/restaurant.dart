// models/restaurant.dart
import 'package:flutter/material.dart';

class Restaurant {
  final int id;
  final String name;
  final String distance;
  final List<String> images;
  final int likeCount;
  final int commentCount;
  final bool isAd;
  final List<Review> reviews;

  Restaurant({
    required this.id,
    required this.name,
    required this.distance,
    required this.images,
    required this.likeCount,
    required this.commentCount,
    this.isAd = false,
    required this.reviews,
  });

  // JSON에서 Restaurant 객체로 변환
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      distance: json['distance'],
      images: List<String>.from(json['images']),
      likeCount: json['likeCount'],
      commentCount: json['commentCount'],
      isAd: json['isAd'] ?? false,
      reviews: (json['reviews'] as List)
          .map((review) => Review.fromJson(review))
          .toList(),
    );
  }

  // Restaurant 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'distance': distance,
      'images': images,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isAd': isAd,
      'reviews': reviews.map((review) => review.toJson()).toList(),
    };
  }
}

class Review {
  final int id;
  final String nickname;
  final String content;
  final List<String> images;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.nickname,
    required this.content,
    required this.images,
    required this.createdAt,
  });

  // JSON에서 Review 객체로 변환
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      nickname: json['nickname'],
      content: json['content'],
      images: List<String>.from(json['images']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Review 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'content': content,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// 샘플 데이터 생성 함수
List<Restaurant> generateSampleRestaurants() {
  return [
    Restaurant(
      id: 1,
      name: '청진동',
      distance: '500m',
      images: ['assets/images/restaurant1_1.jpg', 'assets/images/restaurant1_2.jpg'],
      likeCount: 120,
      commentCount: 34,
      isAd: true,
      reviews: [
        Review(
          id: 1,
          nickname: '맛집탐험가',
          content: '정말 맛있었어요! 특히 스페셜 메뉴가 일품이었습니다. 다음에도 꼭 방문할 예정입니다.',
          images: ['assets/images/review1_1.jpg', 'assets/images/review1_2.jpg'],
          createdAt: DateTime.now().subtract(Duration(days: 2)),

        ),
        Review(
          id: 2,
          nickname: '먹방왕',
          content: '서비스도 좋고 음식도 맛있어요. 가격대비 만족합니다.',
          images: ['assets/images/review2_1.jpg'],
          createdAt: DateTime.now().subtract(Duration(days: 5)),
        ),
      ],
    ),
    Restaurant(
      id: 2,
      name: '강남 파스타',
      distance: '1.2km',
      images: ['assets/images/restaurant2_1.jpg', 'assets/images/restaurant2_2.jpg'],
      likeCount: 85,
      commentCount: 22,
      reviews: [
        Review(
          id: 3,
          nickname: '파스타러버',
          content: '크림 파스타가 정말 부드럽고 맛있어요. 파스타 면의 익힘 정도도 완벽했습니다.',
          images: ['assets/images/review3_1.jpg'],
          createdAt: DateTime.now().subtract(Duration(days: 1)),
        ),
      ],
    ),
    Restaurant(
      id: 3,
      name: '동네 감자탕',
      distance: '0.8km',
      images: ['assets/images/restaurant3_1.jpg'],
      likeCount: 210,
      commentCount: 56,
      isAd: false,
      reviews: [
        Review(
          id: 4,
          nickname: '전통음식마니아',
          content: '뼈에 붙은 고기가 정말 많고 양도 푸짐해요. 해장하기 좋습니다!',
          images: ['assets/images/review4_1.jpg', 'assets/images/review4_2.jpg'],
          createdAt: DateTime.now().subtract(Duration(days: 3)),
        ),
        Review(
          id: 5,
          nickname: '맛집헌터',
          content: '국물이 진하고 감자가 정말 부드러웠어요. 직원분들도 친절하셨습니다.',
          images: [],
          createdAt: DateTime.now().subtract(Duration(days: 7)),
        ),
      ],
    ),
    Restaurant(
      id: 4,
      name: '가메이',
      distance: '600m',
      images: ['assets/images/restaurant3_1.jpg'],
      likeCount: 210,
      commentCount: 56,
      isAd: false,
      reviews: [
        Review(
          id: 6,
          nickname: '일식충',
          content: '마 지리네!',
          images: ['assets/images/review4_1.jpg', 'assets/images/review4_2.jpg'],
          createdAt: DateTime.now().subtract(Duration(days: 3)),
        ),
        Review(
          id: 7,
          nickname: '맛집헌터',
          content: '국물이 진하고 감자가 정말 부드러웠어요. 직원분들도 친절하셨습니다.',
          images: [],
          createdAt: DateTime.now().subtract(Duration(days: 7)),
        ),

      ],
    ),
    Restaurant(
      id: 5,
      name: '고수찜닭',
      distance: '830m',
      images: ['assets/images/restaurant3_1.jpg'],
      likeCount: 210,
      commentCount: 56,
      isAd: false,
      reviews: [
        Review(
          id: 8,
          nickname: '그냥충',
          content: '마 지리네!',
          images: ['assets/images/review4_1.jpg', 'assets/images/review4_2.jpg'],
          createdAt: DateTime.now().subtract(Duration(days: 3)),
        ),
        Review(
          id: 9,
          nickname: '맛집헌터',
          content: '국물이 진하고 직원분들도 친절하셨습니다.',
          images: [],
          createdAt: DateTime.now().subtract(Duration(days: 7)),
        ),

      ],
    ),

    Restaurant(
      id: 5,
      name: '성화해장국',
      distance: '830m',
      images: ['assets/images/restaurant3_1.jpg'],
      likeCount: 210,
      commentCount: 56,
      isAd: false,
      reviews: [
        Review(
          id: 8,
          nickname: '그냥충',
          content: '마 지리네!',
          images: ['assets/images/review4_1.jpg', 'assets/images/review4_2.jpg'],
          createdAt: DateTime.now().subtract(Duration(days: 3)),
        ),
        Review(
          id: 9,
          nickname: '맛집헌터',
          content: '국물이 진하고 직원분들도 친절하셨습니다.',
          images: [],
          createdAt: DateTime.now().subtract(Duration(days: 7)),
        ),

      ],
    ),

    Restaurant(
      id: 5,
      name: '온뚝',
      distance: '830m',
      images: ['assets/images/restaurant3_1.jpg'],
      likeCount: 210,
      commentCount: 56,
      isAd: true,
      reviews: [
        Review(
          id: 8,
          nickname: '그냥충',
          content: '마 지리네!',
          images: ['assets/images/review4_1.jpg', 'assets/images/review4_2.jpg'],
          createdAt: DateTime.now().subtract(Duration(days: 3)),
        ),
        Review(
          id: 9,
          nickname: '맛집헌터',
          content: '국물이 진하고 직원분들도 친절하셨습니다.',
          images: [],
          createdAt: DateTime.now().subtract(Duration(days: 7)),
        ),

      ],
    ),

    Restaurant(
      id: 5,
      name: '성화해장국',
      distance: '830m',
      images: ['assets/images/restaurant3_1.jpg'],
      likeCount: 210,
      commentCount: 56,
      isAd: false,
      reviews: [
        Review(
          id: 8,
          nickname: '그냥충',
          content: '마 지리네!',
          images: ['assets/images/review4_1.jpg', 'assets/images/review4_2.jpg'],
          createdAt: DateTime.now().subtract(Duration(days: 3)),
        ),
        Review(
          id: 9,
          nickname: '맛집헌터',
          content: '국물이 진하고 직원분들도 친절하셨습니다.',
          images: [],
          createdAt: DateTime.now().subtract(Duration(days: 7)),
        ),

      ],
    ),

    Restaurant(
      id: 5,
      name: '성화해장국',
      distance: '830m',
      images: ['assets/images/restaurant3_1.jpg'],
      likeCount: 210,
      commentCount: 56,
      isAd: false,
      reviews: [
        Review(
          id: 8,
          nickname: '그냥충',
          content: '마 지리네!',
          images: ['assets/images/review4_1.jpg', 'assets/images/review4_2.jpg'],
          createdAt: DateTime.now().subtract(Duration(days: 3)),
        ),
        Review(
          id: 9,
          nickname: '맛집헌터',
          content: '국물이 진하고 직원분들도 친절하셨습니다.',
          images: [],
          createdAt: DateTime.now().subtract(Duration(days: 7)),
        ),

      ],
    ),

    Restaurant(
      id: 5,
      name: '성화해장국',
      distance: '830m',
      images: ['assets/images/restaurant3_1.jpg'],
      likeCount: 210,
      commentCount: 56,
      isAd: false,
      reviews: [
        Review(
          id: 8,
          nickname: '그냥충',
          content: '마 지리네!',
          images: ['assets/images/review4_1.jpg', 'assets/images/review4_2.jpg'],
          createdAt: DateTime.now().subtract(Duration(days: 3)),
        ),
        Review(
          id: 9,
          nickname: '맛집헌터',
          content: '국물이 진하고 직원분들도 친절하셨습니다.',
          images: [],
          createdAt: DateTime.now().subtract(Duration(days: 7)),
        ),

      ],
    ),

    Restaurant(
      id: 5,
      name: '성화해장국',
      distance: '830m',
      images: ['assets/images/restaurant3_1.jpg'],
      likeCount: 210,
      commentCount: 56,
      isAd: false,
      reviews: [
        Review(
          id: 8,
          nickname: '그냥충',
          content: '마 지리네!',
          images: ['assets/images/review4_1.jpg', 'assets/images/review4_2.jpg'],
          createdAt: DateTime.now().subtract(Duration(days: 3)),
        ),
        Review(
          id: 9,
          nickname: '맛집헌터',
          content: '국물이 진하고 직원분들도 친절하셨습니다.',
          images: [],
          createdAt: DateTime.now().subtract(Duration(days: 7)),
        ),

      ],
    ),

  ];
}