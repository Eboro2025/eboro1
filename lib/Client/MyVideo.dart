import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/API/VideoApi.dart';
import 'package:eboro/Providers/ClickProvider.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

typedef VideoData = PromoVideo;

extension VideoDataCompat on PromoVideo {
  String get resolvedVideoUrl => videoUrl;
  String get resolvedThumbnailUrl => thumbnailUrl ?? '';
  String get logoUrl => providerLogo ?? '';
}

class MyVideo extends StatefulWidget {
  final ValueNotifier<bool>? isVisible;
  const MyVideo({Key? key, this.isVisible}) : super(key: key);

  @override
  State<MyVideo> createState() => _MyVideoState();
}

class _MyVideoState extends State<MyVideo> {
  List<VideoData> _videos = [];
  List<VideoData> _allVideos = []; // unfiltered list from API
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMsg = '';
  int _currentPage = 0;
  String _currentOrder = 'manual';
  final PageController _pageController = PageController();

  // Video controllers: current, previous, next
  final Map<int, VideoPlayerController> _controllers = {};
  final Set<int> _initializedIndices = {};
  final Set<int> _failedIndices = {};
  bool _isMuted = false;

  late final ProviderController _providerCtrl;

  @override
  void initState() {
    super.initState();
    _providerCtrl = context.read<ProviderController>();
    _loadVideos();
    widget.isVisible?.addListener(_onVisibilityChanged);
    _providerCtrl.addListener(_onProvidersChanged);
  }

  @override
  void dispose() {
    widget.isVisible?.removeListener(_onVisibilityChanged);
    _providerCtrl.removeListener(_onProvidersChanged);
    _pageController.dispose();
    _disposeAllControllers();
    super.dispose();
  }

  void _onProvidersChanged() {
    if (_allVideos.isEmpty || !mounted) return;
    _refilterVideos();
  }

  void _refilterVideos() {
    if (_allVideos.isEmpty || !mounted) return;
    _applyFilter();
  }

  void _onVisibilityChanged() {
    if (widget.isVisible?.value == true) {
      _playCurrentVideo();
    } else {
      _pauseAllVideos();
    }
  }

