import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';
import '../widgets/ListView_AD.dart';
import '../widgets/ListView_RT.dart';
import '../widgets/Filter.dart';
import '../widgets/Rt_image.dart';
import '../widgets/Rt_information.dart';
import '../widgets/Rt_ReviewList.dart';
import '../models/restaurant.dart';

class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  int _currentIndex = 0;
  int? _expandedIndex; // 현재 확장된 항목의 인덱스를 저장
  late List<Restaurant> restaurants; // 식당 데이터 목록

  @override
  void initState() {
    super.initState();
    // 샘플 데이터 로드
    restaurants = generateSampleRestaurants();
  }

  void toggleExpanded(int index) {
    setState(() {
      // 같은 항목을 다시 탭하면 닫기
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseUnit = screenWidth / 360; // 기준 단위 (360은 디자인 기준 너비)

    return Scaffold(
      backgroundColor: Colors.white, // 전체 화면 배경색 흰색으로 설정
      body: Column(
        children: [
          // 배너
          Container(
            margin: EdgeInsets.symmetric(
              vertical: baseUnit * 0.5,
              horizontal: baseUnit * 0.5,
            ),
            width: double.infinity,
            height: screenWidth * 0.2, // 화면 너비의 20%
            color: Colors.white, // 배경색 흰색으로 설정
            child: Image.asset(
              'assets/banner.png', // 배너 이미지
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Text('배너 이미지를 불러올 수 없습니다'),
                  ),
                );
              },
            ),
          ),

          // 필터 영역
          Filter(),

          // 리스트 뷰
          Expanded(
            child: ListView.builder(
              itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = restaurants[index];

                  return Column(
                    children: [
                      restaurant.isAd
                          ? ListViewAd(
                        restaurant: restaurant,
                        isExpanded: _expandedIndex == index,
                        onTap: () => toggleExpanded(index),
                      )
                          : ListViewRt(
                        restaurant: restaurant,
                        isExpanded: _expandedIndex == index,
                        onTap: () => toggleExpanded(index),
                      ),

                      if (_expandedIndex == index)
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          color: Colors.white,
                          child: Column(
                            children: [
                              RtImage(images: restaurant.images),
                              RtInformation(
                                likeCount: restaurant.likeCount,
                                commentCount: restaurant.commentCount,
                              ),
                              RtReviewList(reviews: restaurant.reviews),
                              SizedBox(height: 3),
                            ],
                          ),
                        ),
                    ],
                  );
                }

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