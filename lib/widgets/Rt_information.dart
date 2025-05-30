import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/restaurant.dart';

class RtInformation extends StatefulWidget {
  final int likes;
  final int reviewCount;
  final Restaurant? restaurant;
  final Function? onMapPressed;

  const RtInformation({
    Key? key,
    required this.likes,
    required this.reviewCount,
    this.restaurant,
    this.onMapPressed,
  }) : super(key: key);

  @override
  _RtInformationState createState() => _RtInformationState();
}

class _RtInformationState extends State<RtInformation> {
  bool liked = false;

  // 좋아요 토글 함수
  void toggleLike() {
    HapticFeedback.lightImpact();
    setState(() {
      liked = !liked;
    });
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
          // 좋아요 아이콘
          IconButton(
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? Colors.red : Colors.black,
              size: screenWidth * 0.07,
            ),
            onPressed: toggleLike,
          ),

          // 좋아요 수
          Text(
            widget.likes.toString(),
            style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04),
          ),
          SizedBox(width: screenWidth * 0.04),

          // 댓글 아이콘
          Icon(
              Icons.chat_bubble_outline,
              size: screenWidth * 0.065
          ),
          SizedBox(width: screenWidth * 0.01),

          // 댓글 수
          Text(
            widget.reviewCount.toString(),
            style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04),
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