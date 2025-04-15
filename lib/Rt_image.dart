import 'package:flutter/material.dart';

class RtImage extends StatefulWidget {
  const RtImage({
    Key? key,
  }) : super(key: key);

  @override
  _RtImageState createState() => _RtImageState();
}

class _RtImageState extends State<RtImage> {
  final List<String> imageUrls = [
    'assets/food1.png',
    'assets/food2.png',
    'assets/food3.png',
  ];

  int currentPage = 0; // 현재 페이지 (슬라이더에서의 이미지 인덱스)

  @override
  Widget build(BuildContext context) {
    // 화면의 width를 가져오기
    final screenWidth = MediaQuery.of(context).size.width;

    // width를 기준으로 이미지의 가로세로 크기를 동일하게 설정
    final imageSize = screenWidth;

    return Center(
      child: Container(
        width: imageSize, // 슬라이더와 이미지를 포함하는 박스의 가로 크기
        height: imageSize, // 슬라이더와 이미지를 포함하는 박스의 세로 크기
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15), // 둥근 모서리
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // 그림자 색상
              blurRadius: 10, // 그림자 흐림 정도
              offset: Offset(0, 0.5), // 그림자의 위치
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
      itemCount: imageUrls.length, // 슬라이드할 이미지 개수
      onPageChanged: (index) {
        setState(() {
          currentPage = index; // 페이지가 변경되면 현재 페이지 업데이트
        });
      },
      itemBuilder: (context, index) {
        return InteractiveViewer(
          panEnabled: true, // 드래그로 이미지 이동 가능
          minScale: 1, // 최소 확대 비율
          maxScale: 3, // 최대 확대 비율
          child: Image.asset(
            imageUrls[index], // 현재 인덱스의 이미지 로드
            fit: BoxFit.cover, // 이미지 비율을 유지하면서 크기에 맞게 잘라냄
            width: imageSize, // 동적으로 설정된 크기
            height: imageSize, // 동적으로 설정된 크기
          ),
        );
      },
    );
  }

  // 현재 이미지 인덱스를 표시하는 위젯 (오른쪽 상단에 표시)
  Widget _buildImageIndex(double imageSize) {
    return Positioned(
      top: imageSize * 0.025, // 이미지 상단에 약간의 여백을 줘서 위치시킴
      right: imageSize * 0.025, // 이미지 우측에 약간의 여백을 줘서 위치시킴
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: imageSize * 0.025, // 좌우 여백
          vertical: imageSize * 0.012, // 상하 여백
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5), // 배경색 반투명 처리
          borderRadius: BorderRadius.circular(imageSize * 0.038), // 둥근 모서리

        ),
        child: Text(
          '${currentPage + 1}/${imageUrls.length}', // "현재 페이지/총 이미지 개수"
          style: TextStyle(
            color: Colors.white, // 텍스트 색상: 흰색
            fontSize: imageSize * 0.03, // 폰트 크기 이미지 크기에 비례
          ),
        ),
      ),
    );
  }
}
