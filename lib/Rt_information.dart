import 'package:flutter/material.dart';

class Rt_information extends StatefulWidget {
  @override
  _Rt_information createState() => _Rt_information();
}

class _Rt_information extends State<Rt_information> {
  bool liked = false;

  // ❤️ 좋아요 토글 함수
  void toggleLike() {
    setState(() {
      liked = !liked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
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

          // 좋아요 수
          Text(
            '532',
            style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04),
          ),
          SizedBox(width: 16),

          // 💬 댓글 아이콘
          Icon(Icons.chat_bubble_outline, size: screenWidth * 0.065),
          SizedBox(width: 4),

          // 댓글 수
          Text(
            '120',
            style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04),
          ),

          Spacer(),

          // 📍 지도 아이콘만 표시 (텍스트 없음)
          Icon(Icons.map_outlined, size: screenWidth * 0.07),
        ],
      ),
    );
  }
}
