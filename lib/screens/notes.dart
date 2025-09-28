import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'payment_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Convert Google Drive /view links into direct download
String normalizeDriveUrl(String url) {
  if (url.contains("drive.google.com")) {
    final regex = RegExp(r"/d/([a-zA-Z0-9_-]+)");
    final match = regex.firstMatch(url);
    if (match != null) {
      final fileId = match.group(1);
      return "https://drive.google.com/uc?export=download&id=$fileId";
    }
  }
  return url;
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String? selectedYear;
  String? selectedSubjectId;
  String? selectedSubjectName;
  String? selectedChapterId;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // controlled back behavior: chapter -> subject -> year -> exit
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
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(selectedSubjectName != null
              ? "${selectedSubjectName!} Notes"
              : "Notes"),
          backgroundColor: Colors.blue,
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

  // =================== YEAR SELECTION ===================
  Widget _buildYearSelection() {
    final years = [
      {"title": "1st Year", "short": "1st"},
      {"title": "2nd Year", "short": "2nd"},
      {"title": "3rd Year", "short": "3rd"},
      {"title": "4th Year", "short": "4th"},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Chip(
            label: const Text("Notes"),
            avatar: const Icon(Icons.notes, color: Colors.white, size: 18),
            backgroundColor: Colors.blue,
            labelStyle: const TextStyle(color: Colors.white),
          ),
          const SizedBox(width: 10),
          Chip(label: const Text("Select Year"), backgroundColor: Colors.grey),
        ]),
        const SizedBox(height: 20),
        const Text("Select Year for Notes",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.purple.shade100,
                        radius: 30,
                        child: Text(
                          year["short"]!,
                          style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(year["title"]!,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // =================== SUBJECT LIST ===================
  Widget _buildSubjectList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("notesSubjects")
          .where("year", isEqualTo: selectedYear)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No subjects found"));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 1.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final subjectDoc = docs[index];
            final data = subjectDoc.data() as Map<String, dynamic>;
            final imageUrl = data['imageUrl'] ?? '';
            final subjectName = data['name'] ?? 'Subject';

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedSubjectId = subjectDoc.id;
                  selectedSubjectName = subjectName;
                });
              },
              child: Card(
                elevation: 4,
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: imageUrl.isNotEmpty
                          ? Image.network(normalizeDriveUrl(imageUrl), fit: BoxFit.cover)
                          : Container(
                              color: Colors.blue[100],
                              child: const Icon(Icons.book, size: 60, color: Colors.blue),
                            ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        color: Colors.blueAccent.withOpacity(0.7),
                        padding: const EdgeInsets.all(6),
                        child: Text(subjectName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.white)),
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

  // =================== CHAPTER LIST (chapter-level premium) ===================
  Widget _buildChapterList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("notesChapters")
          .where("subjectId", isEqualTo: selectedSubjectId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No chapters found"));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final chapterDoc = docs[index];
            final data = chapterDoc.data() as Map<String, dynamic>;

            // SAFE field access
            final chapterName = data['name'] ?? 'Chapter';
            final bool isPremium = data.containsKey('isPremium') ? (data['isPremium'] as bool) : false;
            final int premiumAmount = data.containsKey('premiumAmount') ? (data['premiumAmount'] as int) : 100;

            return Card(
              child: ListTile(
                title: Text(chapterName),
                subtitle: Text(
                  isPremium ? "Premium • ₹$premiumAmount" : "Free Access",
                  style: TextStyle(
                    color: isPremium ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: isPremium ? const Icon(Icons.lock, color: Colors.red) : const Icon(Icons.book, color: Colors.green),
                onTap: () {
                  if (!isPremium) {
                    setState(() => selectedChapterId = chapterDoc.id);
                  } else {
                    // Launch your payment flow; PaymentScreen should call onPaymentSuccess when done
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(
                          pdfTitle: "$chapterName Notes",
                          amount: premiumAmount,
                          onPaymentSuccess: () async {
                            // mark chapter as unlocked (set isPremium false)
                            await FirebaseFirestore.instance
                                .collection("notesChapters")
                                .doc(chapterDoc.id)
                                .update({"isPremium": false});
                            setState(() {}); // refresh
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  // =================== PDF LIST ===================
  Widget _buildPdfList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("notesPdfs")
          .where("chapterId", isEqualTo: selectedChapterId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No Notes found"));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final pdfDoc = docs[index];
            final data = pdfDoc.data() as Map<String, dynamic>;
            final url = (data['downloadUrl'] ?? '') as String;
            final title = (data['title'] ?? 'Untitled') as String;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(title),
                subtitle: const Text("Tap to view"),
                onTap: () {
                  if (url.isNotEmpty) {
                    _openPdf(context, url, title);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No download URL provided")));
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  // =================== HELPERS ===================
  void _openPdf(BuildContext context, String rawUrl, String title) {
    final directUrl = normalizeDriveUrl(rawUrl);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfViewerPage(url: directUrl, title: title)),
    );
  }
}

// =================== PDF VIEWER ===================
// Uses pdfx 2.9.2: PdfController expects Future<PdfDocument>
class PdfViewerPage extends StatefulWidget {
  final String url;
  final String title;

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

  Future<void> _initPdf({bool forceReload = false}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeName = widget.title.replaceAll(RegExp(r'[^\w\d_-]'), '_');
      final file = File("${dir.path}/$safeName.pdf");

      // if forceReload requested, remove cached file first
      if (forceReload && await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      // open cached if exists
      if (await file.exists()) {
        final doc = await PdfDocument.openFile(file.path);
        setState(() {
          _controller = PdfController(
            document: Future.value(doc), // required for pdfx 2.9.2
            initialPage: 1,
          );
          _totalPages = doc.pagesCount;
        });
        return;
      }

      // download and cache
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode != 200) throw Exception('Failed to download PDF (${response.statusCode})');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      final doc = await PdfDocument.openFile(file.path);
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
          SnackBar(
            content: Text("Failed to open PDF: $e"),
            action: SnackBarAction(label: "Reload", onPressed: () => _initPdf(forceReload: true)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.blue,
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                PdfView(
                  controller: _controller!,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  builders: PdfViewBuilders<DefaultBuilderOptions>(
                    options: const DefaultBuilderOptions(),
                    documentLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
                    pageLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, error) => Center(child: Text("Error: $error")),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: Text("$_currentPage / $_totalPages", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
