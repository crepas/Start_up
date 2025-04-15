// services/restaurant_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';

class RestaurantService {
  // API 엔드포인트 설정 - 환경에 따라 자동으로 선택
  final String _apiBaseUrl = _getApiBaseUrl();

  // 환경에 따른 API 주소 설정
  static String _getApiBaseUrl() {
    if (kReleaseMode) {
      // 실제 배포 환경
      return 'https://api.yourserver.com/api';
    } else if (kProfileMode) {
      // 프로필 모드
      return 'https://staging-api.yourserver.com/api';
    } else {
      // 개발 환경 - 에뮬레이터에서는 10.0.2.2가 호스트의 localhost를 가리킴
      return 'http://10.0.2.2:3000/api';
    }
  }

  // 모든 식당 데이터 가져오기
  Future<List<Restaurant>> getRestaurants() async {
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/restaurants'));

      switch (response.statusCode) {
        case 200:
          final List<dynamic> data = json.decode(response.body);
          return data.map((json) => Restaurant.fromJson(json)).toList();
        case 401:
          throw Exception('인증 오류가 발생했습니다. 다시 로그인해주세요.');
        case 403:
          throw Exception('접근 권한이 없습니다.');
        case 404:
          throw Exception('요청한 데이터를 찾을 수 없습니다.');
        case 500:
        case 502:
        case 503:
          throw Exception('서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
        default:
          throw Exception('식당 데이터를 불러오는 중 오류가 발생했습니다. (코드: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error fetching restaurants: $e');
      if (e is Exception) {
        rethrow; // 이미 처리된 예외는 그대로 전달
      }
      throw Exception('네트워크 연결 중 오류가 발생했습니다. 인터넷 연결을 확인해주세요.');
    }
  }

  // 좋아요 상태 업데이트
  Future<bool> updateFavoriteStatus(String restaurantId, bool isFavorite) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiBaseUrl/restaurants/$restaurantId/favorite'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isFavorite': isFavorite}),
      );

      switch (response.statusCode) {
        case 200:
          return true;
        case 401:
          throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
        case 404:
          throw Exception('해당 식당을 찾을 수 없습니다.');
        default:
          throw Exception('좋아요 상태 업데이트 중 오류가 발생했습니다. (코드: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error updating favorite status: $e');
      return false;
    }
  }

  // 오프라인 모드용 샘플 데이터 가져오기
  List<Restaurant> getSampleRestaurants() {
    return generateSampleRestaurants();
  }
}