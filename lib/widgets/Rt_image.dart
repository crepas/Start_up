// lib/widgets/Rt_image.dart 수정
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  int currentPage = 0;

  bool _isNetworkImage(String imagePath) {
    return imagePath.startsWith('http://') || imagePath.startsWith('https://');
  }

  Widget _buildImage(String imagePath, double imageSize) {
    if (_isNetworkImage(imagePath)) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        width: imageSize,
        height: imageSize,
        placeholder: (context, url) => Container(
          width: imageSize,
          height: imageSize,
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, error, stackTrace) => Container(
          width: imageSize,
          height: imageSize,
          color: Colors.grey[300],
          child: Icon(
            Icons.broken_image,
            size: imageSize * 0.2,
            color: Colors.grey[500],
          ),
        ),
      );
    } else {
      return Image.asset(
        imagePath,
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
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth;

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
            if (widget.images.length > 1) _buildImageIndex(imageSize),
          ],
        ),
      ),
    );
  }

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
            child: _buildImage(widget.images[index], imageSize),
          ),
        );
      },
    );
  }

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