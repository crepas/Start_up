import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';     // 하단 네비게이션 바 위젯
import '../widgets/ListView_AD.dart';      // 광고 항목 위젯
import '../widgets/ListView_RT.dart';      // 일반 식당 항목 위젯
import '../widgets/Filter.dart';           // 필터 위젯
import '../widgets/Rt_image.dart';         // 식당 이미지 위젯
import '../widgets/Rt_information.dart';   // 식당 정보 위젯
import '../widgets/Rt_ReviewList.dart';    // 식당 리뷰 목록 위젯
import '../models/restaurant.dart';        // 식당 데이터 모델

// 식당 목록 화면을 관리하는 StatefulWidget
class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

// ListScreen의 상태 관리 클래스
class _ListScreenState extends State<ListScreen> {
  int _currentIndex = 0;                  // 현재 선택된 bottom navigation bar 인덱스
  int? _expandedIndex;                    // 현재 확장된 항목의 인덱스 (null이면 확장된 항목 없음)
  late List<Restaurant> restaurants;      // 식당 데이터 목록

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 샘플 식당 데이터 로드
    restaurants = generateSampleRestaurants();  // 샘플 데이터 생성 함수 호출 (별도 구현 필요)
  }

  // 항목 확장/축소 토글 함수
  void toggleExpanded(int index) {
    setState(() {
      // 이미 확장된 항목을 다시 탭하면 축소
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        // 다른 항목 탭하면 해당 항목으로 확장 상태 변경
        _expandedIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 반응형 디자인을 위한 화면 너비 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final baseUnit = screenWidth / 360;  // 360px 기준으로 비율 계산 (디자인 기준점)

    return Scaffold(
      backgroundColor: Colors.white,  // 전체 화면 배경색 흰색으로 설정
      body: Column(
        children: [
          // 상단 배너 영역
          Container(
            margin: EdgeInsets.symmetric(
              vertical: baseUnit * 0.5,    // 수직 마진 설정
              horizontal: baseUnit * 0.5,  // 수평 마진 설정
            ),
            width: double.infinity,        // 너비를 부모 컨테이너에 맞춤
            height: screenWidth * 0.2,     // 높이는 화면 너비의 20%로 설정
            color: Colors.white,           // 배경색 흰색으로 설정
            child: Image.asset(
              'assets/banner.png',         // 배너 이미지 경로
              fit: BoxFit.cover,           // 이미지가 컨테이너를 꽉 채우도록 설정
              errorBuilder: (context, error, stackTrace) {
                // 이미지 로드 실패 시 대체 UI 표시
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Text('배너 이미지를 불러올 수 없습니다'),
                  ),
                );
              },
            ),
          ),

          // 필터 영역 위젯
          Filter(),

          // 식당 목록 영역 (스크롤 가능)
          Expanded(
            child: ListView.builder(
                itemCount: restaurants.length,  // 전체 식당 목록 개수
                itemBuilder: (context, index) {
                  final restaurant = restaurants[index];  // 현재 인덱스의 식당 데이터

                  return Column(
                    children: [
                      // 광고 여부에 따라 다른 레이아웃 표시
                      restaurant.isAd
                          ? ListViewAd(
                        restaurant: restaurant,              // 식당 데이터 전달
                        isExpanded: _expandedIndex == index, // 현재 항목 확장 여부
                        onTap: () => toggleExpanded(index),  // 탭 이벤트 핸들러
                      )
                          : ListViewRt(
                        restaurant: restaurant,              // 식당 데이터 전달
                        isExpanded: _expandedIndex == index, // 현재 항목 확장 여부
                        onTap: () => toggleExpanded(index),  // 탭 이벤트 핸들러
                      ),

                      // 확장된 항목일 경우 추가 정보 표시
                      if (_expandedIndex == index)
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),  // 애니메이션 지속 시간
                          curve: Curves.easeInOut,                // 애니메이션 효과
                          color: Colors.white,                    // 배경색
                          child: Column(
                            children: [
                              RtImage(images: restaurant.images),  // 식당 이미지 위젯
                              RtInformation(
                                likeCount: restaurant.likeCount,     // 좋아요 수
                                commentCount: restaurant.commentCount, // 댓글 수
                              ),
                              RtReviewList(reviews: restaurant.reviews),  // 리뷰 목록 위젯
                              SizedBox(height: 3),  // 하단 여백
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

      // 하단 네비게이션 바
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,           // 현재 선택된 탭 인덱스
        onTap: (index) {
          setState(() {
            _currentIndex = index;             // 선택된 탭 변경 시 상태 업데이트
          });
        },
      ),
    );
  }
}