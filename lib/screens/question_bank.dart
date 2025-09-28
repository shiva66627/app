import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;

String normalizeDriveUrl(String url) {
  if (url.contains("drive.google.com")) {
    final regex = RegExp(r"/d/([a-zA-Z0-9_-]+)");
    final match = regex.firstMatch(url);
    if (match != null) {
      return "https://drive.google.com/uc?export=download&id=${match.group(1)}";
    }
  }
  return url;
}

class QuestionBankPage extends StatefulWidget {
  const QuestionBankPage({super.key});
  @override
  State<QuestionBankPage> createState() => _QuestionBankPageState();
}

class _QuestionBankPageState extends State<QuestionBankPage> {
  String? selectedYear, selectedSubjectId, selectedSubjectName, selectedChapterId;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectedChapterId != null) {
          setState(() => selectedChapterId = null);
          return false;
        } else if (selectedSubjectId != null) {
          setState(() {
            selectedSubjectId = null;
            selectedSubjectName = null;
          });
          return false;
        } else if (selectedYear != null) {
          setState(() => selectedYear = null);
          return false;
        }
        return true; // exit to home
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(selectedSubjectName != null
              ? "${selectedSubjectName!} Question Bank"
              : "Question Bank"),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (selectedYear == null) return _buildYearSelection();
    if (selectedSubjectId == null) return _buildSubjectList();
    if (selectedChapterId == null) return _buildChapterList();
    return _buildPdfList();
  }

  // =================== YEAR ===================
  Widget _buildYearSelection() {
    final years = [
      {"title": "1st Year", "short": "1st"},
      {"title": "2nd Year", "short": "2nd"},
      {"title": "3rd Year", "short": "3rd"},
      {"title": "4th Year", "short": "4th"},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              Chip(
                label: const Text("Question Bank"),
                avatar: const Icon(Icons.library_books,
                    color: Colors.white, size: 18),
                backgroundColor: Colors.green,
                labelStyle: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 10),
              Chip(
                label: const Text("Select Year"),
                backgroundColor: Colors.grey.shade200,
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            "Select Year for Question Bank",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: GridView.builder(
              itemCount: years.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final year = years[index];
                return GestureDetector(
                  onTap: () => setState(() => selectedYear = year["title"]),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          radius: 30,
                          child: Text(
                            year["short"]!,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          year["title"]!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =================== SUBJECTS ===================
  Widget _buildSubjectList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("qbSubjects")
          .where("year", isEqualTo: selectedYear)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No subjects found"));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final subject = snapshot.data!.docs[index];
            final imageUrl = subject['imageUrl'] ?? '';
            final subjectName = subject['name'] ?? 'Subject';

            return GestureDetector(
              onTap: () => setState(() {
                selectedSubjectId = subject.id;
                selectedSubjectName = subjectName;
              }),
              child: Card(
                elevation: 4,
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              normalizeDriveUrl(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.green[100],
                              child: const Icon(Icons.book,
                                  size: 60, color: Colors.green),
                            ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        color: Colors.green.withOpacity(0.7),
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          subjectName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =================== CHAPTERS ===================
  Widget _buildChapterList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("qbChapters")
          .where("subjectId", isEqualTo: selectedSubjectId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No chapters"));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final chapter = snapshot.data!.docs[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(chapter['name'] ?? 'Chapter'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => setState(() => selectedChapterId = chapter.id),
              ),
            );
          },
        );
      },
    );
  }

  // =================== PDFs ===================
  Widget _buildPdfList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("qbPdfs")
          .where("chapterId", isEqualTo: selectedChapterId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No Question Bank PDFs"));

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final url = data['downloadUrl'] ?? '';
            final title = data['title'] ?? 'Untitled';

            return Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.green),
                title: Text(title),
                onTap: () {
                  if (url.isNotEmpty) _openPdf(context, url, title);
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // =================== PDF VIEWER ===================
  void _openPdf(BuildContext context, String rawUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PdfViewerPage(url: normalizeDriveUrl(rawUrl), title: title),
      ),
    );
  }
}

// =================== PDF VIEWER ===================
class PdfViewerPage extends StatefulWidget {
  final String url, title;
  const PdfViewerPage({super.key, required this.url, required this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  PdfController? _controller;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async {
    try {
      final res = await http.get(Uri.parse(widget.url));
      if (res.statusCode != 200) throw Exception("Failed to load PDF");

      final bytes = res.bodyBytes;
      final doc = await PdfDocument.openData(bytes);

      setState(() {
        _controller = PdfController(
          document: Future.value(doc),
          initialPage: 1,
        );
        _totalPages = doc.pagesCount;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading PDF: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                PdfView(
                  controller: _controller!,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  builders: PdfViewBuilders<DefaultBuilderOptions>(
                    options: const DefaultBuilderOptions(),
                    documentLoaderBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    pageLoaderBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, error) =>
                        Center(child: Text("Error: $error")),
                  ),
                ),
                // Page counter
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$_currentPage / $_totalPages",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