  Future<void> _loadVideos({String? order}) async {
    final orderToUse = order ?? _currentOrder;

    // Pause and dispose all current controllers
    _disposeAllControllers();

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMsg = '';
      _currentOrder = orderToUse;
      _currentPage = 0;
    });

    try {
      // Wait for providers to load first (max 5 seconds)
      if (_providerCtrl.providers == null || _providerCtrl.providers!.isEmpty) {
        await Future.any([
          _providerCtrl.waitForProviders(),
          Future.delayed(const Duration(seconds: 5)),
        ]);
      }

      // Wait for delivery data (max 5 seconds)
      for (int i = 0; i < 10; i++) {
        if (!mounted) return;
        if (_providerCtrl.providers?.any((p) => p.Delivery != null) == true) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) return;

      _allVideos = await VideoApi.getPromoVideos(order: orderToUse);
      if (!mounted) return;

      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMsg = 'Error: $e';
      });
    }
  }

  void _applyFilter() {
    final providerList = _providerCtrl.providers;
    List<VideoData> videos;
    if (providerList != null && providerList.isNotEmpty) {
      final inRangeIds = providerList
          .where((p) => !p.outOfDeliveryRange)
          .map((p) => p.id)
          .toSet();
      videos = _allVideos
          .where((v) => inRangeIds.contains(v.providerId))
          .toList();
    } else {
      // No providers loaded - show nothing instead of all
      videos = [];
    }

    setState(() {
      _videos = videos;
      _isLoading = false;
      _hasError = videos.isEmpty;
      if (videos.isEmpty) {
        _errorMsg = 'Nessun video disponibile';
      }
    });
    if (_videos.isNotEmpty) {
      _initController(0);
    }
  }

  void _switchOrder(String order) {
    if (order == _currentOrder) return;
    _loadVideos(order: order);
  }

  void _initController(int index) {
    if (index < 0 || index >= _videos.length) return;
    if (_controllers.containsKey(index)) return;

    final url = _videos[index].resolvedVideoUrl;
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;

    // ignore: deprecated_member_use
    final controller = VideoPlayerController.network(url);
    _controllers[index] = controller;

    controller.initialize().timeout(const Duration(seconds: 15)).then((_) {
      if (!mounted) return;
      _initializedIndices.add(index);
      _failedIndices.remove(index);
      controller.setLooping(true);
      controller.setVolume(_isMuted ? 0 : 1);

      if (index == _currentPage && (widget.isVisible?.value ?? true)) {
        controller.play();
      }
      if (mounted) setState(() {});
    }).catchError((e) {
      _failedIndices.add(index);
      _disposeController(index);
      if (mounted) setState(() {});
    });
  }

  void _disposeController(int index) {
    _controllers[index]?.dispose();
    _controllers.remove(index);
    _initializedIndices.remove(index);
  }

  void _disposeAllControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _initializedIndices.clear();
  }

  void _onPageChanged(int index) {
    // Pause old video
    _controllers[_currentPage]?.pause();

    _currentPage = index;

    // Init nearby controllers
    _initController(index);
    if (index > 0) _initController(index - 1);
    if (index < _videos.length - 1) _initController(index + 1);

    // Dispose far controllers (keep current ± 1)
    final keysToRemove =
        _controllers.keys.where((k) => (k - index).abs() > 1).toList();
    for (final k in keysToRemove) {
      _disposeController(k);
    }

    // Play current video
    _playCurrentVideo();

    // Increment view count
    VideoApi.incrementView(_videos[index].id);
  }

  void _playCurrentVideo() {
    final c = _controllers[_currentPage];
    if (c != null && c.value.isInitialized) {
      c.setVolume(_isMuted ? 0 : 1);
      c.play();
    }
  }

  void _pauseAllVideos() {
    for (final c in _controllers.values) {
      c.pause();
    }
  }

  Future<void> _navigateToProvider(VideoData video) async {
    _pauseAllVideos();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClickProvider(
          providerID: video.providerId,
          name: video.providerName,
          catID: null,
          catName: null,
        ),
      ),
    );
    // Resume when coming back
    if (mounted && (widget.isVisible?.value ?? true)) {
      _playCurrentVideo();
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controllers[_currentPage]?.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: myColor),
        ),
      );
    }

    if (_hasError || _videos.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'Nessun video disponibile',
                style: TextStyle(color: Colors.grey[400], fontSize: 18),
              ),
              if (_errorMsg.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMsg,
                    style: TextStyle(color: Colors.red[300], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadVideos,
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: myColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Video PageView
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _videos.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return _buildVideoPage(index);
            },
          ),

          // Top safe area gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Sort tabs at top
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSortTab('Per te', 'manual'),
                const SizedBox(width: 20),
                _buildSortTab('Popolari', 'popular'),
                const SizedBox(width: 20),
                _buildSortTab('VIP', 'vip'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortTab(String label, String order) {
    final isActive = _currentOrder == order;
    return GestureDetector(
      onTap: () => _switchOrder(order),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPage(int index) {
    final video = _videos[index];
    final controller = _controllers[index];
    final isInitialized = controller != null && controller.value.isInitialized;

    return GestureDetector(
      onTap: _toggleMute,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video or placeholder
          if (isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          else
            _buildVideoPlaceholder(video),

          // Bottom gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom info overlay
          Positioned(
            bottom: 90,
            left: 16,
            right: 80,
            child: _buildVideoInfo(video),
          ),

          // Right side buttons
          Positioned(
            right: 12,
            bottom: 120,
            child: _buildSideButtons(video),
          ),

          // Mute indicator
          if (isInitialized)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 50,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

          // Loading indicator
          if (!isInitialized &&
              !_failedIndices.contains(index) &&
              video.resolvedVideoUrl.isNotEmpty)
            const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),

          if (!isInitialized && _failedIndices.contains(index))
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _failedIndices.remove(index);
                  _disposeController(index);
                  _initController(index);
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder(VideoData video) {
    if (video.resolvedThumbnailUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: video.resolvedThumbnailUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.black),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: Icon(Icons.play_circle_outline,
                size: 64, color: Colors.white30),
          ),
        ),
      );
    }
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.play_circle_outline, size: 64, color: Colors.white30),
      ),
    );
  }

  Widget _buildVideoInfo(VideoData video) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Provider info
        GestureDetector(
          onTap: () => _navigateToProvider(video),
          child: Row(
            children: [
              if (video.logoUrl.isNotEmpty)
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: CachedNetworkImageProvider(video.logoUrl),
                )
              else
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.store, color: Colors.white, size: 18),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  video.providerName ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Title
        if (video.title != null && video.title!.isNotEmpty)
          Text(
            video.title!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 4),
        // Description
        if (video.description != null && video.description!.isNotEmpty)
          Text(
            video.description!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 6),
        // View count
        Row(
          children: [
            const Icon(Icons.visibility, color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text(
              '${video.viewsCount}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _toggleLike(VideoData video) async {
    setState(() {
      video.isLiked = !video.isLiked;
      video.likesCount += video.isLiked ? 1 : -1;
      if (video.likesCount < 0) video.likesCount = 0;
    });
    final result = await VideoApi.toggleLike(video.id);
    if (result != null && mounted) {
      setState(() {
        video.isLiked = result['is_liked'] ?? video.isLiked;
        video.likesCount = result['likes_count'] ?? video.likesCount;
      });
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  Widget _buildSideButtons(VideoData video) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like button
        _buildSideButton(
          icon: video.isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(video.likesCount),
          color: video.isLiked ? Colors.red : Colors.black38,
          onTap: () => _toggleLike(video),
        ),
        const SizedBox(height: 20),
        // Rating
        _buildSideButton(
          icon: Icons.star,
          label: video.avgRating > 0
              ? video.avgRating.toStringAsFixed(1)
              : '0',
          color: Colors.black38,
          iconColor: Colors.amber,
          onTap: () => _navigateToProvider(video),
        ),
        const SizedBox(height: 20),
        // Reviews count
        _buildSideButton(
          icon: Icons.rate_review_outlined,
          label: _formatCount(video.ratesCount),
          onTap: () => _navigateToProvider(video),
        ),
        const SizedBox(height: 20),
        // Views count
        _buildSideButton(
          icon: Icons.visibility,
          label: _formatCount(video.viewsCount),
        ),
        const SizedBox(height: 20),
        // Order button (prominent)
        _buildSideButton(
          icon: Icons.shopping_bag,
          label: 'Ordina',
          color: myColor,
          onTap: () => _navigateToProvider(video),
        ),
        const SizedBox(height: 20),
        // Share button
        _buildSideButton(
          icon: Icons.share,
          label: 'Condividi',
          onTap: () => _shareVideo(video),
        ),
      ],
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color ?? Colors.black38,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareVideo(VideoData video) async {
    try {
      final message = StringBuffer()
        ..writeln(
            '${video.providerName ?? "Eboro"} - ${video.title ?? "Video"}')
        ..writeln(video.description ?? '')
        ..writeln('')
        ..writeln('Guarda su Eboro!');
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        message.toString(),
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : Rect.fromLTWH(0, 0, 100, 100),
      );
    } catch (e) {
      // Share failed silently
    }
  }
}
