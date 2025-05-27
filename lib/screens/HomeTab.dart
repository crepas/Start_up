import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';
import 'ListScreen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // 검색 컨트롤러 추가
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['맛집', '카페', '한식', '양식', '중식'];

  // 음식 데이터 모델 (나중에 API 연결 시 대체될 예정)
  final List<Map<String, dynamic>> _foodItems = [
    {
      'title': '장터삼겹살',
      'imageUrl': 'assets/samgyupsal.png',
    },
    {
      'title': '명륜진사갈비',
      'imageUrl': 'assets/myung_jin.png',
    },
    {
      'title': '온기족발',
      'imageUrl': 'assets/onki.png',
    },
  ];

  // 섹션 데이터
  final List<String> _sections = ['#고기', '#분식', '#해산물'];

  // 현재 위치
  double _currentLat = 37.4516;
  double _currentLng = 126.7015;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
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

  // 카테고리 선택 시 해당 카테고리로 검색
  void _searchByCategory(String category) {
    _performSearch(category);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Scaffold(
        body: Column(
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

            // 카테고리 버튼 (클릭 기능 추가)
            Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _searchByCategory(_categories[index]),
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
                                _categories[index],
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

            // 음식 목록 섹션들 (기존 코드 유지)
            Expanded(
              child: ListView.builder(
                itemCount: _sections.length,
                itemBuilder: (context, sectionIndex) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 섹션 제목
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                        child: Text(
                          _sections[sectionIndex],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // 음식 카드 슬라이더
                      Container(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _foodItems.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                // 음식점 이름으로 검색
                                _performSearch(_foodItems[index]['title']);
                              },
                              child: Container(
                                width: 150,
                                margin: EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 음식 이미지
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10.0),
                                        child: Container(
                                          color: theme.cardColor,
                                          child: Image.asset(
                                            _foodItems[index]['imageUrl'],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(child: Icon(Icons.image_not_supported));
                                            },
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 음식 이름
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        _foodItems[index]['title'],
                                        style: theme.textTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}