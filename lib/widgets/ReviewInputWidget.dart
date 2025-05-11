import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

/// 리뷰 입력 위젯
/// 
/// 사용자가 리뷰를 작성하고 이미지를 첨부할 수 있는 위젯입니다.
/// 최대 5개의 이미지를 첨부할 수 있으며, 텍스트와 이미지를 함께 입력할 수 있습니다.
class ReviewInputWidget extends StatefulWidget {
  /// 사용자 닉네임
  final String nickname;

  ReviewInputWidget({required this.nickname});

  @override
  _ReviewInputWidgetState createState() => _ReviewInputWidgetState();
}

class _ReviewInputWidgetState extends State<ReviewInputWidget> {
  /// 리뷰 텍스트 입력을 위한 컨트롤러
  final TextEditingController _reviewController = TextEditingController();
  
  /// 선택된 이미지 파일 목록
  List<File> _selectedImages = [];
  
  /// 작성된 리뷰 목록
  List<Map<String, dynamic>> _reviewList = [];

  /// 이미지 선택 메서드
  /// 
  /// 갤러리에서 최대 5개의 이미지를 선택할 수 있습니다.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImages = await picker.pickMultiImage();

    if (pickedImages != null && pickedImages.isNotEmpty) {
      // 최대 5개까지만 선택 가능하도록 제한
      final limitedImages = pickedImages.take(5 - _selectedImages.length).toList();
      final imageFiles = limitedImages.map((picked) => File(picked.path)).toList();

      setState(() {
        _selectedImages.addAll(imageFiles);
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.sublist(0, 5);
        }
      });
    }
  }

  /// 리뷰 제출 메서드
  /// 
  /// 텍스트나 이미지가 하나 이상 있어야 제출 가능합니다.
  void _submitReview() {
    if (_reviewController.text.trim().isEmpty && _selectedImages.isEmpty) return;

    setState(() {
      _reviewList.insert(0, {
        'nickname': widget.nickname,
        'text': _reviewController.text.trim(),
        'images': [..._selectedImages],
        'time': DateTime.now()
      });
      _reviewController.clear();
      _selectedImages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이미지 첨부 버튼과 리뷰 입력 필드
        Row(
          children: [
            // 이미지 첨부 버튼
            SizedBox(
              width: screenHeight * 0.05,
              height: screenHeight * 0.05,
              child: ElevatedButton(
                onPressed: _selectedImages.length < 5 ? _pickImage : null,
                child: Text('+', style: TextStyle(fontSize: screenWidth * 0.05)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.01),
            // 리뷰 입력 필드
            Expanded(
              child: TextField(
                controller: _reviewController,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: '리뷰를 입력하세요',
                  hintStyle: TextStyle(fontSize: 12),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  // 제출 버튼
                  suffixIcon: Padding(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                    child: ElevatedButton(
                      onPressed: _submitReview,
                      child: Icon(Icons.arrow_upward),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(0),
                        backgroundColor: Colors.white,
                        shape: CircleBorder(),
                        minimumSize: Size(screenWidth * 0.01, screenHeight * 0.005),
                      ),
                    ),
                  ),
                ),
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.01),
        // 선택된 이미지 미리보기
        if (_selectedImages.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _selectedImages.map((img) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Stack(
                    children: [
                      Image.file(img, height: screenHeight * 0.15),
                      // 이미지 삭제 버튼
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.remove(img);
                            });
                          },
                          child: Icon(Icons.close, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        Divider(),
        // 작성된 리뷰 목록
        ..._reviewList.map((review) => _buildReviewItem(review, screenWidth, screenHeight)).toList(),
      ],
    );
  }

  /// 리뷰 아이템 위젯 생성
  Widget _buildReviewItem(Map<String, dynamic> review, double screenWidth, double screenHeight) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01, horizontal: screenWidth * 0.03),
      child: ListTile(
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${review['text']}'),
            SizedBox(height: screenHeight * 0.005),
            // 첨부된 이미지 표시
            if (review['images'] != null)
              Wrap(
                spacing: 4,
                children: List.generate(
                  review['images'].length,
                      (index) => Image.file(
                    review['images'][index],
                    height: screenHeight * 0.15,
                  ),
                ),
              ),
            // 작성 시간 표시
            Text(
              '${review['time'].toLocal()}',
              style: TextStyle(fontSize: screenWidth * 0.025, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
