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
  final bool resetToMyLocation; // 내 위치로 리셋할지 여부

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
  double _currentZoom = 14.0; // 현재 줌 레벨 추적

  // 인하대 후문 정확한 좌표 (인천 미추홀구 용현동)
  final double inhaBackGateLat = 37.45169;
  final double inhaBackGateLng = 126.65464;

  // 데이터베이스에서 받아온 음식점 데이터를 저장할 리스트
  List<Map<String, dynamic>> _restaurants = [];

  // 내 위치
  double? _myLat;
  double? _myLng;

  @override
  void initState() {
    super.initState();
    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation(); // 내 위치 먼저 가져오기
      _fetchRestaurantsFromDatabase();
    });
  }

  // 현재 위치 가져오기 (인하대 후문으로 고정)
  Future<void> _getCurrentLocation() async {
    // 인하대 후문 좌표로 고정
    setState(() {
      _myLat = inhaBackGateLat;
      _myLng = inhaBackGateLng;
    });

    print('내 위치 설정 (인하대 후문): $_myLat, $_myLng');

    // 내 위치 마커 추가
    if (_mapController != null) {
      await _addMyLocationMarker();
    }
  }
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

          // 지도가 이미 준비된 상태라면 마커 추가
          if (_mapController != null) {
            print('지도 컨트롤러가 준비되어 있음 - 마커 추가 시작');
            await _addRestaurantMarkers();
            // 내 위치 마커도 추가
            if (_myLat != null && _myLng != null) {
              await _addMyLocationMarker();
            }
          } else {
            print('지도 컨트롤러가 아직 준비되지 않음');
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

  // 내 위치 마커 추가
  Future<void> _addMyLocationMarker() async {
    if (_mapController == null || _myLat == null || _myLng == null) return;

    try {
      // 내 위치를 초록색 원으로 표시
      final myLocationCircle = NCircleOverlay(
        id: 'my_location_circle',
        center: NLatLng(_myLat!, _myLng!),
        radius: 4, // 반지름 4미터
        color: Colors.green.withOpacity(0.3),
        outlineColor: Colors.green,
        outlineWidth: 2,
      );

      // 원형 오버레이 추가
      await _mapController!.addOverlay(myLocationCircle);

      print('내 위치 원형 표시 완료: $_myLat, $_myLng');
    } catch (e) {
      print('내 위치 원형 표시 실패: $e');
    }
  }

  // 데이터베이스에서 음식점 데이터 가져오기
  double _parseCoordinate(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // 좌표 안전하게 파싱하는 함수
  Future<void> _addRestaurantMarkers() async {
    if (_mapController == null) {
      print('지도 컨트롤러가 없습니다');
      return;
    }

    if (_restaurants.isEmpty) {
      print('음식점 데이터가 없습니다');
      return;
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
          print('유효하지 않은 좌표 스킵: ${restaurant['name']} - lat: $lat, lng: $lng');
          continue;
        }

        print('마커 추가 중: ${restaurant['name']} ($lat, $lng)');

        // 마커 생성 (기본 마커 사용)
        final marker = NMarker(
          id: 'restaurant_${restaurant['_id'] ?? restaurant['id']}_$i',
          position: NLatLng(lat, lng),
        );

        // 마커 추가
        await _mapController!.addOverlay(marker);
        print('마커 추가 성공: ${restaurant['name']}');

        // 클릭 이벤트 설정
        marker.setOnTapListener((overlay) {
          print('마커 클릭됨: ${restaurant['name']}');
          _showRestaurantInfo(restaurant);
        });

      } catch (e) {
        print('마커 추가 실패 (${restaurant['name']}): $e');
        print('마커 추가 실패 상세 오류: ${e.toString()}');
      }
    }

    print('마커 추가 완료 - 총 ${_restaurants.length}개 처리됨');
  }

  // 선택된 음식점 마커 추가
  Future<void> _addSelectedRestaurantMarker() async {
    if (_mapController == null || widget.selectedRestaurant == null) return;

    try {
      final restaurant = widget.selectedRestaurant!;

      print('선택된 음식점 마커 추가: ${restaurant.name} (${restaurant.lat}, ${restaurant.lng})');

      // 선택된 음식점 마커 생성 (기본 마커에 다른 색상)
      final selectedMarker = NMarker(
        id: 'selected_restaurant_${restaurant.id}',
        position: NLatLng(restaurant.lat, restaurant.lng),
      );

      // 마커 추가
      await _mapController!.addOverlay(selectedMarker);
      print('선택된 음식점 마커 추가 성공');

      // 정보창 추가 (선택된 음식점은 정보창 표시)
      final infoWindow = NInfoWindow.onMarker(
        id: "selected_info_${restaurant.id}",
        text: "📍 ${restaurant.name}",
      );
      selectedMarker.openInfoWindow(infoWindow);

      // 클릭 이벤트
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

      print('선택된 음식점 마커 설정 완료: ${restaurant.name}');
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
      // 내 위치가 없으면 인하대 후문으로
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

              print('지도 준비 완료');

              // 카메라 초기 위치 설정 로직
              if (widget.selectedRestaurant != null && !widget.resetToMyLocation) {
                // 선택된 음식점으로 이동 (리스트에서 온 경우)
                print('선택된 음식점으로 이동: ${widget.selectedRestaurant!.name}');
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
                // 내 위치로 이동 (홈에서 온 경우 또는 일반적인 경우)
                if (_myLat != null && _myLng != null) {
                  print('내 위치로 이동: $_myLat, $_myLng');
                  await _mapController!.updateCamera(
                    NCameraUpdate.withParams(
                      target: NLatLng(_myLat!, _myLng!),
                      zoom: 18,
                    ),
                  );
                } else {
                  print('내 위치가 없어서 인하대 후문으로 이동');
                  await _mapController!.updateCamera(
                    NCameraUpdate.withParams(
                      target: NLatLng(inhaBackGateLat, inhaBackGateLng),
                      zoom: 18,
                    ),
                  );
                }
              }

              // 마커들 추가
              print('일반 음식점 마커 추가 시작 - 데이터 개수: ${_restaurants.length}');
              if (_restaurants.isNotEmpty) {
                await _addRestaurantMarkers();
              } else {
                print('음식점 데이터가 아직 로드되지 않음');
              }

              // 내 위치 마커 추가
              if (_myLat != null && _myLng != null) {
                await _addMyLocationMarker();
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

          // 내 위치 버튼
          Positioned(
            right: 16,
            bottom: 180,
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