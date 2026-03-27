import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../theme/app_theme.dart';

/// Écran de consultation des règles officielles du Tarot (PDF FFT).
class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  static const _assetPath = 'assets/rules/regles_tarot.pdf';
  bool _assetExists = true;
  final PdfViewerController _pdfController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    _checkAsset();
  }

  Future<void> _checkAsset() async {
    try {
      await rootBundle.load(_assetPath);
    } catch (_) {
      if (mounted) setState(() => _assetExists = false);
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Règles du Tarot'),
        actions: [
          if (_assetExists) ...[
            IconButton(
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Zoom -',
              onPressed: () => _pdfController.zoomLevel =
                  (_pdfController.zoomLevel - 0.25).clamp(1.0, 3.0),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Zoom +',
              onPressed: () => _pdfController.zoomLevel =
                  (_pdfController.zoomLevel + 0.25).clamp(1.0, 3.0),
            ),
          ],
        ],
      ),
      body: _assetExists
          ? SfPdfViewer.asset(
              _assetPath,
              controller: _pdfController,
              canShowScrollHead: true,
              canShowPaginationDialog: true,
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf,
                        size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'PDF des règles non trouvé',
                      style: AppTheme.bodyFont(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Placez le fichier des règles FFT à :\n$_assetPath',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyFont(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
