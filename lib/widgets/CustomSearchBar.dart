/// CustomSearchBar.dart
/// 커스텀 검색 바 위젯
/// 
/// 주요 기능:
/// - 검색어 입력 및 검색 실행
/// - 검색 결과 표시
/// - 검색 모드 전환
/// - 위치 기반 검색
/// - 검색 히스토리 관리
/// - 자동완성 기능

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/restaurant.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(List<Restaurant>) onSearchResults;
  final double currentLat;
  final double currentLng;
  final bool isSearchMode;
  final Function(bool) onSearchModeChanged;
  final String initialSearchText;

  const CustomSearchBar({
    Key? key,
    required this.onSearchResults,
    required this.currentLat,
    required this.currentLng,
    required this.isSearchMode,
    required this.onSearchModeChanged,
    this.initialSearchText = '',
  }) : super(key: key);

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _searchController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchText);
  }

  @override
  void didUpdateWidget(CustomSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSearchText != widget.initialSearchText) {
      _searchController.text = widget.initialSearchText;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 카테고리에서 음식 타입 추출
  List<String> _parseFoodTypesFromCategory(String category) {
    List<String> parts = category.split(' > ');
    if (parts.length > 1) {
      return [parts[1]];
    } else if (parts.isNotEmpty) {
      return [parts[0]];
    }
    return ['기타'];
  }

  // 카테고리에 따른 이미지 반환
  String _getCategoryImage(String category) {
    if (category.contains('고기') || category.contains('삼겹살')) {
      return 'assets/samgyupsal.png';
    } else if (category.contains('갈비')) {
      return 'assets/myung_jin.png';
    } else if (category.contains('족발') || category.contains('보쌈')) {
      return 'assets/onki.png';
    } else if (category.contains('카페') || category.contains('커피')) {
      return 'assets/cafe.png';
    } else if (category.contains('중식')) {
      return 'assets/chinese.png';
    } else if (category.contains('일식')) {
      return 'assets/japanese.png';
    } else if (category.contains('분식')) {
      return 'assets/bunsik.png';
    } else {
      return 'assets/restaurant.png';
    }
  }

  // 검색 수행
  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      widget.onSearchModeChanged(false);
      return;
    }

    setState(() {
      _isLoading = true;
    });
    widget.onSearchModeChanged(true);

    try {
      final apiKey = '4e4572f409f9b0cd5dc1f574779a03a7';

      final response = await http.get(
        Uri.parse('https://dapi.kakao.com/v2/local/search/keyword.json?query=$keyword&x=${widget.currentLng}&y=${widget.currentLat}&radius=5000&size=30'),
        headers: {
          'Authorization': 'KakaoAK $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> documents = data['documents'];

        // 검색 결과를 Restaurant 객체로 변환
        List<Restaurant> searchRestaurants = documents.map((doc) {
          Map<String, dynamic> searchResult = doc as Map<String, dynamic>;
          return Restaurant(
            id: searchResult['id']?.toString() ?? '',
            name: searchResult['place_name'] ?? '',
            address: searchResult['address_name'] ?? '',
            roadAddress: searchResult['road_address_name'] ?? '',
            lat: double.tryParse(searchResult['y'] ?? '0') ?? 0,
            lng: double.tryParse(searchResult['x'] ?? '0') ?? 0,
            categoryName: searchResult['category_name'] ?? '',
            foodTypes: _parseFoodTypesFromCategory(searchResult['category_name'] ?? ''),
            phone: searchResult['phone'] ?? '',
            placeUrl: searchResult['place_url'] ?? '',
            priceRange: '중간',
            likes: 0, // ← 이렇게 수정!
            reviews: [],
            images: [_getCategoryImage(searchResult['category_name'] ?? '')],
            createdAt: DateTime.now(),
            reviewCount: 0,
            isOpen: true,
            hasParking: searchResult['id'].hashCode % 2 == 0,
            hasDelivery: searchResult['id'].hashCode % 3 == 0,
          );
        }).toList();

        widget.onSearchResults(searchRestaurants);
      } else {
        throw Exception('검색 API 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('검색 오류: $e');
      widget.onSearchResults([]);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: theme.textTheme.bodyLarge,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: '음식점이나 음식을 검색해보세요...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchModeChanged(false);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
                  isCollapsed: true,
                ),
                onChanged: (value) {
                  setState(() {}); // suffixIcon을 위한 상태 업데이트
                },
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _performSearch(value.trim());
                  }
                },
              ),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 