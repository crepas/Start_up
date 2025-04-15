import 'package:flutter/material.dart';

class RtImage extends StatefulWidget {
  final List<String> images;

  const RtImage({
    Key? key,
    required this.images,
  }) : super(key: key);

  @override
  _RtImageState createState() => _RtImageState();
}

class _RtImageState extends State<RtImage> {
  int currentPage = 0; // 현재 페이지 (슬라이더에서의 이미지 인덱스)

  @override
  Widget build(BuildContext context) {
    // 화면의 width를 가져오기
    final screenWidth = MediaQuery.of(context).size.width;

    // width를 기준으로 이미지의 가로세로 크기를 동일하게 설정
    final imageSize = screenWidth;

    // 이미지가 없는 경우 기본 이미지 표시
    if (widget.images.isEmpty) {
      return Center(
        child: Container(
          width: imageSize,
          height: imageSize,
          color: Colors.grey[300],
          child: Icon(
            Icons.image_not_supported,
            size: imageSize * 0.3,
            color: Colors.grey[500],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: screenWidth * 0.02,
              offset: Offset(0, screenWidth * 0.001),
            ),
          ],
        ),
        child: Stack(
          children: [
            _buildImageSlider(imageSize),
            _buildImageIndex(imageSize),
          ],
        ),
      ),
    );
  }

  // 이미지 슬라이더를 생성하는 함수
  Widget _buildImageSlider(double imageSize) {
    return PageView.builder(
      itemCount: widget.images.length,
      onPageChanged: (index) {
        setState(() {
          currentPage = index;
        });
      },
      itemBuilder: (context, index) {
        return InteractiveViewer(
          panEnabled: true,
          minScale: 1,
          maxScale: 3,
          child: Image.asset(
            widget.images[index],
            fit: BoxFit.cover,
            width: imageSize,
            height: imageSize,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: imageSize,
                height: imageSize,
                color: Colors.grey[300],
                child: Icon(
                  Icons.broken_image,
                  size: imageSize * 0.2,
                  color: Colors.grey[500],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 현재 이미지 인덱스를 표시하는 위젯 (오른쪽 상단에 표시)
  Widget _buildImageIndex(double imageSize) {
    return Positioned(
      top: imageSize * 0.025,
      right: imageSize * 0.025,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: imageSize * 0.025,
          vertical: imageSize * 0.012,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(imageSize * 0.038),
        ),
        child: Text(
          '${currentPage + 1}/${widget.images.length}',
          style: TextStyle(
            color: Colors.white,
            fontSize: imageSize * 0.03,
          ),
        ),
      ),
    );
  }
}