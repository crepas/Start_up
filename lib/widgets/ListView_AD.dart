import 'package:flutter/material.dart';
import '../models/restaurant.dart';

class ListViewAd extends StatefulWidget {
  final Restaurant restaurant;
  final bool isExpanded;
  final VoidCallback onTap;

  const ListViewAd({
    Key? key,
    required this.restaurant,
    required this.isExpanded,
    required this.onTap,
  }) : super(key: key);

  @override
  _ListViewAdState createState() => _ListViewAdState();
}

class _ListViewAdState extends State<ListViewAd> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _rotation = Tween<double>(begin: 0.0, end: 0.125) // 1/8 회전 = 45도
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant ListViewAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 확장 상태에 따라 애니메이션 방향 조절
    if (widget.isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: screenWidth * 0.01,
          horizontal: screenWidth * 0.02,
        ),
        padding: EdgeInsets.all(screenWidth * 0.02),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.01),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, screenWidth * 0.002),
              blurRadius: screenWidth * 0.01,
            ),
          ],
          border: widget.isExpanded
              ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5)
              : null,
        ),
        height: screenWidth * 0.21,
        child: Row(
          children: [
            // 이미지 + AD 뱃지
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.01),
                  child: widget.restaurant.images.isNotEmpty
                      ? Image.asset(
                    widget.restaurant.images.first,
                    width: screenWidth * 0.18,
                    height: screenWidth * 0.18,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: screenWidth * 0.18,
                        height: screenWidth * 0.18,
                        color: Colors.grey[300],
                        child: Icon(Icons.restaurant, color: Colors.grey[600]),
                      );
                    },
                  )
                      : Container(
                    width: screenWidth * 0.18,
                    height: screenWidth * 0.18,
                    color: Colors.grey[300],
                    child: Icon(Icons.restaurant, color: Colors.grey[600]),
                  ),
                ),
                Positioned(
                  top: screenWidth * 0.01,
                  left: screenWidth * 0.01,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.006,
                      vertical: screenWidth * 0.001,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    child: Text(
                      'AD',
                      style: TextStyle(
                        fontSize: screenWidth * 0.016,
                        fontWeight: FontWeight.bold,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: screenWidth * 0.025),

            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.restaurant.name,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    widget.restaurant.address,
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // 회전하는 + 아이콘
            RotationTransition(
              turns: _rotation,
              child: Icon(
                Icons.add,
                size: screenWidth * 0.06,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}