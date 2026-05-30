import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/set_model.dart';
import '../services/image_download_service.dart';
import '../screens/card_list_screen.dart';

class SetMetadata {
  final String title;
  final String category; // "Booster Pack", "Starter Deck", "Extra Booster", "Premium Booster", "Ultimate Deck"
  final String releaseDate;
  final String featuredText;
  final List<Color> bannerGradient;

  const SetMetadata({
    required this.title,
    required this.category,
    required this.releaseDate,
    required this.featuredText,
    required this.bannerGradient,
  });
}

class OnePieceSetCard extends StatefulWidget {
  final SetModel set;

  const OnePieceSetCard({Key? key, required this.set}) : super(key: key);

  @override
  State<OnePieceSetCard> createState() => _OnePieceSetCardState();
}

class _OnePieceSetCardState extends State<OnePieceSetCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  final ImageDownloadService _downloadService = ImageDownloadService();
  int _cachedCount = 0;
  int _totalCount = 0;
  bool _checkingCache = true;
  bool _isDownloading = false;

  // Curated metadata mapping for all major sets
  static const Map<String, SetMetadata> _metadataMap = {
    'OP-01': SetMetadata(
      title: 'ROMANCE DAWN',
      category: 'Booster Pack',
      releaseDate: 'December 2, 2022',
      featuredText: 'Colors: Red, Green, Blue, Purple | Leaders: Luffy, Zoro, Law, Kaido',
      bannerGradient: [Color(0xFF0284C7), Color(0xFF1D4ED8), Color(0xFF0A0F1E)],
    ),
    'OP-02': SetMetadata(
      title: 'Paramount War',
      category: 'Booster Pack',
      releaseDate: 'March 10, 2023',
      featuredText: 'Colors: Red, Green, Blue, Purple, Black | Leaders: Whitebeard, Smoker',
      bannerGradient: [Color(0xFFDC2626), Color(0xFF7F1D1D), Color(0xFF0A0F1E)],
    ),
    'OP-03': SetMetadata(
      title: 'Pillars of Strength',
      category: 'Booster Pack',
      releaseDate: 'June 9, 2023',
      featuredText: 'Colors: Red, Green, Blue, Purple, Yellow | Leaders: Katakuri, Lucci, Ace',
      bannerGradient: [Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFF0A0F1E)],
    ),
    'OP-04': SetMetadata(
      title: 'Kingdoms of Intrigue',
      category: 'Booster Pack',
      releaseDate: 'September 22, 2023',
      featuredText: 'Colors: Red, Green, Blue, Purple, Black, Yellow | Leaders: Rebecca, Crocodile',
      bannerGradient: [Color(0xFFEAB308), Color(0xFFD97706), Color(0xFF0A0F1E)],
    ),
    'OP-05': SetMetadata(
      title: 'Awakening of the New Era',
      category: 'Booster Pack',
      releaseDate: 'December 8, 2023',
      featuredText: 'Colors: Red, Green, Blue, Purple, Black, Yellow | Leaders: Gear 5 Luffy, Enel',
      bannerGradient: [Color(0xFF9333EA), Color(0xFFEC4899), Color(0xFF0A0F1E)],
    ),
    'OP-06': SetMetadata(
      title: 'Wings of Captain',
      category: 'Booster Pack',
      releaseDate: 'March 15, 2024',
      featuredText: 'Colors: Red, Green, Blue, Purple, Black, Yellow | Leaders: Yamato, Reiju',
      bannerGradient: [Color(0xFF059669), Color(0xFF1D4ED8), Color(0xFF0A0F1E)],
    ),
    'OP-07': SetMetadata(
      title: '500 Years in the Future',
      category: 'Booster Pack',
      releaseDate: 'May 24, 2024',
      featuredText: 'Colors: Red, Green, Blue, Purple, Black, Yellow | Leaders: Egghead Luffy, Bonney',
      bannerGradient: [Color(0xFF06B6D4), Color(0xFF4F46E5), Color(0xFF0A0F1E)],
    ),
    'OP-08': SetMetadata(
      title: 'Two Legends',
      category: 'Booster Pack',
      releaseDate: 'September 13, 2024',
      featuredText: 'Colors: Red, Green, Blue, Purple, Black, Yellow | Leaders: Roger, Rayleigh, Marco',
      bannerGradient: [Color(0xFFEA580C), Color(0xFF7C2D12), Color(0xFF0A0F1E)],
    ),
    'OP-09': SetMetadata(
      title: 'Emperors in the New World',
      category: 'Booster Pack',
      releaseDate: 'December 13, 2024',
      featuredText: 'Colors: Red, Green, Blue, Purple, Black, Yellow | Leaders: Shanks, Blackbeard, Luffy',
      bannerGradient: [Color(0xFF4F46E5), Color(0xFFEC4899), Color(0xFF0A0F1E)],
    ),
    'OP-10': SetMetadata(
      title: 'Royal Blood',
      category: 'Booster Pack',
      releaseDate: 'March 14, 2025',
      featuredText: 'Colors: Red, Green, Blue, Purple, Black, Yellow | Leaders: Sabo, Rosinante',
      bannerGradient: [Color(0xFFB91C1C), Color(0xFFEA580C), Color(0xFF0A0F1E)],
    ),
    'OP-11': SetMetadata(
      title: 'A Fist of Divine Speed',
      category: 'Booster Pack',
      releaseDate: 'June 20, 2025',
      featuredText: 'Colors: Red, Green, Blue, Purple, Black, Yellow | Leaders: Kizaru, Kuzan',
      bannerGradient: [Color(0xFFFBBF24), Color(0xFF1D4ED8), Color(0xFF0A0F1E)],
    ),
    'OP-12': SetMetadata(
      title: 'Legacy of the Master',
      category: 'Booster Pack',
      releaseDate: 'August 22, 2025',
      featuredText: 'Colors: Red, Green, Blue, Purple, Black, Yellow | Leaders: Rayleigh, Oden',
      bannerGradient: [Color(0xFF10B981), Color(0xFFEA580C), Color(0xFF0A0F1E)],
    ),
    'OP-13': SetMetadata(
      title: 'Carrying on His Will',
      category: 'Booster Pack',
      releaseDate: 'November 21, 2025',
      featuredText: 'Colors: Red, Green, Blue, Purple, Black, Yellow | Leaders: Ace, Sabo',
      bannerGradient: [Color(0xFFE11D48), Color(0xFF4F46E5), Color(0xFF0A0F1E)],
    ),
    'OP-14': SetMetadata(
      title: 'The Azure Sea\'s Seven',
      category: 'Booster Pack',
      releaseDate: 'January 23, 2026',
      featuredText: 'Colors: Red, Green, Blue, Purple, Black, Yellow | Leaders: Crocodile, Jinbe',
      bannerGradient: [Color(0xFF1E3A8A), Color(0xFF64748B), Color(0xFF0A0F1E)],
    ),
    'OP-15': SetMetadata(
      title: 'Adventure on KAMI\'s Island',
      category: 'Booster Pack',
      releaseDate: 'April 2026',
      featuredText: 'Colors: Red, Green, Blue, Purple, Black, Yellow | Leaders: Enel, Wyper',
      bannerGradient: [Color(0xFFF59E0B), Color(0xFF0EA5E9), Color(0xFF0A0F1E)],
    ),
    'EB-01': SetMetadata(
      title: 'Memorial Collection',
      category: 'Extra Booster',
      releaseDate: 'May 3, 2024',
      featuredText: 'Leaders: Chopper, Hannyabal, Kid | Theme: Memorial Character Support',
      bannerGradient: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF0A0F1E)],
    ),
    'ST-01': SetMetadata(
      title: 'Straw Hat Crew',
      category: 'Starter Deck',
      releaseDate: 'December 2, 2022',
      featuredText: 'Featured Leader: Monkey.D.Luffy | Theme: Red Rush Straw Hats',
      bannerGradient: [Color(0xFFEF4444), Color(0xFF7F1D1D), Color(0xFF0A0F1E)],
    ),
    'ST-02': SetMetadata(
      title: 'Worst Generation',
      category: 'Starter Deck',
      releaseDate: 'December 2, 2022',
      featuredText: 'Featured Leader: Eustass.Kid | Theme: Green Rest/Re-stand Supernovas',
      bannerGradient: [Color(0xFF22C55E), Color(0xFF14532D), Color(0xFF0A0F1E)],
    ),
    'ST-03': SetMetadata(
      title: 'The Seven Warlords of the Sea',
      category: 'Starter Deck',
      releaseDate: 'December 2, 2022',
      featuredText: 'Featured Leader: Crocodile | Theme: Blue Bounce Warlords',
      bannerGradient: [Color(0xFF3B82F6), Color(0xFF1E3A8A), Color(0xFF0A0F1E)],
    ),
    'ST-04': SetMetadata(
      title: 'Animal Kingdom Pirates',
      category: 'Starter Deck',
      releaseDate: 'March 10, 2023',
      featuredText: 'Featured Leader: Kaido | Theme: Purple Kaido DON!! Ramp/KO',
      bannerGradient: [Color(0xFF8B5CF6), Color(0xFF4C1D95), Color(0xFF0A0F1E)],
    ),
    'ST-10': SetMetadata(
      title: 'The Three Captains',
      category: 'Ultimate Deck',
      releaseDate: 'November 10, 2023',
      featuredText: 'Featured Leaders: Luffy, Law, Kid | Theme: Red-Purple Synergy',
      bannerGradient: [Color(0xFFDC2626), Color(0xFF6B21A8), Color(0xFF0A0F1E)],
    ),
    'ST-13': SetMetadata(
      title: 'The Three Brothers\' Bond',
      category: 'Ultimate Deck',
      releaseDate: 'March 2024',
      featuredText: 'Featured Leaders: Luffy, Ace, Sabo | Theme: Red-Yellow-Blue Bonds',
      bannerGradient: [Color(0xFFEAB308), Color(0xFF2563EB), Color(0xFFB91C1C)],
    ),
  };

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

  SetMetadata _getMetadata() {
    final setCode = widget.set.setCode.toUpperCase();
    if (_metadataMap.containsKey(setCode)) {
      return _metadataMap[setCode]!;
    }

    // Smart parsing fallback
    final isStarter = setCode.startsWith('ST-');
    final isExtra = setCode.startsWith('EB-');
    final isPremium = setCode.startsWith('PRB-');
    
    String category = 'Booster Pack';
    if (isStarter) {
      category = (setCode.contains('10') || setCode.contains('13')) ? 'Ultimate Deck' : 'Starter Deck';
    } else if (isExtra) {
      category = 'Extra Booster';
    } else if (isPremium) {
      category = 'Premium Booster';
    }

    List<Color> gradient;
    if (isStarter) {
      gradient = [const Color(0xFFEF4444), const Color(0xFF1E3A8A), const Color(0xFF0A0F1E)];
    } else if (isExtra) {
      gradient = [const Color(0xFF059669), const Color(0xFF0F766E), const Color(0xFF0A0F1E)];
    } else if (isPremium) {
      gradient = [const Color(0xFFFFD700), const Color(0xFFD97706), const Color(0xFF0A0F1E)];
    } else {
      gradient = [const Color(0xFF2563EB), const Color(0xFF7C3AED), const Color(0xFF0A0F1E)];
    }

    return SetMetadata(
      title: widget.set.name,
      category: category,
      releaseDate: widget.set.releaseDate,
      featuredText: 'Featured expansion containing ${widget.set.totalCards} cards.',
      bannerGradient: gradient,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = _getMetadata();
    final isFullyCached = _cachedCount == _totalCount && _totalCount > 0;

    // Badges colors based on product category
    Color badgeColor;
    switch (meta.category) {
      case 'Starter Deck':
        badgeColor = const Color(0xFF1D4ED8); // Royal Blue
        break;
      case 'Ultimate Deck':
        badgeColor = const Color(0xFF6B21A8); // Purple Accent
        break;
      case 'Extra Booster':
        badgeColor = const Color(0xFF059669); // Emerald Green
        break;
      case 'Premium Booster':
        badgeColor = const Color(0xFFD97706); // Gold Orange
        break;
      default:
        badgeColor = const Color(0xFFDC2626); // Booster Pack Red
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => _animController.forward(),
          onTapUp: (_) => _animController.reverse(),
          onTapCancel: () => _animController.reverse(),
          onTap: () {
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
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Matches AppTheme cardBg
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. The Landscape Artwork Banner (Dynamic Gradient + Faded 3D Box image + Stylized Text)
                  Stack(
                    children: [
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: meta.bannerGradient,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Abstract Circle Overlay
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            // Rotated square overlay
                            Positioned(
                              left: -10,
                              bottom: -35,
                              child: Transform.rotate(
                                angle: 0.4,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            // Giant low-opacity set code in background
                            Center(
                              child: Opacity(
                                opacity: 0.08,
                                child: Text(
                                  widget.set.setCode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                            // Faded 3D Booster Box Image on Right
                            if (widget.set.images.boxImage.isNotEmpty)
                              Positioned(
                                right: 12,
                                top: -10,
                                bottom: -10,
                                width: 110,
                                child: Opacity(
                                  opacity: 0.38,
                                  child: Transform.rotate(
                                    angle: 0.12,
                                    child: CachedNetworkImage(
                                      imageUrl: widget.set.images.boxImage,
                                      fit: BoxFit.contain,
                                      errorWidget: (context, url, error) => const SizedBox(),
                                    ),
                                  ),
                                ),
                              ),
                            // Shimmer Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Colors.white.withOpacity(0.08),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                  stops: const [0.3, 0.7],
                                ),
                              ),
                            ),
                            // Premium Gold Set Code Box (Centered)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFFD700).withOpacity(0.5), // Gold Accent Border
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.set.setCode,
                                style: const TextStyle(
                                  color: Color(0xFFFFD700), // Gold Text
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black54,
                                      offset: Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Floating Frosted Download Action Overlay
                      Positioned(
                        top: 10,
                        right: 10,
                        child: ClipOval(
                          child: Container(
                            color: Colors.black.withOpacity(0.45),
                            child: _buildDownloadButton(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 2. Category Banner (Booster, Starter, etc.)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    color: badgeColor,
                    alignment: Alignment.center,
                    child: Text(
                      meta.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  // 3. Set Name / Title Area
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Text(
                      '[OP-${widget.set.setCode}] ${widget.set.name}',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 4. Caching & Card Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.style_outlined, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.set.totalCards} Cards',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 5. Bordered Release Date Box
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        meta.releaseDate,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // 6. Featured Taglines Details
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Text(
                      meta.featuredText,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (_checkingCache) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white70,
          ),
        ),
      );
    }

    final isFullyCached = _cachedCount == _totalCount && _totalCount > 0;

    if (_isDownloading) {
      final double progress = _totalCount > 0 ? _cachedCount / _totalCount : 0.0;
      return Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(6),
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2,
          color: const Color(0xFFFFD700),
          backgroundColor: Colors.white24,
        ),
      );
    }

    if (isFullyCached) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
        ),
      );
    }

    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.cloud_download_rounded, color: Colors.white, size: 18),
        tooltip: 'Download Offline Images',
        onPressed: _startDownload,
      ),
    );
  }
}
