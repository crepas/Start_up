import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/TopAppbar.dart';

class ReviewManagementTab extends StatefulWidget {
  @override
  _ReviewManagementTabState createState() => _ReviewManagementTabState();
}

class _ReviewManagementTabState extends State<ReviewManagementTab> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _myReviews = [];
  List<Map<String, dynamic>> _savedReviews = []; // 저장한 리뷰를 위한 리스트 추가

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

  // 리뷰 수정 페이지로 이동
  void _navigateToEditReview(Map<String, dynamic> review) {
    // 실제 구현 시 리뷰 수정 페이지로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('리뷰 수정 기능은 준비 중입니다')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('리뷰 관리'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
            labelColor: colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodyLarge?.color,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReviewList(_myReviews),
                _buildReviewList(_savedReviews),
              ],
            ),
          ),
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

  Widget _buildReviewList(List<Map<String, dynamic>> reviews) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
        ),
      );
    }

    if (reviews.isEmpty) {
      return Center(
        child: Text(
          '리뷰가 없습니다',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        return _buildReviewCard(reviews[index]);
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String restaurantName = review['restaurantName'] ?? '식당 이름 없음';
    final int rating = review['rating'] ?? 0;
    final String content = review['content'] ?? '내용 없음';
    final String date = review['createdAt'] != null
        ? DateTime.parse(review['createdAt']).toString().substring(0, 10)
        : '날짜 정보 없음';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    restaurantName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: colorScheme.primary, size: 20),
                    SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              content,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _navigateToEditReview(review),
                      child: Text(
                        '수정',
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _deleteReview(review['_id']),
                      child: Text(
                        '삭제',
                        style: TextStyle(color: colorScheme.error),
                      ),
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

  void _showErrorSnackBar(String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
      ),
    );
  }
}