import 'dart:async';
import 'dart:developer';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MapTab extends StatefulWidget {
  @override
  _MapTabState createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  // NaverMapController 객체의 비동기 작업 완료를 나타내는 Completer 생성
  final Completer<NaverMapController> _mapControllerCompleter = Completer();
  NaverMapController? _mapController;
  bool _isLoading = true;
  bool _isLoadingRestaurants = false;

  // 고정된 위치 좌표 (인천 용현동 근처)
  final double fixedLat = 37.4516;
  final double fixedLng = 126.7015;

  // 카카오 API에서 받아온 음식점 데이터를 저장할 리스트
  List<Map<String, dynamic>> _restaurants = [];

  @override
  void initState() {
    super.initState();
    _isLoading = false; // 위치 서비스 없이 바로 로딩 완료
    // 화면이 준비되면 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRestaurantsFromKakao();
    });
  }

  // 카카오 로컬 API에서 음식점 데이터 가져오기
  Future<void> _fetchRestaurantsFromKakao() async {
    if (_isLoadingRestaurants) return;

    setState(() {
      _isLoadingRestaurants = true;
    });

    try {
      // 카카오 API 키 (실제 키로 변경 필요)
      final apiKey = '4e4572f409f9b0cd5dc1f574779a03a7';

      // API 요청
      final response = await http.get(
        Uri.parse('https://dapi.kakao.com/v2/local/search/keyword.json?query=맛집&x=$fixedLng&y=$fixedLat&radius=2000'),
        headers: {
          'Authorization': 'KakaoAK $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> documents = data['documents'];

        setState(() {
          _restaurants = documents.map((doc) => doc as Map<String, dynamic>).toList();
          _isLoadingRestaurants = false;
        });

        // 음식점 마커 추가
        if (_mapController != null) {
          _addRestaurantMarkers();
        }

      } else {
        print('카카오 API 오류: ${response.statusCode} - ${response.body}');
        _showErrorSnackBar('음식점 정보를 가져오는데 실패했습니다.');
        setState(() {
          _isLoadingRestaurants = false;
          // API 실패 시 기본 데이터 사용
          _restaurants = _getDefaultRestaurants();
        });

        // 기본 데이터로 마커 추가
        if (_mapController != null) {
          _addRestaurantMarkers();
        }
      }
    } catch (e) {
      print('음식점 데이터 가져오기 오류: $e');
      _showErrorSnackBar('음식점 정보를 가져오는데 실패했습니다.');
      setState(() {
        _isLoadingRestaurants = false;
        // 오류 발생 시 기본 데이터 사용
        _restaurants = _getDefaultRestaurants();
      });

      // 기본 데이터로 마커 추가
      if (_mapController != null) {
        _addRestaurantMarkers();
      }
    }
  }

  // 기본 음식점 데이터 반환 (API 실패 시 사용)
  List<Map<String, dynamic>> _getDefaultRestaurants() {
    return [
      {
        'id': '1',
        'place_name': '장터삼겹살',
        'y': '37.4512',
        'x': '126.7019',
        'category_name': '고기/구이',
      },
      {
        'id': '2',
        'place_name': '명륜진사갈비',
        'y': '37.4522',
        'x': '126.7032',
        'category_name': '고기/구이',
      },
      {
        'id': '3',
        'place_name': '온기족발',
        'y': '37.4508',
        'x': '126.7027',
        'category_name': '족발/보쌈',
      },
    ];
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

    // 기존 마커 모두 제거 (실제 앱에서는 마커 ID 추적하여 개별 제거 필요)
    try {
      await _mapController!.clearOverlays();
    } catch (e) {
      print('마커 제거 오류: $e');
    }

    for (final restaurant in _restaurants) {
      try {
        // 마커 생성
        final marker = NMarker(
          id: restaurant['id'] ?? '',
          position: NLatLng(
            double.parse(restaurant['y']),
            double.parse(restaurant['x']),
          ),
        );

        // 마커 정보창
        final infoWindow = NInfoWindow.onMarker(
          id: "info_${restaurant['id'] ?? ''}",
          text: "${restaurant['place_name']}", // 가게 이름만 표시
        );

        // 마커 추가
        await _mapController!.addOverlay(marker);

        // 마커에 정보창 설정
        marker.openInfoWindow(infoWindow);

        // 마커 클릭 이벤트 설정
        marker.setOnTapListener((overlay) {
          _showRestaurantInfo(restaurant);
        });
      } catch (e) {
        print('마커 추가 오류: $e');
      }
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
                restaurant['place_name'] ?? '이름 없음',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                restaurant['category_name'] ?? '분류 정보 없음',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                restaurant['address_name'] ?? '주소 정보 없음',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              if (restaurant['phone'] != null && restaurant['phone'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    restaurant['phone'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 길찾기 버튼 제거됨
                  _buildActionButton(Icons.favorite_border, '찜하기'),
                  _buildActionButton(Icons.share, '공유하기'),
                ],
              ),
              SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // 카카오맵으로 연결
                  if (restaurant['place_url'] != null) {
                    // 실제 앱에서는 URL 런처를 사용하여 웹 브라우저나 카카오맵 앱으로 연결
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('상세 페이지로 이동 기능은 준비 중입니다.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('상세 페이지 정보가 없습니다.')),
                    );
                  }
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
                target: NLatLng(fixedLat, fixedLng), // 고정된 위치 좌표
                zoom: 15,
              ),
              indoorEnable: true,
              locationButtonEnable: false, // 위치 버튼 비활성화
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
                      // 음식점 데이터 새로고침
                      await _fetchRestaurantsFromKakao();

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

          // 센터 위치 버튼 (위치 서비스 대신 고정 위치로 이동)
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: Icon(Icons.center_focus_strong, 
                color: Theme.of(context).textTheme.bodyLarge?.color
              ),
              onPressed: _moveToFixedLocation,
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