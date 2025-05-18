import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';     // 하단 네비게이션 바 위젯
import '../widgets/ListView_AD.dart';      // 광고 항목 위젯
import '../widgets/ListView_RT.dart';      // 일반 식당 항목 위젯
import '../widgets/Filter.dart';           // 필터 위젯
import '../widgets/Rt_image.dart';         // 식당 이미지 위젯
import '../widgets/Rt_information.dart';   // 식당 정보 위젯
import '../widgets/Rt_ReviewList.dart';    // 식당 리뷰 목록 위젯
import '../models/restaurant.dart';        // 식당 데이터 모델
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/api_config.dart';         // API 설정 파일 import

/// 식당 목록 화면을 관리하는 StatefulWidget
/// 
/// 이 위젯은 식당 목록을 표시하고 필터링하는 화면을 구현합니다.
/// 
/// [selectedCategory] - 선택된 카테고리 (거리순, 가격대, 평점, 카테고리)
///   - 'distance': 거리순 정렬
///   - 'price': 가격대별 필터링
///   - 'rating': 평점 기준 필터링
///   - 'category': 음식 카테고리별 필터링
class ListScreen extends StatefulWidget {
  final String? selectedCategory;

  const ListScreen({
    Key? key,
    this.selectedCategory,
  }) : super(key: key);

  @override
  _ListScreenState createState() => _ListScreenState();
}

/// ListScreen의 상태 관리 클래스
/// 
/// 이 클래스는 식당 목록의 상태를 관리하고 UI를 구성합니다.
/// 주요 기능:
/// - 식당 데이터 관리
/// - 필터링 및 정렬
/// - UI 상태 관리 (확장/축소 등)
class _ListScreenState extends State<ListScreen> {
  // UI 관련 상수
  static const double _bannerHeight = 0.2;        // 배너 높이 비율 (화면 너비 기준)
  static const double _bannerMargin = 0.5;        // 배너 마진 비율 (기준 단위 기준)
  static const Duration _animationDuration = Duration(milliseconds: 300);  // 애니메이션 지속 시간
  static const double _bottomSpacing = 3.0;       // 하단 여백 (픽셀 단위)

  // 상태 변수
  int _currentIndex = 0;                          // 현재 선택된 하단 네비게이션 바 인덱스
  Set<int> _expandedIndices = {};                 // 현재 확장된 항목들의 인덱스 집합
  late List<Restaurant> restaurants;              // 식당 데이터 목록
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final baseUrl = getServerUrl();

