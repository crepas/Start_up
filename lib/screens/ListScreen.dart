import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';
import '../widgets/ListView_AD.dart';
import '../widgets/ListView_RT.dart';
import '../widgets/Filter.dart';
import '../widgets/Rt_image.dart';
import '../widgets/Rt_information.dart';
import '../widgets/Rt_ReviewList.dart';
import '../models/restaurant.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/api_config.dart';
import '../screens/MainScreen.dart';

class ListScreen extends StatefulWidget {
  final String? selectedCategory;

  const ListScreen({
    Key? key,
    this.selectedCategory,
  }) : super(key: key);

  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  static const double _bannerHeight = 0.2;
  static const double _bannerMargin = 0.5;
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const double _bottomSpacing = 3.0;

  int _currentIndex = 0;
  Set<int> _expandedIndices = {};
  List<Restaurant> restaurants = [];
  List<Restaurant> filteredRestaurants = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final baseUrl = getServerUrl();

      // 현재 위치 기준으로 음식점 조회 (인천 용현동 좌표)
      final queryParams = {
        'lat': '37.4516',
        'lng': '126.7015',
        'radius': '5000',
        'limit': '20',
        'sort': 'rating',
      };

      final uri = Uri.parse('$baseUrl/restaurants').replace(
        queryParameters: queryParams,
      );

