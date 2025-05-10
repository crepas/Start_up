import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import '../utils/api_config.dart';

class RestaurantService {
  // 서버 URL 가져오기
  final String baseUrl = getServerUrl();

  // 인증 헤더 가져오기
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // 주변 음식점 목록 가져오기
  Future<Map<String, dynamic>> getNearbyRestaurants({
    required double lat,
    required double lng,
    int radius = 2000,
    int page = 1,
    int limit = 10,
    String? sort,
    String? category,
    String? foodType,
    String? priceRange,
    String? query,
  }) async {
    try {
      final headers = await _getHeaders();

      // 쿼리 파라미터 구성
      final queryParams = {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radius.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (sort != null) queryParams['sort'] = sort;
      if (category != null) queryParams['category'] = category;
      if (foodType != null) queryParams['foodType'] = foodType;
      if (priceRange != null) queryParams['priceRange'] = priceRange;
      if (query != null) queryParams['query'] = query;

      // URL 구성
      final uri = Uri.parse('$baseUrl/restaurants').replace(
        queryParameters: queryParams,
      );

      // API 호출
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> restaurantsJson = data['restaurants'];

        // JSON을 Restaurant 객체 리스트로 변환
        final restaurants = restaurantsJson
            .map((json) => Restaurant.fromJson(json))
            .toList();

        return {
          'restaurants': restaurants,
          'totalPages': data['totalPages'],
          'currentPage': data['currentPage'],
          'total': data['total'],
        };
      } else {
        throw Exception('음식점 데이터를 불러오는데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('주변 음식점 조회 오류: $e');
      rethrow;
    }
  }

  // 음식점 상세 정보 가져오기
  Future<Restaurant> getRestaurantDetails(String id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Restaurant.fromJson(data['restaurant']);
      } else {
        throw Exception('음식점 상세 정보를 불러오는데 실패했습니다.');
      }
    } catch (e) {
      print('음식점 상세 조회 오류: $e');
      rethrow;
    }
  }

  // 리뷰 작성하기
  Future<bool> writeReview({
    required String restaurantId,
    required double rating,
    required String comment,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/restaurants/$restaurantId/reviews'),
        headers: headers,
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('리뷰 작성 오류: $e');
      return false;
    }
  }

  // 좋아요 추가/취소
  Future<Map<String, dynamic>> toggleLike(String restaurantId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/restaurants/$restaurantId/like'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'message': data['message'],
          'likes': data['likes'],
          'isLiked': data['isLiked'],
        };
      } else {
        throw Exception('좋아요 처리에 실패했습니다.');
      }
    } catch (e) {
      print('좋아요 오류: $e');
      rethrow;
    }
  }

  // 다음 행선지 추천
  Future<List<Restaurant>> getNextRecommendations({
    String? currentId,
    double? lat,
    double? lng,
  }) async {
    try {
      final headers = await _getHeaders();

      // 쿼리 파라미터 구성
      final queryParams = <String, String>{};

      if (currentId != null) queryParams['currentId'] = currentId;
      if (lat != null) queryParams['lat'] = lat.toString();
      if (lng != null) queryParams['lng'] = lng.toString();

      // URL 구성
      final uri = Uri.parse('$baseUrl/restaurants/recommend/next').replace(
        queryParameters: queryParams,
      );

      // API 호출
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> recommendationsJson = data['recommendations'];

        // JSON을 Restaurant 객체 리스트로 변환
        return recommendationsJson
            .map((json) => Restaurant.fromJson(json))
            .toList();
      } else {
        throw Exception('추천 데이터를 불러오는데 실패했습니다.');
      }
    } catch (e) {
      print('추천 조회 오류: $e');
      rethrow;
    }
  }

  // 카테고리별 음식점 가져오기
  Future<List<Restaurant>> getRestaurantsByCategory(String category, {int limit = 10}) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/categories/$category?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> restaurantsJson = data['restaurants'];

        return restaurantsJson
            .map((json) => Restaurant.fromJson(json))
            .toList();
      } else {
        throw Exception('카테고리별 음식점 데이터를 불러오는데 실패했습니다.');
      }
    } catch (e) {
      print('카테고리별 음식점 조회 오류: $e');
      rethrow;
    }
  }
}