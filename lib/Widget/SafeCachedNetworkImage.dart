import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:flutter/material.dart';

/// A safe wrapper for CachedNetworkImage that validates URLs before loading
/// Prevents "No host specified in URI" errors from empty or invalid URLs
class SafeCachedNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final Widget Function(BuildContext, String, DownloadProgress)?
      progressIndicatorBuilder;
  final String? placeholder;

  const SafeCachedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.progressIndicatorBuilder,
    this.placeholder,
  }) : super(key: key);

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final fixedUrl = fixImageUrl(url);
      return fixedUrl.isNotEmpty &&
          (fixedUrl.startsWith('http://') || fixedUrl.startsWith('https://'));
    } catch (e) {
      debugPrint('⚠️ [SafeCachedNetworkImage] URL validation failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidUrl(imageUrl)) {
      debugPrint(
          '🟡 [SafeCachedNetworkImage] Invalid URL, showing placeholder: $imageUrl');
      return _buildPlaceholder();
    }

    final fixedUrl = fixImageUrl(imageUrl);

    return CachedNetworkImage(
      imageUrl: fixedUrl,
      height: height,
      width: width,
      fit: fit,
      placeholder: (context, url) => _buildPlaceholder(),
      progressIndicatorBuilder: progressIndicatorBuilder ??
          (context, url, progress) {
            return Center(
              child: CircularProgressIndicator(
                value: progress.progress,
                strokeWidth: 2,
              ),
            );
          },
      errorWidget: errorWidget ??
          (context, url, error) {
            debugPrint('🔴 [SafeCachedNetworkImage] Failed to load: $url');
            return _buildPlaceholder();
          },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: height,
      width: width,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[400],
          size: 32,
        ),
      ),
    );
  }
}