      print('API 호출 URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('API 응답 상태: ${response.statusCode}');
      print('API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['restaurants'] != null) {
          setState(() {
            restaurants = (data['restaurants'] as List)
                .map((item) => Restaurant.fromJson(item))
                .toList();
            filteredRestaurants = List.from(restaurants);
            _isLoading = false;
          });

          print('로드된 음식점 수: ${restaurants.length}');
        } else {
          throw Exception('No restaurants data in response');
        }
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      print('음식점 목록 로드 오류: $e');
      setState(() {
        _isLoading = false;
        // 오류 발생 시 더미 데이터로 초기화
        restaurants = _getDummyRestaurants();
        filteredRestaurants = List.from(restaurants);
      });
      _showErrorSnackBar('서버에서 데이터를 불러올 수 없어 샘플 데이터를 표시합니다.');
    }
  }

  List<Restaurant> _getDummyRestaurants() {
    return [
      Restaurant(
        id: '1',
        name: '장터삼겹살',
        address: '인천 미추홀구 용현동 618-1',
        roadAddress: '인천 미추홀구 인하로 100',
        lat: 37.4512,
        lng: 126.7019,
        categoryName: '음식점 > 한식 > 고기구이',
        foodTypes: ['한식', '고기'],
        phone: '032-123-4567',
        placeUrl: '',
        priceRange: '중간',
        rating: 4.5,
        likes: 120,
        reviews: [
          Review(
            username: '맛집헌터',
            comment: '삼겹살이 정말 맛있어요! 직원분들도 친절하고 분위기도 좋습니다.',
            rating: 4.5,
            date: DateTime.now().subtract(Duration(days: 2)),
          ),
          Review(
            username: '용현동주민',
            comment: '자주 가는 단골집입니다. 고기 질이 좋아요.',
            rating: 4.0,
            date: DateTime.now().subtract(Duration(days: 5)),
          ),
        ],
        images: ['assets/samgyupsal.png'],
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        reviewCount: 2,
        isOpen: true,
        hasParking: true,
        hasDelivery: false,
      ),
      Restaurant(
        id: '2',
        name: '명륜진사갈비',
        address: '인천 미추홀구 용현동 621-5',
        roadAddress: '인천 미추홀구 인하로 200',
        lat: 37.4522,
        lng: 126.7032,
        categoryName: '음식점 > 한식 > 갈비',
        foodTypes: ['한식', '갈비'],
        phone: '032-123-4568',
        placeUrl: '',
        priceRange: '중간',
        rating: 4.3,
        likes: 89,
        reviews: [
          Review(
            username: '갈비러버',
            comment: '갈비가 부드럽고 양념이 맛있어요!',
            rating: 4.5,
            date: DateTime.now().subtract(Duration(days: 1)),
          ),
        ],
        images: ['assets/myung_jin.png'],
        createdAt: DateTime.now().subtract(Duration(days: 45)),
        reviewCount: 1,
        isOpen: true,
        hasParking: false,
        hasDelivery: true,
      ),
      Restaurant(
        id: '3',
        name: '온기족발',
        address: '인천 미추홀구 용현동 615-2',
        roadAddress: '인천 미추홀구 인하로 300',
        lat: 37.4508,
        lng: 126.7027,
        categoryName: '음식점 > 한식 > 족발보쌈',
        foodTypes: ['한식', '족발'],
        phone: '032-123-4569',
        placeUrl: '',
        priceRange: '저렴',
        rating: 4.2,
        likes: 76,
        reviews: [
          Review(
            username: '족발좋아',
            comment: '족발이 쫄깃하고 맛있어요. 가격도 합리적!',
            rating: 4.2,
            date: DateTime.now().subtract(Duration(days: 3)),
          ),
        ],
        images: ['assets/onki.png'],
        createdAt: DateTime.now().subtract(Duration(days: 20)),
        reviewCount: 1,
        isOpen: false,
        hasParking: true,
        hasDelivery: true,
      ),
      Restaurant(
        id: '4',
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
        reviews: [
          Review(
            username: '중식러버',
            comment: '짜장면 맛집! 학생들이 많이 찾는 곳이에요.',
            rating: 4.0,
            date: DateTime.now().subtract(Duration(days: 1)),
          ),
        ],
        images: ['assets/restaurant.png'],
        createdAt: DateTime.now().subtract(Duration(days: 60)),
        reviewCount: 1,
        isOpen: true,
        hasParking: false,
        hasDelivery: true,
        isAd: true, // 광고 표시
      ),
      Restaurant(
        id: '5',
        name: '스타벅스 인하대점',
        address: '인천 미추홀구 용현동 253',
        roadAddress: '인천 미추홀구 인하로 100',
        lat: 37.4505,
        lng: 126.7020,
        categoryName: '음식점 > 카페 > 커피전문점',
        foodTypes: ['카페', '커피'],
        phone: '1522-3232',
        placeUrl: '',
        priceRange: '중간',
        rating: 4.0,
        likes: 150,
        reviews: [
          Review(
            username: '커피매니아',
            comment: '공부하기 좋은 카페입니다. 와이파이도 잘 터져요.',
            rating: 4.0,
            date: DateTime.now().subtract(Duration(hours: 12)),
          ),
        ],
        images: ['assets/restaurant.png'],
        createdAt: DateTime.now().subtract(Duration(days: 90)),
        reviewCount: 1,
        isOpen: true,
        hasParking: true,
        hasDelivery: false,
        hasWifi: true,
      ),
    ];
  }

  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      filteredRestaurants = restaurants.where((restaurant) {
        bool matches = true;

        // 가격대 필터링
        if (filters['priceRange'] != null) {
          String filterRange = filters['priceRange'];
          String restaurantRange = restaurant.priceRange;

          // 필터 매핑
          Map<String, String> priceMapping = {
            'low': '저렴',
            'medium': '중간',
            'high': '고가',
          };

          String mappedFilter = priceMapping[filterRange] ?? filterRange;
          matches = matches && (restaurantRange == mappedFilter);
        }

        // 평점 필터링
        if (filters['minRating'] != null) {
          matches = matches && restaurant.rating >= filters['minRating'];
        }

        // 카테고리 필터링
        if (filters['categories'] != null && filters['categories'].isNotEmpty) {
          bool categoryMatch = false;
          for (String category in filters['categories']) {
            if (restaurant.categoryName.contains(category) ||
                restaurant.foodTypes.contains(category)) {
              categoryMatch = true;
              break;
            }
          }
          matches = matches && categoryMatch;
        }

        return matches;
      }).toList();

      // 정렬 적용
      String sortBy = filters['sortBy'] ?? 'rating';
      switch (sortBy) {
        case 'rating':
          filteredRestaurants.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'reviews':
          filteredRestaurants.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
          break;
        case 'distance':
        // 거리순 정렬 (현재는 임의로 정렬)
          filteredRestaurants.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
    });
  }

  void _showErrorSnackBar(String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void toggleExpanded(int index) {
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        _expandedIndices.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '맛집 목록',
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 필터 섹션
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.cardColor,
            child: Filter(
              onFilterChanged: _applyFilters,
            ),
          ),

          // 음식점 목록
          Expanded(
            child: _isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '맛집 정보를 불러오는 중...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
                : filteredRestaurants.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 80,
                    color: theme.hintColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '조건에 맞는 맛집이 없습니다',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '필터 조건을 변경해보세요',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadRestaurants,
              child: ListView.builder(
                itemCount: filteredRestaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = filteredRestaurants[index];
                  final isExpanded = _expandedIndices.contains(index);

                  return Column(
                    children: [
                      // 광고 또는 일반 식당 카드
                      restaurant.isAd
                          ? ListViewAd(
                        restaurant: restaurant,
                        isExpanded: isExpanded,
                        onTap: () => toggleExpanded(index),
                      )
                          : ListViewRt(
                        restaurant: restaurant,
                        isExpanded: isExpanded,
                        onTap: () => toggleExpanded(index),
                      ),

                      // 확장된 상세 정보
                      if (isExpanded)
                        AnimatedContainer(
                          duration: _animationDuration,
                          curve: Curves.easeInOut,
                          color: Colors.white,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RtImage(images: restaurant.images.isNotEmpty
                                  ? restaurant.images
                                  : ['assets/restaurant.png']),
                              RtInformation(
                                likes: restaurant.likes,
                                reviewCount: restaurant.reviews.length,
                                restaurant: restaurant,
                                onMapPressed: () {
                                  // 지도 탭으로 이동하면서 음식점 정보 전달
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MainScreen(
                                        initialTab: 1,
                                        selectedRestaurant: restaurant, // 음식점 정보 전달
                                      ),
                                    ),
                                  );
                                },
                              ),
                              RtReviewList(reviews: restaurant.reviews),
                              SizedBox(height: _bottomSpacing),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
}