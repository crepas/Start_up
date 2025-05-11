import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';     // 하단 네비게이션 바 위젯
import '../widgets/ListView_AD.dart';      // 광고 항목 위젯
import '../widgets/ListView_RT.dart';      // 일반 식당 항목 위젯
import '../widgets/Filter.dart';           // 필터 위젯
import '../widgets/Rt_image.dart';         // 식당 이미지 위젯
import '../widgets/Rt_information.dart';   // 식당 정보 위젯
import '../widgets/Rt_ReviewList.dart';    // 식당 리뷰 목록 위젯
import '../models/restaurant.dart';        // 식당 데이터 모델

/// 식당 목록 화면을 관리하는 StatefulWidget
/// 
/// 이 위젯은 식당 목록을 표시하고 필터링하는 화면을 구현합니다.
/// 
/// [selectedCategory] - 선택된 카테고리 (거리순, 가격대, 평점, 카테고리)
///   - 'distance': 거리순 정렬
///   - 'price': 가격대별 필터링
///   - 'rating': 평점 기준 필터링
///   - 'category': 음식 카테고리별 필터링
class ListScreen extends StatefulWidget {
  final String? selectedCategory;

  const ListScreen({
    Key? key,
    this.selectedCategory,
  }) : super(key: key);

  @override
  _ListScreenState createState() => _ListScreenState();
}

/// ListScreen의 상태 관리 클래스
/// 
/// 이 클래스는 식당 목록의 상태를 관리하고 UI를 구성합니다.
/// 주요 기능:
/// - 식당 데이터 관리
/// - 필터링 및 정렬
/// - UI 상태 관리 (확장/축소 등)
class _ListScreenState extends State<ListScreen> {
  // UI 관련 상수
  static const double _bannerHeight = 0.2;        // 배너 높이 비율 (화면 너비 기준)
  static const double _bannerMargin = 0.5;        // 배너 마진 비율 (기준 단위 기준)
  static const Duration _animationDuration = Duration(milliseconds: 300);  // 애니메이션 지속 시간
  static const double _bottomSpacing = 3.0;       // 하단 여백 (픽셀 단위)

  // 상태 변수
  int _currentIndex = 0;                          // 현재 선택된 하단 네비게이션 바 인덱스
  Set<int> _expandedIndices = {};                 // 현재 확장된 항목들의 인덱스 집합
  late List<Restaurant> restaurants;              // 식당 데이터 목록

  @override
  void initState() {
    super.initState();
    // 초기 데이터 로드
    restaurants = _generateSampleRestaurants();
    
    // 카테고리 필터링 적용
    if (widget.selectedCategory != null) {
      restaurants = restaurants.where((restaurant) {
        switch (widget.selectedCategory) {
          case 'distance':
            return true;  // TODO: 거리순 정렬 로직 구현 필요
                    // - 현재 위치 기준으로 거리 계산
                    // - 가까운 순서대로 정렬
          case 'price':
            return restaurant.priceRange == '중간';  // TODO: 가격대 필터링 로직 개선 필요
                    // - 저렴/중간/고급 구분
                    // - 가격대별 필터링 옵션 추가
          case 'rating':
            return restaurant.rating >= 4.0;  // TODO: 평점 기준 조정 필요
                    // - 평점 기준을 사용자 설정으로 변경
                    // - 평점 범위 설정 기능 추가
          case 'category':
            return restaurant.categoryName == '한식';  // TODO: 카테고리 필터링 로직 개선 필요
                    // - 다중 카테고리 선택 지원
                    // - 카테고리별 하위 분류 추가
          default:
            return true;
        }
      }).toList();
    }
  }

