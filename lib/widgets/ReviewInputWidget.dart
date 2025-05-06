import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ReviewInputWidget extends StatefulWidget {
  final String nickname;

  ReviewInputWidget({required this.nickname});

  @override
  _ReviewInputWidgetState createState() => _ReviewInputWidgetState();
}

class _ReviewInputWidgetState extends State<ReviewInputWidget> {
  final TextEditingController _reviewController = TextEditingController();
  List<File> _selectedImages = [];
  List<Map<String, dynamic>> _reviewList = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImages = await picker.pickMultiImage(); // 다중 이미지 선택

    if (pickedImages != null && pickedImages.isNotEmpty) {
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
        Row(
          children: [
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
        // 선택한 이미지들 미리보기
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
        ..._reviewList.map((review) => _buildReviewItem(review, screenWidth, screenHeight)).toList(),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review, double screenWidth, double screenHeight) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01, horizontal: screenWidth * 0.03),
      child: ListTile(
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${review['text']}'),
            SizedBox(height: screenHeight * 0.005),
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
