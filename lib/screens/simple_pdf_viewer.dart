import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class SimplePdfViewer extends StatefulWidget {
  final String pdfName;
  final String title;

  const SimplePdfViewer({
    super.key,
    required this.pdfName,
    required this.title,
  });

  @override
  State<SimplePdfViewer> createState() => _SimplePdfViewerState();
}

class _SimplePdfViewerState extends State<SimplePdfViewer> {
  String? _localFilePath;
  bool _isLoading = true;
  String? _error;
  int? _totalPages;
  int _currentPage = 0;
  String _loadingMessage = 'Loading PDF...';
  PDFViewController? _pdfController;

  // Sample PDF URLs - replace these with your actual PDF URLs
  final Map<String, String> _samplePdfs = {
    'Sample PDF 1': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    'Sample PDF 2': 'https://www.adobe.com/support/products/enterprise/knowledgecenter/media/c4611_sample_explain.pdf',
    'Anatomy Notes': 'https://drive.google.com/uc?export=download&id=1NLpqtK5y1X5HoLMXtYBhf-JCYiXAx1MZ',
    'Basic Anatomy': 'https://drive.google.com/uc?export=download&id=1wOBonYFVgLfZq_jalrICOUjRQOKb1LEV',
    'Physiology Notes': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
  };

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _loadingMessage = 'Loading PDF...';
      });

      // Check if we have a URL for this PDF
      String? pdfUrl = _samplePdfs[widget.pdfName];
      
      if (pdfUrl == null) {
        // If no specific URL, show a message
        setState(() {
          _error = 'PDF "${widget.pdfName}" is not available yet.\n\nThis is a demo app. In the full version, this PDF would be loaded from the server.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _loadingMessage = 'Downloading PDF...';
      });

      // Download the PDF
      final filePath = await _downloadPdf(pdfUrl, widget.pdfName);
      
      if (filePath != null) {
        setState(() {
          _localFilePath = filePath;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to download PDF';
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

  Future<String?> _downloadPdf(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${fileName.replaceAll(' ', '_')}.pdf');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      print('Error downloading PDF: $e');
    }
    return null;
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
            const SizedBox(height: 16),
            Text(_loadingMessage),
            const SizedBox(height: 8),
            const Text(
              'Please wait...',
              style: TextStyle(color: Colors.grey),
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
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPdf,
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
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
        _pdfController = pdfViewController;
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          _currentPage = page ?? 0;
        });
      },
    );
  }
}
