import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminContentManager extends StatefulWidget {
  final String category; // notes, pyqs, question_banks
  const AdminContentManager({super.key, required this.category});

  @override
  State<AdminContentManager> createState() => _AdminContentManagerState();
}

class _AdminContentManagerState extends State<AdminContentManager> {
  String? selectedYear;
  String? selectedSubject;
  String? selectedChapter;

  List<String> years = ["1st Year", "2nd Year", "3rd Year", "4th Year"];
  List<String> subjects = [];
  List<String> chapters = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage ${widget.category}"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Year Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: selectedYear,
              hint: const Text("Select Year"),
              isExpanded: true,
              items: years
                  .map((y) => DropdownMenuItem<String>(
                        value: y,
                        child: Text(y),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedYear = val;
                  selectedSubject = null;
                  selectedChapter = null;
                  subjects.clear();
                  chapters.clear();
                  _loadSubjects();
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          // Subject Dropdown
          if (selectedYear != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<String>(
                value: selectedSubject,
                hint: const Text("Select Subject"),
                isExpanded: true,
                items: subjects
                    .map((s) => DropdownMenuItem<String>(
                          value: s,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(s),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 18, color: Colors.blue),
                                    onPressed: () => _editSubject(s),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                    onPressed: () => _deleteSubject(s),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedSubject = val;
                    selectedChapter = null;
                    chapters.clear();
                    _loadChapters();
                  });
                },
              ),
            ),

          const SizedBox(height: 12),

