import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import 'deck_qr_screen.dart';

/// QR scanner screen for tournament owners to scan participant QR codes.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isDesktop =>
      !Platform.isAndroid && !Platform.isIOS;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final result = TournamentQrUtils.decode(raw);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code — not a tournament deck.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    _scanned = true;
    Navigator.pop(context, result);
  }

  void _enterManually() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Enter QR Code',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Paste the QR code string here...',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: AppTheme.obsidianBg),
            onPressed: () {
              final result = TournamentQrUtils.decode(ctrl.text.trim());
              if (result == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid code.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }
              Navigator.pop(context); // close dialog
              Navigator.pop(context, result); // return result
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scan Participant QR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.keyboard, color: AppTheme.accentGold),
            tooltip: 'Enter code manually',
            onPressed: _enterManually,
          ),
        ],
      ),
      body: _isDesktop
          ? _buildDesktopFallback()
          : Stack(
              children: [
                MobileScanner(
                  controller: _ctrl,
                  onDetect: _onDetect,
                ),
                // Overlay
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppTheme.accentGold, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      const Text(
                        'Point camera at participant\'s QR code',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accentGold,
                          side: const BorderSide(color: AppTheme.accentGold),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(CupertinoIcons.keyboard, size: 16),
                        label: const Text('Enter Code Manually'),
                        onPressed: _enterManually,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDesktopFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.qrcode,
                  color: AppTheme.accentGold, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Camera scanning is available on Android/iOS.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
                'Ask the participant to copy their QR code data and paste it below.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: AppTheme.obsidianBg,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(CupertinoIcons.keyboard, size: 18),
              label: const Text('Enter Code Manually',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _enterManually,
            ),
          ],
        ),
      ),
    );
  }
}
