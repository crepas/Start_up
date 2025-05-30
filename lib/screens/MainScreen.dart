import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'HomeTab.dart';
import 'MapTab.dart';
import 'MenuTab.dart';
import 'ListScreen.dart';
import '../models/restaurant.dart';
import '../utils/api_config.dart';

class MainScreen extends StatefulWidget {
  final int initialTab; // 초기 탭 설정 추가
  final Restaurant? selectedRestaurant; // 선택된 음식점 정보

  const MainScreen({
    Key? key,
    this.initialTab = 0, // 기본값은 0 (홈 탭)
    this.selectedRestaurant,
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  bool _isLoading = true;
  List<Restaurant> _restaurants = [];

  // 인하대 후문 정확한 좌표
  final double inhaBackGateLat = 37.45169;
  final double inhaBackGateLng = 126.65464;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab; // 초기 탭 설정
    _loadRestaurants(); // 실제 음식점 데이터 로드
  }

  // 실제 음식점 데이터 로드
  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final baseUrl = getServerUrl();

      // 인하대 후문 중심으로 데이터 요청
      final queryParams = {
        'lat': inhaBackGateLat.toString(),
        'lng': inhaBackGateLng.toString(),
        'radius': '2000', // 2km 반경
        'limit': '20', // 홈 화면용으로 20개만
        'sort': 'rating',
      };

      final uri = Uri.parse('$baseUrl/restaurants').replace(
        queryParameters: queryParams,
      );

      print('홈 화면 API 호출 URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['restaurants'] != null) {
          setState(() {
            _restaurants = (data['restaurants'] as List)
                .map((item) => _convertToRestaurant(item))
                .toList();
            _isLoading = false;
          });

          print('홈 화면 로드된 음식점 수: ${_restaurants.length}');
        } else {
          throw Exception('No restaurants data in response');
        }
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      print('홈 화면 음식점 목록 로드 오류: $e');
      setState(() {
        _isLoading = false;
        // 오류 발생 시 더미 데이터로 초기화
        _restaurants = _getInhaDummyRestaurants();
      });
    }
  }

  // 서버 응답 데이터를 Restaurant 객체로 변환하는 함수
  Restaurant _convertToRestaurant(Map<String, dynamic> item) {
    try {
      // MongoDB location.coordinates 형식 처리
      double lat = inhaBackGateLat; // 기본값
      double lng = inhaBackGateLng; // 기본값

      if (item['location'] != null && item['location']['coordinates'] != null) {
        final coords = item['location']['coordinates'] as List;
        if (coords.length >= 2) {
          lng = _parseDouble(coords[0]); // 경도가 먼저
          lat = _parseDouble(coords[1]); // 위도가 나중
        }
      }

      return Restaurant(
        id: item['_id'] ?? item['id'] ?? '',
        name: item['name'] ?? '',
        address: item['address'] ?? '',
        roadAddress: item['roadAddress'] ?? item['road_address_name'] ?? '',
        lat: lat,
        lng: lng,
        categoryName: item['categoryName'] ?? item['category_name'] ?? '',
        foodTypes: _parseFoodTypes(item['foodTypes'] ?? []),
        phone: item['phone'] ?? '',
        placeUrl: item['placeUrl'] ?? item['place_url'] ?? '',
        priceRange: item['priceRange'] ?? '중간',
        rating: _parseDouble(item['rating'] ?? 0),
        likes: _parseInt(item['likes'] ?? 0),
        reviews: _parseReviews(item['reviews'] ?? []),
        images: _parseImages(item['images'] ?? []),
        createdAt: _parseDateTime(item['createdAt']),
        reviewCount: _parseInt(item['reviewCount'] ?? 0),
        isOpen: item['isOpen'] ?? true,
        hasParking: item['hasParking'] ?? false,
        hasDelivery: item['hasDelivery'] ?? false,
        isAd: item['isAd'] ?? false,
      );
    } catch (e) {
      print('데이터 변환 오류: $e');
      return _createFallbackRestaurant(item);
    }
  }

  // 안전한 파싱 함수들
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  List<String> _parseFoodTypes(dynamic value) {
    if (value == null) return ['기타'];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return ['기타'];
  }

  List<Review> _parseReviews(dynamic value) {
    if (value == null || value is! List) return [];
    try {
      return (value as List)
          .map((reviewData) => Review.fromJson(reviewData))
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<String> _parseImages(dynamic value) {
    if (value == null) return ['assets/restaurant.png'];
    if (value is List) {
      final images = value.map((e) => e.toString()).toList();
      return images.isEmpty ? ['assets/restaurant.png'] : images;
    }
    return ['assets/restaurant.png'];
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  // 변환 실패 시 사용할 기본 Restaurant 객체 생성
  Restaurant _createFallbackRestaurant(Map<String, dynamic> item) {
    return Restaurant(
      id: item['_id']?.toString() ?? item['id']?.toString() ?? 'unknown',
      name: item['name']?.toString() ?? '음식점',
      address: item['address']?.toString() ?? '인하대 후문 근처',
      roadAddress: item['roadAddress']?.toString() ?? '',
      lat: inhaBackGateLat,
      lng: inhaBackGateLng,
      categoryName: item['categoryName']?.toString() ?? '음식점',
      foodTypes: ['기타'],
      phone: item['phone']?.toString() ?? '',
      placeUrl: item['placeUrl']?.toString() ?? '',
      priceRange: '중간',
      rating: 4.0,
      likes: 50,
      reviews: [],
      images: ['assets/restaurant.png'],
      createdAt: DateTime.now(),
      reviewCount: 0,
      isOpen: true,
      hasParking: false,
      hasDelivery: false,
    );
  }

  // 인하대 후문 주변 더미 데이터 (백업용)
  List<Restaurant> _getInhaDummyRestaurants() {
    return [
      Restaurant(
        id: '1',
        name: '인하반점',
        address: '인천 미추홀구 용현동 산1-1',
        roadAddress: '인천 미추홀구 인하로 12',
        lat: 37.4495,
        lng: 126.7012,
        categoryName: '음식점 > 중식 > 중화요리',
        foodTypes: ['중식', '짜장면'],
        phone: '032-867-0582',
        placeUrl: '',
        priceRange: '저렴',
        rating: 4.1,
        likes: 95,
        reviews: [],
        images: ['assets/restaurant.png'],
        createdAt: DateTime.now().subtract(Duration(days: 60)),
        reviewCount: 0,
        isOpen: true,
        hasParking: false,
        hasDelivery: true,
      ),
      Restaurant(
        id: '2',
        name: '후문 삼겹살',
        address: '인천 미추홀구 용현동 618-1',
        roadAddress: '인천 미추홀구 인하로 100',
        lat: 37.4492,
        lng: 126.7015,
        categoryName: '음식점 > 한식 > 고기구이',
        foodTypes: ['한식', '고기'],
        phone: '032-123-4567',
        placeUrl: '',
        priceRange: '중간',
        rating: 4.3,
        likes: 76,
        reviews: [],
        images: ['assets/restaurant.png'],
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        reviewCount: 0,
        isOpen: true,
        hasParking: true,
        hasDelivery: false,
      ),
      Restaurant(
        id: '3',
        name: '후문카페',
        address: '인천 미추홀구 용현동 253',
        roadAddress: '인천 미추홀구 인하로 150',
        lat: 37.4498,
        lng: 126.7008,
        categoryName: '음식점 > 카페 > 커피전문점',
        foodTypes: ['카페', '커피'],
        phone: '032-456-7890',
        placeUrl: '',
        priceRange: '저렴',
        rating: 4.0,
        likes: 120,
        reviews: [],
        images: ['assets/restaurant.png'],
        createdAt: DateTime.now().subtract(Duration(days: 90)),
        reviewCount: 0,
        isOpen: true,
        hasParking: false,
        hasDelivery: false,
      ),
    ];
  }

  // 카테고리별 음식점 필터링
  List<Restaurant> _getRestaurantsByCategory(String category) {
    switch (category) {
      case '한식':
        return _restaurants.where((r) =>
        r.foodTypes.any((type) => type.contains('한식')) ||
            r.categoryName.contains('한식')
        ).take(5).toList();
      case '중식':
        return _restaurants.where((r) =>
        r.foodTypes.any((type) => type.contains('중식')) ||
            r.categoryName.contains('중식')
        ).take(5).toList();
      case '일식':
        return _restaurants.where((r) =>
        r.foodTypes.any((type) => type.contains('일식')) ||
            r.categoryName.contains('일식')
        ).take(5).toList();
      case '양식':
        return _restaurants.where((r) =>
        r.foodTypes.any((type) => type.contains('양식')) ||
            r.categoryName.contains('양식')
        ).take(5).toList();
      case '카페':
        return _restaurants.where((r) =>
        r.foodTypes.any((type) => type.contains('카페')) ||
            r.categoryName.contains('카페')
        ).take(5).toList();
      default:
        return _restaurants.take(5).toList();
    }
  }

  // 카테고리 선택 시 ListScreen으로 이동
  void _navigateToListScreen(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListScreen(selectedCategory: category),
      ),
    );
  }

  // 상태가 변경될 때마다 위젯 다시 생성 - 중요!
  Widget _getBodyWidget() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTabContent();
      case 1:
        return MapTab(selectedRestaurant: widget.selectedRestaurant);
      case 2:
        return MenuTab();
      default:
        return _buildHomeTabContent();
    }
  }

  // 홈 탭 콘텐츠 빌드 (실제 음식점 데이터 사용)
  Widget _buildHomeTabContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            SizedBox(height: 16),
            Text(
              '인하대 후문 맛집 정보를 불러오는 중...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '위치나 음식을 검색해보세요!',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0.0),
              ),
            ),
          ),

          // 환영 메시지 배너
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.0),
            color: colorScheme.secondary.withOpacity(0.3),
            child: Center(
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyLarge,
                  children: [
                    TextSpan(text: '✨ '),
                    TextSpan(
                      text: '인하대 후문 맛집 랭킹',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' ✨'),
                  ],
                ),
              ),
            ),
          ),

          // 카테고리 버튼
          Container(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryButton('한식'),
                _buildCategoryButton('중식'),
                _buildCategoryButton('일식'),
                _buildCategoryButton('양식'),
                _buildCategoryButton('카페'),
                _buildCategoryButton('전체', isSpecial: true),
              ],
            ),
          ),

          // 실제 음식점 목록 섹션들
          Expanded(
            child: ListView(
              children: [
                // 한식 맛집 섹션
                _buildRestaurantSection('🍚 한식 맛집', '한식'),
                // 중식 맛집 섹션
                _buildRestaurantSection('🥟 중식 맛집', '중식'),
                // 일식 맛집 섹션
                _buildRestaurantSection('🍣 일식 맛집', '일식'),
                // 양식 맛집 섹션
                _buildRestaurantSection('🍝 양식 맛집', '양식'),
                // 카페 섹션
                _buildRestaurantSection('☕ 카페', '카페'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 카테고리 버튼 빌드
  Widget _buildCategoryButton(String category, {bool isSpecial = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => _navigateToListScreen(category),
      child: Container(
        margin: EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSpecial ? colorScheme.primary.withOpacity(0.1) : theme.cardColor,
                border: Border.all(
                  color: isSpecial ? colorScheme.primary : theme.dividerColor,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSpecial ? colorScheme.primary : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 음식점 섹션 빌드
  Widget _buildRestaurantSection(String title, String category) {
    final theme = Theme.of(context);
    final restaurants = _getRestaurantsByCategory(category);

    if (restaurants.isEmpty) {
      return SizedBox.shrink(); // 해당 카테고리 음식점이 없으면 섹션 숨김
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToListScreen(category),
                child: Text('더보기'),
              ),
            ],
          ),
        ),

        // 음식점 카드 슬라이더
        Container(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return Container(
                width: 160,
                margin: EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildRestaurantCard(restaurant),
              );
            },
          ),
        ),
      ],
    );
  }

  // 음식점 카드 빌드
  Widget _buildRestaurantCard(Restaurant restaurant) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 음식점 이미지
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                width: double.infinity,
                color: theme.cardColor,
                child: restaurant.images.isNotEmpty
                    ? (restaurant.images.first.startsWith('http')
                    ? Image.network(
                  restaurant.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                )
                    : Image.asset(
                  restaurant.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                ))
                    : _buildPlaceholderImage(),
              ),
            ),
          ),

          // 음식점 정보
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 음식점 이름
                  Text(
                    restaurant.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 카테고리
                  Text(
                    restaurant.foodTypes.isNotEmpty
                        ? restaurant.foodTypes.first
                        : '음식점',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 평점과 좋아요
                  Row(
                    children: [
                      Icon(Icons.star, color: colorScheme.primary, size: 16),
                      SizedBox(width: 2),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall,
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.favorite, color: Colors.red, size: 16),
                      SizedBox(width: 2),
                      Text(
                        restaurant.likes.toString(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 플레이스홀더 이미지 빌드
  Widget _buildPlaceholderImage() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.cardColor,
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 40,
          color: theme.hintColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // 바디에 동적으로 생성된 위젯 할당
      body: _getBodyWidget(),

      // 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '지도',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: '메뉴',
          ),
        ],
        selectedItemColor: colorScheme.primary,
      ),
    );
  }
}