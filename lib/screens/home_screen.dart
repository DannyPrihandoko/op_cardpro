import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/set_model.dart';
import '../services/data_service.dart';
import '../services/image_download_service.dart';
import 'card_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataService _dataService = DataService();
  List<SetModel> _sets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    setState(() {
      _isLoading = true;
    });

    final sets = await _dataService.getSets();

    setState(() {
      _sets = sets;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSets,
          color: const Color(0xFFFFD700),
          backgroundColor: const Color(0xFF1E293B),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                )
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header Area
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'ONE PIECE TCG',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4.0,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Booster Sets',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            // Decorative One Piece Card back icon/logo
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFD700).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.style_rounded,
                                color: Color(0xFFFFD700),
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                        child: Text(
                          'Select a expansion set to view card gallery, details, and explore stats.',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),

                    // Booster Sets List
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final set = _sets[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _SetListItem(set: set),
                            );
                          },
                          childCount: _sets.length,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SetListItem extends StatefulWidget {
  final SetModel set;

  const _SetListItem({Key? key, required this.set}) : super(key: key);

  @override
  State<_SetListItem> createState() => _SetListItemState();
}

class _SetListItemState extends State<_SetListItem> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  final ImageDownloadService _downloadService = ImageDownloadService();
  int _cachedCount = 0;
  int _totalCount = 0;
  bool _checkingCache = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _checkCache();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkCache() async {
    if (!mounted) return;
    setState(() {
      _checkingCache = true;
      _isDownloading = _downloadService.isDownloading(widget.set.setCode);
    });
    
    final status = await _downloadService.checkCacheStatus(widget.set.setCode);
    
    if (mounted) {
      setState(() {
        _cachedCount = status['cached'] ?? 0;
        _totalCount = status['total'] ?? 0;
        _checkingCache = false;
      });
    }
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return;
    
    setState(() {
      _isDownloading = true;
    });
    
    await _downloadService.downloadSetImages(
      widget.set.setCode,
      onProgress: (cached, total) {
        if (mounted) {
          setState(() {
            _cachedCount = cached;
            _totalCount = total;
          });
        }
      },
    );
    
    if (mounted) {
      setState(() {
        _isDownloading = false;
      });
      
      // Show snackbar upon complete download success
      if (_cachedCount == _totalCount && _totalCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.set.name} fully downloaded for offline use! 🚀'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFullyCached = _cachedCount == _totalCount && _totalCount > 0;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _animController.forward(),
        onTapUp: (_) => _animController.reverse(),
        onTapCancel: () => _animController.reverse(),
        onTap: () {
          // If downloading, prevent navigation so users can track downloading
          if (_isDownloading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Downloading card images, please wait... ⚡'),
                duration: Duration(seconds: 1),
              ),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CardListScreen(set: widget.set),
            ),
          );
        },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 3D-angled Faded Booster Box Decoration
                Positioned(
                  top: -10,
                  right: -10,
                  bottom: -10,
                  width: 140,
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1E293B).withOpacity(0.1),
                          const Color(0xFF1E293B).withOpacity(0.9),
                          const Color(0xFF1E293B),
                        ],
                        stops: const [0.0, 0.4, 0.85, 1.0],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Opacity(
                      opacity: 0.65,
                      child: Transform.rotate(
                        angle: 0.15,
                        child: CachedNetworkImage(
                          imageUrl: widget.set.images.boxImage,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => const SizedBox(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Set Details Text Info
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge code & type
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              widget.set.setCode,
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.set.type.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Set Name
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 180,
                        child: Text(
                          widget.set.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Stats row
                      Row(
                        children: [
                          Icon(Icons.style_outlined, size: 13, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.set.totalCards} Cards',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            isFullyCached ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                            size: 13,
                            color: isFullyCached ? const Color(0xFF81C784) : Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _checkingCache ? 'Checking...' : '$_cachedCount/$_totalCount Cached',
                            style: TextStyle(
                              color: isFullyCached ? const Color(0xFF81C784) : Colors.grey[400],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow Chevron / Download Status Icon in bottom-right corner
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: _buildDownloadIndicator(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadIndicator() {
    if (_checkingCache) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white30,
        ),
      );
    }

    final isFullyCached = _cachedCount == _totalCount && _totalCount > 0;

    if (_isDownloading) {
      final double progress = _totalCount > 0 ? _cachedCount / _totalCount : 0.0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                color: const Color(0xFFFFD700),
                backgroundColor: Colors.white10,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (isFullyCached) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFF1B5E20), // Forest Green
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 16,
        ),
      );
    }

    // Touch-trigger download icon
    return GestureDetector(
      onTap: _startDownload,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4), width: 1),
        ),
        child: const Icon(
          Icons.cloud_download_rounded,
          color: Color(0xFFFFD700),
          size: 16,
        ),
      ),
    );
  }
}
