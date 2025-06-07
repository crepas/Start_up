import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/api_config.dart';

class RestaurantService {
  // 서버 URL 가져오기
  static final String baseUrl = getServerUrl();

  // 인증 헤더 가져오기
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // 좋아요 토글 (추가/취소)
  Future<Map<String, dynamic>> toggleLike(String restaurantId) async {
    try {
      final headers = await _getHeaders();

      if (headers['Authorization'] == 'Bearer ') {
        return {
          'success': false,
          'error': '로그인이 필요합니다.'
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/restaurants/$restaurantId/like'),
        headers: headers,
      );

      print('좋아요 토글 응답 상태: ${response.statusCode}');
      print('좋아요 토글 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'likes': data['likes'],
          'isLiked': data['isLiked'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? '좋아요 처리에 실패했습니다.'
        };
      }
    } catch (e) {
      print('좋아요 토글 오류: $e');
      return {
        'success': false,
        'error': '네트워크 오류가 발생했습니다.'
      };
    }
  }

  // 좋아요 상태 확인
  Future<Map<String, dynamic>> getLikeStatus(String restaurantId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/$restaurantId/like/status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'isLiked': data['isLiked'] ?? false,
          'likes': data['likes'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'isLiked': false,
          'likes': 0,
        };
      }
    } catch (e) {
      print('좋아요 상태 확인 오류: $e');
      return {
        'success': false,
        'isLiked': false,
        'likes': 0,
      };
    }
  }

  // 리뷰 추가 (RestaurantService와 동일한 엔드포인트 사용)
  static Future<Map<String, dynamic>> addReview({
    required String restaurantId,
    required String restaurantName,
    required String comment,
    required double rating,
  }) async {
    try {
      final headers = await _getHeaders();

      if (headers['Authorization'] == 'Bearer ') {
        return {
          'success': false,
          'error': '로그인이 필요합니다.'
        };
      }

      // RestaurantService와 동일한 엔드포인트 사용
      final response = await http.post(
        Uri.parse('$baseUrl/restaurants/$restaurantId/reviews'),
        headers: headers,
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      );

      print('리뷰 추가 응답 상태: ${response.statusCode}');
      print('리뷰 추가 응답 본문: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'review': data['review'],
          'reviewCount': data['reviewCount'],
          'averageRating': data['averageRating'],
          'message': data['message'] ?? '리뷰가 성공적으로 등록되었습니다.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? '리뷰 추가에 실패했습니다.'
        };
      }
    } catch (e) {
      print('리뷰 추가 오류: $e');
      return {
        'success': false,
        'error': '네트워크 오류가 발생했습니다.'
      };
    }
  }

  // 리뷰 목록 가져오기
  static Future<Map<String, dynamic>> getReviews(String restaurantId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/$restaurantId/reviews'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reviews': data['reviews'] ?? [],
          'reviewCount': data['reviewCount'] ?? 0,
          'averageRating': data['averageRating'] ?? 0.0,
        };
      } else {
        return {
          'success': false,
          'error': '리뷰를 불러올 수 없습니다.'
        };
      }
    } catch (e) {
      print('리뷰 목록 가져오기 오류: $e');
      return {
        'success': false,
        'error': '네트워크 오류가 발생했습니다.'
      };
    }
  }

  // 리뷰 수정
  static Future<Map<String, dynamic>> updateReview({
    required String restaurantId,
    required String reviewId,
    required String comment,
    required double rating,
  }) async {
    try {
      final headers = await _getHeaders();

      if (headers['Authorization'] == 'Bearer ') {
        return {
          'success': false,
          'error': '로그인이 필요합니다.'
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/restaurants/$restaurantId/reviews/$reviewId'),
        headers: headers,
        body: jsonEncode({
          'comment': comment,
          'rating': rating,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'review': data['review'],
          'message': data['message'] ?? '리뷰가 수정되었습니다.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? '리뷰 수정에 실패했습니다.'
        };
      }
    } catch (e) {
      print('리뷰 수정 오류: $e');
      return {
        'success': false,
        'error': '네트워크 오류가 발생했습니다.'
      };
    }
  }

  // 리뷰 삭제
  static Future<Map<String, dynamic>> deleteReview({
    required String restaurantId,
    required String reviewId,
  }) async {
    try {
      final headers = await _getHeaders();

      if (headers['Authorization'] == 'Bearer ') {
        return {
          'success': false,
          'error': '로그인이 필요합니다.'
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/restaurants/$restaurantId/reviews/$reviewId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? '리뷰가 삭제되었습니다.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? '리뷰 삭제에 실패했습니다.'
        };
      }
    } catch (e) {
      print('리뷰 삭제 오류: $e');
      return {
        'success': false,
        'error': '네트워크 오류가 발생했습니다.'
      };
    }
  }
}