  /// 샘플 식당 데이터 생성 함수
  /// 
  /// 실제 서비스에서는 API를 통해 데이터를 가져와야 함
  /// 
  /// 반환값:
  /// - List<Restaurant>: 식당 정보 목록
  /// 
  /// TODO:
  /// - API 연동 구현
  /// - 데이터 캐싱 구현
  /// - 에러 처리 추가
  List<Restaurant> _generateSampleRestaurants() {
    return [
      Restaurant(
        id: '1',
        name: '청진동',
        address: '서울시 강남구',
        roadAddress: '서울시 강남구 테헤란로 123',
        lat: 37.5665,
        lng: 126.9780,
        categoryName: '한식',
        foodTypes: ['한식', '분식'],
        phone: '02-123-4567',
        placeUrl: 'https://example.com',
        priceRange: '중간',
        rating: 4.5,
        likes: 120,
        reviews: [
          Review(
            username: '맛집탐험가',
            comment: '정말 맛있었어요!',
            rating: 4.5,
            date: DateTime.now(),
            images: [
              'assets/food1.png',
              'assets/food2.png',
              'assets/food3.png',
            ],
          ),
        ],
        images: ['assets/rt1.png', 'assets/food1.png'],
        isLiked: true,
        isAd: true,
        isOpen: true,
        hasParking: true,
        hasDelivery: true,
        hasReservation: true,
        hasWifi: true,
        isPetFriendly: false,
        reviewCount: 1,
        createdAt: DateTime.now(),
      ),
      Restaurant(
        id: '2',
        name: '강남 파스타',
        address: '서울시 강남구',
        roadAddress: '서울시 강남구 테헤란로 456',
        lat: 37.5666,
        lng: 126.9781,
        categoryName: '양식',
        foodTypes: ['파스타', '피자'],
        phone: '02-234-5678',
        placeUrl: 'https://example.com',
        priceRange: '고급',
        rating: 4.3,
        likes: 85,
        reviews: [
          Review(
            username: '파스타러버',
            comment: '크림 파스타가 정말 맛있어요!',
            rating: 4.3,
            date: DateTime.now(),
            images: [
              'assets/food1.png',
              'assets/food2.png',
              'assets/food3.png',
            ],
          ),
        ],
        images: ['assets/food2.png', 'assets/food2.png'],
        isLiked: false,
        isAd: false,
        isOpen: true,
        hasParking: true,
        hasDelivery: false,
        hasReservation: true,
        hasWifi: true,
        isPetFriendly: false,
        reviewCount: 1,
        createdAt: DateTime.now(),
      ),
      Restaurant(
        id: '3',
        name: '용두동 마라샹궈',
        address: '서울시 강남구',
        roadAddress: '서울시 강남구 테헤란로 789',
        lat: 37.5667,
        lng: 126.9782,
        categoryName: '중식',
        foodTypes: ['중식', '마라샹궈'],
        phone: '02-345-6789',
        placeUrl: 'https://example.com',
        priceRange: '중간',
        rating: 4.7,
        likes: 150,
        reviews: [
          Review(
            username: '중식러버',
            comment: '마라샹궈가 정말 맵고 맛있어요!',
            rating: 4.7,
            date: DateTime.now(),
            images: [
              'https://example.com/review3_1.jpg',
              'https://example.com/review3_2.jpg',
            ],
          ),
        ],
        images: ['assets/food3_1.jpg', 'assets/food3_2.jpg'],
        isLiked: true,
        isAd: false,
        isOpen: true,
        hasParking: false,
        hasDelivery: true,
        hasReservation: false,
        hasWifi: true,
        isPetFriendly: false,
        reviewCount: 1,
        createdAt: DateTime.now(),
      ),
      Restaurant(
        id: '4',
        name: '스시코우지',
        address: '서울시 강남구',
        roadAddress: '서울시 강남구 테헤란로 101',
        lat: 37.5668,
        lng: 126.9783,
        categoryName: '일식',
        foodTypes: ['초밥', '회'],
        phone: '02-456-7890',
        placeUrl: 'https://example.com',
        priceRange: '고급',
        rating: 4.8,
        likes: 200,
        reviews: [
          Review(
            username: '스시매니아',
            comment: '신선한 회와 초밥이 일품이에요!',
            rating: 4.8,
            date: DateTime.now(),
            images: [
              'https://example.com/review4_1.jpg',
              'https://example.com/review4_2.jpg',
            ],
          ),
        ],
        images: ['assets/food4_1.jpg', 'assets/food4_2.jpg'],
        isLiked: true,
        isAd: false,
        isOpen: true,
        hasParking: true,
        hasDelivery: false,
        hasReservation: true,
        hasWifi: true,
        isPetFriendly: false,
        reviewCount: 1,
        createdAt: DateTime.now(),
      ),
      Restaurant(
        id: '5',
        name: '카페 드 파리',
        address: '서울시 강남구',
        roadAddress: '서울시 강남구 테헤란로 202',
        lat: 37.5669,
        lng: 126.9784,
        categoryName: '카페/디저트',
        foodTypes: ['커피', '디저트'],
        phone: '02-567-8901',
        placeUrl: 'https://example.com',
        priceRange: '저렴',
        rating: 4.2,
        likes: 95,
        reviews: [
          Review(
            username: '카페인러버',
            comment: '분위기 좋고 커피도 맛있어요!',
            rating: 4.2,
            date: DateTime.now(),
            images: [
              'https://example.com/review5_1.jpg',
              'https://example.com/review5_2.jpg',
            ],
          ),
        ],
        images: ['assets/food5_1.jpg', 'assets/food5_2.jpg'],
        isLiked: false,
        isAd: false,
        isOpen: true,
        hasParking: false,
        hasDelivery: false,
        hasReservation: false,
        hasWifi: true,
        isPetFriendly: true,
        reviewCount: 1,
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// 항목 확장/축소 토글 함수
  /// 
  /// [index] - 토글할 항목의 인덱스
  /// 
  /// 동작:
  /// - 이미 확장된 항목이면 축소
  /// - 축소된 항목이면 확장
  /// 
  /// TODO:
  /// - 애니메이션 개선
  /// - 다중 선택 지원
  void toggleExpanded(int index) {
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        _expandedIndices.add(index);
      }
    });
  }

