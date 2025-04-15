import 'package:flutter/material.dart';
import 'BottomNavBar.dart';
import 'ListView_AD.dart';
import 'ListView_RT.dart';
import 'Filter.dart';
import 'Rt_image.dart';
import 'Rt_information.dart';
import 'Rt_ReviewList.dart';

class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  int _currentIndex = 0;
  int? _expandedIndex; // 현재 확장된 항목의 인덱스를 저장

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
            ),
          ),

          // 필터 영역
          Filter(),

          // 리스트 뷰
          Expanded(
            child: ListView.builder(
              itemCount: 30,
              itemBuilder: (context, index) {
                if (index % 6 == 0) {
                  // 광고 항목은 확장 기능 없음
                  return ListView_AD();
                } else {
                  // 식당 항목 (확장 가능)
                  return Column(
                    children: [
                      ListView_RT(
                        isExpanded: _expandedIndex == index,
                        onTap: () => toggleExpanded(index),
                      ),

                      // 확장된 상태일 때만 상세 정보 표시
                      if (_expandedIndex == index)
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          color: Colors.white,
                          child: Column(
                            children: [
                              // 식당 이미지 슬라이더
                              RtImage(),

                              // 식당 정보
                              Rt_information(),

                              // 리뷰 목록

                              ReviewList(),

                            ],
                          ),
                        ),
                    ],
                  );
                }
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
    );
  }
}