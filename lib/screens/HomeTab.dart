import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final List<String> _categories = ['맛집', '카페', '???', '', ''];

  // 음식 데이터 모델 (나중에 API 연결 시 대체될 예정)
  final List<Map<String, dynamic>> _foodItems = [
    {
      'title': '장터삼겹살',
      'imageUrl': 'assets/samgyupsal.png', // 나중에 서버에서 실제 이미지 URL로 교체
    },
    {
      'title': '명륜진사갈비',
      'imageUrl': 'assets/myung_jin.png', // 나중에 서버에서 실제 이미지 URL로 교체
    },
    {
      'title': '온기족발',
      'imageUrl': 'assets/onki.png', // 나중에 서버에서 실제 이미지 URL로 교체
    },
  ];

  // 섹션 데이터
  final List<String> _sections = ['#고기', '#분식', '#해산물'];

  int _currentIndex = 0;

  // 이미지 URL이 네트워크 이미지인지 확인하는 헬퍼 함수
  bool _isNetworkImage(String imagePath) {
    return imagePath.startsWith('http://') || imagePath.startsWith('https://');
  }

  // 안전한 이미지 위젯을 생성하는 헬퍼 함수
  Widget _buildFoodImage(String imageUrl, double width, double height) {
    if (_isNetworkImage(imageUrl)) {
      // 네트워크 이미지인 경우
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Theme.of(context).cardColor,
          child: Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).cardColor,
            child: Center(
              child: Icon(
                Icons.image_not_supported,
                size: 40,
                color: Theme.of(context).hintColor,
              ),
            ),
          );
        },
      );
    } else {
      // 로컬 assets 이미지인 경우
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).cardColor,
            child: Center(
              child: Icon(
                Icons.image_not_supported,
                size: 40,
                color: Theme.of(context).hintColor,
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Scaffold(
        body: Column(
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
              color: colorScheme.secondary.withOpacity(0.3),
              child: Center(
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyLarge,
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
                  );
                },
              ),
            ),

            // 음식 목록 섹션들
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
                            return Container(
                              width: 150,
                              margin: EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 음식 이미지 - 네트워크 이미지 지원
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Container(
                                        color: theme.cardColor,
                                        width: double.infinity,
                                        child: _buildFoodImage(
                                          _foodItems[index]['imageUrl'],
                                          double.infinity,
                                          double.infinity,
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