import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http; // API 호출용
// import 'dart:convert'; // JSON 변환용

class ListView_RT extends StatefulWidget {
  @override
  _ListView_RTState createState() => _ListView_RTState();
}

class _ListView_RTState extends State<ListView_RT> {
  bool isFavorite = false; // 좋아요 상태를 저장하는 변수

  // ============================================
  // MongoDB 저장 방식 (현재는 주석 처리)
  // ============================================
  /*
  // API 엔드포인트 설정
  final String _apiBaseUrl = 'http://localhost:3000/api'; // Node.js 서버 주소

  // 좋아요 상태 저장
  Future<void> _saveFavoriteStateToMongoDB() async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/favorite'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'restaurantId': '신촌설렁탕', // 실제로는 고유 ID 사용
          'isFavorite': isFavorite,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save favorite state');
      }
    } catch (e) {
      print('Error saving favorite state: $e');
    }
  }

  // 좋아요 상태 로드
  Future<void> _loadFavoriteStateFromMongoDB() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/favorite/신촌설렁탕'), // 실제로는 고유 ID 사용
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          isFavorite = data['isFavorite'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading favorite state: $e');
    }
  }
  */

  @override
  void initState() {
    super.initState();
    // MongoDB에서 상태 로드 (주석 해제 필요)
    // _loadFavoriteStateFromMongoDB();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseUnit = screenWidth / 360; // 기준 단위 (360은 디자인 기준 너비)

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: baseUnit * 4, // 4.0
        horizontal: baseUnit * 8, // 8.0
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(baseUnit * 5), // 5
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(0, baseUnit * 0.8), // 0.8
            blurRadius: baseUnit * 4, // 4
            spreadRadius: 0,
          ),
        ],
      ),
      width: double.infinity,
      height: screenWidth * 0.14, // 기존 비율 유지
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.025, // 기존 비율 유지
          vertical: screenWidth * 0.018, // 기존 비율 유지
        ),
        child: Row(
          children: [
            // 음식점 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(baseUnit * 5), // 5
              child: Image.asset(
                'assets/restaurant.png', // 가게 사진
                width: screenWidth * 0.12, // 기존 비율 유지
                height: screenWidth * 0.12, // 기존 비율 유지
                fit: BoxFit.cover, // 이미지가 컨테이너에 맞게 채워지도록 설정
              ),
            ),

            // 이미지와 텍스트 사이 간격
            SizedBox(width: screenWidth * 0.02), // 기존 비율 유지

            // 음식점 정보 컬럼
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 음식점 이름
                  Text(
                    '신촌설렁탕',
                    style: TextStyle(
                      color: const Color(0xFF151618),
                      fontSize: screenWidth * 0.033, // 기존 비율 유지
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  // 거리 텍스트
                  Text(
                    '350m 이내',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: screenWidth * 0.028, // 기존 비율 유지
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // 좋아요 버튼
            GestureDetector(
              onTap: () {
                setState(() {
                  isFavorite = !isFavorite; // 상태 토글
                  // MongoDB에 상태 저장 (주석 해제 필요)
                  // _saveFavoriteStateToMongoDB();
                });
              },
              child: Image.asset(
                isFavorite ? 'assets/Heart_P.png' : 'assets/Heart_G.png',
                width: screenWidth * 0.073, // 기존 비율 유지
                height: screenWidth * 0.063, // 기존 비율 유지
              ),
            ),
          ],
        ),
      ),
    );
  }
}