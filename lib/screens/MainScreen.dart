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
import '../widgets/CustomSearchBar.dart';
import '../widgets/FoodCategoryBar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MainScreen extends StatefulWidget {
  final int initialTab; // 초기 선택 탭 (0: 홈, 1: 지도, 2: 메뉴)
  final Restaurant? selectedRestaurant; // 선택된 음식점 정보

  const MainScreen({
    Key? key,
    this.initialTab = 0,
    this.selectedRestaurant,
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex; // 현재 선택된 탭 인덱스
  bool _isLoading = true; // 데이터 로딩 상태
  List<Restaurant> _restaurants = []; // 음식점 목록
  bool _isSearchMode = false; // 검색 모드 상태
  List<Restaurant> _searchResults = []; // 검색 결과
  String _currentCategory = 'all'; // 현재 선택된 카테고리

  // 현재 위치 좌표
  double _currentLat = 37.4516;
  double _currentLng = 126.7015;

  // 인하대 후문 정확한 좌표
  final double inhaBackGateLat = 37.45169;
  final double inhaBackGateLng = 126.65464;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _getCurrentLocation(); // 현재 위치 가져오기
    _loadRestaurants(); // 음식점 데이터 로드
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    try {
      // 위치 권한 요청
      PermissionStatus status = await Permission.location.request();

      if (status.isGranted) {
        // 현재 위치 좌표 가져오기
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

  // 검색 결과 처리
  void _handleSearchResults(List<Restaurant> results) {
    setState(() {
      _searchResults = results;
      if (results.isNotEmpty) {
        // 검색 결과가 있으면 ListScreen으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListScreen(
              searchKeyword: results.first.name,
              searchResults: results.map((r) => r.toMap()).toList(),
            ),
          ),
        );
      }
    });
  }

  // 검색 모드 변경
  void _handleSearchModeChanged(bool isSearchMode) {
    setState(() {
      _isSearchMode = isSearchMode;
    });
  }

  // 카테고리 선택 시 해당 카테고리로 검색
  Future<void> _searchByCategory(String category) async {
    if (category.trim().isEmpty) return;

    try {
      final apiKey = '4e4572f409f9b0cd5dc1f574779a03a7';

      final response = await http.get(
        Uri.parse('https://dapi.kakao.com/v2/local/search/keyword.json?query=$category&x=$_currentLng&y=$_currentLat&radius=5000&size=15'),
        headers: {
          'Authorization': 'KakaoAK $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> documents = data['documents'];

        List<Restaurant> searchRestaurants = documents.map((doc) {
          Map<String, dynamic> searchResult = doc as Map<String, dynamic>;
          return Restaurant(
            id: searchResult['id']?.toString() ?? '',
            name: searchResult['place_name'] ?? '',
            address: searchResult['address_name'] ?? '',
            roadAddress: searchResult['road_address_name'] ?? '',
            lat: double.tryParse(searchResult['y'] ?? '0') ?? 0,
            lng: double.tryParse(searchResult['x'] ?? '0') ?? 0,
            categoryName: searchResult['category_name'] ?? '',
            foodTypes: [category],
            phone: searchResult['phone'] ?? '',
            placeUrl: searchResult['place_url'] ?? '',
            priceRange: '중간',
            rating: 4.0 + (searchResult['id'].hashCode % 10) / 10,
            likes: 50 + (searchResult['id'].hashCode % 100),
            reviews: [],
            images: ['assets/restaurant.png'],
            createdAt: DateTime.now(),
            reviewCount: searchResult['id'].hashCode % 50,
            isOpen: true,
            hasParking: searchResult['id'].hashCode % 2 == 0,
            hasDelivery: searchResult['id'].hashCode % 3 == 0,
          );
        }).toList();

        if (searchRestaurants.isNotEmpty) {
          // 검색 결과가 있으면 ListScreen으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListScreen(
                searchKeyword: category,
                searchResults: searchRestaurants.map((r) => r.toMap()).toList(),
                initialSearchText: category, // 초기 검색어 설정
              ),
            ),
          );
        }
      } else {
        _showErrorSnackBar('검색 중 오류가 발생했습니다.');
      }
    } catch (e) {
      print('검색 오류: $e');
      _showErrorSnackBar('검색 중 오류가 발생했습니다.');
    }
  }

  // 에러 메시지 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  // 카테고리 선택 처리
  void _handleCategorySelected(String category) {
    setState(() {
      _currentCategory = category;
    });

    if (category == 'all') {
      _loadRestaurants(); // 전체 음식점 로드
    } else {
      // 카테고리 ID를 한글 이름으로 변환
      Map<String, String> categoryMap = {
        'korean': '한식',
        'chinese': '중식',
        'japanese': '일식',
        'western': '양식',
        'cafe': '카페',
      };
      _searchByCategory(categoryMap[category] ?? category);
    }
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

  // 홈 탭 콘텐츠 빌드
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
          CustomSearchBar(
            onSearchResults: _handleSearchResults,
            currentLat: _currentLat,
            currentLng: _currentLng,
            isSearchMode: _isSearchMode,
            onSearchModeChanged: _handleSearchModeChanged,
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

          // 카테고리 바
          FoodCategoryBar(
            currentCategory: _currentCategory,
            onCategorySelected: _handleCategorySelected,
          ),

          // 음식점 목록
          Expanded(
            child: ListView(
              children: [
                _buildRestaurantSection('🍚 한식 맛집', '한식'),
                _buildRestaurantSection('🥟 중식 맛집', '중식'),
                _buildRestaurantSection('🍣 일식 맛집', '일식'),
                _buildRestaurantSection('🍝 양식 맛집', '양식'),
                _buildRestaurantSection('☕ 카페', '카페'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 음식점 섹션 빌드
  Widget _buildRestaurantSection(String title, String category) {
    final theme = Theme.of(context);
    final restaurants = _currentCategory == 'all' 
        ? _getRestaurantsByCategory(category)
        : _currentCategory == category.toLowerCase()
            ? _getRestaurantsByCategory(category)
            : [];

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