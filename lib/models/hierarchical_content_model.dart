enum ContentCategory {
  notes('Notes', 'Study materials and lecture notes', 'notes'),
  pyqs('PYQs', 'Previous Year Questions', 'pyqs'),
  questionBanks(
    'Question Banks',
    'Practice question collections',
    'question_banks',
  );

  const ContentCategory(
    this.displayName,
    this.description,
    this.firestoreCollection,
  );

  final String displayName;
  final String description;
  final String firestoreCollection;
}

enum AcademicYear {
  first('1st Year', '1st', 1),
  second('2nd Year', '2nd', 2),
  third('3rd Year', '3rd', 3),
  fourth('4th Year', '4th', 4);

  const AcademicYear(this.displayName, this.shortName, this.yearNumber);

  final String displayName;
  final String shortName;
  final int yearNumber;
}

class ContentSubject {
  final String id;
  final String name;
  final String code;
  final String description;
  final String imageUrl; // ✅ Google Drive Image Link
  final ContentCategory category; // Notes, PYQs, or Question Banks
  final AcademicYear year; // 1st, 2nd, 3rd, 4th
  final List<ContentChapter> chapters;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ContentSubject({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.year,
    this.chapters = const [],
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory ContentSubject.fromJson(Map<String, dynamic> json) {
    return ContentSubject(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '', // ✅ added
      category: ContentCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ContentCategory.notes,
      ),
      year: AcademicYear.values.firstWhere(
        (e) => e.name == json['year'],
        orElse: () => AcademicYear.first,
      ),
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((chapter) =>
                  ContentChapter.fromJson(chapter as Map<String, dynamic>))
              .toList() ??
          [],
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'imageUrl': imageUrl, // ✅ save subject image
      'category': category.name,
      'year': year.name,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  ContentSubject copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? imageUrl,
    ContentCategory? category,
    AcademicYear? year,
    List<ContentChapter>? chapters,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ContentSubject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      year: year ?? this.year,
      chapters: chapters ?? this.chapters,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  int get totalChapters => chapters.where((c) => c.isActive).length;
  int get totalPDFs =>
      chapters.fold(0, (sum, chapter) => sum + chapter.totalPDFs);
  int get totalFileSize =>
      chapters.fold(0, (sum, chapter) => sum + chapter.totalFileSize);
}

class ContentChapter {
  final String id;
  final String name;
  final String description;
  final String subjectId; // Parent subject ID
  final List<ContentPDF> pdfs;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ContentChapter({
    required this.id,
    required this.name,
    required this.description,
    required this.subjectId,
    this.pdfs = const [],
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory ContentChapter.fromJson(Map<String, dynamic> json) {
    return ContentChapter(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      subjectId: json['subjectId'] as String,
      pdfs: (json['pdfs'] as List<dynamic>?)
              ?.map((pdf) => ContentPDF.fromJson(pdf as Map<String, dynamic>))
              .toList() ??
          [],
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subjectId': subjectId,
      'pdfs': pdfs.map((pdf) => pdf.toJson()).toList(),
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  int get totalPDFs => pdfs.where((pdf) => pdf.isActive).length;
  int get totalFileSize => pdfs.fold(0, (sum, pdf) => sum + pdf.fileSize);
}

class ContentPDF {
  final String id;
  final String title;
  final String description;
  final String driveFileId; // Google Drive file ID
  final String downloadUrl; // Google Drive link
  final String storagePath;
  final int fileSize;
  final int pageCount;
  final Map<String, String> metadata;
  final List<String> tags;
  final int order;
  final DateTime uploadedAt;
  final DateTime? lastAccessedAt;
  final int downloadCount;
  final bool isActive;
  final bool isPublic;
  final String uploadedBy;
  final String? chapterId;

  ContentPDF({
    required this.id,
    required this.title,
    required this.description,
    required this.driveFileId,
    required this.downloadUrl,
    required this.storagePath,
    required this.fileSize,
    required this.pageCount,
    this.metadata = const {},
    this.tags = const [],
    required this.order,
    required this.uploadedAt,
    this.lastAccessedAt,
    this.downloadCount = 0,
    this.isActive = true,
    this.isPublic = true,
    required this.uploadedBy,
    this.chapterId,
  });

  factory ContentPDF.fromJson(Map<String, dynamic> json) {
    return ContentPDF(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      driveFileId: json['driveFileId'] ?? json['fileId'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      storagePath: json['storagePath'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      pageCount: json['pageCount'] ?? 0,
      metadata: Map<String, String>.from(json['metadata'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      order: json['order'] ?? 0,
      uploadedAt:
          DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.tryParse(json['lastAccessedAt'])
          : null,
      downloadCount: json['downloadCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      isPublic: json['isPublic'] ?? true,
      uploadedBy: json['uploadedBy'] ?? 'admin',
      chapterId: json['chapterId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'driveFileId': driveFileId,
      'fileId': driveFileId,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'fileSize': fileSize,
      'pageCount': pageCount,
      'metadata': metadata,
      'tags': tags,
      'order': order,
      'uploadedAt': uploadedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'downloadCount': downloadCount,
      'isActive': isActive,
      'isPublic': isPublic,
      'uploadedBy': uploadedBy,
      'chapterId': chapterId,
    };
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Google Drive specific URL
  String get googleDriveViewUrl =>
      'https://drive.google.com/file/d/$driveFileId/view';
  String get googleDriveDownloadUrl =>
      'https://drive.google.com/uc?export=download&id=$driveFileId';
}
