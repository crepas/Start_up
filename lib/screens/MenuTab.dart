import 'package:flutter/material.dart';
import '../screens/login.dart';

class MenuTab extends StatefulWidget {
  @override
  _MenuTabState createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  // 사용자 정보 (실제로는 로그인 상태에서 가져와야 함)
  final Map<String, dynamic> _userInfo = {
    'name': '사용자',
    'email': 'user@example.com',
    'profileImage': 'assets/profile_placeholder.png'
  };

  // 메뉴 항목 목록
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': '내 프로필',
      'icon': Icons.person,
      'onTap': () {},
    },
    {
      'title': '찜 목록',
      'icon': Icons.favorite,
      'onTap': () {},
    },
    {
      'title': '방문 기록',
      'icon': Icons.history,
      'onTap': () {},
    },
    {
      'title': '리뷰 관리',
      'icon': Icons.rate_review,
      'onTap': () {},
    },
    {
      'title': '앱 설정',
      'icon': Icons.settings,
      'onTap': () {},
    },
    {
      'title': '알림 설정',
      'icon': Icons.notifications,
      'onTap': () {},
    },
    {
      'title': '고객 지원',
      'icon': Icons.help,
      'onTap': () {},
    },
    {
      'title': '로그아웃',
      'icon': Icons.logout,
      'onTap': () {},
      'isRed': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 프로필 헤더
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // 프로필 이미지
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: AssetImage(_userInfo['profileImage']),
                  onBackgroundImageError: (exception, stackTrace) {
                    // 이미지 로드 실패 시 기본 아이콘 표시
                  },
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(width: 16),
                // 사용자 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userInfo['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _userInfo['email'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // 프로필 편집 버튼
                IconButton(
                  icon: Icon(Icons.edit, color: Color(0xFFA0CC71)),
                  onPressed: () {
                    // 프로필 편집 화면으로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('프로필 편집 기능은 준비 중입니다'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 메뉴 목록
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final bool isRed = item['isRed'] ?? false;

                return ListTile(
                  leading: Icon(
                    item['icon'],
                    color: isRed ? Colors.red : Colors.grey[700],
                  ),
                  title: Text(
                    item['title'],
                    style: TextStyle(
                      color: isRed ? Colors.red : Colors.black,
                      fontWeight: isRed ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                  onTap: () {
                    // 로그아웃 처리
                    if (item['title'] == '로그아웃') {
                      _showLogoutDialog(context);
                    } else {
                      // 다른 메뉴 항목 처리
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item['title']} 기능은 준비 중입니다'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),

          // 앱 버전 정보
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '나루나루 앱 버전 1.0.0',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // 로그아웃 확인 다이얼로그
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('로그아웃'),
          content: Text('정말 로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
            ),
            TextButton(
              child: Text(
                '로그아웃',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                // 로그아웃 처리 로직
                // 세션 정보, 토큰 등 삭제 필요
                Navigator.of(context).pop(); // 다이얼로그 닫기

                // 로그인 화면으로 이동
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false, // 모든 이전 화면 제거
                );
              },
            ),
          ],
        );
      },
    );
  }
}