import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import '../services/google_drive_service.dart';

class SmartPdfViewer extends StatefulWidget {
  final String pdfName;
  final String title;

  const SmartPdfViewer({
    super.key,
    required this.pdfName,
    required this.title,
  });

  @override
  State<SmartPdfViewer> createState() => _SmartPdfViewerState();
}

class _SmartPdfViewerState extends State<SmartPdfViewer> {
  final GoogleDriveService _driveService = GoogleDriveService();
  String? _localFilePath;
  bool _isLoading = true;
  String? _error;
  int? _totalPages;
  int _currentPage = 0;
  String _loadingMessage = 'Connecting to Google Drive...';

  @override
  void initState() {
    super.initState();
    _searchAndLoadPdf();
  }

  Future<void> _searchAndLoadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _loadingMessage = 'Connecting to Google Drive...';
      });

      // Check if user is already signed in to Google Drive
      final isSignedIn = await _driveService.isSignedIn();
      if (isSignedIn) {
        setState(() {
          _loadingMessage = 'Searching for "${widget.pdfName}" in your Google Drive...';
        });
      } else {
        setState(() {
          _loadingMessage = 'Connecting to your Google Drive account...';
        });
      }

      final fileId = await _driveService.searchPDFByName(widget.pdfName);
      
      if (fileId == null) {
        setState(() {
          _error = 'PDF "${widget.pdfName}" not found in your Google Drive.\n\nPlease make sure you have a PDF with this name uploaded to your Google Drive.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _loadingMessage = 'Found PDF! Downloading...';
      });

      // Check if file is already downloaded locally
      final fileName = '${widget.pdfName}.pdf';
      final isDownloaded = await _driveService.isFileDownloaded(fileName);
      
      if (isDownloaded) {
        _localFilePath = await _driveService.getLocalFilePath(fileName);
      } else {
        // Download the PDF
        String? filePath = await _driveService.downloadPdf(fileId, fileName);
        
        // If authentication fails, try public download
        if (filePath == null) {
          filePath = await _driveService.downloadPublicPdf(fileId, fileName);
        }
        
        if (filePath != null) {
          _localFilePath = filePath;
        } else {
          setState(() {
            _error = 'Failed to download PDF from Google Drive.\n\nPlease ensure the PDF is accessible and try again.';
            _isLoading = false;
          });
          return;
        }
      }

      // Verify file exists and is readable
      if (_localFilePath != null && File(_localFilePath!).existsSync()) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
        });
      } else {
        setState(() {
          _error = 'Downloaded PDF file is not accessible.';
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _loadingMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'This may take a few moments...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _searchAndLoadPdf,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Help'),
                      content: Text(
                        'To fix this issue:\n\n'
                        '1. Make sure you have a PDF named "${widget.pdfName}" in your Google Drive\n'
                        '2. Ensure the PDF is not in trash\n'
                        '3. Check your internet connection\n'
                        '4. Make sure you\'re signed in to the correct Google account'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Need Help?'),
              ),
            ],
          ),
        ),
      );
    }

    if (_localFilePath == null) {
      return const Center(
        child: Text('PDF file not available'),
      );
    }

    return PDFView(
      filePath: _localFilePath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: false,
      pageSnap: true,
      defaultPage: _currentPage,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {
          _totalPages = pages;
        });
      },
      onError: (error) {
        setState(() {
          _error = 'Error displaying PDF: $error';
        });
      },
      onPageError: (page, error) {
        setState(() {
          _error = 'Error on page $page: $error';
        });
      },
      onViewCreated: (PDFViewController pdfViewController) {
        // PDF view created
      },
      onLinkHandler: (String? uri) {
        // Handle link clicks if needed
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          _currentPage = page ?? 0;
        });
      },
    );
  }
}
