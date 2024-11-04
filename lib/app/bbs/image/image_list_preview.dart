import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageListPreview extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageListPreview({super.key, required this.imageUrls, this.initialIndex = 0});

  @override
  _ImageListPreviewState createState() => _ImageListPreviewState();
}

class _ImageListPreviewState extends State<ImageListPreview> {
  late List<String> _imageUrls;
  int _currentIndex = 0;
  // final CarouselController _carouselController = CarouselController();
  final CarouselSliderController _carouselController = CarouselSliderController();

  ValueNotifier<bool> ishideThumb = ValueNotifier<bool>(true);

  late List<TransformationController> _transformationControllers;

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.imageUrls);
    _currentIndex = widget.initialIndex;
    _transformationControllers = List.generate(
      _imageUrls.length,
      (_) => TransformationController(),
    );
  }

  void _resetZoom() {
    _transformationControllers[_currentIndex].value = Matrix4.identity();
  }

  @override
  void dispose() {
    for (var controller in _transformationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main carousel
          Container(
            alignment: Alignment.topCenter,
            color: Colors.black,
            child: CarouselSlider(
              // items: _imageUrls.map((url) => Image.network(url, fit: BoxFit.cover)).toList(),
              items: _imageUrls.asMap().entries.map((entry) {
                int index = entry.key;
                String url = entry.value;
                return InteractiveViewer(
                  transformationController: _transformationControllers[index],
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(tag: url, child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain)),
                );
              }).toList(),
              options: CarouselOptions(
                height: MediaQuery.of(context).size.height,
                viewportFraction: 1.0,
                enlargeCenterPage: false,
                initialPage: widget.initialIndex,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              carouselController: _carouselController,
            ),
          ),
          // Close button
          Positioned(
            top: 40,
            right: 10,
            child: CircleAvatar(
              backgroundColor: Colors.grey.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          // Thumbnail list
          ValueListenableBuilder<bool>(
              valueListenable: ishideThumb,
              builder: (context, val, snapshot) {
                return AnimatedPositioned(
                  bottom: 20,
                  left: val ? 0 : 700,
                  right: val ? 0 : -700,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    height: 70,
                    color: val ? Colors.black.withOpacity(0.4) : Colors.transparent,
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageUrls.length,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  _carouselController.animateToPage(index);
                                },
                                child: Container(
                                  width: 80,
                                  height: 50,
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _currentIndex == index ? Colors.white : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(imageUrl: _imageUrls[index], fit: BoxFit.cover),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          Positioned(
            bottom: 20,
            right: 0,
            child: GestureDetector(
              onTap: () => ishideThumb.value = !ishideThumb.value,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                height: 70,
                width: 20,
                child: ValueListenableBuilder<bool>(
                    valueListenable: ishideThumb,
                    builder: (context, val, snapshot) {
                      return val
                          ? const Center(
                              child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ))
                          : const Icon(
                              Icons.arrow_left,
                              color: Colors.white,
                              size: 25,
                            );
                    }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
