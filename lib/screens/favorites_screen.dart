import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/TopAppbar.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _favorites = [];
  
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }
  
  // MongoDB에서 찜 목록 데이터 불러오기
  Future<void> _loadFavorites() async {
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
      
      // 서버 API 호출
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        setState(() {
          _favorites = List<Map<String, dynamic>>.from(
            responseData['favorites'].map((item) => {
              'id': item['_id'],
              'name': item['name'],
              'category': item['category'],
              'rating': item['rating'] ?? 0.0,
              'imageUrl': item['imageUrl'] ?? 'assets/restaurant_placeholder.png',
              'address': item['address'] ?? '주소 정보 없음',
            })
          );
          _isLoading = false;
        });
      } else {
        // 에러 처리
        print('찜 목록 로드 오류: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('찜 목록 로드 중 예외 발생: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 찜 해제하기
  Future<void> _removeFavorite(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.delete(
        Uri.parse('http://localhost:8081/api/favorites/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        // 로컬 목록에서 제거
        setState(() {
          _favorites.removeWhere((item) => item['id'] == id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('찜 목록에서 삭제되었습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 중 오류가 발생했습니다')),
        );
      }
    } catch (e) {
      print('찜 삭제 중 예외 발생: $e');
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
        content: Text('찜 목록을 보려면 로그인이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '찜 목록',
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        '찜한 가게가 없습니다',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '마음에 드는 가게를 찜해보세요!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final item = _favorites[index];
                    return Dismissible(
                      key: Key(item['id']),
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
                        _removeFavorite(item['id']);
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              item['imageUrl'],
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 70,
                                  height: 70,
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
                            item['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                item['category'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                item['address'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    item['rating'].toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.favorite,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              _removeFavorite(item['id']);
                            },
                          ),
                          onTap: () {
                            // 가게 상세 정보로 이동
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('가게 상세 페이지 준비 중입니다')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}