import 'package:flutter/material.dart';
import 'HomeTab.dart';
import 'MapTab.dart';
import 'MenuTab.dart';
import 'ListScreen.dart';
import '../models/restaurant.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../services/restaurant_image_service.dart';

// 또는 같은 파일에 포함시킬 경우 아래 클래스를 추가

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

  // 검색 컨트롤러 추가
  final TextEditingController _searchController = TextEditingController();

  // 현재 위치
  double _currentLat = 37.4516;
  double _currentLng = 126.7015;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'distance', 'label': '거리'},
    {'id': 'price', 'label': '가격'},
    {'id': 'rating', 'label': '평점'},
    {'id': 'category', 'label': '카테고리'},
  ];

  // 주변 음식점 데이터 (API로 받아옴)
  List<Map<String, dynamic>> _foodItems = [];
  List<Map<String, dynamic>> _cafeItems = [];
  List<Map<String, dynamic>> _koreanItems = [];

  final List<String> _sectionTitles = ['#고기', '#분식', '#카페'];
  final List<String> _searchKeywords = ['고기', '분식', '카페'];

  // 로딩 상태
  bool _isLoadingFoodData = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab; // 초기 탭 설정
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // 위치 서비스가 비활성화되어 있어도 기본 위치로 음식점 데이터 로드
        _loadNearbyRestaurants();
        return;
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _loadNearbyRestaurants();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _loadNearbyRestaurants();
        return;
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });

      // 위치를 얻은 후 주변 음식점 데이터 로드
      _loadNearbyRestaurants();
    } catch (e) {
      print('위치 가져오기 오류: $e');
      // 오류 발생 시에도 기본 위치로 음식점 데이터 로드
      _loadNearbyRestaurants();
    }
  }

  // 주변 음식점 데이터 로드
  Future<void> _loadNearbyRestaurants() async {
    setState(() {
      _isLoadingFoodData = true;
    });

    try {
      final apiKey = '4e4572f409f9b0cd5dc1f574779a03a7';

      // 카테고리별로 음식점 데이터 가져오기
      List<Map<String, dynamic>> allFoodItems = [];
      List<Map<String, dynamic>> allCafeItems = [];
      List<Map<String, dynamic>> allKoreanItems = [];

      // 고기/구이 음식점
      await _fetchCategoryData('고기', allFoodItems, apiKey);

      // 카페
      await _fetchCategoryData('카페', allCafeItems, apiKey);

      // 한식/분식
      await _fetchCategoryData('분식', allKoreanItems, apiKey);

      setState(() {
        _foodItems = allFoodItems.take(6).toList(); // 최대 6개까지
        _cafeItems = allCafeItems.take(6).toList();
        _koreanItems = allKoreanItems.take(6).toList();
        _isLoadingFoodData = false;
      });

    } catch (e) {
      print('주변 음식점 데이터 로드 오류: $e');
      setState(() {
        _isLoadingFoodData = false;
        // 오류 발생 시 기본 데이터 사용
        _setDefaultFoodData();
      });
    }
  }

  // 카테고리별 데이터 가져오기 (크롤링으로 실제 이미지 포함)
  Future<void> _fetchCategoryData(String category, List<Map<String, dynamic>> targetList, String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://dapi.kakao.com/v2/local/search/keyword.json?query=$category&x=$_currentLng&y=$_currentLat&radius=3000&size=10'),
        headers: {
          'Authorization': 'KakaoAK $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> documents = data['documents'];

        for (var doc in documents) {
          // 크롤링으로 실제 음식점 이미지 가져오기 (place_url 추가!)
          String? realImageUrl = await RestaurantImageService.getRestaurantImage(
            doc['place_name'] ?? '음식점',
            doc['category_name'] ?? '', // address_name 대신 category_name 사용
            placeUrl: doc['place_url'], // 카카오맵 상세 페이지 URL 추가!
          );

          // 실제 이미지가 있으면 사용, 없으면 카테고리 기본 이미지 사용
          String finalImageUrl = realImageUrl ?? _getCategoryImage(doc['category_name'] ?? '');

          targetList.add({
            'id': doc['id'] ?? '',
            'title': doc['place_name'] ?? '음식점',
            'category': doc['category_name'] ?? '',
            'address': doc['address_name'] ?? '',
            'phone': doc['phone'] ?? '',
            'x': doc['x'] ?? '',
            'y': doc['y'] ?? '',
            'place_url': doc['place_url'] ?? '', // place_url도 저장
            'imageUrl': finalImageUrl,
            'hasRealImage': realImageUrl != null,
          });
        }
      }
    } catch (e) {
      print('$category 데이터 가져오기 오류: $e');
    }
  }

  // 카테고리에 따른 이미지 반환 (개선된 버전)
  String _getCategoryImage(String category) {
    String lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('고기') || lowerCategory.contains('삼겹살') ||
        lowerCategory.contains('갈비') || lowerCategory.contains('구이') ||
        lowerCategory.contains('스테이크') || lowerCategory.contains('bbq')) {
      return 'assets/samgyupsal.png';
    } else if (lowerCategory.contains('족발') || lowerCategory.contains('보쌈')) {
      return 'assets/onki.png';
    } else if (lowerCategory.contains('카페') || lowerCategory.contains('커피') ||
        lowerCategory.contains('coffee') || lowerCategory.contains('cafe')) {
      return 'assets/cafe.png';
    } else if (lowerCategory.contains('중식') || lowerCategory.contains('중국') ||
        lowerCategory.contains('짜장') || lowerCategory.contains('짬뽕')) {
      return 'assets/chinese.png';
    } else if (lowerCategory.contains('일식') || lowerCategory.contains('초밥') ||
        lowerCategory.contains('라멘') || lowerCategory.contains('돈까스')) {
      return 'assets/japanese.png';
    } else if (lowerCategory.contains('분식') || lowerCategory.contains('김밥') ||
        lowerCategory.contains('떡볶이') || lowerCategory.contains('순대')) {
      return 'assets/bunsik.png';
    } else if (lowerCategory.contains('피자')) {
      return 'assets/pizza.png';
    } else if (lowerCategory.contains('치킨') || lowerCategory.contains('닭')) {
      return 'assets/chicken.png';
    } else if (lowerCategory.contains('햄버거') || lowerCategory.contains('burger')) {
      return 'assets/burger.png';
    } else {
      return 'assets/restaurant.png';
    }
  }

  // 카테고리별 아이콘 반환 (이미지가 없을 때 사용)
  IconData _getCategoryIcon(String category) {
    String lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('고기') || lowerCategory.contains('갈비')) {
      return Icons.outdoor_grill;
    } else if (lowerCategory.contains('카페') || lowerCategory.contains('커피')) {
      return Icons.local_cafe;
    } else if (lowerCategory.contains('중식')) {
      return Icons.ramen_dining;
    } else if (lowerCategory.contains('일식')) {
      return Icons.set_meal;
    } else if (lowerCategory.contains('분식')) {
      return Icons.rice_bowl;
    } else if (lowerCategory.contains('피자')) {
      return Icons.local_pizza;
    } else if (lowerCategory.contains('치킨')) {
      return Icons.lunch_dining;
    } else if (lowerCategory.contains('햄버거')) {
      return Icons.lunch_dining;
    } else {
      return Icons.restaurant;
    }
  }

  // 카테고리별 색상 반환
  Color _getCategoryColor(String category) {
    String lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('고기') || lowerCategory.contains('갈비')) {
      return Colors.red[400]!;
    } else if (lowerCategory.contains('카페') || lowerCategory.contains('커피')) {
      return Colors.brown[400]!;
    } else if (lowerCategory.contains('중식')) {
      return Colors.orange[400]!;
    } else if (lowerCategory.contains('일식')) {
      return Colors.green[400]!;
    } else if (lowerCategory.contains('분식')) {
      return Colors.amber[400]!;
    } else if (lowerCategory.contains('피자')) {
      return Colors.deepOrange[400]!;
    } else if (lowerCategory.contains('치킨')) {
      return Colors.yellow[700]!;
    } else {
      return Colors.grey[400]!;
    }
  }

  // 기본 데이터 설정 (API 실패 시)
  void _setDefaultFoodData() {
    _foodItems = [
      {
        'title': '장터삼겹살',
        'imageUrl': 'assets/samgyupsal.png',
        'category': '고기구이',
      },
      {
        'title': '명륜진사갈비',
        'imageUrl': 'assets/myung_jin.png',
        'category': '갈비',
      },
      {
        'title': '온기족발',
        'imageUrl': 'assets/onki.png',
        'category': '족발',
      },
    ];

    _cafeItems = [
      {
        'title': '스타벅스',
        'imageUrl': 'assets/cafe.png',
        'category': '커피전문점',
      },
    ];

    _koreanItems = [
      {
        'title': '김밥천국',
        'imageUrl': 'assets/bunsik.png',
        'category': '분식',
      },
    ];
  }

  // 검색 기능
  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    try {
      final apiKey = '4e4572f409f9b0cd5dc1f574779a03a7';

      final response = await http.get(
        Uri.parse('https://dapi.kakao.com/v2/local/search/keyword.json?query=$keyword&x=$_currentLng&y=$_currentLat&radius=5000&size=15'),
        headers: {
          'Authorization': 'KakaoAK $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> documents = data['documents'];

        // 검색 결과를 ListScreen으로 전달
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListScreen(
              searchKeyword: keyword,
              searchResults: documents.map((doc) => doc as Map<String, dynamic>).toList(),
            ),
          ),
        );
      } else {
        _showErrorSnackBar('검색 중 오류가 발생했습니다.');
      }
    } catch (e) {
      print('검색 오류: $e');
      _showErrorSnackBar('검색 중 오류가 발생했습니다.');
    }
  }

  // 카테고리 선택 시 ListScreen으로 이동 (카테고리별 검색)
  void _navigateToListScreen(String category) {
    // 카테고리에 따라 검색 키워드 설정
    String searchKeyword = '';
    switch (category) {
      case 'distance':
        searchKeyword = '맛집'; // 거리순은 기본 맛집 검색
        break;
      case 'price':
        searchKeyword = '저렴한 맛집';
        break;
      case 'rating':
        searchKeyword = '맛집';
        break;
      case 'category':
      // 카테고리 선택 다이얼로그 표시
        _showCategoryDialog();
        return;
      default:
        searchKeyword = category;
    }

    _performSearch(searchKeyword);
  }

  // 카테고리 선택 다이얼로그
  void _showCategoryDialog() {
    final categories = ['한식', '중식', '일식', '양식', '카페', '분식', '치킨', '피자'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('카테고리 선택'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(categories[index]),
                  onTap: () {
                    Navigator.pop(context);
                    _performSearch(categories[index]);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 카테고리에서 간단한 이름 추출
  String _getSimpleCategory(String category) {
    List<String> parts = category.split(' > ');
    if (parts.length > 1) {
      return parts[1];
    } else if (parts.isNotEmpty) {
      return parts[0];
    } else {
      return '음식점';
    }
  }

  // 음식점 이미지 빌더 (크롤링 이미지 지원)
  Widget _buildRestaurantImage(Map<String, dynamic> item) {
    String imageUrl = item['imageUrl'] ?? '';
    bool hasRealImage = item['hasRealImage'] ?? false;

    // 네트워크 이미지인지 확인 (http/https로 시작)
    bool isNetworkImage = imageUrl.startsWith('http');

    return Stack(
      children: [
        // 메인 이미지
        Positioned.fill(
          child: isNetworkImage
              ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getCategoryColor(item['category'] ?? '').withOpacity(0.7),
                      _getCategoryColor(item['category'] ?? '').withOpacity(0.9),
                    ],
                  ),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('네트워크 이미지 로드 실패: $imageUrl');
              return _buildFallbackImage(item);
            },
          )
              : Image.asset(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackImage(item);
            },
          ),
        ),
        // 실제 이미지 여부 표시 배지
        if (hasRealImage)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '실제',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // 오버레이 그라데이션
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        // 카테고리 라벨
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getSimpleCategory(item['category'] ?? ''),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: _getCategoryColor(item['category'] ?? ''),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 이미지 로드 실패 시 대체 이미지
  Widget _buildFallbackImage(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(item['category'] ?? '').withOpacity(0.7),
            _getCategoryColor(item['category'] ?? '').withOpacity(0.9),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 배경 패턴
          Positioned.fill(
            child: CustomPaint(
            ),
          ),
          // 중앙 아이콘
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(item['category'] ?? ''),
                  size: 40,
                  color: Colors.white,
                ),
                SizedBox(height: 4),
                Text(
                  _getSimpleCategory(item['category'] ?? ''),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 상태가 변경될 때마다 위젯 다시 생성 - 중요!
  Widget _getBodyWidget() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTabContent();
      case 1:
        return MapTab(selectedRestaurant: widget.selectedRestaurant); // 음식점 정보 전달
      case 2:
        return MenuTab();
      default:
        return _buildHomeTabContent();
    }
  }

  // 홈 탭 콘텐츠 빌드 (검색 기능 추가)
  Widget _buildHomeTabContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Column(
        children: [
          // 검색 바 (기능 추가)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '위치나 음식을 검색해보세요!',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0.0),
              ),
              onChanged: (value) {
                setState(() {}); // suffixIcon을 위한 상태 업데이트
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _performSearch(value.trim());
                }
              },
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
                      text: '주변 맛집 추천',
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
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _navigateToListScreen(_categories[index]['id']),
                  child: Container(
                    margin: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.cardColor,
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Center(
                            child: Text(
                              _categories[index]['label'],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 음식 목록 섹션들 (API 데이터 사용)
          Expanded(
            child: _isLoadingFoodData
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('주변 맛집을 찾는 중...'),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _sectionTitles.length,
              itemBuilder: (context, sectionIndex) {
                // 섹션별 데이터 선택
                List<Map<String, dynamic>> sectionItems = [];
                switch (sectionIndex) {
                  case 0: // #고기
                    sectionItems = _foodItems;
                    break;
                  case 1: // #분식
                    sectionItems = _koreanItems;
                    break;
                  case 2: // #카페
                    sectionItems = _cafeItems;
                    break;
                }

                if (sectionItems.isEmpty) {
                  return SizedBox.shrink(); // 데이터가 없으면 표시하지 않음
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 섹션 제목 (클릭 가능하게 만들기)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // 섹션 이름에서 # 제거하고 검색
                              _performSearch(_searchKeywords[sectionIndex]);
                            },
                            child: Text(
                              _sectionTitles[sectionIndex],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _performSearch(_searchKeywords[sectionIndex]);
                            },
                            child: Text(
                              '더보기',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 음식 카드 슬라이더 (API 데이터 사용)
                    Container(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: sectionItems.length,
                        itemBuilder: (context, index) {
                          final item = sectionItems[index];
                          return GestureDetector(
                            onTap: () {
                              // 음식점 이름으로 검색
                              _performSearch(item['title']);
                            },
                            child: Container(
                              width: 150,
                              margin: EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 음식 이미지 (네트워크 이미지 지원)
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Container(
                                        child: _buildRestaurantImage(item),
                                      ),
                                    ),
                                  ),

                                  // 음식점 이름
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      item['title'],
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // 카테고리 정보
                                  if (item['category'] != null && item['category'].isNotEmpty)
                                    Text(
                                      _getSimpleCategory(item['category']),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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

      // 하단 네비게이션 바 (두 번째 코드의 스타일 사용)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          print("탭 인덱스 변경: $_currentIndex -> $index"); // 디버깅용
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