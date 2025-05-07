import 'package:flutter/material.dart';
import 'HomeTab.dart';
import 'MapTab.dart';
import 'MenuTab.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<String> _categories = ['맛집', '카페', '???', '', ''];

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

  // 상태가 변경될 때마다 위젯 다시 생성 - 중요!
  Widget _getBodyWidget() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTabContent();
      case 1:
        return MapTab();
      case 2:
        return MenuTab();
      default:
        return _buildHomeTabContent();
    }
  }

  // 홈 탭 콘텐츠 빌드 (기존 첫 번째 코드의 UI 부분)
  Widget _buildHomeTabContent() {
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
            color: Color(0xFFD2E6A9), // 연한 녹색 배경
            child: Center(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(text: '✨ '),
                    TextSpan(
                      text: '용현동 맛집 랭킹',
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
                return Container(
                  margin: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: Text(
                            _categories[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 음식 목록 섹션들
          Expanded(
            child: ListView.builder(
              itemCount: 3, // 3개의 섹션으로 나누기
              itemBuilder: (context, sectionIndex) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 섹션 제목
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                      child: Text(
                        '#고기',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // 음식 카드 슬라이더 (ListView로 구현)
                    Container(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _foodItems.length,
                        itemBuilder: (context, index) {
                          return Container(
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
                                      color: Colors.grey[300], // 이미지 로딩 전 배경색
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
                                    style: TextStyle(fontSize: 12.0),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
        selectedItemColor: Color(0xFFA0CC71),
      ),
    );
  }
}