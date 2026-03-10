import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/API/VideoApi.dart';
import 'package:eboro/Providers/ClickProvider.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({Key? key}) : super(key: key);

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> with WidgetsBindingObserver {
  List<PromoVideo> _videos = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _userPaused = false;

  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, bool> _initialized = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadVideos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_userPaused) {
        final c = _controllers[_currentIndex];
        if (c != null && _initialized[_currentIndex] == true) {
          c.play();
        }
      }
    } else if (state == AppLifecycleState.paused) {
      _controllers[_currentIndex]?.pause();
    }
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _initialized.clear();

    final videos = await VideoApi.getPromoVideos();
    if (mounted) {
      setState(() {
        _videos = videos;
        _isLoading = false;
        _currentIndex = 0;
      });
      if (videos.isNotEmpty) {
        _initVideo(0);
        VideoApi.incrementView(videos[0].id);
      }
    }
  }

  void _initVideo(int index) {
    if (index < 0 || index >= _videos.length) return;
    if (_controllers.containsKey(index)) return;

    final vpc = VideoPlayerController.networkUrl(
      Uri.parse(_videos[index].videoUrl),
    );
    _controllers[index] = vpc;
    _initialized[index] = false;

    vpc.initialize().then((_) {
      if (!mounted) return;
      vpc.setLooping(true);
      bool lastPlaying = false;
      bool lastBuffering = false;
      vpc.addListener(() {
        if (!mounted) return;
        final nowPlaying = vpc.value.isPlaying;
        final nowBuffering = vpc.value.isBuffering;
        if (nowPlaying != lastPlaying || nowBuffering != lastBuffering) {
          lastPlaying = nowPlaying;
          lastBuffering = nowBuffering;
          if (mounted) setState(() {});
        }
      });
      setState(() => _initialized[index] = true);
      if (index == _currentIndex) {
        vpc.play();
      }
    }).catchError((e) {
      print('Video $index init error: $e');
    });
  }

  void _onPageChanged(int index) {
    _controllers[_currentIndex]?.pause();
    _userPaused = false;
    setState(() => _currentIndex = index);

    _initVideo(index);
    if (_initialized[index] == true) {
      _controllers[index]?.play();
    }

    // Preload next
    if (index + 1 < _videos.length) _initVideo(index + 1);

    // Free memory for far pages
    for (final key in _controllers.keys.toList()) {
      if ((key - index).abs() > 2) {
        _controllers[key]?.dispose();
        _controllers.remove(key);
        _initialized.remove(key);
      }
    }

    if (index < _videos.length) {
      VideoApi.incrementView(_videos[index].id);
    }
  }

  void _togglePlayPause(int index) {
    final c = _controllers[index];
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
      _userPaused = true;
    } else {
      c.play();
      _userPaused = false;
    }
    setState(() {});
  }

  Future<void> _toggleLike(PromoVideo video) async {
    // Optimistic update
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: myColor,
        title: const Text('Video', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(myColor),
              ),
            )
          : _videos.isEmpty
              ? _buildEmptyState()
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: _videos.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) =>
                      _buildVideoItem(_videos[index], index),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nessun video disponibile',
            style: TextStyle(fontSize: 18, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadVideos,
            icon: const Icon(Icons.refresh),
            label: const Text('Riprova'),
            style: ElevatedButton.styleFrom(
              backgroundColor: myColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoItem(PromoVideo video, int index) {
    final controller = _controllers[index];
    final isReady = _initialized[index] == true && controller != null;

    return GestureDetector(
      onTap: () => _togglePlayPause(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video or thumbnail
          if (isReady)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          else
            _buildLoadingThumbnail(video),

          // Buffering spinner
          if (isReady && controller.value.isBuffering)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(myColor),
              ),
            ),

          // Play icon (only when user paused)
          if (isReady &&
              !controller.value.isPlaying &&
              !controller.value.isBuffering &&
              _userPaused)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.play_arrow, size: 50, color: Colors.white),
              ),
            ),

          // Right sidebar — TikTok style
          Positioned(
            right: 8,
            bottom: 160,
            child: _buildRightSidebar(video),
          ),

          // Progress bar
          if (isReady)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: myColor,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),

          // Bottom info
          Positioned(
            bottom: 0,
            left: 0,
            right: 60,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (video.providerName != null)
                    Row(
                      children: [
                        if (video.providerLogo != null &&
                            video.providerLogo!.isNotEmpty)
                          ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: video.providerLogo!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _buildInitialAvatar(video.providerName!),
                            ),
                          )
                        else
                          _buildInitialAvatar(video.providerName!),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            video.providerName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _controllers[_currentIndex]?.pause();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClickProvider(
                                  providerID: video.providerId,
                                  name: video.providerName,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag, size: 16),
                          label: const Text('Ordina'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: myColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (video.title != null && video.title!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      video.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (video.description != null &&
                      video.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      video.description!,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Page indicator
          Positioned(
            top: 8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_currentIndex + 1}/${_videos.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar(PromoVideo video) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like button
        _buildSidebarButton(
          icon: video.isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(video.likesCount),
          color: video.isLiked ? Colors.red : Colors.white,
          onTap: () => _toggleLike(video),
        ),
        const SizedBox(height: 20),
        // Rating
        _buildSidebarButton(
          icon: Icons.star,
          label: video.avgRating > 0
              ? video.avgRating.toStringAsFixed(1)
              : '0',
          color: Colors.amber,
          onTap: () {
            _controllers[_currentIndex]?.pause();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClickProvider(
                  providerID: video.providerId,
                  name: video.providerName,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        // Rates count
        _buildSidebarButton(
          icon: Icons.rate_review_outlined,
          label: _formatCount(video.ratesCount),
          color: Colors.white,
          onTap: () {
            _controllers[_currentIndex]?.pause();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClickProvider(
                  providerID: video.providerId,
                  name: video.providerName,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        // Views count
        _buildSidebarButton(
          icon: Icons.visibility,
          label: _formatCount(video.viewsCount),
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildSidebarButton({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar(String name) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: myColor,
      child: Text(
        name[0].toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildLoadingThumbnail(PromoVideo video) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: video.thumbnailUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: Colors.grey[900]),
          )
        else
          Container(color: Colors.grey[900]),
        Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(myColor),
          ),
        ),
      ],
    );
  }
}
