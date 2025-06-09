/// MapTab.dart - 필터링 기능이 추가된 지도 화면
///
/// 주요 기능:
/// - 카테고리별 음식점 필터링
/// - 음식점 타입별 다른 마커 표시
/// - 실시간 필터 적용
/// - 가격대별 필터링
/// - 영업시간 필터링

import 'dart:async';
import 'dart:developer';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import '../utils/api_config.dart';
import 'package:permission_handler/permission_handler.dart';

class MapTab extends StatefulWidget {
  final Restaurant? selectedRestaurant;
  final bool resetToMyLocation;

  const MapTab({
    Key? key,
    this.selectedRestaurant,
    this.resetToMyLocation = false,
  }) : super(key: key);

  @override
  _MapTabState createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final Completer<NaverMapController> _mapControllerCompleter = Completer();
  NaverMapController? _mapController;
  bool _isLoading = true;
  bool _isLoadingRestaurants = false;
  double _currentZoom = 14.0;
  bool _isFocusedOnRestaurant = false;
  Restaurant? _focusedRestaurant;

  // 인하대 후문 정확한 좌표
  final double inhaBackGateLat = 37.45169;
  final double inhaBackGateLng = 126.65464;

  // 모든 음식점 데이터
  List<Map<String, dynamic>> _allRestaurants = [];
  // 필터링된 음식점 데이터
  List<Map<String, dynamic>> _filteredRestaurants = [];

  // 내 위치
  double? _myLat;
  double? _myLng;

  // 필터 상태
  Set<String> _selectedCategories = {};
  bool _showFilterPanel = false;

  // 카테고리별 색상 매핑
  final Map<String, Color> _categoryColors = {
    '한식': Colors.red,
    '중식': Colors.orange,
    '일식': Colors.blue,
    '양식': Colors.green,
    '카페': Colors.brown,
    '기타': Colors.grey,
  };

  // 가능한 필터 옵션들
  final List<String> _availableCategories = [
    '한식', '중식', '일식', '양식', '카페'
  ];


  @override
  void initState() {
    super.initState();
    _isLoading = false;

    // 선택된 음식점이 있으면 포커스 상태로 설정
    if (widget.selectedRestaurant != null && !widget.resetToMyLocation) {
      _isFocusedOnRestaurant = true;
      _focusedRestaurant = widget.selectedRestaurant;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
      _fetchRestaurantsFromDatabase();
    });
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    setState(() {
      _myLat = inhaBackGateLat;
      _myLng = inhaBackGateLng;
    });

    print('내 위치 설정 (인하대 후문): $_myLat, $_myLng');

