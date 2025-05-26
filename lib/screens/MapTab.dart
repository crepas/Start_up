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

class MapTab extends StatefulWidget {
  final Restaurant? selectedRestaurant;

  const MapTab({
    Key? key,
    this.selectedRestaurant,
  }) : super(key: key);

  @override
  _MapTabState createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final Completer<NaverMapController> _mapControllerCompleter = Completer();
  NaverMapController? _mapController;
  bool _isLoading = true;
  bool _isLoadingRestaurants = false;
  double _currentZoom = 14.0; // 현재 줌 레벨 추적

  // 고정된 위치 좌표 (인천 용현동 근처)
  final double fixedLat = 37.4516;
  final double fixedLng = 126.7015;

  // 서버에서 받아온 음식점 데이터를 저장할 리스트 (Map 형태로 단순화)
  List<Map<String, dynamic>> _restaurants = [];

  @override
  void initState() {
    super.initState();
    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRestaurantsFromServer();
    });
  }

  // 서버에서 음식점 데이터 가져오기
  Future<void> _fetchRestaurantsFromServer() async {
    if (_isLoadingRestaurants) return;

    setState(() {
      _isLoadingRestaurants = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final baseUrl = getServerUrl();

      final queryParams = {
        'lat': fixedLat.toString(),
        'lng': fixedLng.toString(),
        'radius': '2000',
        'limit': '20',
        'sort': 'rating',
      };

      final uri = Uri.parse('$baseUrl/restaurants').replace(
        queryParameters: queryParams,
      );

      print('지도 API 호출 URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('지도 API 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['restaurants'] != null) {
          // 서버 데이터를 단순한 Map 형태로 저장 (Restaurant 객체 변환 안 함)
          setState(() {
            _restaurants = List<Map<String, dynamic>>.from(data['restaurants']);
            _isLoadingRestaurants = false;
          });

          print('지도에서 로드된 음식점 수: ${_restaurants.length}');

          // 지도가 준비되면 마커 추가
          if (_mapController != null) {
            await _addRestaurantMarkers();
          }
        } else {
          throw Exception('No restaurants data in response');
        }
      } else {
        // 서버 오류 시 기본 데이터 사용
        setState(() {
          _isLoadingRestaurants = false;
          _restaurants = _getDefaultRestaurants();
        });

        if (_mapController != null) {
          await _addRestaurantMarkers();
        }
      }
    } catch (e) {
      print('음식점 데이터 가져오기 오류: $e');
      setState(() {
        _isLoadingRestaurants = false;
        _restaurants = _getDefaultRestaurants();
      });

      if (_mapController != null) {
        await _addRestaurantMarkers();
      }
    }
  }

  // 기본 음식점 데이터 (Map 형태)
  List<Map<String, dynamic>> _getDefaultRestaurants() {
    return [
      {
        'id': '1',
        'name': '장터삼겹살',
        'address_name': '인천 미추홀구 용현동 618-1',
        'category_name': '음식점 > 한식 > 고기구이',
        'phone': '032-123-4567',
        'y': '37.4512',
        'x': '126.7019',
        'place_url': '',
        'rating': 4.5,
        'likes': 120,
      },
      {
        'id': '2',
        'name': '명륜진사갈비',
        'address_name': '인천 미추홀구 용현동 621-5',
        'category_name': '음식점 > 한식 > 갈비',
        'phone': '032-123-4568',
        'y': '37.4522',
        'x': '126.7032',
        'place_url': '',
        'rating': 4.3,
        'likes': 89,
      },
      {
        'id': '3',
        'name': '온기족발',
        'address_name': '인천 미추홀구 용현동 615-2',
        'category_name': '음식점 > 한식 > 족발보쌈',
        'phone': '032-123-4569',
        'y': '37.4508',
        'x': '126.7027',
        'place_url': '',
        'rating': 4.2,
        'likes': 76,
      },
      {
        'id': '4',
        'name': '인하반점',
        'address_name': '인천 미추홀구 용현동 산1-1',
        'category_name': '음식점 > 중식 > 중화요리',
        'phone': '032-867-0582',
        'y': '37.4495',
        'x': '126.7012',
        'place_url': '',
        'rating': 4.1,
        'likes': 95,
      },
      {
        'id': '5',
        'name': '스타벅스 인하대점',
        'address_name': '인천 미추홀구 용현동 253',
        'category_name': '음식점 > 카페 > 커피전문점',
        'phone': '1522-3232',
        'y': '37.4505',
        'x': '126.7020',
        'place_url': '',
        'rating': 4.0,
        'likes': 150,
      },
    ];
  }

  // 좌표 안전하게 파싱하는 함수
  double _parseCoordinate(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // 맛집 마커 추가 (단순한 Map 데이터 사용)
  Future<void> _addRestaurantMarkers() async {
    if (_mapController == null || _restaurants.isEmpty) return;

    // 기존 마커 제거
    try {
      await _mapController!.clearOverlays();
    } catch (e) {
      print('마커 제거 오류: $e');
    }

    print('마커 추가 시작: ${_restaurants.length}개');

    for (int i = 0; i < _restaurants.length; i++) {
      final restaurant = _restaurants[i];

      try {
        // 좌표 추출 (여러 방법 시도)
        double lat = 0.0;
        double lng = 0.0;

        // 방법 1: y, x 필드 (카카오 API 형식)
        if (restaurant['y'] != null && restaurant['x'] != null) {
          lat = _parseCoordinate(restaurant['y']);
          lng = _parseCoordinate(restaurant['x']);
        }
        // 방법 2: lat, lng 필드
        else if (restaurant['lat'] != null && restaurant['lng'] != null) {
          lat = _parseCoordinate(restaurant['lat']);
          lng = _parseCoordinate(restaurant['lng']);
        }
        // 방법 3: location.coordinates (MongoDB 형식)
        else if (restaurant['location'] != null &&
            restaurant['location']['coordinates'] != null) {
          final coords = restaurant['location']['coordinates'] as List;
          if (coords.length >= 2) {
            lng = _parseCoordinate(coords[0]);
            lat = _parseCoordinate(coords[1]);
          }
        }

        // 좌표가 유효하지 않으면 스킵
        if (lat == 0.0 && lng == 0.0) {
          print('유효하지 않은 좌표 스킵: ${restaurant['name']}');
          continue;
        }

        print('마커 추가: ${restaurant['name']} ($lat, $lng)');

        // 마커 생성
        final marker = NMarker(
          id: 'restaurant_${restaurant['id']}_$i',
          position: NLatLng(lat, lng),
        );

        // 마커 추가
        await _mapController!.addOverlay(marker);

        // 정보창 추가
        final infoWindow = NInfoWindow.onMarker(
          id: "info_${restaurant['id']}_$i",
          text: restaurant['name']?.toString() ?? '음식점',
        );
        marker.openInfoWindow(infoWindow);

        // 클릭 이벤트
        marker.setOnTapListener((overlay) {
          _showRestaurantInfo(restaurant);
        });

      } catch (e) {
        print('마커 추가 실패 (${restaurant['name']}): $e');
      }
    }

    print('마커 추가 완료');
  }

  // 고정 위치로 지도 이동
  void _moveToFixedLocation() {
    if (_mapController != null) {
      _mapController!.updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(fixedLat, fixedLng),
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

        if (currentZoom < 21) { // 최대 줌 레벨 제한
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

        if (currentZoom > 5) { // 최소 줌 레벨 제한
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

  // 맛집 정보 모달 표시
  void _showRestaurantInfo(Map<String, dynamic> restaurant) {
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
                restaurant['name']?.toString() ?? restaurant['place_name']?.toString() ?? '음식점',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                restaurant['category_name']?.toString() ?? '음식점',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                restaurant['address_name']?.toString() ?? restaurant['address']?.toString() ?? '주소 정보 없음',
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
                target: NLatLng(fixedLat, fixedLng),
                zoom: 14, // 초기 줌을 약간 낮춰서 마커들을 더 잘 볼 수 있게
              ),
              indoorEnable: true,
              locationButtonEnable: false,
              consumeSymbolTapEvents: false,
              // 지도 제스처 설정 (지원되는 것만)
              scrollGesturesEnable: true, // 스크롤 가능
              zoomGesturesEnable: true,   // 핀치 줌 가능
              tiltGesturesEnable: true,   // 틸트 가능
              // 줌 범위 설정
              minZoom: 5,
              maxZoom: 21,
            ),
            onMapReady: (controller) async {
              _mapController = controller;
              _mapControllerCompleter.complete(controller);

              // 선택된 음식점이 있으면 해당 위치로 이동
              if (widget.selectedRestaurant != null) {
                await _mapController!.updateCamera(
                  NCameraUpdate.withParams(
                    target: NLatLng(
                        widget.selectedRestaurant!.lat,
                        widget.selectedRestaurant!.lng
                    ),
                    zoom: 16,
                  ),
                );
              }

              // 지도가 준비되면 맛집 마커 추가
              if (_restaurants.isNotEmpty) {
                await _addRestaurantMarkers();
              }

              log("지도가 준비되었습니다", name: "MapTab");
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
                  Text(
                    '주변 맛집 지도',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () async {
                      await _fetchRestaurantsFromServer();
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

          // 센터 위치 버튼
          Positioned(
            right: 16,
            bottom: 180, // 버튼들이 겹치지 않도록 위치 조정
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: Icon(Icons.center_focus_strong,
                  color: Theme.of(context).textTheme.bodyLarge?.color
              ),
              onPressed: _moveToFixedLocation,
              heroTag: "center_btn", // 고유 태그 추가
            ),
          ),

          // 확대 버튼
          Positioned(
            right: 16,
            bottom: 240, // 센터 버튼 위에 배치
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: Icon(Icons.add,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                size: 20,
              ),
              onPressed: _zoomIn,
              heroTag: "zoom_in_btn",
              mini: true, // 작은 크기
            ),
          ),

          // 축소 버튼
          Positioned(
            right: 16,
            bottom: 120, // 센터 버튼 아래에 배치
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: Icon(Icons.remove,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                size: 20,
              ),
              onPressed: _zoomOut,
              heroTag: "zoom_out_btn",
              mini: true, // 작은 크기
            ),
          ),

          // 줌 레벨 표시
          Positioned(
            left: 16,
            bottom: 120,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '줌: ${_currentZoom.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),

          // 필터 패널
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 60,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    icon: Icon(Icons.filter_list),
                    label: Text('필터'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('필터 기능은 준비 중입니다.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: Icon(Icons.restaurant),
                    label: Text('맛집 종류'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('맛집 종류 필터는 준비 중입니다.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('검색 기능은 준비 중입니다.')),
                      );
                    },
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
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}