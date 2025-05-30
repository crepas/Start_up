import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';
import '../widgets/ListView_AD.dart';
import '../widgets/ListView_RT.dart';
import '../widgets/Filter.dart';
import '../widgets/Rt_image.dart';
import '../widgets/Rt_information.dart';
import '../widgets/Rt_ReviewList.dart';
import '../widgets/CustomSearchBar.dart';
import '../models/restaurant.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/api_config.dart';
import '../screens/MainScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class ListScreen extends StatefulWidget {
  final String? selectedCategory;
  final String? searchKeyword; // 검색 키워드 추가
  final List<Map<String, dynamic>>? searchResults; // 검색 결과 추가

  const ListScreen({
    Key? key,
    this.selectedCategory,
    this.searchKeyword,
    this.searchResults,
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
  bool _isSearchMode = false;

  // 현재 위치
  double _currentLat = 37.4516;
  double _currentLng = 126.7015;

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 화면 초기화
  Future<void> _initScreen() async {
    // 현재 위치 가져오기
    await _getCurrentLocation();

    // 검색 결과가 있으면 검색 모드로 시작
    if (widget.searchKeyword != null && widget.searchResults != null) {
      _isSearchMode = true;
      _convertSearchResultsToRestaurants();
    } else {
      // 기본 음식점 목록 로드
      _loadRestaurants();
    }
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    try {
      PermissionStatus status = await Permission.location.request();

      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        );

        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
        });
      }
    } catch (e) {
      print('위치 가져오기 오류: $e');
    }
  }

  // 검색 결과를 Restaurant 객체로 변환
  void _convertSearchResultsToRestaurants() {
    if (widget.searchResults == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      restaurants = widget.searchResults!.map((searchResult) {
        return Restaurant(
          id: searchResult['id']?.toString() ?? '',
          name: searchResult['place_name'] ?? '',
          address: searchResult['address_name'] ?? '',
          roadAddress: searchResult['road_address_name'] ?? '',
          lat: _parseDouble(searchResult['y'] ?? 0),
          lng: _parseDouble(searchResult['x'] ?? 0),
          categoryName: searchResult['category_name'] ?? '',
          foodTypes: _parseFoodTypesFromCategory(searchResult['category_name'] ?? ''),
          phone: searchResult['phone'] ?? '',
          placeUrl: searchResult['place_url'] ?? '',
          priceRange: '중간',
          rating: 4.0 + (searchResult['id'].hashCode % 10) / 10, // 임시 평점
          likes: 50 + (searchResult['id'].hashCode % 100),
          reviews: [],
          images: [_getCategoryImage(searchResult['category_name'] ?? '')],
          createdAt: DateTime.now(),
          reviewCount: searchResult['id'].hashCode % 50,
          isOpen: true,
          hasParking: searchResult['id'].hashCode % 2 == 0,
          hasDelivery: searchResult['id'].hashCode % 3 == 0,
        );
      }).toList();

      filteredRestaurants = List.from(restaurants);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('검색 결과 변환 오류: $e');
      setState(() {
        _isLoading = false;
        restaurants = [];
        filteredRestaurants = [];
      });
    }
  }

  // 카테고리에서 음식 타입 추출
  List<String> _parseFoodTypesFromCategory(String category) {
    List<String> parts = category.split(' > ');
    if (parts.length > 1) {
      return [parts[1]];
    } else if (parts.isNotEmpty) {
      return [parts[0]];
    }
    return ['기타'];
  }

  // 카테고리에 따른 이미지 반환
  String _getCategoryImage(String category) {
    if (category.contains('고기') || category.contains('삼겹살')) {
      return 'assets/samgyupsal.png';
    } else if (category.contains('갈비')) {
      return 'assets/myung_jin.png';
    } else if (category.contains('족발') || category.contains('보쌈')) {
      return 'assets/onki.png';
    } else if (category.contains('카페') || category.contains('커피')) {
      return 'assets/cafe.png';
    } else if (category.contains('중식')) {
      return 'assets/chinese.png';
    } else if (category.contains('일식')) {
      return 'assets/japanese.png';
    } else if (category.contains('분식')) {
      return 'assets/bunsik.png';
    } else {
      return 'assets/restaurant.png';
    }
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final baseUrl = getServerUrl();

      // MapTab과 동일한 방식으로 하이브리드 데이터 가져오기
      final queryParams = {
        'lat': _currentLat.toString(),
        'lng': _currentLng.toString(),
        'radius': '2000',
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
                .map((item) => _convertToRestaurant(item))
                .toList();
            filteredRestaurants = List.from(restaurants);
            _isLoading = false;
          });

          print('로드된 음식점 수: ${restaurants.length}');
          print('데이터 소스: ${data['source'] ?? 'unknown'}');
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

  // 서버 응답 데이터를 Restaurant 객체로 변환하는 함수 (기존 코드 유지)
  Restaurant _convertToRestaurant(Map<String, dynamic> item) {
    try {
      // 서버 응답이 이미 Restaurant 형태인 경우
      if (item.containsKey('_id') || item.containsKey('id')) {
        return Restaurant.fromJson(item);
      }

      // 카카오 API 형태의 데이터인 경우 변환
      return Restaurant(
        id: item['id']?.toString() ?? '',
        name: item['name'] ?? item['place_name'] ?? '',
        address: item['address'] ?? item['address_name'] ?? '',
        roadAddress: item['roadAddress'] ?? item['road_address_name'] ?? '',
        lat: _parseDouble(item['lat'] ?? item['y'] ?? 0),
        lng: _parseDouble(item['lng'] ?? item['x'] ?? 0),
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

  // 안전한 파싱 함수들 (기존 코드 유지)
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

  // 변환 실패 시 사용할 기본 Restaurant 객체 생성 (기존 코드 유지)
  Restaurant _createFallbackRestaurant(Map<String, dynamic> item) {
    return Restaurant(
      id: item['id']?.toString() ?? 'unknown',
      name: item['name']?.toString() ?? item['place_name']?.toString() ?? '음식점',
      address: item['address']?.toString() ?? item['address_name']?.toString() ?? '주소 정보 없음',
      roadAddress: item['roadAddress']?.toString() ?? item['road_address_name']?.toString() ?? '',
      lat: _currentLat,
      lng: _currentLng,
      categoryName: item['categoryName']?.toString() ?? item['category_name']?.toString() ?? '음식점',
      foodTypes: ['기타'],
      phone: item['phone']?.toString() ?? '',
      placeUrl: item['placeUrl']?.toString() ?? item['place_url']?.toString() ?? '',
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

  // 검색 결과 처리
  void _handleSearchResults(List<Restaurant> results) {
    setState(() {
      restaurants = results;
      filteredRestaurants = List.from(restaurants);
    });
  }

  // 검색 모드 변경
  void _handleSearchModeChanged(bool isSearchMode) {
    setState(() {
      _isSearchMode = isSearchMode;
      if (!isSearchMode) {
        _loadRestaurants();
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
          _isSearchMode ? '검색 결과' : '맛집 목록',
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(72),
          child: Column(
            children: [
              CustomSearchBar(
                onSearchResults: _handleSearchResults,
                currentLat: _currentLat,
                currentLng: _currentLng,
                isSearchMode: _isSearchMode,
                onSearchModeChanged: _handleSearchModeChanged,
              ),
              if (_isSearchMode)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    '검색 결과 (${filteredRestaurants.length}개)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
                          _isSearchMode ? '검색 중...' : '맛집 정보를 불러오는 중...',
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
                              _isSearchMode ? Icons.search_off : Icons.restaurant,
                              size: 80,
                              color: theme.hintColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _isSearchMode ? '검색 결과가 없습니다' : '조건에 맞는 맛집이 없습니다',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _isSearchMode ? '다른 키워드로 검색해보세요' : '필터 조건을 변경해보세요',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _isSearchMode
                            ? () async {
                                setState(() {
                                  filteredRestaurants = List.from(restaurants);
                                });
                                return;
                              }
                            : _loadRestaurants,
                        child: ListView.builder(
                          itemCount: filteredRestaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = filteredRestaurants[index];
                            final isExpanded = _expandedIndices.contains(index);

                            return Column(
                              children: [
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

                                if (isExpanded)
                                  AnimatedContainer(
                                    duration: _animationDuration,
                                    curve: Curves.easeInOut,
                                    color: Colors.white,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        RtImage(
                                            images: restaurant.images.isNotEmpty
                                                ? restaurant.images
                                                : ['assets/restaurant.png']),
                                        RtInformation(
                                          likes: restaurant.likes,
                                          reviewCount: restaurant.reviews.length,
                                          restaurant: restaurant,
                                          onMapPressed: () {
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.primary),
          SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}