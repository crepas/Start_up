import 'package:flutter/material.dart';
import '../widgets/Filter.dart';
import '../widgets/ListView_AD.dart';
import '../widgets/ListView_RT.dart';
import '../models/restaurant.dart';
import '../widgets/TopAppbar.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 더미 데이터 생성
    final List<String> foodImages = [
      'assets/food1.png',
      'assets/food2.png',
      'assets/food3.png',
      'assets/food4.png',
    ];
    int imgIdx = 0;
    List<Restaurant> restaurants = [
      // AD 1개
      Restaurant(
        id: 'ad1',
        name: '광고 샐러드볼',
        address: '서울 강남구',
        roadAddress: '서울 강남구 테헤란로 1',
        lat: 0,
        lng: 0,
        categoryName: '샐러드',
        foodTypes: [],
        phone: '',
        placeUrl: '',
        priceRange: '',
        rating: 4.8,
        likes: 0,
        reviews: [],
        images: [foodImages[imgIdx++ % 4]],
        isLiked: false,
        isAd: true,
        isOpen: true,
        hasParking: false,
        hasDelivery: false,
        hasReservation: false,
        hasWifi: false,
        isPetFriendly: false,
        reviewCount: 0,
        createdAt: DateTime.now(),
      ),
      // RT 5개
      ...List.generate(5, (i) => Restaurant(
        id: 'rt${i+1}',
        name: '맛집 ${i+1}',
        address: '서울시 구로구 ${i+1}번지',
        roadAddress: '서울시 구로구 ${i+1}번지',
        lat: 0,
        lng: 0,
        categoryName: '한식',
        foodTypes: [],
        phone: '',
        placeUrl: '',
        priceRange: '',
        rating: 4.0 + i * 0.1,
        likes: 0,
        reviews: [],
        images: [foodImages[imgIdx++ % 4]],
        isLiked: false,
        isAd: false,
        isOpen: true,
        hasParking: false,
        hasDelivery: false,
        hasReservation: false,
        hasWifi: false,
        isPetFriendly: false,
        reviewCount: 0,
        createdAt: DateTime.now(),
      )),
      // AD 1개
      Restaurant(
        id: 'ad2',
        name: '광고 파스타',
        address: '서울 마포구',
        roadAddress: '서울 마포구 월드컵북로',
        lat: 0,
        lng: 0,
        categoryName: '파스타',
        foodTypes: [],
        phone: '',
        placeUrl: '',
        priceRange: '',
        rating: 4.7,
        likes: 0,
        reviews: [],
        images: [foodImages[imgIdx++ % 4]],
        isLiked: false,
        isAd: true,
        isOpen: true,
        hasParking: false,
        hasDelivery: false,
        hasReservation: false,
        hasWifi: false,
        isPetFriendly: false,
        reviewCount: 0,
        createdAt: DateTime.now(),
      ),
    ];

    return Scaffold(
      appBar: CommonAppBar(title: '맛집 리스트'),
      body: Column(
        children: [
          // 최상단에 필터
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Filter(
              onFilterChanged: (filters) {
                // 필터 변경 시 동작 (현재는 예시)
                print(filters);
              },
            ),
          ),
          // 나머지 영역
          Expanded(
            child: ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, idx) {
                final r = restaurants[idx];
                if (r.isAd) {
                  return ListViewAd(
                    restaurant: r,
                    isExpanded: false,
                    onTap: () {},
                  );
                } else {
                  return ListViewRt(
                    restaurant: r,
                    isExpanded: false,
                    onTap: () {},
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}