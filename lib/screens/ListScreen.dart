import 'dart:math' as Math;

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
import 'dart:math';
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
          likes: _parseInt(searchResult['likes'] ?? 0), // 데이터베이스에서 받아온 좋아요 수 사용
          reviews: [],
          images: searchResult['images'] != null && (searchResult['images'] as List).isNotEmpty
              ? List<String>.from(searchResult['images'])
              : [_getCategoryImage(searchResult['category_name'] ?? '')],
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

      // 더 넓은 범위와 더 많은 데이터 요청
      final queryParams = {
        'lat': inhaBackGateLat.toString(),
        'lng': inhaBackGateLng.toString(),
        'radius': '5000', // 5km로 확대
        'limit': '100', // 100개로 증가
        'sort': 'likes',
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

            // 데이터가 적으면 더미 데이터 추가
            if (restaurants.length < 10) {
              print('더미 데이터 추가 후: ${restaurants.length}개');
            }

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
      // 필터를 새로 설정하고 바로 적용
      Map<String, dynamic> categoryFilter = {
        'categories': [widget.selectedCategory!],
        'sortBy': 'likes', // 기본 정렬
      };
      _applyFilters(categoryFilter);
    } else {
      // 전체 카테고리인 경우 정렬만 적용
      Map<String, dynamic> defaultFilter = {
        'sortBy': 'likes',
      };
      _applyFilters(defaultFilter);
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

      List<Review> reviews = _parseReviews(item['reviews'] ?? []);

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
        likes: _parseInt(item['likes'] ?? 0),
        reviews: reviews,
        images: _parseImages(item['images'] ?? []),
        createdAt: _parseDateTime(item['createdAt']),
        reviewCount: reviews.length,
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
      likes: _parseInt(item['likes'] ?? 0),
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

    setState(() {
      _currentFilters = Map.from(filters); // 깊은 복사로 변경
      _isLoading = true;
    });

    // 필터링을 별도 함수로 분리하여 비동기 처리
    final filtered = await _performFiltering(filters);

    if (mounted) {
      setState(() {
        filteredRestaurants = List.from(filtered); // 새 리스트로 생성
        _isLoading = false;
      });

      // UI 업데이트 후 로그 출력
      print('UI 업데이트 완료 - 표시되는 음식점 수: ${filteredRestaurants.length}');
      if (filteredRestaurants.isNotEmpty) {
        print('첫 번째 음식점: ${filteredRestaurants.first.name} (좋아요: ${filteredRestaurants.first.likes})');
        print('두 번째 음식점: ${filteredRestaurants.length > 1 ? filteredRestaurants[1].name : "없음"} (좋아요: ${filteredRestaurants.length > 1 ? filteredRestaurants[1].likes : 0})');
      }
    }
  }


  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000; // 지구 반지름 (미터)
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;

    final a = sin(dLat/2) * sin(dLat/2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLng/2) * sin(dLng/2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // 거리 (단위: m)
  }

  // 실제 필터링 로직을 별도 함수로 분리
  Future<List<Restaurant>> _performFiltering(Map<String, dynamic> filters) async {
    return await Future.microtask(() {
      List<Restaurant> filtered = restaurants.where((restaurant) {
        bool matches = true;

        // 카테고리 필터링 로직은 기존과 동일...
        if (filters['categories'] != null && filters['categories'].isNotEmpty) {
          bool filterCategoryMatch = false;
          for (String category in filters['categories']) {
            bool categoryMatch = false;

            switch (category) {
              case '한식':
                categoryMatch = restaurant.categoryName.contains('한식') ||
                    restaurant.categoryName.contains('한국') ||
                    restaurant.categoryName.contains('고기구이') ||
                    restaurant.categoryName.contains('족발') ||
                    restaurant.categoryName.contains('보쌈') ||
                    restaurant.categoryName.contains('갈비') ||
                    restaurant.categoryName.contains('삼겹살') ||
                    restaurant.categoryName.contains('분식') ||
                    restaurant.foodTypes.any((type) =>
                    type.contains('한식') ||
                        type.contains('고기') ||
                        type.contains('족발') ||
                        type.contains('갈비') ||
                        type.contains('분식'));
                break;
              case '중식':
                categoryMatch = restaurant.categoryName.contains('중식') ||
                    restaurant.categoryName.contains('중국') ||
                    restaurant.categoryName.contains('중화') ||
                    restaurant.foodTypes.any((type) =>
                    type.contains('중식') ||
                        type.contains('짜장') ||
                        type.contains('짬뽕'));
                break;
              case '일식':
                categoryMatch = restaurant.categoryName.contains('일식') ||
                    restaurant.categoryName.contains('일본') ||
                    restaurant.categoryName.contains('초밥') ||
                    restaurant.categoryName.contains('라멘') ||
                    restaurant.foodTypes.any((type) =>
                    type.contains('일식') ||
                        type.contains('초밥') ||
                        type.contains('라멘'));
                break;
              case '양식':
                categoryMatch = restaurant.categoryName.contains('양식') ||
                    restaurant.categoryName.contains('서양') ||
                    restaurant.categoryName.contains('파스타') ||
                    restaurant.categoryName.contains('피자') ||
                    restaurant.foodTypes.any((type) =>
                    type.contains('양식') ||
                        type.contains('피자') ||
                        type.contains('파스타'));
                break;
              case '카페':
                categoryMatch = restaurant.categoryName.contains('카페') ||
                    restaurant.categoryName.contains('커피') ||
                    restaurant.categoryName.contains('디저트') ||
                    restaurant.foodTypes.any((type) =>
                    type.contains('카페') ||
                        type.contains('커피'));
                break;
            }

            if (categoryMatch) {
              filterCategoryMatch = true;
              break;
            }
          }
          matches = matches && filterCategoryMatch;
        }

        return matches;
      }).toList();

      // 정렬 전 로그 (rating 제거)
      print('정렬 전 음식점들:');
      for (int i = 0; i < Math.min(3, filtered.length); i++) {
        print('${i+1}. ${filtered[i].name} - 좋아요: ${filtered[i].likes}, 리뷰: ${filtered[i].reviews.length}');
      }

      // 정렬 로직에서 rating 관련 제거
      String sortBy = filters['sortBy'] ?? 'likes';
      print('적용할 정렬 방식: $sortBy');

      switch (sortBy) {
        case 'likes':
        case '좋아요순':
          filtered.sort((a, b) => b.likes.compareTo(a.likes));
          break;
        case 'reviews':
        case '리뷰순':
          filtered.sort((a, b) => b.reviews.length.compareTo(a.reviews.length));
          break;
        case 'distance':
        case '거리순':
        case '가까운순':
        // 가까운 순으로만 정렬 (오름차순)
          filtered.sort((a, b) {
            final distA = calculateDistance(inhaBackGateLat, inhaBackGateLng, a.lat, a.lng);
            final distB = calculateDistance(inhaBackGateLat, inhaBackGateLng, b.lat, b.lng);
            return distA.compareTo(distB); // 가까운 순
          });
          break;
        case 'name':
        case '이름순':
          filtered.sort((a, b) => a.name.compareTo(b.name));
          break;
        default:
          filtered.sort((a, b) => b.likes.compareTo(a.likes));
          break;
      }

      // 정렬 후 로그 (rating 제거)
      print('정렬 후 음식점들:');
      for (int i = 0; i < Math.min(3, filtered.length); i++) {
        print('${i+1}. ${filtered[i].name} - 좋아요: ${filtered[i].likes}, 리뷰: ${filtered[i].reviews.length}');
      }

      return List.from(filtered);
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
      _isSearchMode = true;
      _currentFilters.clear(); // 모든 필터 초기화

      // 검색 결과를 바로 filteredRestaurants에 설정
      filteredRestaurants = List.from(results);
    });

    print('검색 결과 적용: ${results.length}개의 음식점');
    print('필터 초기화됨: $_currentFilters');
  }

  // 검색 모드 변경
  void _handleSearchModeChanged(bool isSearchMode) {
    setState(() {
      _isSearchMode = isSearchMode;

      if (!isSearchMode) {
        // 검색 모드가 꺼질 때 모든 필터 해제하고 전체 음식점 표시
        _currentFilters.clear();

        // restaurants가 비어있지 않으면 전체 음식점 표시
        if (restaurants.isNotEmpty) {
          filteredRestaurants = List.from(restaurants);
        } else {
          // restaurants가 비어있으면 다시 로드
          _loadRestaurants();
        }
      }
    });

    print('검색 모드 변경: $isSearchMode');
    print('필터 완전 초기화: $_currentFilters');
    print('전체 음식점 표시: ${filteredRestaurants.length}개');
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
              initialFilters: {
                // 카테고리가 선택된 경우 해당 카테고리를 초기값으로 설정
                if (widget.selectedCategory != null && widget.selectedCategory != '전체')
                  'categories': [widget.selectedCategory!],
                'sortBy': 'likes', // 기본 정렬값 명시적 설정
                ..._currentFilters, // 기존 필터도 유지
              },
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
}