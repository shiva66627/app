import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import '../services/google_drive_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String fileId;
  final String fileName;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.fileId,
    required this.fileName,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final GoogleDriveService _driveService = GoogleDriveService();
  String? _localFilePath;
  bool _isLoading = true;
  String? _error;
  int? _totalPages;
  int _currentPage = 0;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _downloadAndLoadPdf();
  }

  Future<void> _downloadAndLoadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // ✅ Check if already downloaded
      final isDownloaded = await _driveService.isFileDownloaded(widget.fileName);

      if (isDownloaded) {
        _localFilePath = await _driveService.getLocalFilePath(widget.fileName);
      } else {
        // ✅ Try downloading
        String? filePath =
            await _driveService.downloadPdf(widget.fileId, widget.fileName);

        // fallback → public link
        filePath ??=
            await _driveService.downloadPublicPdf(widget.fileId, widget.fileName);

        if (filePath != null) {
          _localFilePath = filePath;
        } else {
          setState(() {
            _error = 'Failed to download PDF from Google Drive';
            _isLoading = false;
          });
          return;
        }
      }

      if (_localFilePath != null && File(_localFilePath!).existsSync()) {
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Downloaded file not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading PDF: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_totalPages != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Downloading PDF from Google Drive...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _downloadAndLoadPdf,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_localFilePath == null) {
      return const Center(
        child: Text('PDF file not available'),
      );
    }

    // ✅ Main PDF Viewer
    return PDFView(
      filePath: _localFilePath!,
      enableSwipe: true,
      swipeHorizontal: false, // vertical scrolling
      autoSpacing: true, // ✅ keeps each page centered with spacing
      pageFling: true,
      pageSnap: true,
      defaultPage: _currentPage,
      fitPolicy: FitPolicy.BOTH, // ✅ scale width & height to center
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {
          _totalPages = pages;
          _isReady = true;
        });
      },
      onError: (error) {
        setState(() {
          _error = 'Error rendering PDF: $error';
        });
      },
      onPageError: (page, error) {
        setState(() {
          _error = 'Error on page $page: $error';
        });
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          _currentPage = page ?? 0;
        });
      },
    );
  }
}
