class Chapter {
  final String id;
  final String name;
  final String description;
  final List<ChapterPDF> pdfs;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Chapter({
    required this.id,
    required this.name,
    required this.description,
    required this.pdfs,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      pdfs:
          (json['pdfs'] as List<dynamic>?)
              ?.map((pdf) => ChapterPDF.fromJson(pdf as Map<String, dynamic>))
              .toList() ??
          [],
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pdfs': pdfs.map((pdf) => pdf.toJson()).toList(),
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  Chapter copyWith({
    String? id,
    String? name,
    String? description,
    List<ChapterPDF>? pdfs,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Chapter(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pdfs: pdfs ?? this.pdfs,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class ChapterPDF {
  final String id;
  final String name;
  final String description;
  final String fileId; // Google Drive file ID or Firebase Storage path
  final String downloadUrl;
  final String storagePath; // Firebase Storage path
  final int fileSize;
  final int pageCount;
  final int order;
  final DateTime uploadedAt;
  final bool isActive;

  ChapterPDF({
    required this.id,
    required this.name,
    required this.description,
    required this.fileId,
    required this.downloadUrl,
    required this.storagePath,
    required this.fileSize,
    required this.pageCount,
    required this.order,
    required this.uploadedAt,
    this.isActive = true,
  });

  factory ChapterPDF.fromJson(Map<String, dynamic> json) {
    return ChapterPDF(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      fileId: json['fileId'] as String,
      downloadUrl: json['downloadUrl'] as String,
      storagePath: json['storagePath'] as String,
      fileSize: json['fileSize'] as int? ?? 0,
      pageCount: json['pageCount'] as int? ?? 0,
      order: json['order'] as int? ?? 0,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'fileId': fileId,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'fileSize': fileSize,
      'pageCount': pageCount,
      'order': order,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  ChapterPDF copyWith({
    String? id,
    String? name,
    String? description,
    String? fileId,
    String? downloadUrl,
    String? storagePath,
    int? fileSize,
    int? pageCount,
    int? order,
    DateTime? uploadedAt,
    bool? isActive,
  }) {
    return ChapterPDF(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      fileId: fileId ?? this.fileId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      storagePath: storagePath ?? this.storagePath,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      order: order ?? this.order,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
