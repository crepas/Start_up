import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RtInformation extends StatefulWidget {
  final int likeCount;
  final int commentCount;
  final Function? onMapPressed;

  const RtInformation({
    Key? key,
    required this.likeCount,
    required this.commentCount,
    this.onMapPressed,
  }) : super(key: key);

  @override
  _RtInformationState createState() => _RtInformationState();
}

class _RtInformationState extends State<RtInformation> {
  bool liked = false;

  // ❤️ 좋아요 토글 함수
  void toggleLike() {
    HapticFeedback.lightImpact(); // 햅틱 피드백 추가
    setState(() {
      liked = !liked;
    });
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
          // ❤️ 좋아요 아이콘
          IconButton(
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? Colors.red : Colors.black,
              size: screenWidth * 0.07,
            ),
            onPressed: toggleLike,
          ),

          // 좋아요 수 - 데이터에서 가져옴
          Text(
            widget.likeCount.toString(),
            style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04),
          ),
          SizedBox(width: screenWidth * 0.04),

          // 💬 댓글 아이콘
          Icon(
              Icons.chat_bubble_outline,
              size: screenWidth * 0.065
          ),
          SizedBox(width: screenWidth * 0.01),

          // 댓글 수 - 데이터에서 가져옴
          Text(
            widget.commentCount.toString(),
            style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04),
          ),

          Spacer(),

          // 📍 지도 아이콘 - 터치 가능하게 수정
          IconButton(
            icon: Icon(
                Icons.map_outlined,
                size: screenWidth * 0.07
            ),
            onPressed: widget.onMapPressed != null
                ? () => widget.onMapPressed!()
                : () {
              // 기본 동작 구현 - 지도 관련 기능이 추가되기 전까지 임시 메시지
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('지도 기능이 준비 중입니다.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}