import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hierarchical_content_model.dart';
import 'pdf_viewer_screen.dart';

class UserContentBrowser extends StatefulWidget {
  const UserContentBrowser({super.key});

  @override
  State<UserContentBrowser> createState() => _UserContentBrowserState();
}

class _UserContentBrowserState extends State<UserContentBrowser> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ContentCategory? selectedCategory;
  AcademicYear? selectedYear;
  ContentSubject? selectedSubject;
  ContentChapter? selectedChapter;

  List<ContentSubject> subjects = [];
  List<ContentChapter> chapters = [];
  List<ContentPDF> pdfs = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default to Notes category
    selectedCategory = ContentCategory.notes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Materials'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb Navigation
          _buildBreadcrumb(),

          // Main Content Area
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          Icon(Icons.navigation, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildBreadcrumbItem(
                    'Notes',
                    selectedCategory?.displayName ?? 'Select Category',
                    () => _selectCategory(null),
                    isActive: selectedCategory != null,
                  ),
                  if (selectedCategory != null) ...[
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    _buildBreadcrumbItem(
                      'Year',
                      selectedYear?.displayName ?? 'Select Year',
                      () => _selectYear(null),
                      isActive: selectedYear != null,
                    ),
                  ],
                  if (selectedYear != null) ...[
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    _buildBreadcrumbItem(
                      'Subject',
                      selectedSubject?.name ?? 'Select Subject',
                      () => _selectSubject(null),
                      isActive: selectedSubject != null,
                    ),
                  ],
                  if (selectedSubject != null) ...[
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    _buildBreadcrumbItem(
                      'Chapter',
                      selectedChapter?.name ?? 'Select Chapter',
                      () => _selectChapter(null),
                      isActive: selectedChapter != null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(
    String label,
    String value,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.purple[600] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (selectedCategory == null) {
      return _buildCategorySelection();
    } else if (selectedYear == null) {
      return _buildYearSelection();
    } else if (selectedSubject == null) {
      return _buildSubjectList();
    } else if (selectedChapter == null) {
      return _buildChapterList();
    } else {
      return _buildPDFList();
    }
  }

  Widget _buildCategorySelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Content Category',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: ContentCategory.values.length,
              itemBuilder: (context, index) {
                final category = ContentCategory.values[index];
                return _buildCategoryCard(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(ContentCategory category) {
    IconData icon;
    Color color;

    switch (category) {
      case ContentCategory.notes:
        icon = Icons.book;
        color = Colors.blue;
        break;
      case ContentCategory.pyqs:
        icon = Icons.description;
        color = Colors.green;
        break;
      case ContentCategory.questionBanks:
        icon = Icons.library_books;
        color = Colors.orange;
        break;
    }

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _selectCategory(category),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                category.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                category.description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearSelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Year for ${selectedCategory?.displayName}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: AcademicYear.values.length,
              itemBuilder: (context, index) {
                final year = AcademicYear.values[index];
                return _buildYearCard(year);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearCard(AcademicYear year) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _selectYear(year),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  shape: BoxShape.circle,
                ),
                child: Text(
                  year.shortName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                year.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subjects (${selectedYear?.displayName})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : subjects.isEmpty
                ? _buildEmptyState(
                    'No subjects found',
                    'No subjects available for this year',
                  )
                : ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return _buildSubjectCard(subject);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(ContentSubject subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple[100],
          child: Text(
            subject.code.isNotEmpty ? subject.code[0].toUpperCase() : 'S',
            style: TextStyle(
              color: Colors.purple[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          subject.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.folder, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${subject.totalChapters} chapters'),
                const SizedBox(width: 16),
                Icon(Icons.picture_as_pdf, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${subject.totalPDFs} PDFs'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _selectSubject(subject),
      ),
    );
  }

  Widget _buildChapterList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chapters (${selectedSubject?.name})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : chapters.isEmpty
                ? _buildEmptyState(
                    'No chapters found',
                    'No chapters available for this subject',
                  )
                : ListView.builder(
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      return _buildChapterCard(chapter);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(ContentChapter chapter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            chapter.name[0].toUpperCase(),
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          chapter.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chapter.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.picture_as_pdf, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${chapter.totalPDFs} PDFs'),
                const SizedBox(width: 16),
                Icon(Icons.storage, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  chapter.totalFileSize > 0
                      ? '${(chapter.totalFileSize / 1024 / 1024).toStringAsFixed(1)} MB'
                      : '0 MB',
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _selectChapter(chapter),
      ),
    );
  }

  Widget _buildPDFList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PDFs (${selectedChapter?.name})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : pdfs.isEmpty
                ? _buildEmptyState(
                    'No PDFs found',
                    'No PDFs available for this chapter',
                  )
                : ListView.builder(
                    itemCount: pdfs.length,
                    itemBuilder: (context, index) {
                      final pdf = pdfs[index];
                      return _buildPDFCard(pdf);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPDFCard(ContentPDF pdf) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.picture_as_pdf, size: 40, color: Colors.red[600]),
        title: Text(
          pdf.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pdf.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.storage, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(pdf.formattedFileSize),
                const SizedBox(width: 16),
                Icon(Icons.pages, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${pdf.pageCount} pages'),
                const SizedBox(width: 16),
                Icon(Icons.download, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${pdf.downloadCount} downloads'),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: () => _viewPDF(pdf),
        ),
        onTap: () => _viewPDF(pdf),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Navigation Methods
  void _selectCategory(ContentCategory? category) {
    setState(() {
      selectedCategory = category;
      selectedYear = null;
      selectedSubject = null;
      selectedChapter = null;
      subjects.clear();
      chapters.clear();
      pdfs.clear();
    });
  }

  void _selectYear(AcademicYear? year) {
    setState(() {
      selectedYear = year;
      selectedSubject = null;
      selectedChapter = null;
      subjects.clear();
      chapters.clear();
      pdfs.clear();
    });
    if (year != null) {
      _loadSubjects();
    }
  }

  void _selectSubject(ContentSubject? subject) {
    setState(() {
      selectedSubject = subject;
      selectedChapter = null;
      chapters.clear();
      pdfs.clear();
    });
    if (subject != null) {
      _loadChapters();
    }
  }

  void _selectChapter(ContentChapter? chapter) {
    setState(() {
      selectedChapter = chapter;
      pdfs.clear();
    });
    if (chapter != null) {
      _loadPDFs();
    }
  }

  // Data Loading Methods
  Future<void> _loadSubjects() async {
    if (selectedCategory == null || selectedYear == null) return;

    setState(() => isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('subjects')
          .where('category', isEqualTo: selectedCategory!.name)
          .where('year', isEqualTo: selectedYear!.name)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      setState(() {
        subjects = querySnapshot.docs
            .map(
              (doc) => ContentSubject.fromJson({...doc.data(), 'id': doc.id}),
            )
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading subjects: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadChapters() async {
    if (selectedSubject == null) return;

    setState(() => isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('chapters')
          .where('subjectId', isEqualTo: selectedSubject!.id)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      setState(() {
        chapters = querySnapshot.docs
            .map(
              (doc) => ContentChapter.fromJson({...doc.data(), 'id': doc.id}),
            )
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading chapters: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadPDFs() async {
    if (selectedChapter == null) return;

    setState(() => isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('pdfs')
          .where('chapterId', isEqualTo: selectedChapter!.id)
          .where('isActive', isEqualTo: true)
          .where('isPublic', isEqualTo: true)
          .orderBy('order')
          .get();

      setState(() {
        pdfs = querySnapshot.docs
            .map((doc) => ContentPDF.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading PDFs: $e');
      setState(() => isLoading = false);
    }
  }

  // Action Methods
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController searchController = TextEditingController();

        return AlertDialog(
          title: const Text('Search Content'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by title, description, or tags',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (value) {
                  Navigator.pop(context);
                  _searchContent(value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _searchContent(searchController.text);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _searchContent(String query) {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for: $query'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _viewPDF(ContentPDF pdf) {
    // Navigate to PDF viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          title: pdf.title,
          fileId: pdf.driveFileId,
          fileName: pdf.title,
        ),
      ),
    );
  }
}
