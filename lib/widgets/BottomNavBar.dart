import 'package:flutter/material.dart';
import 'package:start_up/screens/MainScreen.dart';
import '../screens/MenuTab.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MenuTab()),
          );
        } else {
          onTap(index); // 지도 탭 눌렀을 때만 onTap 호출
        }
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
      selectedItemColor: Colors.green,
    );
  }
}
