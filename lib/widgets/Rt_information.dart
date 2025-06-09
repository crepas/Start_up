import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import '../utils/api_config.dart';
import '../services/restaurant_service.dart'; // RestaurantService 사용
import '../widgets/ReviewSheetContainer.dart'; // 기존 리뷰 위젯 import
import '../utils/api_config.dart';

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
  late RestaurantService _restaurantService;

  @override
  void initState() {
    super.initState();
    currentLikes = widget.likes;
    _restaurantService = RestaurantService();

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

  // 초기 좋아요 상태 확인 - 일단 간단하게 초기화만
  Future<void> _checkInitialLikeStatus() async {
    if (widget.restaurant == null) {
      setState(() {
        isInitialized = true;
      });
      return;
    }

    try {
      // RestaurantService를 사용하여 좋아요 상태 확인
      final result = await _restaurantService.getLikeStatus(widget.restaurant!.id);

      print('좋아요 상태 확인 결과: $result');

      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            liked = result['isLiked'] ?? false;
            currentLikes = result['likes'] ?? widget.likes;
          } else {
            liked = false;
            currentLikes = widget.likes;
          }
          isInitialized = true;
        });
      }
    } catch (e) {
      print('좋아요 상태 확인 오류: $e');
      if (mounted) {
        setState(() {
          liked = false;
          currentLikes = widget.likes;
          isInitialized = true;
        });
      }
    }
  }

// 세션 쿠키를 가져오는 헬퍼 함수 추가 (아직 없다면)
  Future<String> _getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_cookie') ?? '';
  }

  // 좋아요 토글 함수 (RestaurantService 사용)
  Future<void> toggleLike() async {
    if (isProcessing || widget.restaurant == null) return;

    setState(() {
      isProcessing = true;
    });

    try {
      HapticFeedback.lightImpact();

      // RestaurantService의 toggleLike 사용
      final result = await _restaurantService.toggleLike(widget.restaurant!.id);

      if (mounted) {
        setState(() {
          // API 응답에서 현재 좋아요 상태와 수를 받아옴
          liked = result['isLiked'] ?? !liked;
          currentLikes = result['likes'] ?? currentLikes;
        });

        // 하트 애니메이션 실행 (좋아요 추가일 때만)
        if (liked) {
          _heartController.forward().then((_) {
            _heartController.reverse();
          });
        }

        // 부모 위젯에 좋아요 수 변경 알림
        if (widget.onLikesChanged != null) {
          widget.onLikesChanged!(currentLikes);
        }

        // 성공 메시지 표시
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
    } catch (e) {
      print('좋아요 처리 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('서버에서 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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