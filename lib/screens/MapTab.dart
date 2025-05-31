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
import 'package:permission_handler/permission_handler.dart'; // 추가된 패키지


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

  // 인하대 후문 정확한 좌표 (인천 미추홀구 용현동)
  final double inhaBackGateLat = 37.45169;
  final double inhaBackGateLng = 126.65464;

  // 데이터베이스에서 받아온 음식점 데이터를 저장할 리스트
  List<Map<String, dynamic>> _restaurants = [];

  @override
  void initState() {
    super.initState();
    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRestaurantsFromDatabase();
    });
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
        'radius': '2000', // 2km 반경
        'limit': '50',
        'sort': 'distance',
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
          setState(() {
            _restaurants = List<Map<String, dynamic>>.from(data['restaurants']);
            _isLoadingRestaurants = false;
          });

          print('지도에서 로드된 음식점 수: ${_restaurants.length}개');

          // 지도가 준비되면 마커 추가
          if (_mapController != null) {
            await _addRestaurantMarkers();
          }
        } else {
          throw Exception('No restaurants data in response');
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

  // 음식점 마커 추가
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
        // 좌표 추출
        double lat = 0.0;
        double lng = 0.0;

        // MongoDB location.coordinates 형식 또는 lat/lng 형식
        if (restaurant['location'] != null &&
            restaurant['location']['coordinates'] != null) {
          final coords = restaurant['location']['coordinates'] as List;
          if (coords.length >= 2) {
            lng = _parseCoordinate(coords[0]); // 경도가 먼저
            lat = _parseCoordinate(coords[1]); // 위도가 나중
          }
        } else if (restaurant['lat'] != null && restaurant['lng'] != null) {
          lat = _parseCoordinate(restaurant['lat']);
          lng = _parseCoordinate(restaurant['lng']);
        }

        // 좌표가 유효하지 않으면 스킵
        if (lat == 0.0 && lng == 0.0) {
          print('유효하지 않은 좌표 스킵: ${restaurant['name']}');
          continue;
        }

        print('마커 추가: ${restaurant['name']} ($lat, $lng)');

        // 마커 아이콘 설정 (카페와 음식점 구분)
        String iconPath = 'assets/restaurant_marker.png';
        if (restaurant['categoryGroupCode'] == 'CE7' ||
            (restaurant['categoryName'] != null &&
                restaurant['categoryName'].toString().contains('카페'))) {
          iconPath = 'assets/cafe_marker.png';
        }

        // 마커 생성
        final marker = NMarker(
          id: 'restaurant_${restaurant['_id'] ?? restaurant['id']}_$i',
          position: NLatLng(lat, lng),
        );

        // 마커 추가
        await _mapController!.addOverlay(marker);

        // 정보창 추가
        final infoWindow = NInfoWindow.onMarker(
          id: "info_${restaurant['_id'] ?? restaurant['id']}_$i",
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
              Text(
                restaurant['categoryName']?.toString() ?? '음식점',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
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
                target: NLatLng(inhaBackGateLat, inhaBackGateLng), // 인하대 후문 중심
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

              // 지도가 준비되면 음식점 마커 추가
              if (_restaurants.isNotEmpty) {
                await _addRestaurantMarkers();
              }

              log("지도가 준비되었습니다 (인하대 후문 중심)", name: "MapTab");
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
                    '인하대 후문 맛집 지도',
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

          // 인하대 후문 중심 버튼
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: Icon(Icons.school,
                  color: Theme.of(context).textTheme.bodyLarge?.color
              ),
              onPressed: _moveToInhaBackGate,
              heroTag: "center_btn",
            ),
          ),

          // 확대 버튼
          Positioned(
            right: 16,
            bottom: 240,
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
            bottom: 120,
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
                    icon: Icon(Icons.restaurant),
                    label: Text('음식점'),
                    onPressed: () {
                      // 음식점만 필터링하는 기능 추가 가능
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('음식점 필터는 준비 중입니다.')),
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
                    icon: Icon(Icons.local_cafe),
                    label: Text('카페'),
                    onPressed: () {
                      // 카페만 필터링하는 기능 추가 가능
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('카페 필터는 준비 중입니다.')),
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