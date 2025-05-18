import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:start_up/utils/api_config.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  EditProfileScreen({required this.userInfo});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  List<String> _selectedFoodTypes = [];
  String _selectedPriceRange = '중간';
  bool _isLoading = false;

  // 가능한 음식 종류 목록
  final List<String> _availableFoodTypes = [
    '한식', '중식', '일식', '양식', '분식',
    '고기', '해산물', '채식', '면류', '디저트'
  ];

  // 가격대 옵션
  final List<String> _priceRanges = ['저렴', '중간', '고가'];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.userInfo['username']);

    // 기존 선호 음식 종류 설정
    if (widget.userInfo['preferences'] != null &&
        widget.userInfo['preferences']['foodTypes'] != null) {
      _selectedFoodTypes = List<String>.from(widget.userInfo['preferences']['foodTypes']);
    }

    // 기존 선호 가격대 설정
    if (widget.userInfo['preferences'] != null &&
        widget.userInfo['preferences']['priceRange'] != null) {
      _selectedPriceRange = widget.userInfo['preferences']['priceRange'];
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  // 프로필 업데이트 함수
  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _showErrorMessage('인증 정보가 없습니다. 다시 로그인해주세요.');
        return;
      }

      // 요청 데이터 준비
      final requestData = {
        'username': _usernameController.text.trim(),
        'preferences': {
          'foodTypes': _selectedFoodTypes,
          'priceRange': _selectedPriceRange
        }
      };

      print('요청 데이터: ${jsonEncode(requestData)}');

      // 두 가지 URL로 시도해 보기
      // 첫 번째 시도: /profile 경로
      final response = await _tryApiCall(
          '${getServerUrl()}/profile',
          token,
          requestData
      );

      // 응답 처리
      if (response.statusCode == 200) {
        await _handleSuccessResponse(prefs);
      } else if (response.statusCode == 404) {
        // 404 오류가 발생하면 /api/profile로 다시 시도
        final apiResponse = await _tryApiCall(
            '${getServerUrl()}/profile',
            token,
            requestData
        );

        if (apiResponse.statusCode == 200) {
          await _handleSuccessResponse(prefs);
        } else {
          _handleErrorResponse(apiResponse);
        }
      } else {
        _handleErrorResponse(response);
      }
    } catch (e) {
      print('프로필 업데이트 오류: $e');
      print(StackTrace.current);
      _showErrorMessage('서버 연결 오류가 발생했습니다. 다시 시도해주세요.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// API 호출 시도 함수
  Future<http.Response> _tryApiCall(String url, String token, Map<String, dynamic> data) async {
    print('API 호출 시도: $url');
    print('사용 토큰: $token'); // 디버깅용

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    print('서버 응답 상태 코드($url): ${response.statusCode}');
    print('서버 응답 본문($url): ${response.body}');

    return response;
  }

// 성공 응답 처리 함수
  Future<void> _handleSuccessResponse(SharedPreferences prefs) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 로컬 저장소 업데이트
    await prefs.setString('username', _usernameController.text.trim());
    await prefs.setStringList('foodTypes', _selectedFoodTypes);
    await prefs.setString('priceRange', _selectedPriceRange);

    // 성공 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('프로필이 성공적으로 업데이트되었습니다.'),
        backgroundColor: colorScheme.primary,
      ),
    );

    // 이전 화면으로 돌아가기
    Navigator.pop(context, true);
  }

// 오류 응답 처리 함수
  void _handleErrorResponse(http.Response response) {
    try {
      final responseData = jsonDecode(response.body);
      _showErrorMessage(responseData['message'] ?? '프로필 업데이트에 실패했습니다.');
    } catch (jsonError) {
      print('JSON 파싱 오류: $jsonError');
      _showErrorMessage('서버 응답 형식 오류: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }

  // 에러 메시지 표시
  void _showErrorMessage(String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 편집'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 사진 (기능 미구현)
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: theme.dividerColor,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: theme.hintColor,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // 사용자 이름 입력
                  Text(
                    '사용자 이름',
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: '사용자 이름을 입력하세요',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // 선호 음식 종류
                  Text(
                    '선호하는 음식 종류',
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableFoodTypes.map((type) {
                      final isSelected = _selectedFoodTypes.contains(type);
                      return FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedFoodTypes.add(type);
                            } else {
                              _selectedFoodTypes.remove(type);
                            }
                          });
                        },
                        backgroundColor: theme.cardColor,
                        selectedColor: colorScheme.primary.withOpacity(0.2),
                        checkmarkColor: colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? colorScheme.primary : theme.textTheme.bodyMedium?.color,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                  // 선호 가격대
                  Text(
                    '선호하는 가격대',
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _priceRanges.map((range) {
                      final isSelected = _selectedPriceRange == range;
                      return ChoiceChip(
                        label: Text(range),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPriceRange = range;
                            });
                          }
                        },
                        backgroundColor: theme.cardColor,
                        selectedColor: colorScheme.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? colorScheme.primary : theme.textTheme.bodyMedium?.color,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 32),
                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '저장하기',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}