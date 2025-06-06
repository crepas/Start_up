import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import '../services/api_config.dart';
import '../services/likeService.dart'; // 위에서 만든 LikeService import
import '../services/restaurant_service.dart'; // ReviewService import 추가
import '../widgets/ReviewSheetContainer.dart'; // 기존 리뷰 위젯 import

class RtInformation extends StatefulWidget {
  final int likes;
  final int reviewCount;
  final Restaurant? restaurant;
  final Function? onMapPressed;
  final Function? onLikesChanged; // 좋아요 수 변경 콜백 추가

  const RtInformation({
    Key? key,
    required this.likes,
    required this.reviewCount,
    this.restaurant,
    this.onMapPressed,
    this.onLikesChanged,
  }) : super(key: key);

  @override
  _RtInformationState createState() => _RtInformationState();
}

class _RtInformationState extends State<RtInformation> with TickerProviderStateMixin {
  bool liked = false;
  int currentLikes = 0;
  bool isProcessing = false;
  bool isInitialized = false;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();
    currentLikes = widget.likes;

    // 하트 애니메이션 컨트롤러
    _heartController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _heartAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.elasticOut,
    ));

    // 초기 좋아요 상태 확인
    _checkInitialLikeStatus();
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  // 초기 좋아요 상태 확인
  Future<void> _checkInitialLikeStatus() async {
    if (widget.restaurant == null) return;

    try {
      // getLikeStatus가 매개변수를 받지 않는다면 다른 방법 사용
      // 또는 직접 API 호출
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          isInitialized = true;
        });
        return;
      }

      final baseUrl = getServerUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/likes/status/${widget.restaurant!.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            liked = data['isLiked'] ?? false;
            // 서버에서 받아온 최신 좋아요 수로 업데이트
            if (data['likes'] != null) {
              currentLikes = data['likes'];
            }
            isInitialized = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('좋아요 상태 확인 오류: $e');
      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    }
  }

  // 좋아요 토글 함수 (실제 API 호출)
  Future<void> toggleLike() async {
    if (isProcessing || widget.restaurant == null) return;

    setState(() {
      isProcessing = true;
    });

    try {
      HapticFeedback.lightImpact();

      Map<String, dynamic> result;

      if (liked) {
        // 좋아요 취소
        result = await LikeService.unlikeRestaurant(
          restaurantId: widget.restaurant!.id,
          restaurantName: widget.restaurant!.name,
        );
      } else {
        // 좋아요 추가
        result = await LikeService.likeRestaurant(
          restaurantId: widget.restaurant!.id,
          restaurantName: widget.restaurant!.name,
        );

        // 하트 애니메이션 실행
        _heartController.forward().then((_) {
          _heartController.reverse();
        });
      }

      if (result['success'] == true) {
        setState(() {
          liked = !liked;
          // 서버에서 반환된 좋아요 수가 있으면 사용, 없으면 로컬에서 계산
          if (result['likes'] != null) {
            currentLikes = result['likes'];
          } else {
            currentLikes = liked ? currentLikes + 1 : currentLikes - 1;
          }
        });

        // 부모 위젯에 좋아요 수 변경 알림
        if (widget.onLikesChanged != null) {
          widget.onLikesChanged!(currentLikes);
        }

        // 성공 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                liked
                    ? '${widget.restaurant!.name}을(를) 좋아요에 추가했습니다! ❤️'
                    : '${widget.restaurant!.name} 좋아요를 취소했습니다.',
              ),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // 실패 시 에러 메시지
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('좋아요 처리 중 오류가 발생했습니다: ${result['error'] ?? '알 수 없는 오류'}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('좋아요 처리 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  // 지도로 이동하는 함수
  void _navigateToMap() {
    if (widget.onMapPressed != null) {
      widget.onMapPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenWidth * 0.02
      ),
      child: Row(
        children: [
          // 좋아요 아이콘 (애니메이션 적용)
          AnimatedBuilder(
            animation: _heartAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _heartAnimation.value,
                child: Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? Colors.red : Colors.grey[600],
                        size: screenWidth * 0.07,
                      ),
                      onPressed: (!isInitialized || isProcessing) ? null : toggleLike,
                    ),
                    // 로딩 인디케이터
                    if (isProcessing)
                      Positioned.fill(
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[400]!,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          // 좋아요 수 (실시간 업데이트)
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: Text(
              currentLikes.toString(),
              key: ValueKey(currentLikes),
              style: TextStyle(
                color: Colors.black,
                fontSize: screenWidth * 0.04,
                fontWeight: liked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.04),

          // 댓글 아이콘과 리뷰 시트 열기
          GestureDetector(
            onTap: () {
              // 기존 리뷰 시트 열기
              if (widget.restaurant != null) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.7,
                    minChildSize: 0.3,
                    maxChildSize: 0.9,
                    builder: (context, scrollController) => ReviewSheetContainer(
                      screenWidth: MediaQuery.of(context).size.width,
                      reviews: widget.restaurant!.reviews,
                      scrollController: scrollController,
                    ),
                  ),
                );
              }
            },
            child: Row(
              children: [
                Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey[600],
                    size: screenWidth * 0.065
                ),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  widget.reviewCount.toString(),
                  style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04),
                ),
              ],
            ),
          ),

          Spacer(),

          // 지도 아이콘
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: IconButton(
              icon: Icon(
                Icons.map_outlined,
                size: screenWidth * 0.07,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: _navigateToMap,
              tooltip: '지도에서 보기',
            ),
          ),
        ],
      ),
    );
  }
}