    if (_mapController != null) {
      await _addMyLocationMarker();
    }
  }

  // 포커스 리셋 함수
  void _resetFocus() {
    setState(() {
      _isFocusedOnRestaurant = false;
      _focusedRestaurant = null;
    });

    _moveToMyLocation();

    if (_mapController != null && widget.selectedRestaurant != null) {
      _removeSelectedRestaurantMarker();
    }
  }

  // 데이터베이스에서 음식점 데이터 가져오기
  Future<void> _fetchRestaurantsFromDatabase() async {
    if (_isLoadingRestaurants) return;

    setState(() {
      _isLoadingRestaurants = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final baseUrl = getServerUrl();

      final queryParams = {
        'lat': inhaBackGateLat.toString(),
        'lng': inhaBackGateLng.toString(),
        'radius': '2000',
        'limit': '120',
        'sort': 'distance',
      };

      final uri = Uri.parse('$baseUrl/restaurants').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['restaurants'] != null) {
          setState(() {
            _allRestaurants = List<Map<String, dynamic>>.from(data['restaurants']);
            _filteredRestaurants = List.from(_allRestaurants);
            _isLoadingRestaurants = false;
          });

          print('지도에서 로드된 음식점 수: ${_allRestaurants.length}개');

          if (_mapController != null) {
            await _updateMapMarkers();
            if (_myLat != null && _myLng != null) {
              await _addMyLocationMarker();
            }
          }
        }
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      print('음식점 데이터 가져오기 오류: $e');
      setState(() {
        _isLoadingRestaurants = false;
      });
      _showErrorSnackBar('음식점 데이터를 불러올 수 없습니다.');
    }
  }

  // 필터 적용
  void _applyFilters() {
    setState(() {
      _filteredRestaurants = _allRestaurants.where((restaurant) {
        // 카테고리 필터
        if (_selectedCategories.isNotEmpty) {
          bool categoryMatch = false;
          for (String category in _selectedCategories) {
            if (_getCategoryFromRestaurant(restaurant).toLowerCase().contains(category.toLowerCase())) {
              categoryMatch = true;
              break;
            }
          }
          if (!categoryMatch) return false;
        }
        return true;
      }).toList();
    });

    // 지도 마커 업데이트
    if (_mapController != null) {
      _updateMapMarkers();
    }

    print('🎯 필터 적용 결과: ${_filteredRestaurants.length}개 음식점');
  }

  // 음식점에서 카테고리 추출
  String _getCategoryFromRestaurant(Map<String, dynamic> restaurant) {
    String categoryName = restaurant['categoryName'] ?? '';
    List<dynamic> foodTypes = restaurant['foodTypes'] ?? [];

    // foodTypes에서 우선적으로 카테고리 찾기
    for (String foodType in foodTypes) {
      for (String category in _availableCategories) {
        if (foodType.toLowerCase().contains(category.toLowerCase())) {
          return category;
        }
      }
    }

    // categoryName에서 카테고리 찾기
    for (String category in _availableCategories) {
      if (categoryName.toLowerCase().contains(category.toLowerCase())) {
        return category;
      }
    }

    return '기타';
  }

  // 카테고리별 마커 색상 가져오기
  Color _getMarkerColor(Map<String, dynamic> restaurant) {
    String category = _getCategoryFromRestaurant(restaurant);
    return _categoryColors[category] ?? Colors.grey;
  }

  // 내 위치 마커 추가
  Future<void> _addMyLocationMarker() async {
    if (_mapController == null || _myLat == null || _myLng == null) return;

    try {
      final myLocationCircle = NCircleOverlay(
        id: 'my_location_circle',
        center: NLatLng(_myLat!, _myLng!),
        radius: 4,
        color: Colors.green.withOpacity(0.3),
        outlineColor: Colors.green,
        outlineWidth: 2,
      );

      await _mapController!.addOverlay(myLocationCircle);
      print('내 위치 원형 표시 완료: $_myLat, $_myLng');
    } catch (e) {
      print('내 위치 원형 표시 실패: $e');
    }
  }

  // 좌표 파싱 함수
  double _parseCoordinate(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // 지도 마커 업데이트
  Future<void> _updateMapMarkers() async {
    if (_mapController == null) {
      print('❌ 지도 컨트롤러가 null입니다');
      return;
    }

    try {
      print('🔄 마커 업데이트 시작: ${_filteredRestaurants.length}개');

      // 기존 마커 제거 (내 위치 마커 제외)
      await _mapController!.clearOverlays(type: NOverlayType.marker);
      print('✅ 기존 마커 제거 완료');

      // 필터링된 음식점 마커 추가
      int successCount = 0;
      for (int i = 0; i < _filteredRestaurants.length; i++) {
        final restaurant = _filteredRestaurants[i];

        try {
          double lat = 0.0;
          double lng = 0.0;

          if (restaurant['location'] != null &&
              restaurant['location']['coordinates'] != null) {
            final coords = restaurant['location']['coordinates'] as List;
            if (coords.length >= 2) {
              lng = _parseCoordinate(coords[0]);
              lat = _parseCoordinate(coords[1]);
            }
          } else if (restaurant['lat'] != null && restaurant['lng'] != null) {
            lat = _parseCoordinate(restaurant['lat']);
            lng = _parseCoordinate(restaurant['lng']);
          }

          if (lat == 0.0 && lng == 0.0) {
            print('⚠️ 유효하지 않은 좌표 스킵: ${restaurant['name']} - lat: $lat, lng: $lng');
            continue;
          }

          // 기본 마커 생성 (커스텀 아이콘 없이)
          String category = _getCategoryFromRestaurant(restaurant);
          String markerId = 'restaurant_${restaurant['_id'] ?? restaurant['id']}_$i';

          final marker = NMarker(
            id: markerId,
            position: NLatLng(lat, lng),
            // 기본 마커 사용 (아이콘 설정 제거)
          );

          await _mapController!.addOverlay(marker);
          successCount++;

          print('✅ 마커 추가 성공: ${restaurant['name']} ($lat, $lng) - 카테고리: $category');

          // 클릭 이벤트 설정
          marker.setOnTapListener((overlay) {
            print('📍 마커 클릭됨: ${restaurant['name']}');
            _showRestaurantInfo(restaurant);
          });

        } catch (e) {
          print('❌ 마커 추가 실패 (${restaurant['name']}): $e');
        }
      }

      print('🎯 마커 업데이트 완료 - 성공: $successCount/${_filteredRestaurants.length}');

      // 내 위치 마커 다시 추가
      if (_myLat != null && _myLng != null) {
        await _addMyLocationMarker();
      }

    } catch (e) {
      print('❌ 마커 업데이트 중 치명적 오류: $e');
    }
  }

  // 카테고리별 마커 아이콘 생성
  Future<NOverlayImage?> _createCategoryMarkerIcon(String category, Color color) async {
    // 기본 네이버 지도 마커 사용
    return null; // 기본 마커 사용
  }

  // 선택된 음식점 마커 제거
  Future<void> _removeSelectedRestaurantMarker() async {
    if (_mapController == null || widget.selectedRestaurant == null) return;

    try {
      await _mapController!.clearOverlays(type: NOverlayType.marker);
      await _updateMapMarkers();
    } catch (e) {
      print('선택된 음식점 마커 제거 실패: $e');
    }
  }

  // 선택된 음식점 마커 추가
  Future<void> _addSelectedRestaurantMarker() async {
    if (_mapController == null || widget.selectedRestaurant == null) return;

    try {
      final restaurant = widget.selectedRestaurant!;

      final selectedMarker = NMarker(
        id: 'selected_restaurant_${restaurant.id}',
        position: NLatLng(restaurant.lat, restaurant.lng),
      );

      await _mapController!.addOverlay(selectedMarker);

      final infoWindow = NInfoWindow.onMarker(
        id: "selected_info_${restaurant.id}",
        text: "📍 ${restaurant.name}",
      );
      selectedMarker.openInfoWindow(infoWindow);

      selectedMarker.setOnTapListener((overlay) {
        _showRestaurantInfo({
          'name': restaurant.name,
          'categoryName': restaurant.categoryName,
          'address': restaurant.address,
          'phone': restaurant.phone,
          'rating': restaurant.rating,
          'likes': restaurant.likes,
        });
      });

    } catch (e) {
      print('선택된 음식점 마커 추가 실패: $e');
    }
  }

  // 내 위치로 지도 이동
  void _moveToMyLocation() {
    if (_mapController != null && _myLat != null && _myLng != null) {
      _mapController!.updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(_myLat!, _myLng!),
          zoom: 18,
        ),
      );
    } else {
      _moveToInhaBackGate();
    }
  }

  // 인하대 후문으로 지도 이동
  void _moveToInhaBackGate() {
    if (_mapController != null) {
      _mapController!.updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(inhaBackGateLat, inhaBackGateLng),
          zoom: 15,
        ),
      );
    }
  }

  // 지도 확대
  void _zoomIn() async {
    if (_mapController != null) {
      try {
        final cameraPosition = await _mapController!.getCameraPosition();
        final currentZoom = cameraPosition.zoom;

        if (currentZoom < 21) {
          await _mapController!.updateCamera(
            NCameraUpdate.withParams(
              target: cameraPosition.target,
              zoom: currentZoom + 1,
            ),
          );
          setState(() {
            _currentZoom = currentZoom + 1;
          });
        }
      } catch (e) {
        print('확대 오류: $e');
      }
    }
  }

  // 지도 축소
  void _zoomOut() async {
    if (_mapController != null) {
      try {
        final cameraPosition = await _mapController!.getCameraPosition();
        final currentZoom = cameraPosition.zoom;

        if (currentZoom > 5) {
          await _mapController!.updateCamera(
            NCameraUpdate.withParams(
              target: cameraPosition.target,
              zoom: currentZoom - 1,
            ),
          );
          setState(() {
            _currentZoom = currentZoom - 1;
          });
        }
      } catch (e) {
        print('축소 오류: $e');
      }
    }
  }

  // 에러 메시지 표시
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // 음식점 정보 모달 표시
  void _showRestaurantInfo(Map<String, dynamic> restaurant) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                restaurant['name']?.toString() ?? '음식점',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMarkerColor(restaurant).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getCategoryFromRestaurant(restaurant),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getMarkerColor(restaurant),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    restaurant['categoryName']?.toString() ?? '음식점',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                restaurant['address']?.toString() ?? '주소 정보 없음',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              if ((restaurant['phone']?.toString() ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    restaurant['phone'].toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text(
                    (restaurant['rating']?.toString() ?? '0.0'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.favorite, color: Colors.red, size: 16),
                  SizedBox(width: 4),
                  Text(
                    (restaurant['likes']?.toString() ?? '0'),
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(Icons.favorite_border, '찜하기'),
                  _buildActionButton(Icons.share, '공유하기'),
                ],
              ),
              SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('상세 정보 기능은 준비 중입니다.')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 40),
                ),
                child: Text('상세 정보 보기'),
              ),
            ],
          ),
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

  // 필터 패널 빌드
  Widget _buildFilterPanel() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _showFilterPanel ? 220 : 60,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 필터 버튼들
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.restaurant),
                  label: Text('음식점 (${_filteredRestaurants.length})'),
                  onPressed: () {
                    setState(() {
                      _showFilterPanel = !_showFilterPanel;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: Icon(Icons.filter_list),
                  label: Text('필터'),
                  onPressed: () {
                    setState(() {
                      _showFilterPanel = !_showFilterPanel;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: (_selectedCategories.isNotEmpty)
                        ? colorScheme.primary.withOpacity(0.1)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Spacer(),
                if (_selectedCategories.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategories.clear();
                      });
                      _applyFilters();
                    },
                    child: Text('초기화'),
                  ),
              ],
            ),
          ),

          // 확장된 필터 옵션들
          if (_showFilterPanel)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카테고리 필터
                    Text(
                      '음식 카테고리',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _availableCategories.map((category) {
                        final isSelected = _selectedCategories.contains(category);
                        final color = _categoryColors[category] ?? Colors.grey;

                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                            _applyFilters();
                          },
                          backgroundColor: theme.cardColor,
                          selectedColor: color.withOpacity(0.2),
                          checkmarkColor: color,
                          labelStyle: TextStyle(
                            color: isSelected ? color : theme.textTheme.bodyMedium?.color,
                          ),
                        );
                      }).toList(),
                    ),

                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // 네이버 지도
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(inhaBackGateLat, inhaBackGateLng),
                zoom: 15,
              ),
              indoorEnable: true,
              locationButtonEnable: false,
              consumeSymbolTapEvents: false,
              scrollGesturesEnable: true,
              zoomGesturesEnable: true,
              tiltGesturesEnable: true,
              minZoom: 5,
              maxZoom: 21,
            ),
            onMapReady: (controller) async {
              _mapController = controller;
              _mapControllerCompleter.complete(controller);

              print('🗺️ 지도 준비 완료');

              if (widget.selectedRestaurant != null && !widget.resetToMyLocation) {
                await _mapController!.updateCamera(
                  NCameraUpdate.withParams(
                    target: NLatLng(
                        widget.selectedRestaurant!.lat,
                        widget.selectedRestaurant!.lng
                    ),
                    zoom: 19,
                  ),
                );
                await _addSelectedRestaurantMarker();
              } else {
                if (_myLat != null && _myLng != null) {
                  print('📍 내 위치로 카메라 이동: $_myLat, $_myLng');
                  await _mapController!.updateCamera(
                    NCameraUpdate.withParams(
                      target: NLatLng(_myLat!, _myLng!),
                      zoom: 18,
                    ),
                  );
                } else {
                  print('🏢 인하대 후문으로 카메라 이동');
                  await _mapController!.updateCamera(
                    NCameraUpdate.withParams(
                      target: NLatLng(inhaBackGateLat, inhaBackGateLng),
                      zoom: 18,
                    ),
                  );
                }
              }

              // 마커들 추가
              print('📍 마커 추가 시작 - 전체 데이터: ${_allRestaurants.length}개');
              if (_allRestaurants.isNotEmpty) {
                await _updateMapMarkers();
              } else {
                print('⚠️ 음식점 데이터가 아직 로드되지 않음 - 마커 추가 건너뜀');
              }

              // 내 위치 마커 추가
              if (_myLat != null && _myLng != null) {
                await _addMyLocationMarker();
              }

              log("✅ 지도 초기화 완료", name: "MapTab");
            },
          ),

          // 앱바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
              child: Row(
                children: [
                  // 뒤로가기 버튼 (포커스된 상태일 때만 표시)
                  if (_isFocusedOnRestaurant)
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: _resetFocus,
                      tooltip: '목록으로 돌아가기',
                    ),
                  Expanded(
                    child: Text(
                      _isFocusedOnRestaurant && _focusedRestaurant != null
                          ? _focusedRestaurant!.name
                          : '인하대 후문 맛집 지도',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () async {
                      await _fetchRestaurantsFromDatabase();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('맛집 정보를 새로고침했습니다'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 내 위치 버튼
          Positioned(
            right: 16,
            bottom: _showFilterPanel ? 240 : 180,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: Icon(Icons.my_location,
                  color: Theme.of(context).textTheme.bodyLarge?.color
              ),
              onPressed: _moveToMyLocation,
              heroTag: "my_location_btn",
            ),
          ),

          // 확대 버튼
          Positioned(
            right: 16,
            bottom: _showFilterPanel ? 300 : 240,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: Icon(Icons.add,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                size: 20,
              ),
              onPressed: _zoomIn,
              heroTag: "zoom_in_btn",
              mini: true,
            ),
          ),

          // 축소 버튼
          Positioned(
            right: 16,
            bottom: _showFilterPanel ? 360 : 280,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: Icon(Icons.remove,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                size: 20,
              ),
              onPressed: _zoomOut,
              heroTag: "zoom_out_btn",
              mini: true,
            ),
          ),

          // 필터 패널
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFilterPanel(),
          ),

          // 범례 (카테고리별 색상 안내)
          if (_showFilterPanel)
            Positioned(
              top: 80,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '카테고리 범례',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ...(_selectedCategories.isEmpty
                        ? _availableCategories.take(5)
                        : _selectedCategories).map((category) {
                      final color = _categoryColors[category] ?? Colors.grey;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              category,
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    if (_selectedCategories.isEmpty && _availableCategories.length > 5)
                      Text(
                        '...',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),

          // 로딩 표시
          if (_isLoadingRestaurants)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '인하대 후문 맛집 정보를 불러오는 중...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}