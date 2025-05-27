import 'dart:convert';
import 'package:http/http.dart' as http;

class RestaurantImageService {
  // 백엔드 서버 URL (실제 IP로 변경하세요)
  static const String baseUrl = 'http://192.168.35.29:8081'; // 또는 본인의 로컬 IP

  // 이미지 캐시
  static final Map<String, String?> _imageCache = {};

  // 메인 이미지 가져오기 함수 (카카오맵 URL 포함)
  static Future<String?> getRestaurantImage(String restaurantName, String category, {String? placeUrl}) async {
    final cacheKey = '$restaurantName-$category-${placeUrl ?? ''}';
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey];
    }

    try {
      // 백엔드 API 호출 (place_url 포함)
      final uri = Uri.parse('$baseUrl/api/restaurant/image').replace(queryParameters: {
        'name': restaurantName,
        'category': category,
        if (placeUrl != null) 'placeUrl': placeUrl,
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 8)); // 타임아웃 8초로 증가

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['imageUrl'] != null) {
          String imageUrl = data['imageUrl'];
          _imageCache[cacheKey] = imageUrl;

          print('백엔드에서 이미지 받음: $imageUrl (출처: ${data['source']})');
          return imageUrl;
        }
      }
    } catch (e) {
      print('백엔드 이미지 API 호출 오류: $e');
    }

    // 실패 시 null 반환
    _imageCache[cacheKey] = null;
    return null;
  }

  // 통합 음식점 검색 (카카오맵 + 이미지)
  static Future<List<Map<String, dynamic>>> searchRestaurantsWithImages({
    required String query,
    required double latitude,
    required double longitude,
    int radius = 3000,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/restaurant/search?query=${Uri.encodeComponent(query)}&x=$longitude&y=$latitude&radius=$radius'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['restaurants'] != null) {
          List<Map<String, dynamic>> restaurants = List<Map<String, dynamic>>.from(data['restaurants']);

          print('백엔드에서 ${restaurants.length}개 음식점 + 이미지 받음');
          return restaurants;
        }
      }
    } catch (e) {
      print('통합 검색 API 호출 오류: $e');
    }

    return [];
  }

  // 캐시 초기화
  static void clearCache() {
    _imageCache.clear();
  }

  // 캐시 크기 확인
  static int getCacheSize() {
    return _imageCache.length;
  }

  // 백엔드 서버 연결 테스트
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/restaurant/cache/stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('백엔드 연결 테스트 실패: $e');
      return false;
    }
  }
}