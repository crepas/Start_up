import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http; // API 호출용
// import 'dart:convert'; // JSON 변환용

class ListView_AD extends StatefulWidget {
  @override
  _ListView_ADState createState() => _ListView_ADState();
}

class _ListView_ADState extends State<ListView_AD> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isRotated = false;

  // ============================================
  // MongoDB 저장 방식 (현재는 주석 처리)
  // ============================================
  /*
  // API 엔드포인트 설정
  final String _apiBaseUrl = 'http://localhost:3000/api'; // Node.js 서버 주소

  // 회전 상태 저장
  Future<void> _saveRotationStateToMongoDB() async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/rotation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'isRotated': _isRotated,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save rotation state');
      }
    } catch (e) {
      print('Error saving rotation state: $e');
    }
  }

  // 회전 상태 로드
  Future<void> _loadRotationStateFromMongoDB() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/rotation'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isRotated = data['isRotated'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading rotation state: $e');
    }
  }
  */

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // MongoDB에서 상태 로드 (주석 해제 필요)
    // _loadRotationStateFromMongoDB();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleRotation() {
    setState(() {
      _isRotated = !_isRotated;
      if (_isRotated) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      // MongoDB에 상태 저장 (주석 해제 필요)
      // _saveRotationStateToMongoDB();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ============================================
    // 1. 기본 설정
    // ============================================
    // 화면 크기 계산을 위한 기본 단위 설정
    final screenWidth = MediaQuery.of(context).size.width;
    final baseUnit = screenWidth / 360; // 기준 단위 (360은 디자인 기준 너비)

    return Container(
      // ============================================
      // 2. 컨테이너 기본 스타일
      // ============================================
      // 외부 여백 설정
      margin: EdgeInsets.symmetric(
        vertical: baseUnit * 1, // 3 -> 6
        horizontal: baseUnit * 7, // 7 -> 10
      ),
      // 내부 여백 설정
      padding: EdgeInsets.all(baseUnit * 7), // 9 -> 12
      // 컨테이너 디자인 설정
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(baseUnit * 3), // 3 -> 6
      ),
      width: double.infinity,
      height: baseUnit * 75, // 75 -> 95

      // ============================================
      // 3. 내부 컨텐츠 레이아웃
      // ============================================
      child: Row(
        children: [
          // ============================================
          // 4. 왼쪽 영역: 이미지와 AD 배지
          // ============================================
          Stack(
            children: [
              // 식당 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(baseUnit * 4), // 1 -> 4
                child: Image.asset(
                  'assets/restaurant.png',
                  width: baseUnit * 65, // 60 -> 75
                  height: baseUnit * 65, // 60 -> 75
                  fit: BoxFit.cover,
                ),
              ),
              // AD 배지
              Positioned(
                top: baseUnit * 4, // 4 -> 7
                left: baseUnit * 4, // 4 -> 7
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: baseUnit * 2, // 4 -> 7
                    vertical: baseUnit * 0.2, // 1 -> 2
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(baseUnit * 6), // 3 -> 6
                  ),
                  child: Text(
                    'AD',
                    style: TextStyle(
                      fontSize: baseUnit * 6, // 5 -> 8
                      fontWeight: FontWeight.bold,
                      color: Colors.black38,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ============================================
          // 5. 중간 영역: 텍스트 정보
          // ============================================
          SizedBox(width: baseUnit * 9), // 9 -> 12
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 식당 이름
                Text(
                  '인하반점',
                  style: TextStyle(
                    fontSize: baseUnit * 15, // 15 -> 18
                    fontWeight: FontWeight.w400,
                  ),
                ),
                // 거리 정보
                Text(
                  '305m 이내',
                  style: TextStyle(
                    fontSize: baseUnit * 11, // 11 -> 14
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // ============================================
          // 6. 오른쪽 영역: 추가 아이콘
          // ============================================
          GestureDetector(
            onTap: _toggleRotation,
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 0.125).animate(_controller),
              child: Icon(
                Icons.add,
                size: baseUnit * 22, // 18 -> 22
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
