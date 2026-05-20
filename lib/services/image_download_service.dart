import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'data_service.dart';

class ImageDownloadService {
  static final ImageDownloadService _instance = ImageDownloadService._internal();
  factory ImageDownloadService() => _instance;
  ImageDownloadService._internal();

  final DataService _dataService = DataService();
  final BaseCacheManager _cache = DefaultCacheManager();
  
  // Set of sets currently actively downloading
  final Set<String> _activeDownloads = {};

  bool isDownloading(String setCode) {
    return _activeDownloads.contains(setCode.toUpperCase());
  }

  // Check cache status: returns the number of images currently cached and total images
  Future<Map<String, int>> checkCacheStatus(String setCode) async {
    final cleanCode = setCode.toUpperCase();
    try {
      final cards = await _dataService.getCards(cleanCode);
      if (cards.isEmpty) {
        return {'cached': 0, 'total': 0};
      }

      int cachedCount = 0;
      for (final card in cards) {
        if (card.cardImageUrl.isEmpty) {
          cachedCount++; // Treat as cached if empty
          continue;
        }
        final fileInfo = await _cache.getFileFromCache(card.cardImageUrl);
        if (fileInfo != null) {
          cachedCount++;
        }
      }

      return {'cached': cachedCount, 'total': cards.length};
    } catch (e) {
      print('Error checking cache status for $cleanCode: $e');
      return {'cached': 0, 'total': 0};
    }
  }

  // Download all set images sequentially in chunks
  Future<void> downloadSetImages(
    String setCode, {
    required Function(int cached, int total) onProgress,
  }) async {
    final cleanCode = setCode.toUpperCase();
    if (_activeDownloads.contains(cleanCode)) return;
    
    _activeDownloads.add(cleanCode);
    
    try {
      final cards = await _dataService.getCards(cleanCode);
      if (cards.isEmpty) {
        _activeDownloads.remove(cleanCode);
        onProgress(0, 0);
        return;
      }

      final total = cards.length;
      
      // Step 1: Identify all URLs that need to be downloaded
      final List<String> urlsToDownload = [];
      int alreadyCached = 0;
      
      for (final card in cards) {
        if (card.cardImageUrl.isEmpty) {
          alreadyCached++;
          continue;
        }
        final fileInfo = await _cache.getFileFromCache(card.cardImageUrl);
        if (fileInfo != null) {
          alreadyCached++;
        } else {
          urlsToDownload.add(card.cardImageUrl);
        }
      }

      // Fire initial progress
      onProgress(alreadyCached, total);

      if (urlsToDownload.isEmpty) {
        _activeDownloads.remove(cleanCode);
        return;
      }

      int currentCached = alreadyCached;
      const int chunkSize = 5; // Download 5 concurrently

      for (int i = 0; i < urlsToDownload.length; i += chunkSize) {
        final end = (i + chunkSize) > urlsToDownload.length
            ? urlsToDownload.length
            : (i + chunkSize);
        final chunk = urlsToDownload.sublist(i, end);

        await Future.wait(chunk.map((url) async {
          try {
            await _cache.downloadFile(url);
          } catch (e) {
            print('Failed to cache image inside download queue: $url, error: $e');
          } finally {
            currentCached++;
            onProgress(currentCached, total);
          }
        }));
      }
    } catch (e) {
      print('Error during downloading set $cleanCode: $e');
    } finally {
      _activeDownloads.remove(cleanCode);
    }
  }
}
