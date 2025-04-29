import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../utils/api_config.dart';

class VisitHistoryScreen extends StatefulWidget {
  @override
  _VisitHistoryScreenState createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _visitHistory = [];

  @override
  void initState() {
    super.initState();
    _loadVisitHistory();
  }

  // MongoDB에서 방문 기록 데이터 불러오기
  Future<void> _loadVisitHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        // 로그인 필요 처리
        _showLoginRequiredDialog();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 서버 URL 가져오기 로그인 된 경우
      final baseUrl = getServerUrl();

      // 서버 API 호출
      final response = await http.get(
        Uri.parse('$baseUrl/api/visits'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        setState(() {
          _visitHistory = List<Map<String, dynamic>>.from(
              responseData['visits'].map((item) => {
                'id': item['_id'],
                'restaurantId': item['restaurantId'],
                'restaurantName': item['restaurantName'],
                'category': item['category'] ?? '기타',
                'visitDate': DateTime.parse(item['visitDate']),
                'imageUrl': item['imageUrl'] ?? 'assets/restaurant_placeholder.png',
              })
          );

          // 방문 날짜 기준으로 정렬 (최신순)
          _visitHistory.sort((a, b) => b['visitDate'].compareTo(a['visitDate']));

          _isLoading = false;
        });
      } else {
        // 에러 처리
        print('방문 기록 로드 오류: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('방문 기록 로드 중 예외 발생: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 방문 기록 삭제하기
  Future<void> _removeVisitHistory(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // 서버 URL 가져오기
      final baseUrl = getServerUrl();

      final response = await http.delete(
        Uri.parse('$baseUrl/api/visits/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // 로컬 목록에서 제거
        setState(() {
          _visitHistory.removeWhere((item) => item['id'] == id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('방문 기록이 삭제되었습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 중 오류가 발생했습니다')),
        );
      }
    } catch (e) {
      print('방문 기록 삭제 중 예외 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류가 발생했습니다')),
      );
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('로그인 필요'),
        content: Text('방문 기록을 보려면 로그인이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  // 날짜를 그룹화하여 표시하기 위한 함수
  String _formatVisitDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final visitDate = DateTime(date.year, date.month, date.day);

    if (visitDate.year == now.year &&
        visitDate.month == now.month &&
        visitDate.day == now.day) {
      return '오늘';
    } else if (visitDate.year == yesterday.year &&
        visitDate.month == yesterday.month &&
        visitDate.day == yesterday.day) {
      return '어제';
    } else {
      return DateFormat('yyyy년 MM월 dd일').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Map<String, dynamic>>> groupedVisits = {};

    // 방문 날짜별로 그룹화
    for (var visit in _visitHistory) {
      String dateKey = _formatVisitDate(visit['visitDate']);
      if (!groupedVisits.containsKey(dateKey)) {
        groupedVisits[dateKey] = [];
      }
      groupedVisits[dateKey]!.add(visit);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('방문 기록'),
        backgroundColor: Color(0xFFA0CC71),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _visitHistory.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              '방문 기록이 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              '맛집을 방문하고 기록을 남겨보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: groupedVisits.keys.length,
        itemBuilder: (context, index) {
          String dateKey = groupedVisits.keys.elementAt(index);
          List<Map<String, dynamic>> visits = groupedVisits[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              // 해당 날짜의 방문 기록
              ...visits.map((visit) => Dismissible(
                key: Key(visit['id']),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _removeVisitHistory(visit['id']);
                },
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('방문 기록 삭제'),
                        content: Text('이 방문 기록을 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('삭제'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Card(
                  margin: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        visit['imageUrl'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.restaurant,
                              color: Colors.grey[500],
                            ),
                          );
                        },
                      ),
                    ),
                    title: Text(
                      visit['restaurantName'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          visit['category'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('a h:mm', 'ko_KR').format(visit['visitDate']),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.rate_review_outlined,
                            color: Color(0xFFA0CC71),
                          ),
                          onPressed: () {
                            // 리뷰 작성 화면으로 이동
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('리뷰 작성 기능은 준비 중입니다')),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      // 가게 상세 정보로 이동
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('가게 상세 페이지 준비 중입니다')),
                      );
                    },
                  ),
                ),
              )).toList(),
            ],
          );
        },
      ),
    );
  }
}