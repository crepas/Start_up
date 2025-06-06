import 'package:flutter/material.dart';
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
import 'MainScreen.dart';
import 'MapTab.dart';
import 'MenuTab.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class ListScreen extends StatefulWidget {
  final String? selectedCategory;
  final String? searchKeyword;
  final List<Map<String, dynamic>>? searchResults;
  final String? initialSearchText;

  const ListScreen({
    Key? key,
    this.selectedCategory,
    this.searchKeyword,
    this.searchResults,
    this.initialSearchText,
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
  // 필터 상태 변수 추가
  Map<String, dynamic> _currentFilters = {};

  // 인하대 후문 정확한 좌표 (MapTab과 동일하게 설정)
  final double inhaBackGateLat = 37.45169;
  final double inhaBackGateLng = 126.65464;

  @override
  void initState() {
    super.initState();
    print('ListScreen 초기화 - selectedCategory: ${widget.selectedCategory}');
    _initScreen();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 화면 초기화
  Future<void> _initScreen() async {
    await _getCurrentLocation();

    // 선택된 카테고리가 있으면 초기 필터 설정
    if (widget.selectedCategory != null && widget.selectedCategory != '전체') {
      _currentFilters = {
        'categories': [widget.selectedCategory!],
      };
      print('초기 카테고리 필터 설정: ${widget.selectedCategory}');
    }

    // 검색 결과가 있으면 검색 모드로 시작
    if (widget.searchKeyword != null && widget.searchResults != null) {
      _isSearchMode = true;
      _convertSearchResultsToRestaurants();
    } else {
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
          likes: _parseInt(searchResult['likes'] ?? 0), // 데이터베이스에서 받아온 좋아요 수 사용
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['restaurants'] != null) {
          setState(() {
            restaurants = (data['restaurants'] as List)
                .map((item) => _convertToRestaurant(item))
                .toList();

            print('로드된 전체 음식점 수: ${restaurants.length}');

            // 초기 필터 적용
            _applyInitialFilters();
            _isLoading = false;
          });

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
        _applyInitialFilters();
      });
      _showErrorSnackBar('서버에서 데이터를 불러올 수 없어 샘플 데이터를 표시합니다.');
    }
  }

  // 초기 필터 적용 - 수정됨
  Future<void> _applyInitialFilters() async {
    print('초기 필터 적용 시작');
    print('현재 필터: $_currentFilters');
    print('선택된 카테고리: ${widget.selectedCategory}');

    // selectedCategory가 있으면 해당 카테고리로 필터링
    if (widget.selectedCategory != null && widget.selectedCategory != '전체') {
      _currentFilters['categories'] = [widget.selectedCategory!];
      print('카테고리 필터 적용: ${widget.selectedCategory}');
    }

    if (_currentFilters.isNotEmpty) {
      _applyFilters(_currentFilters);
    } else {
      setState(() {
        filteredRestaurants = List.from(restaurants);
      });
      print('필터 없음 - 전체 음식점 표시: ${filteredRestaurants.length}개');
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

      // 카카오 API 형태의 데이터인 경우 변환
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
        likes: _parseInt(item['likes'] ?? 0), // 데이터베이스에서 받아온 좋아요 수 사용
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
      likes: _parseInt(item['likes'] ?? 0), // 데이터베이스에서 받아온 좋아요 수 사용 (기본값 0)
      reviews: [],
      images: ['assets/restaurant.png'],
      createdAt: DateTime.now(),
      reviewCount: 0,
      isOpen: true,
      hasParking: false,
      hasDelivery: false,
    );
  }

  void _applyFilters(Map<String, dynamic> filters) async {
    print('필터 적용 시작: $filters');

    // UI를 먼저 업데이트하고 필터링은 비동기로 처리
    setState(() {
      _currentFilters = filters;
    });

    // 필터링을 별도 함수로 분리하여 비동기 처리
    final filtered = await _performFiltering(filters);

    if (mounted) {
      setState(() {
        filteredRestaurants = filtered;
      });
    }
  }

  // 실제 필터링 로직을 별도 함수로 분리
  Future<List<Restaurant>> _performFiltering(Map<String, dynamic> filters) async {
    return await Future.microtask(() {
      List<Restaurant> filtered = restaurants.where((restaurant) {
        bool matches = true;

        // 필터에서 선택된 카테고리 필터링 (가장 중요한 필터)
        if (filters['categories'] != null && filters['categories'].isNotEmpty) {
          bool filterCategoryMatch = false;
          for (String category in filters['categories']) {
            bool categoryMatch = false;

            // 카테고리명에서 필터링
            bool categoryNameMatch = restaurant.categoryName.toLowerCase().contains(category.toLowerCase());

            // foodTypes에서 필터링
            bool foodTypeMatch = restaurant.foodTypes.any((type) =>
                type.toLowerCase().contains(category.toLowerCase()));

            // 세부 카테고리 매칭
            bool detailMatch = false;
            switch (category) {
              case '한식':
                detailMatch = restaurant.categoryName.contains('한식') ||
                    restaurant.categoryName.contains('한국') ||
                    restaurant.categoryName.contains('김치') ||
                    restaurant.categoryName.contains('불고기') ||
                    restaurant.categoryName.contains('갈비') ||
                    restaurant.foodTypes.any((type) => ['한식', '한국음식', '김치', '불고기', '갈비', '비빔밥', '냉면'].contains(type));
                break;
              case '중식':
                detailMatch = restaurant.categoryName.contains('중식') ||
                    restaurant.categoryName.contains('중국') ||
                    restaurant.categoryName.contains('짜장') ||
                    restaurant.categoryName.contains('탕수육') ||
                    restaurant.foodTypes.any((type) => ['중식', '중국음식', '짜장면', '탕수육', '짬뽕', '볶음밥'].contains(type));
                break;
              case '일식':
                detailMatch = restaurant.categoryName.contains('일식') ||
                    restaurant.categoryName.contains('일본') ||
                    restaurant.categoryName.contains('초밥') ||
                    restaurant.categoryName.contains('라멘') ||
                    restaurant.categoryName.contains('우동') ||
                    restaurant.foodTypes.any((type) => ['일식', '일본음식', '초밥', '라멘', '돈까스', '우동', '덮밥'].contains(type));
                break;
              case '양식':
                detailMatch = restaurant.categoryName.contains('양식') ||
                    restaurant.categoryName.contains('서양') ||
                    restaurant.categoryName.contains('파스타') ||
                    restaurant.categoryName.contains('피자') ||
                    restaurant.categoryName.contains('스테이크') ||
                    restaurant.foodTypes.any((type) => ['양식', '서양음식', '파스타', '피자', '스테이크', '햄버거', '샐러드'].contains(type));
                break;
              case '카페':
                detailMatch = restaurant.categoryName.contains('카페') ||
                    restaurant.categoryName.contains('커피') ||
                    restaurant.categoryName.contains('디저트') ||
                    restaurant.categoryName.contains('베이커리') ||
                    restaurant.foodTypes.any((type) => ['카페', '커피', '디저트', '베이커리', '케이크', '빵'].contains(type));
                break;
            }

            categoryMatch = categoryNameMatch || foodTypeMatch || detailMatch;

            if (categoryMatch) {
              filterCategoryMatch = true;
              break;
            }
          }
          matches = matches && filterCategoryMatch;
        }

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

        return matches;
      }).toList();

      // 정렬 적용
      String sortBy = filters['sortBy'] ?? 'rating';
      switch (sortBy) {
        case 'rating':
          filtered.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'reviews':
          filtered.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
          break;
        case 'distance':
        // 거리순 정렬 (현재는 임의로 정렬)
          filtered.sort((a, b) => a.name.compareTo(b.name));
          break;
      }

      print('전체 음식점: ${restaurants.length}개');
      print('카테고리 "${filters['categories']}" 필터링 결과: ${filtered.length}개');

      return filtered;
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

  // 네비게이션 처리 함수
  void _handleNavigation(int index) {
    switch (index) {
      case 0: // 홈
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(initialTab: 0),
          ),
              (route) => false,
        );
        break;
      case 1: // 지도
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(initialTab: 1),
          ),
              (route) => false,
        );
        break;
      case 2: // 메뉴
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(initialTab: 2),
          ),
              (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 현재 선택된 카테고리에 따른 타이틀 설정
    String appBarTitle = '인하대 후문 맛집';
    if (widget.selectedCategory != null && widget.selectedCategory != '전체') {
      appBarTitle = '인하대 후문 ${widget.selectedCategory} 맛집';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSearchMode ? '검색 결과' : appBarTitle,
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(72),
          child: Column(
            children: [
              // 검색바
              CustomSearchBar(
                onSearchResults: _handleSearchResults,
                currentLat: _currentLat,
                currentLng: _currentLng,
                isSearchMode: _isSearchMode,
                onSearchModeChanged: _handleSearchModeChanged,
                initialSearchText: widget.initialSearchText ?? widget.searchKeyword ?? '',
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // 검색 결과 표시
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

          // 카테고리 결과 표시
          if (widget.selectedCategory != null && widget.selectedCategory != '전체' && !_isSearchMode)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorScheme.primary.withOpacity(0.1),
              child: Text(
                '${widget.selectedCategory} 음식점 (${filteredRestaurants.length}개)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // 필터 섹션
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.cardColor,
            child: Filter(
              onFilterChanged: _applyFilters,
              initialFilters: _currentFilters, // 초기 필터 전달
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
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MainScreen(
                                        initialTab: 1,
                                        selectedRestaurant: restaurant,
                                      ),
                                    ),
                                        (route) => false,
                                  );
                                },
                              ),
                              RtReviewList(reviews: restaurant.reviews),

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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _handleNavigation,
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
        likes: 0, // 데이터베이스에서 받아온 값을 사용하도록 0으로 초기화
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
        likes: 0, // 데이터베이스에서 받아온 값을 사용하도록 0으로 초기화
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
        likes: 0, // 데이터베이스에서 받아온 값을 사용하도록 0으로 초기화
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
}