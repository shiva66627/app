import 'package:flutter/foundation.dart';

/// Categories for content (you can extend if needed).
enum ContentCategory {
  notes,
  pyqs,
  questionBank,
  quiz,
}

/// Academic years
enum AcademicYear {
  first,
  second,
  third,
  finalYear,
}

/// Subject model
class ContentSubject {
  final String id;
  final String name;
  final String code;
  final String description;
  final ContentCategory category;
  final AcademicYear year;
  final int order;
  final bool isActive;

  ContentSubject({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.category,
    required this.year,
    required this.order,
    required this.isActive,
  });

  factory ContentSubject.fromJson(Map<String, dynamic> json) {
    return ContentSubject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      category: ContentCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ContentCategory.notes,
      ),
      year: AcademicYear.values.firstWhere(
        (e) => e.name == json['year'],
        orElse: () => AcademicYear.first,
      ),
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}

/// Chapter model
class ContentChapter {
  final String id;
  final String name;
  final String description;
  final String subjectId;
  final int order;
  final bool isActive;

  ContentChapter({
    required this.id,
    required this.name,
    required this.description,
    required this.subjectId,
    required this.order,
    required this.isActive,
  });

  factory ContentChapter.fromJson(Map<String, dynamic> json) {
    return ContentChapter(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      subjectId: json['subjectId'] ?? '',
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}

/// PDF model
class ContentPDF {
  final String id;
  final String title;
  final String description;
  final String driveFileId;
  final String downloadUrl;
  final String storagePath;
  final int fileSize;
  final int pageCount;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final int order;
  final DateTime? uploadedAt;
  final DateTime? lastAccessedAt;
  final int downloadCount;
  final bool isActive;
  final bool isPublic;
  final String uploadedBy;
  final String chapterId;

  ContentPDF({
    required this.id,
    required this.title,
    required this.description,
    required this.driveFileId,
    required this.downloadUrl,
    required this.storagePath,
    required this.fileSize,
    required this.pageCount,
    required this.metadata,
    required this.tags,
    required this.order,
    this.uploadedAt,
    this.lastAccessedAt,
    required this.downloadCount,
    required this.isActive,
    required this.isPublic,
    required this.uploadedBy,
    required this.chapterId,
  });

  factory ContentPDF.fromJson(Map<String, dynamic> json) {
    return ContentPDF(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      driveFileId: json['driveFileId'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      storagePath: json['storagePath'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      pageCount: json['pageCount'] ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      order: json['order'] ?? 0,
      uploadedAt: (json['uploadedAt'] is DateTime)
          ? json['uploadedAt']
          : null,
      lastAccessedAt: (json['lastAccessedAt'] is DateTime)
          ? json['lastAccessedAt']
          : null,
      downloadCount: json['downloadCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      isPublic: json['isPublic'] ?? true,
      uploadedBy: json['uploadedBy'] ?? '',
      chapterId: json['chapterId'] ?? '',
    );
  }
}

/// Stats object for each category + year
class ContentCategoryStats {
  final int subjects;
  final int chapters;
  final int pdfs;
  final int totalSize;

  ContentCategoryStats({
    required this.subjects,
    required this.chapters,
    required this.pdfs,
    required this.totalSize,
  });
}

/// Global statistics
class HierarchicalContentStatistics {
  final Map<ContentCategory, Map<AcademicYear, ContentCategoryStats>>
      statsByCategory;
  final Map<ContentCategory, int> totalSubjectsByCategory;
  final Map<ContentCategory, int> totalChaptersByCategory;
  final Map<ContentCategory, int> totalPDFsByCategory;
  final Map<AcademicYear, int> totalSubjectsByYear;
  final Map<AcademicYear, int> totalChaptersByYear;
  final Map<AcademicYear, int> totalPDFsByYear;
  final int totalSubjects;
  final int totalChapters;
  final int totalPDFs;
  final int totalSize;

  HierarchicalContentStatistics({
    required this.statsByCategory,
    required this.totalSubjectsByCategory,
    required this.totalChaptersByCategory,
    required this.totalPDFsByCategory,
    required this.totalSubjectsByYear,
    required this.totalChaptersByYear,
    required this.totalPDFsByYear,
    required this.totalSubjects,
    required this.totalChapters,
    required this.totalPDFs,
    required this.totalSize,
  });
}