      final response = await http.get(
        Uri.parse('$baseUrl/api/restaurants'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          restaurants = (data['restaurants'] as List)
              .map((item) => Restaurant.fromJson(item))
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load restaurants');
      }
    } catch (e) {
      print('식당 목록 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('식당 목록을 불러오는데 실패했습니다.');
    }
  }

  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      restaurants = restaurants.where((restaurant) {
        bool matches = true;
        
        // 거리순 정렬
        if (filters['sortBy'] == 'distance') {
          // TODO: 현재 위치 기준으로 거리 계산 및 정렬
        }
        
        // 가격대 필터링
        if (filters['priceRange'] != null) {
          matches = matches && restaurant.priceRange == filters['priceRange'];
        }
        
        // 평점 필터링
        if (filters['minRating'] != null) {
          matches = matches && restaurant.rating >= filters['minRating'];
        }
        
        // 카테고리 필터링
        if (filters['categories'] != null && filters['categories'].isNotEmpty) {
          matches = matches && filters['categories'].contains(restaurant.categoryName);
        }
        
        return matches;
      }).toList();
    });
  }

  void _showErrorSnackBar(String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 항목 확장/축소 토글 함수
  /// 
  /// [index] - 토글할 항목의 인덱스
  /// 
  /// 동작:
  /// - 이미 확장된 항목이면 축소
  /// - 축소된 항목이면 확장
  /// 
  /// TODO:
  /// - 애니메이션 개선
  /// - 다중 선택 지원
  void toggleExpanded(int index) {
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        _expandedIndices.add(index);
      }
    });
  }

  /// 배너 이미지 위젯 생성
  /// 
  /// [screenWidth] - 화면 너비
  /// [baseUnit] - 기준 단위 (화면 너비 / 360)
  /// 
  /// 반환값:
  /// - Widget: 배너 이미지를 포함한 컨테이너
  /// 
  /// 기능:
  /// - 배너 이미지 표시
  /// - 이미지 로드 실패 시 에러 UI 표시
  /// - 반응형 크기 조정
  Widget _buildBannerImage(double screenWidth, double baseUnit) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: baseUnit * _bannerMargin,
        horizontal: baseUnit * _bannerMargin,
      ),
      width: double.infinity,
      height: screenWidth * _bannerHeight,
      color: Colors.white,
      child: Image.asset(
        'assets/banner.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.grey[600]),
                  SizedBox(height: 8),
                  Text(
                    '배너 이미지를 불러올 수 없습니다',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 식당 목록 아이템 위젯 생성
  /// 
  /// [restaurant] - 표시할 식당 정보
  /// [index] - 아이템의 인덱스
  /// 
  /// 반환값:
  /// - Widget: 식당 정보를 표시하는 컬럼 위젯
  /// 
  /// 기능:
  /// - 광고/일반 식당 구분 표시
  /// - 확장/축소 상태에 따른 추가 정보 표시
  /// - 애니메이션 효과
  Widget _buildRestaurantItem(Restaurant restaurant, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        restaurant.isAd
            ? ListViewAd(
                key: ValueKey(restaurant.id),
                restaurant: restaurant,
                isExpanded: _expandedIndices.contains(index),
                onTap: () => toggleExpanded(index),
              )
            : ListViewRt(
                key: ValueKey(restaurant.id),
                restaurant: restaurant,
                isExpanded: _expandedIndices.contains(index),
                onTap: () => toggleExpanded(index),
              ),
        if (_expandedIndices.contains(index))
          AnimatedContainer(
            duration: _animationDuration,
            curve: Curves.easeInOut,
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RtImage(images: restaurant.images),
                RtInformation(
                  likes: restaurant.likes,
                  reviewCount: restaurant.reviews.length,
                ),
                RtReviewList(reviews: restaurant.reviews),
                SizedBox(height: _bottomSpacing),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '맛집 목록',
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 필터 섹션
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.cardColor,
            child: Row(
          children: [
                Expanded(
                  child: Filter(
                    onFilterChanged: (filters) {
                      _applyFilters(filters);
                    },
                  ),
                ),
              ],
            ),
            ),

            // 식당 목록
            Expanded(
            child: _isLoading
                ? CircularProgressIndicator()
                : ListView.builder(
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      final isExpanded = _expandedIndices.contains(index);

                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 식당 기본 정보
                            ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  restaurant.images.first,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: theme.cardColor,
                                      child: Icon(Icons.restaurant, color: colorScheme.primary),
                                    );
                                  },
                                ),
                              ),
                              title: Text(
                                restaurant.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    restaurant.categoryName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: colorScheme.primary,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        restaurant.rating.toString(),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '(${restaurant.reviewCount})',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: colorScheme.primary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedIndices.remove(index);
                                    } else {
                                      _expandedIndices.add(index);
                                    }
                                  });
                                },
                              ),
                            ),

                            // 확장된 상세 정보
                            if (isExpanded)
                              Container(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(color: theme.dividerColor),
                                    SizedBox(height: 8),
                                    Text(
                                      '영업 정보',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildInfoChip(
                                          icon: Icons.access_time,
                                          label: restaurant.isOpen ? '영업중' : '영업종료',
                                          color: restaurant.isOpen ? colorScheme.primary : colorScheme.error,
                                          theme: theme,
                                        ),
                                        SizedBox(width: 8),
                                        if (restaurant.hasParking)
                                          _buildInfoChip(
                                            icon: Icons.local_parking,
                                            label: '주차',
                                            color: colorScheme.primary,
                                            theme: theme,
                                          ),
                                        SizedBox(width: 8),
                                        if (restaurant.hasDelivery)
                                          _buildInfoChip(
                                            icon: Icons.delivery_dining,
                                            label: '배달',
                                            color: colorScheme.primary,
                                            theme: theme,
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      '주소',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      restaurant.roadAddress,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildActionButton(
                                          icon: Icons.directions,
                                          label: '길찾기',
                                          onTap: () {
                                            // 길찾기 기능 구현
                                          },
                                          theme: theme,
                                          colorScheme: colorScheme,
                                        ),
                                        _buildActionButton(
                                          icon: restaurant.isLiked ? Icons.favorite : Icons.favorite_border,
                                          label: '찜하기',
                                          onTap: () {
                                            // 찜하기 기능 구현
                                          },
                                          theme: theme,
                                          colorScheme: colorScheme,
                                        ),
                                        _buildActionButton(
                                          icon: Icons.rate_review,
                                          label: '리뷰',
                                          onTap: () {
                                            // 리뷰 기능 구현
                                          },
                                          theme: theme,
                                          colorScheme: colorScheme,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                  );
                },
              ),
            ),
          ],
        ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.primary),
          SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 메모리 정리
    // TODO: 리소스 해제 로직 추가
    super.dispose();
  }
}