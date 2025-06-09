/// CustomSearchBar.dart
/// 커스텀 검색 바 위젯
///
/// 주요 기능:
/// - 검색어 입력 및 검색 실행
/// - 검색 결과 표시
/// - 검색 모드 전환
/// - 위치 기반 검색
/// - 검색 히스토리 관리
/// - 자동완성 기능

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/restaurant.dart';
import '../utils/api_config.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(List<Restaurant>) onSearchResults;
  final double currentLat;
  final double currentLng;
  final bool isSearchMode;
  final Function(bool) onSearchModeChanged;
  final String initialSearchText;

  const CustomSearchBar({
    Key? key,
    required this.onSearchResults,
    required this.currentLat,
    required this.currentLng,
    required this.isSearchMode,
    required this.onSearchModeChanged,
    this.initialSearchText = '',
  }) : super(key: key);

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _searchController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchText);
  }

  @override
  void didUpdateWidget(CustomSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSearchText != widget.initialSearchText) {
      _searchController.text = widget.initialSearchText;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  // 검색 수행
  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      widget.onSearchModeChanged(false);
      return;
    }

    setState(() {
      _isLoading = true;
    });
    widget.onSearchModeChanged(true);

    try {
      // 데이터베이스에서 모든 음식점 가져오기
      List<Restaurant> allRestaurants = await _getAllRestaurantsFromDatabase();

      // 검색어로 필터링
      List<Restaurant> filteredRestaurants = _filterRestaurantsByKeyword(allRestaurants, keyword);

      print('데이터베이스 검색 완료: ${filteredRestaurants.length}개 결과');
      widget.onSearchResults(filteredRestaurants);

    } catch (e) {
      print('데이터베이스 검색 오류: $e');
      widget.onSearchResults([]);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Restaurant>> _getAllRestaurantsFromDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final baseUrl = getServerUrl();

      // 인하대 후문 고정 좌표 사용
      const double inhaBackGateLat = 37.45169;
      const double inhaBackGateLng = 126.65464;

      final queryParams = {
        'lat': inhaBackGateLat.toString(),
        'lng': inhaBackGateLng.toString(),
        'radius': '2000', // 2km 반경
        'limit': '100', // 더 많은 데이터 가져오기
        'sort': 'name',
      };

      final uri = Uri.parse('$baseUrl/restaurants').replace(
        queryParameters: queryParams,
      );

      print('데이터베이스 검색 API 호출: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('서버 응답 상태 코드: ${response.statusCode}');
      print('서버 응답 본문: ${response.body}'); // 전체 응답 확인

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 응답 구조 확인
        print('응답 데이터 키들: ${data.keys.toList()}');

        // 여러 가지 가능한 필드명 확인
        List<dynamic> restaurantsList = [];

        if (data['restaurants'] != null) {
          restaurantsList = data['restaurants'];
          print('restaurants 필드에서 데이터 찾음: ${restaurantsList.length}개');
        } else if (data['data'] != null) {
          restaurantsList = data['data'];
          print('data 필드에서 데이터 찾음: ${restaurantsList.length}개');
        } else if (data is List) {
          restaurantsList = data;
          print('응답 자체가 배열: ${restaurantsList.length}개');
        } else {
          print('음식점 데이터를 찾을 수 없음. 응답 구조: $data');
          return [];
        }

        if (restaurantsList.isNotEmpty) {
          print('첫 번째 음식점 데이터 샘플: ${restaurantsList[0]}');

          List<Restaurant> restaurants = restaurantsList
              .map((item) => _convertToRestaurant(item))
              .toList();

          print('데이터베이스에서 ${restaurants.length}개 음식점 로드 완료');
          return restaurants;
        } else {
          print('음식점 목록이 비어 있음');
          return [];
        }
      } else {
        print('데이터베이스 API 에러: ${response.statusCode}');
        print('에러 메시지: ${response.body}');
        return [];
      }
    } catch (e) {
      print('데이터베이스 연결 오류: $e');
      print('스택 트레이스: ${StackTrace.current}');
      return [];
    }
  }

  List<Restaurant> _filterRestaurantsByKeyword(List<Restaurant> restaurants, String keyword) {
    final searchKeyword = keyword.toLowerCase().trim();

    return restaurants.where((restaurant) {
      // 음식점 이름에서 검색
      bool nameMatch = restaurant.name.toLowerCase().contains(searchKeyword);

      // 카테고리명에서 검색
      bool categoryMatch = restaurant.categoryName.toLowerCase().contains(searchKeyword);

      // 음식 타입에서 검색
      bool foodTypeMatch = restaurant.foodTypes.any(
              (foodType) => foodType.toLowerCase().contains(searchKeyword)
      );

      // 주소에서 검색 (선택사항)
      bool addressMatch = restaurant.address.toLowerCase().contains(searchKeyword);

      return nameMatch || categoryMatch || foodTypeMatch || addressMatch;
    }).toList();
  }

  Restaurant _convertToRestaurant(Map<String, dynamic> item) {
    try {
      // 좌표 처리
      const double inhaBackGateLat = 37.45169;
      const double inhaBackGateLng = 126.65464;

      double lat = inhaBackGateLat; // 기본값을 인하대 후문으로 변경
      double lng = inhaBackGateLng; // 기본값을 인하대 후문으로 변경

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
        likes: _parseInt(item['likes'] ?? 0),
        reviews: [], // 리뷰는 별도 로딩
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
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }

  List<String> _parseImages(dynamic value) {
    if (value == null) return [_getCategoryImage('')];
    if (value is List) {
      List<String> images = value.map((e) => e.toString()).toList();
      return images.isNotEmpty ? images : [_getCategoryImage('')];
    }
    if (value is String) return [value];
    return [_getCategoryImage('')];
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Restaurant _createFallbackRestaurant(Map<String, dynamic> item) {
    const double inhaBackGateLat = 37.45169;
    const double inhaBackGateLng = 126.65464;


    return Restaurant(
      id: item['_id'] ?? item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: item['name'] ?? '알 수 없는 음식점',
      address: item['address'] ?? '',
      roadAddress: item['roadAddress'] ?? '',
      lat: inhaBackGateLat, // 인하대 후문 좌표 사용
      lng: inhaBackGateLng, // 인하대 후문 좌표 사용
      categoryName: item['categoryName'] ?? '기타',
      foodTypes: ['기타'],
      phone: item['phone'] ?? '',
      placeUrl: item['placeUrl'] ?? '',
      priceRange: '중간',
      likes: 0,
      reviews: [],
      images: [_getCategoryImage('')],
      createdAt: DateTime.now(),
      reviewCount: 0,
      isOpen: true,
      hasParking: false,
      hasDelivery: false,
      isAd: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: theme.textTheme.bodyLarge,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: '음식점이나 음식을 검색해보세요...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      // clear 시에도 검색 모드 해제하여 필터 초기화
                      widget.onSearchModeChanged(false);
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
                  isCollapsed: true,
                ),
                onChanged: (value) {
                  setState(() {}); // suffixIcon을 위한 상태 업데이트

                  // 검색어가 입력되면 검색 모드 활성화, 비어있으면 검색 모드 해제
                  if (value.trim().isNotEmpty) {
                    widget.onSearchModeChanged(true);
                  } else {
                    widget.onSearchModeChanged(false);
                  }
                },
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _performSearch(value.trim());
                  }
                },
              ),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}