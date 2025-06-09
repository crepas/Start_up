// ListView_RT.dart 수정 - 네트워크 이미지 지원

import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ListViewRt extends StatefulWidget {
  final Restaurant restaurant;
  final bool isExpanded;
  final VoidCallback onTap;

  const ListViewRt({
    Key? key,
    required this.restaurant,
    this.isExpanded = false,
    required this.onTap,
  }) : super(key: key);

  @override
  _ListViewRtState createState() => _ListViewRtState();
}

class _ListViewRtState extends State<ListViewRt> {
  bool isFavorite = false;

  // 이미지 URL이 네트워크 이미지인지 확인
  bool _isNetworkImage(String imagePath) {
    return imagePath.startsWith('http://') || imagePath.startsWith('https://');
  }

  // 안전한 이미지 위젯 생성
  Widget _buildRestaurantImage(String imagePath, double width, double height) {
    if (_isNetworkImage(imagePath)) {
      // 네트워크 이미지인 경우
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Center(
            child: SizedBox(
              width: width * 0.3,
              height: width * 0.3,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant,
                color: Colors.grey[600],
                size: width * 0.3,
              ),
              SizedBox(height: 4),
              Text(
                '이미지 로드 실패',
                style: TextStyle(
                  fontSize: width * 0.08,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      // 로컬 assets 이미지인 경우
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant,
                  color: Colors.grey[600],
                  size: width * 0.3,
                ),
                SizedBox(height: 4),
                Text(
                  '이미지 없음',
                  style: TextStyle(
                    fontSize: width * 0.08,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    }
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.015),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, screenWidth * 0.002),
              blurRadius: screenWidth * 0.01,
              spreadRadius: 0,
            ),
          ],
          border: widget.isExpanded
              ? Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5)
              : null,
        ),
        width: double.infinity,
        height: screenWidth * 0.14,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.025,
            vertical: screenWidth * 0.018,
          ),
          child: Row(
            children: [
              // 음식점 이미지 - 네트워크 이미지 지원
              ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.015),
                child: widget.restaurant.images.isNotEmpty
                    ? _buildRestaurantImage(
                  widget.restaurant.images.first,
                  screenWidth * 0.12,
                  screenWidth * 0.12,
                )
                    : Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  color: Colors.grey[300],
                  child: Icon(Icons.restaurant, color: Colors.grey[600]),
                ),
              ),

              SizedBox(width: screenWidth * 0.02),

              // 음식점 정보 컬럼
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 음식점 이름
                    Text(
                      widget.restaurant.name,
                      style: TextStyle(
                        color: const Color(0xFF151618),
                        fontSize: screenWidth * 0.033,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    // 거리 텍스트
                    Text(
                      widget.restaurant.address,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.028,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // 좋아요 버튼

            ],
          ),
        ),
      ),
    );
  }
}