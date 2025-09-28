class PdfFile {
  final String name;        // Display name for the PDF
  final String fileId;      // Google Drive file ID
  final String fileName;    // Actual filename for local storage

  const PdfFile({
    required this.name,
    required this.fileId,
    required this.fileName,
  });

  // Convert from JSON
  factory PdfFile.fromJson(Map<String, dynamic> json) {
    return PdfFile(
      name: json['name'] as String,
      fileId: json['fileId'] as String,
      fileName: json['fileName'] as String,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fileId': fileId,
      'fileName': fileName,
    };
  }

  // For backwards compatibility with string-only data
  factory PdfFile.fromString(String pdfName) {
    return PdfFile(
      name: pdfName,
      fileId: '', // Empty file ID means it's not a Google Drive file
      fileName: pdfName,
    );
  }
}
