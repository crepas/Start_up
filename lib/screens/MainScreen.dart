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

  // 상태가 변경될 때마다 위젯 다시 생성 - 중요!
  Widget _getBodyWidget() {
    switch (_currentIndex) {
      case 0:
        return HomeTab();
      case 1:
        return MapTab();
      case 2:
        return MenuTab();
      default:
        return HomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 바디에 동적으로 생성된 위젯 할당
      body: _getBodyWidget(),

      // 하단 네비게이션 바
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