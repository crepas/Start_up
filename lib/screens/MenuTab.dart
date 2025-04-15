import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

class MenuTab extends StatefulWidget {
  @override
  _MenuTabState createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  // 사용자 정보를 저장할 변수
  Map<String, dynamic> _userInfo = {
    'username': '로딩 중...',
    'email': '로딩 중...',
    'profileImage': 'assets/profile_placeholder.png',
    'preferences': {
      'foodTypes': [],
      'priceRange': ''
    }
  };

  bool _isLoading = true;

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
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 로컬에 저장된 토큰 확인
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        // 토큰이 없는 경우 로그인 화면으로 이동할 수 있음
        setState(() {
          _userInfo = {
            'username': '게스트',
            'email': '로그인이 필요합니다',
            'profileImage': 'assets/profile_placeholder.png',
            'preferences': {
              'foodTypes': [],
              'priceRange': ''
            }
          };
          _isLoading = false;
        });
        return;
      }

      // 2. 저장된 사용자 데이터가 있는지 먼저 확인
      final savedUsername = prefs.getString('username');
      final savedEmail = prefs.getString('email');

      if (savedUsername != null && savedEmail != null) {
        // 저장된 기본 정보 로드
        setState(() {
          _userInfo = {
            'username': savedUsername,
            'email': savedEmail,
            'profileImage': 'assets/profile_placeholder.png',
            'preferences': {
              'foodTypes': prefs.getStringList('foodTypes') ?? [],
              'priceRange': prefs.getString('priceRange') ?? '중간'
            }
          };
        });
      }

      // 3. 서버에서 최신 프로필 정보 가져오기
      await _fetchProfileFromServer();
    } catch (e) {
      print('사용자 정보 로드 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 서버에서 프로필 정보 가져오기
  Future<void> _fetchProfileFromServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 서버 API 호출
      final response = await http.get(
        Uri.parse('http://localhost:8081/profile'),
        headers: {
          'Content-Type': 'application/json',
          // 실제 인증 구현에 따라 토큰 헤더 추가가 필요할 수 있음
          // 'Authorization': 'Bearer ${prefs.getString('token')}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final user = responseData['user'];

        if (user != null) {
          // 서버에서 가져온 정보로 업데이트
          setState(() {
            _userInfo = {
              'username': user['username'],
              'email': user['email'],
              'profileImage': 'assets/profile_placeholder.png',
              'preferences': {
                'foodTypes': List<String>.from(user['preferences']['foodTypes'] ?? []),
                'priceRange': user['preferences']['priceRange'] ?? '중간'
              }
            };
          });

          // 로컬 저장소 업데이트
          await prefs.setString('username', user['username']);
          await prefs.setString('email', user['email']);
          await prefs.setStringList('foodTypes', List<String>.from(user['preferences']['foodTypes'] ?? []));
          await prefs.setString('priceRange', user['preferences']['priceRange'] ?? '중간');
        }
      } else {
        print('서버 응답 오류: ${response.statusCode}');
        // 오류 시 로컬 데이터 유지
      }
    } catch (e) {
      print('서버 연결 오류: $e');
      // 네트워크 오류 시 로컬 데이터 유지
    }
  }

  // 로그아웃 처리
  Future<void> _logout() async {
    try {
      // 1. 서버에 로그아웃 요청
      await http.get(Uri.parse('http://localhost:8081/logout'));

      // 2. 로컬 저장소에서 토큰 및 사용자 정보 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('foodTypes');
      await prefs.remove('priceRange');

      // 3. 로그인 화면으로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false, // 모든 이전 화면 제거
      );
    } catch (e) {
      print('로그아웃 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 중 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    }
  }

  // 로그아웃 확인 다이얼로그
  void _showLogoutDialog() {
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
                Navigator.of(context).pop(); // 다이얼로그 닫기
                _logout(); // 로그아웃 실행
              },
            ),
          ],
        );
      },
    );
  }

  // 액션 버튼 위젯
  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label 기능은 준비 중입니다.')),
            );
          },
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

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
                _isLoading
                    ? CircularProgressIndicator()
                    : CircleAvatar(
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
                        _userInfo['username'] ?? '사용자',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _userInfo['email'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (_userInfo['preferences']['foodTypes'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '선호 음식: ${_userInfo['preferences']['foodTypes'].join(', ')}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
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
                      _showLogoutDialog();
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
}