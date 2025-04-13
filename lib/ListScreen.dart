import 'package:flutter/material.dart';
import 'BottomNavBar.dart';
import 'ListView_AD.dart';
import 'ListView_RT.dart';
import 'Filter.dart';

class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseUnit = screenWidth / 360; // 기준 단위 (360은 디자인 기준 너비)

    return Scaffold(
      backgroundColor: Colors.white, // 전체 화면 배경색 흰색으로 설정
      // appBar: AppBar(
      //   title: Text('식당 리스트'),
      // ),
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
                  return ListView_AD();
                } else {
                  return ListView_RT();
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