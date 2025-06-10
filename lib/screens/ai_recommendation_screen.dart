import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:start_up/utils/api_config.dart';
import '../models/restaurant.dart';
import 'MainScreen.dart';

class AIRecommendationScreen extends StatefulWidget {
  @override
  _AIRecommendationScreenState createState() => _AIRecommendationScreenState();
}

class _AIRecommendationScreenState extends State<AIRecommendationScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _response;
  List<dynamic> _recommendations = [];
  bool _loading = false;

  Future<void> _getRecommendation() async {
    setState(() => _loading = true);

    final prompt = _controller.text;
    final url = Uri.parse('${getServerUrl()}/api/gpt-recommend');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _response = data['reply'];
          _recommendations = data['recommendations'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _response = '추천에 실패했습니다.';
          _recommendations = [];
          _loading = false;
        });
      }
    } catch (error) {
      setState(() {
        _response = '네트워크 오류가 발생했습니다.';
        _recommendations = [];
        _loading = false;
      });
    }
  }

  // 지도로 이동하는 함수
  void _navigateToMap(Map<String, dynamic> restaurant) {
    // AI 추천 음식점 데이터를 Restaurant 모델로 변환
    final Restaurant focusRestaurant = Restaurant(
      id: restaurant['id'] ?? '',
      name: restaurant['name'] ?? '음식점',
      address: restaurant['address'] ?? '',
      roadAddress: restaurant['address'] ?? '',
      lat: restaurant['coordinates'] != null ? restaurant['coordinates'][0] : 0.0,
      lng: restaurant['coordinates'] != null ? restaurant['coordinates'][1] : 0.0,
      categoryName: restaurant['category'] ?? '',
      foodTypes: [restaurant['category']?.split(' > ').last ?? '기타'],
      phone: '',
      placeUrl: '',
      priceRange: '중간',
      likes: int.tryParse(restaurant['likes']?.toString() ?? '0') ?? 0,
      reviews: [],
      images: ['assets/restaurant.png'],
      createdAt: DateTime.now(),
      reviewCount: 0,
      isOpen: true,
      hasParking: false,
      hasDelivery: false,
    );

    // MainScreen의 지도 탭으로 이동하면서 포커스할 음식점 전달
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialTab: 1, // 지도 탭
          selectedRestaurant: focusRestaurant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('AI 맛집 추천'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '예: 강남역 근처 회식하기 좋은 맛집 추천해줘',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.5),
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _getRecommendation,
                icon: Icon(Icons.smart_toy),
                label: Text('추천 받기'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_loading)
              Center(child: CircularProgressIndicator()),

            if (!_loading && (_response != null || _recommendations.isNotEmpty))
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 구조화된 추천 결과가 있는 경우
                      if (_recommendations.isNotEmpty) ...[
                        Text(
                          'AI 추천 맛집',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...(_recommendations.map((restaurant) =>
                            _buildRestaurantCard(restaurant, theme)
                        ).toList()),
                        const SizedBox(height: 16),
                      ],

                      // 기존 텍스트 응답 (요약)
                      if (_response != null) ...[
                        if (_recommendations.isNotEmpty)
                          Text(
                            '추천 요약',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: Text(
                            _response!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant, ThemeData theme) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 음식점 이름
            Text(
              restaurant['name'] ?? '음식점 이름',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 카테고리 및 평점
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  restaurant['category'] ?? '카테고리',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.favorite, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  '${restaurant['likes'] ?? '0'}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 주소
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    restaurant['address'] ?? '주소',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 추천 이유
            if (restaurant['reason'] != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  restaurant['reason'],
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 지도에서 보기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToMap(restaurant),
                icon: Icon(Icons.map, size: 20),
                label: Text('지도에서 보기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}