  /// 배너 이미지 위젯 생성
  /// 
  /// [screenWidth] - 화면 너비
  /// [baseUnit] - 기준 단위 (화면 너비 / 360)
  /// 
  /// 반환값:
  /// - Widget: 배너 이미지를 포함한 컨테이너
  /// 
  /// 기능:
  /// - 배너 이미지 표시
  /// - 이미지 로드 실패 시 에러 UI 표시
  /// - 반응형 크기 조정
  Widget _buildBannerImage(double screenWidth, double baseUnit) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: baseUnit * _bannerMargin,
        horizontal: baseUnit * _bannerMargin,
      ),
      width: double.infinity,
      height: screenWidth * _bannerHeight,
      color: Colors.white,
      child: Image.asset(
        'assets/banner.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.grey[600]),
                  SizedBox(height: 8),
                  Text(
                    '배너 이미지를 불러올 수 없습니다',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 식당 목록 아이템 위젯 생성
  /// 
  /// [restaurant] - 표시할 식당 정보
  /// [index] - 아이템의 인덱스
  /// 
  /// 반환값:
  /// - Widget: 식당 정보를 표시하는 컬럼 위젯
  /// 
  /// 기능:
  /// - 광고/일반 식당 구분 표시
  /// - 확장/축소 상태에 따른 추가 정보 표시
  /// - 애니메이션 효과
  Widget _buildRestaurantItem(Restaurant restaurant, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        restaurant.isAd
            ? ListViewAd(
                key: ValueKey(restaurant.id),
                restaurant: restaurant,
                isExpanded: _expandedIndices.contains(index),
                onTap: () => toggleExpanded(index),
              )
            : ListViewRt(
                key: ValueKey(restaurant.id),
                restaurant: restaurant,
                isExpanded: _expandedIndices.contains(index),
                onTap: () => toggleExpanded(index),
              ),
        if (_expandedIndices.contains(index))
          AnimatedContainer(
            duration: _animationDuration,
            curve: Curves.easeInOut,
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RtImage(images: restaurant.images),
                RtInformation(
                  likes: restaurant.likes,
                  reviewCount: restaurant.reviews.length,
                ),
                RtReviewList(reviews: restaurant.reviews),
                SizedBox(height: _bottomSpacing),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseUnit = screenWidth / 360;  // 기준 단위 계산 (360dp 기준)

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 배너 이미지
            _buildBannerImage(screenWidth, baseUnit),

            // 필터
            Filter(
              initialFilter: widget.selectedCategory,
            ),

            // 식당 목록
            Expanded(
              child: ListView.builder(
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  return RepaintBoundary(  // 성능 최적화를 위한 RepaintBoundary
                    child: _buildRestaurantItem(restaurants[index], index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // 하단 네비게이션 바
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    // 메모리 정리
    // TODO: 리소스 해제 로직 추가
    super.dispose();
  }
}