          // Chapter Dropdown
          if (selectedSubject != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<String>(
                value: selectedChapter,
                hint: const Text("Select Chapter"),
                isExpanded: true,
                items: chapters
                    .map((c) => DropdownMenuItem<String>(
                          value: c,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(c),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 18, color: Colors.blue),
                                    onPressed: () => _editChapter(c),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                    onPressed: () => _deleteChapter(c),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedChapter = val;
                  });
                },
              ),
            ),

          const Divider(),

          Expanded(
            child: (selectedYear == null ||
                    selectedSubject == null ||
                    selectedChapter == null)
                ? const Center(
                    child: Text("Please select Year → Subject → Chapter"),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(widget.category)
                        .where('year', isEqualTo: selectedYear)
                        .where('subject', isEqualTo: selectedSubject)
                        .where('chapter', isEqualTo: selectedChapter)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No content found"));
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: ListTile(
                              leading: const Icon(Icons.picture_as_pdf,
                                  color: Colors.red),
                              title: Text(
                                data['title'] ?? 'Untitled',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Uploaded by: ${data['uploadedBy'] ?? ''}"),
                                  if (data['uploadedAt'] != null)
                                    Text(
                                      "Uploaded on: ${(data['uploadedAt'] as Timestamp).toDate().toString().split(' ')[0]}",
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _editPdf(doc.id, data),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _deletePdf(doc.id),
                                  ),
                                  Switch(
                                    value: data['isFree'] ?? false,
                                    onChanged: (val) async {
                                      await FirebaseFirestore.instance
                                          .collection(widget.category)
                                          .doc(doc.id)
                                          .update({'isFree': val});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ================== LOADERS ==================
  Future<void> _loadSubjects() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("subjects")
        .where('year', isEqualTo: selectedYear)
        .get();

    final allSubjects =
        snapshot.docs.map((d) => d['name'] as String).toSet().toList();

    setState(() {
      subjects = allSubjects;
    });
  }

  Future<void> _loadChapters() async {
    final subjectDocs = await FirebaseFirestore.instance
        .collection("subjects")
        .where("name", isEqualTo: selectedSubject)
        .where("year", isEqualTo: selectedYear)
        .get();

    if (subjectDocs.docs.isEmpty) return;

    final subjectId = subjectDocs.docs.first.id;

    final snapshot = await FirebaseFirestore.instance
        .collection("chapters")
        .where("subjectId", isEqualTo: subjectId)
        .get();

    final allChapters =
        snapshot.docs.map((d) => d['name'] as String).toSet().toList();

    setState(() {
      chapters = allChapters;
    });
  }

  // ================== DELETE SUBJECT ==================
  Future<void> _deleteSubject(String subject) async {
    try {
      final subjectDocs = await FirebaseFirestore.instance
          .collection("subjects")
          .where("name", isEqualTo: subject)
          .where("year", isEqualTo: selectedYear)
          .get();

      for (var subjectDoc in subjectDocs.docs) {
        final subjectId = subjectDoc.id;

        // Delete chapters + PDFs
        final chapterDocs = await FirebaseFirestore.instance
            .collection("chapters")
            .where("subjectId", isEqualTo: subjectId)
            .get();

        for (var chapter in chapterDocs.docs) {
          final chapterId = chapter.id;

          // Delete PDFs in pdfs collection
          final pdfDocs = await FirebaseFirestore.instance
              .collection("pdfs")
              .where("chapterId", isEqualTo: chapterId)
              .get();

          for (var pdf in pdfDocs.docs) {
            await pdf.reference.delete();
          }

          await chapter.reference.delete();
        }

        // Delete subject itself
        await subjectDoc.reference.delete();
      }

      // Delete from category collection
      final contentDocs = await FirebaseFirestore.instance
          .collection(widget.category)
          .where('year', isEqualTo: selectedYear)
          .where('subject', isEqualTo: subject)
          .get();

      for (var d in contentDocs.docs) {
        await d.reference.delete();
      }

      setState(() {
        selectedSubject = null;
        chapters.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Subject + chapters + PDFs deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error deleting subject: $e")),
      );
    }
  }

  // ================== DELETE CHAPTER ==================
  Future<void> _deleteChapter(String chapterName) async {
    try {
      final chapterDocs = await FirebaseFirestore.instance
          .collection("chapters")
          .where("name", isEqualTo: chapterName)
          .get();

      for (var chapterDoc in chapterDocs.docs) {
        final chapterId = chapterDoc.id;

        // Delete PDFs in pdfs collection
        final pdfDocs = await FirebaseFirestore.instance
            .collection("pdfs")
            .where("chapterId", isEqualTo: chapterId)
            .get();

        for (var pdf in pdfDocs.docs) {
          await pdf.reference.delete();
        }

        await chapterDoc.reference.delete();
      }

      // Delete from category collection
      final contentDocs = await FirebaseFirestore.instance
          .collection(widget.category)
          .where('year', isEqualTo: selectedYear)
          .where('subject', isEqualTo: selectedSubject)
          .where('chapter', isEqualTo: chapterName)
          .get();

      for (var d in contentDocs.docs) {
        await d.reference.delete();
      }

      setState(() {
        selectedChapter = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Chapter + PDFs deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error deleting chapter: $e")),
      );
    }
  }

  // ================== EDITS ==================
  Future<void> _editSubject(String oldName) async {
    final controller = TextEditingController(text: oldName);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Subject"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;

                final subjectDocs = await FirebaseFirestore.instance
                    .collection("subjects")
                    .where("name", isEqualTo: oldName)
                    .where("year", isEqualTo: selectedYear)
                    .get();

                for (var d in subjectDocs.docs) {
                  await d.reference.update({'name': newName});
                }

                Navigator.pop(context);
              },
              child: const Text("Save")),
        ],
      ),
    );
  }

  Future<void> _editChapter(String oldName) async {
    final controller = TextEditingController(text: oldName);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Chapter"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;

                final chapterDocs = await FirebaseFirestore.instance
                    .collection("chapters")
                    .where("name", isEqualTo: oldName)
                    .get();

                for (var d in chapterDocs.docs) {
                  await d.reference.update({'name': newName});
                }

                Navigator.pop(context);
              },
              child: const Text("Save")),
        ],
      ),
    );
  }

  Future<void> _editPdf(String docId, Map<String, dynamic> data) async {
    final titleC = TextEditingController(text: data['title']);
    final linkC = TextEditingController(text: data['downloadUrl']);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit PDF"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleC,
                decoration: const InputDecoration(labelText: "PDF Title")),
            TextField(
                controller: linkC,
                decoration:
                    const InputDecoration(labelText: "Google Drive Link")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection(widget.category)
                    .doc(docId)
                    .update({
                  'title': titleC.text.trim(),
                  'downloadUrl': linkC.text.trim(),
                });
                Navigator.pop(context);
              },
              child: const Text("Save")),
        ],
      ),
    );
  }

  Future<void> _deletePdf(String docId) async {
    await FirebaseFirestore.instance
        .collection(widget.category)
        .doc(docId)
        .delete();
  }
}
