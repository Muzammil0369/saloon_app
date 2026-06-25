import 'package:flutter/material.dart';

class ImageCarousel extends StatefulWidget {
  final List<dynamic> images;

  const ImageCarousel({super.key, required this.images});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
      );
    }

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final img = widget.images[index];
              if (img.startsWith('http')) {
                return Image.network(img, fit: BoxFit.cover, width: double.infinity);
              } else {
                return Image.asset(img, fit: BoxFit.cover, width: double.infinity);
              }
            },
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.images.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
