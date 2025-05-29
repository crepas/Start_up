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

  // 인하대 후문 정확한 좌표 (MapTab과 동일하게 설정)
  final double inhaBackGateLat = 37.45169;
  final double inhaBackGateLng = 126.65464;

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

      // 인하대 후문 중심으로 데이터 요청
      final queryParams = {
        'lat': inhaBackGateLat.toString(),
        'lng': inhaBackGateLng.toString(),
        'radius': '2000', // 2km 반경
        'limit': '50',
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
                .map((item) => _convertToRestaurant(item))
                .toList();
            filteredRestaurants = List.from(restaurants);
            _isLoading = false;
          });

          print('로드된 음식점 수: ${restaurants.length}');
          print('데이터 소스: ${data['source'] ?? 'database'}');
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
        restaurants = _getInhaDummyRestaurants();
        filteredRestaurants = List.from(restaurants);
      });
      _showErrorSnackBar('서버에서 데이터를 불러올 수 없어 샘플 데이터를 표시합니다.');
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
      } else if (item['lat'] != null && item['lng'] != null) {
        lat = _parseDouble(item['lat']);
        lng = _parseDouble(item['lng']);
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
      print('문제가 된 데이터: $item');
      return _createFallbackRestaurant(item);
    }
  }

  // 안전한 파싱 함수들
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
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
      print('리뷰 파싱 오류: $e');
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

  // 인하대 후문 주변 더미 데이터
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
        isAd: true,
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
        reviews: [
          Review(
            username: '고기사랑',
            comment: '후문에서 가장 맛있는 삼겹살집!',
            rating: 4.3,
            date: DateTime.now().subtract(Duration(days: 2)),
          ),
        ],
        images: ['assets/samgyupsal.png'],
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        reviewCount: 1,
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
        reviews: [
          Review(
            username: '커피매니아',
            comment: '공부하기 좋은 카페. 후문에서 가장 넓어요.',
            rating: 4.0,
            date: DateTime.now().subtract(Duration(hours: 12)),
          ),
        ],
        images: ['assets/restaurant.png'],
        createdAt: DateTime.now().subtract(Duration(days: 90)),
        reviewCount: 1,
        isOpen: true,
        hasParking: false,
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
          '인하대 후문 맛집',
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
                    '인하대 후문 맛집 정보를 불러오는 중...',
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
                                        selectedRestaurant: restaurant,
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