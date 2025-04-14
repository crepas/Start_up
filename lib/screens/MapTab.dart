import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

class MapTab extends StatefulWidget {
  @override
  _MapTabState createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  // NaverMapController 객체의 비동기 작업 완료를 나타내는 Completer 생성
  final Completer<NaverMapController> _mapControllerCompleter = Completer();
  NaverMapController? _mapController;
  bool _isLoading = true;

  // 임시 맛집 데이터 - 나중에 API로 대체
  final List<Map<String, dynamic>> _restaurants = [
    {
      'id': '1',
      'name': '장터삼겹살',
      'lat': 37.4512,
      'lng': 126.7019,
      'rating': 4.5,
      'category': '고기/구이',
    },
    {
      'id': '2',
      'name': '명륜진사갈비',
      'lat': 37.4522,
      'lng': 126.7032,
      'rating': 4.3,
      'category': '고기/구이',
    },
    {
      'id': '3',
      'name': '온기족발',
      'lat': 37.4508,
      'lng': 126.7027,
      'rating': 4.1,
      'category': '족발/보쌈',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  // 위치 권한 확인 및 요청
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스가 활성화되어 있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('위치 서비스를 활성화해주세요.');
      return;
    }

    // 위치 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('위치 권한이 거부되었습니다.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 현재 위치로 지도 이동
  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_mapController != null) {
        // 현재 네이버 맵 API에 맞게 수정
        await _mapController!.updateCamera(
          NCameraUpdate.withParams(
            target: NLatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('현재 위치를 가져오는데 실패했습니다.');
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

  // 맛집 마커 추가
  Future<void> _addRestaurantMarkers() async {
    if (_mapController == null) return;

    for (final restaurant in _restaurants) {
      // 마커 생성
      final marker = NMarker(
        id: restaurant['id'],
        position: NLatLng(restaurant['lat'], restaurant['lng']),
      );

      // 마커 정보창
      final infoWindow = NInfoWindow.onMarker(
        id: "info_${restaurant['id']}",
        text: "${restaurant['name']} - ${restaurant['category']} (${restaurant['rating']}⭐)",
      );

      // 마커 추가
      await _mapController!.addOverlay(marker);

      // 마커에 정보창 설정
      marker.openInfoWindow(infoWindow);

      // 마커 클릭 이벤트 설정
      marker.setOnTapListener((overlay) {
        _showRestaurantInfo(restaurant);
      });
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
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    restaurant['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      SizedBox(width: 4),
                      Text(
                        restaurant['rating'].toString(),
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                restaurant['category'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(Icons.directions, '길찾기'),
                  _buildActionButton(Icons.favorite_border, '찜하기'),
                  _buildActionButton(Icons.share, '공유하기'),
                ],
              ),
              SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // 상세 페이지로 이동하는 로직 (나중에 구현)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('맛집 상세 페이지는 준비 중입니다.')),
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
                target: NLatLng(37.4516, 126.7015), // 용현동 중심 좌표 (임시)
                zoom: 15,
              ),
              indoorEnable: true,
              locationButtonEnable: true,
              consumeSymbolTapEvents: false,
            ),
            onMapReady: (controller) async {
              _mapController = controller;
              _mapControllerCompleter.complete(controller);

              // 지도가 준비되면 맛집 마커 추가
              await _addRestaurantMarkers();
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
              color: Colors.white.withOpacity(0.8),
              child: Row(
                children: [
                  Text(
                    '주변 맛집 지도',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () async {
                      // 지도 새로고침 기능
                      final controller = await _mapControllerCompleter.future;
                      controller.updateCamera(
                        NCameraUpdate.withParams(
                          target: NLatLng(37.4516, 126.7015), // 용현동 중심 좌표 (임시)
                          zoom: 15,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('지도를 새로고침했습니다'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 현재 위치 버튼
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: Colors.black),
              onPressed: _moveToCurrentLocation,
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
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                      // 필터 다이얼로그 표시
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
                      // 맛집 종류 필터
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
                      // 검색 기능
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('검색 기능은 준비 중입니다.')),
                      );
                    },
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