import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class CustomImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double borderRadius;

  const CustomImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: width,
        fit: fit,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: height,
            width: width,
            color: Colors.white,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: height,
          width: width,
          color: Colors.grey[200],
          child: Icon(Icons.broken_image, color: Colors.grey[400]),
        ),
      ),
    );
  }
}
