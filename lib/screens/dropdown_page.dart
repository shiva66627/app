import 'package:flutter/material.dart';
import 'simple_pdf_viewer.dart';

class DropdownPage extends StatelessWidget {
  final String title;
  final dynamic
  data; // Changed to dynamic to handle both old and new structures

  const DropdownPage({super.key, required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.blue),
      body: data.isEmpty
          ? const Center(child: Text("No items available"))
          : ListView(
              children: (data as Map<String, dynamic>).entries.map((yearEntry) {
                final year = yearEntry.key;
                final subjects = yearEntry.value;

                return _buildExpansionTile(
                  title: year,
                  children: (subjects as Map<String, dynamic>).entries.map((
                    subjectEntry,
                  ) {
                    final subject = subjectEntry.key;
                    final chapters = subjectEntry.value;

                    return _buildExpansionTile(
                      title: subject,
                      children: (chapters as Map<String, dynamic>).entries.map((
                        chapterEntry,
                      ) {
                        final chapter = chapterEntry.key;
                        final pdfs = chapterEntry.value;

                        return _buildExpansionTile(
                          title: chapter,
                          children: pdfs.map<Widget>((pdf) {
                            // Handle both old (String) and new (Map) data structures
                            if (pdf is String) {
                              // String format - search Google Drive automatically
                              return ListTile(
                                leading: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.blue,
                                ),
                                title: Text(pdf),
                                subtitle: const Text('Tap to view PDF'),
                                trailing: const Icon(
                                  Icons.search,
                                  color: Colors.green,
                                ),
                                onTap: () {
                                  // Navigate to simple PDF viewer
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SimplePdfViewer(
                                        pdfName: pdf,
                                        title: pdf,
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else if (pdf is Map<String, dynamic>) {
                              // New format - use PdfViewer for consistency
                              final pdfName =
                                  pdf['name']?.toString() ?? 'Unknown PDF';

                              return ListTile(
                                leading: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.blue,
                                ),
                                title: Text(pdfName),
                                subtitle: const Text('Tap to view PDF'),
                                trailing: const Icon(
                                  Icons.cloud_download,
                                  color: Colors.grey,
                                ),
                                onTap: () {
                                  // Use SimplePdfViewer for all PDFs
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SimplePdfViewer(
                                        pdfName: pdfName,
                                        title: pdfName,
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              // Fallback for unknown format
                              return ListTile(
                                leading: const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                ),
                                title: const Text('Invalid PDF data'),
                              );
                            }
                          }).toList(),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
    );
  }

  // Helper method to create an ExpansionTile with consistent styling
  Widget _buildExpansionTile({
    required String title,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: children,
      initiallyExpanded: false,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    );
  }
}
