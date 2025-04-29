import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReviewManagementTab extends StatefulWidget {
  @override
  _ReviewManagementTabState createState() => _ReviewManagementTabState();
}

class _ReviewManagementTabState extends State<ReviewManagementTab> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _myReviews = [];
  
  TabController? _tabController;
  final List<String> _tabs = ['작성한 리뷰', '저장한 리뷰'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // 리뷰 데이터 로드
  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 로컬에 저장된 토큰 확인
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        // 토큰이 없는 경우 처리
        setState(() {
          _myReviews = [];
          _isLoading = false;
        });
        return;
      }

      // 서버에서 리뷰 데이터 가져오기
      final response = await http.get(
        Uri.parse('http://localhost:8081/reviews/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _myReviews = List<Map<String, dynamic>>.from(responseData['reviews'] ?? []);
        });
      } else {
        print('서버 응답 오류: ${response.statusCode}');
        _showErrorSnackBar('리뷰를 불러오는 중 오류가 발생했습니다');
      }
    } catch (e) {
      print('리뷰 로드 오류: $e');
      _showErrorSnackBar('리뷰를 불러오는 중 오류가 발생했습니다');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 리뷰 삭제 함수
  Future<void> _deleteReview(String reviewId) async {
    try {
      // 로컬에 저장된 토큰 확인
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _showErrorSnackBar('로그인이 필요합니다');
        return;
      }

      // 삭제 확인 다이얼로그 표시
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('리뷰 삭제'),
            content: Text('이 리뷰를 삭제하시겠습니까?'),
            actions: [
              TextButton(
                child: Text('취소'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text(
                  '삭제',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      // 서버에 삭제 요청
      final response = await http.delete(
        Uri.parse('http://localhost:8081/reviews/$reviewId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // 삭제 성공 시 목록 갱신
        setState(() {
          _myReviews.removeWhere((review) => review['_id'] == reviewId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리뷰가 삭제되었습니다')),
        );
      } else {
        print('서버 응답 오류: ${response.statusCode}');
        _showErrorSnackBar('리뷰 삭제 중 오류가 발생했습니다');
      }
    } catch (e) {
      print('리뷰 삭제 오류: $e');
      _showErrorSnackBar('리뷰 삭제 중 오류가 발생했습니다');
    }
  }

  // 오류 메시지 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 리뷰 수정 페이지로 이동
  void _navigateToEditReview(Map<String, dynamic> review) {
    // 실제 구현 시 리뷰 수정 페이지로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('리뷰 수정 기능은 준비 중입니다')),
    );
  }

  // 리뷰 카드 위젯
  Widget _buildReviewCard(Map<String, dynamic> review) {
    final String restaurantName = review['restaurantName'] ?? '식당 이름 없음';
    final int rating = review['rating'] ?? 0;
    final String content = review['content'] ?? '내용 없음';
    final String date = review['createdAt'] != null 
      ? DateTime.parse(review['createdAt']).toString().substring(0, 10)
      : '날짜 정보 없음';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  restaurantName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    ...List.generate(5, (index) => Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: index < rating ? Colors.amber : Colors.grey,
                      size: 20,
                    )),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () => _navigateToEditReview(review),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _deleteReview(review['_id']),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 저장한 리뷰 카드 위젯
  Widget _buildSavedReviewCard(Map<String, dynamic> review) {
    final String restaurantName = review['restaurantName'] ?? '식당 이름 없음';
    final String authorName = review['authorName'] ?? '작성자 정보 없음';
    final int rating = review['rating'] ?? 0;
    final String content = review['content'] ?? '내용 없음';
    final String date = review['createdAt'] != null 
      ? DateTime.parse(review['createdAt']).toString().substring(0, 10)
      : '날짜 정보 없음';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '작성자: $authorName',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ...List.generate(5, (index) => Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: index < rating ? Colors.amber : Colors.grey,
                      size: 20,
                    )),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.bookmark_remove, color: Colors.red, size: 20),
                  onPressed: () {
                    // 저장한 리뷰 삭제 기능
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('저장한 리뷰 삭제 기능은 준비 중입니다')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('리뷰 관리'),
        backgroundColor: Color(0xFFA0CC71),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 작성한 리뷰 탭
          _isLoading
            ? Center(child: CircularProgressIndicator())
            : _myReviews.isEmpty
              ? Center(child: Text('작성한 리뷰가 없습니다'))
              : ListView.builder(
                  itemCount: _myReviews.length,
                  itemBuilder: (context, index) => _buildReviewCard(_myReviews[index]),
                ),
          
          // 저장한 리뷰 탭
          _isLoading
            ? Center(child: CircularProgressIndicator())
            : Center(child: Text('저장한 리뷰 기능은 준비 중입니다')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 리뷰 작성 페이지로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('리뷰 작성 기능은 준비 중입니다')),
          );
        },
        backgroundColor: Color(0xFFA0CC71),
        child: Icon(Icons.add),
      ),
    );
  }
}