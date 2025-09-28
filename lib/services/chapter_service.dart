import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chapter_model.dart';

class ChapterService {
  static final ChapterService _instance = ChapterService._internal();
  factory ChapterService() => _instance;
  ChapterService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _chaptersCollection => 
      _firestore.collection('chapters');


  // Chapter Management
  Future<List<Chapter>> getAllChapters() async {
    try {
      final querySnapshot = await _chaptersCollection
          .where('isActive', isEqualTo: true)
          .get();

      final chapters = querySnapshot.docs
          .map((doc) => Chapter.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
      
      // Sort by order locally to avoid index requirement
      chapters.sort((a, b) => a.order.compareTo(b.order));
      return chapters;
    } catch (e) {
      print('Error getting chapters: $e');
      return [];
    }
  }

  Stream<List<Chapter>> getChaptersStream() {
    return _chaptersCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final chapters = snapshot.docs
              .map((doc) => Chapter.fromJson({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }))
              .toList();
          
          // Sort by order locally to avoid index requirement
          chapters.sort((a, b) => a.order.compareTo(b.order));
          return chapters;
        });
  }

  Future<Chapter?> getChapterById(String chapterId) async {
    try {
      final doc = await _chaptersCollection.doc(chapterId).get();
      if (doc.exists) {
        return Chapter.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      print('Error getting chapter: $e');
      return null;
    }
  }

  Future<String> createChapter(Chapter chapter) async {
    try {
      final docRef = await _chaptersCollection.add(chapter.toJson());
      print('Chapter created: ${chapter.name} with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating chapter: $e');
      throw e;
    }
  }

  Future<void> updateChapter(Chapter chapter) async {
    try {
      await _chaptersCollection.doc(chapter.id).update(
        chapter.copyWith(updatedAt: DateTime.now()).toJson()
      );
      print('Chapter updated: ${chapter.name}');
    } catch (e) {
      print('Error updating chapter: $e');
      throw e;
    }
  }

  Future<void> deleteChapter(String chapterId) async {
    try {
      await _chaptersCollection.doc(chapterId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('Chapter deleted: $chapterId');
    } catch (e) {
      print('Error deleting chapter: $e');
      throw e;
    }
  }

  Future<void> reorderChapters(List<Chapter> chapters) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < chapters.length; i++) {
        final chapter = chapters[i];
        final updatedChapter = chapter.copyWith(
          order: i,
          updatedAt: DateTime.now(),
        );
        
        batch.update(
          _chaptersCollection.doc(chapter.id),
          updatedChapter.toJson(),
        );
      }
      
      await batch.commit();
      print('Chapters reordered successfully');
    } catch (e) {
      print('Error reordering chapters: $e');
      throw e;
    }
  }

  // PDF Management within Chapters
  Future<void> addPdfToChapter(String chapterId, ChapterPDF pdf) async {
    try {
      final chapter = await getChapterById(chapterId);
      if (chapter == null) throw Exception('Chapter not found');

      final updatedPdfs = [...chapter.pdfs, pdf];
      final updatedChapter = chapter.copyWith(
        pdfs: updatedPdfs,
        updatedAt: DateTime.now(),
      );

      await updateChapter(updatedChapter);
      print('PDF added to chapter: ${pdf.name}');
    } catch (e) {
      print('Error adding PDF to chapter: $e');
      throw e;
    }
  }

  Future<void> updatePdfInChapter(String chapterId, ChapterPDF updatedPdf) async {
    try {
      final chapter = await getChapterById(chapterId);
      if (chapter == null) throw Exception('Chapter not found');

      final updatedPdfs = chapter.pdfs.map((pdf) => 
          pdf.id == updatedPdf.id ? updatedPdf : pdf).toList();
      
      final updatedChapter = chapter.copyWith(
        pdfs: updatedPdfs,
        updatedAt: DateTime.now(),
      );

      await updateChapter(updatedChapter);
      print('PDF updated in chapter: ${updatedPdf.name}');
    } catch (e) {
      print('Error updating PDF in chapter: $e');
      throw e;
    }
  }

  Future<void> removePdfFromChapter(String chapterId, String pdfId) async {
    try {
      final chapter = await getChapterById(chapterId);
      if (chapter == null) throw Exception('Chapter not found');

      final updatedPdfs = chapter.pdfs.where((pdf) => pdf.id != pdfId).toList();
      final updatedChapter = chapter.copyWith(
        pdfs: updatedPdfs,
        updatedAt: DateTime.now(),
      );

      await updateChapter(updatedChapter);
      print('PDF removed from chapter: $pdfId');
    } catch (e) {
      print('Error removing PDF from chapter: $e');
      throw e;
    }
  }

  Future<void> reorderPdfsInChapter(String chapterId, List<ChapterPDF> pdfs) async {
    try {
      final chapter = await getChapterById(chapterId);
      if (chapter == null) throw Exception('Chapter not found');

      final reorderedPdfs = pdfs.asMap().entries.map((entry) {
        return entry.value.copyWith(order: entry.key);
      }).toList();

      final updatedChapter = chapter.copyWith(
        pdfs: reorderedPdfs,
        updatedAt: DateTime.now(),
      );

      await updateChapter(updatedChapter);
      print('PDFs reordered in chapter: $chapterId');
    } catch (e) {
      print('Error reordering PDFs in chapter: $e');
      throw e;
    }
  }

  // Search and Filter
  Future<List<Chapter>> searchChapters(String query) async {
    try {
      final allChapters = await getAllChapters();
      
      return allChapters.where((chapter) {
        return chapter.name.toLowerCase().contains(query.toLowerCase()) ||
               chapter.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('Error searching chapters: $e');
      return [];
    }
  }

  Future<List<ChapterPDF>> searchPdfsInAllChapters(String query) async {
    try {
      final allChapters = await getAllChapters();
      final List<ChapterPDF> allPdfs = [];

      for (final chapter in allChapters) {
        final matchingPdfs = chapter.pdfs.where((pdf) {
          return pdf.name.toLowerCase().contains(query.toLowerCase()) ||
                 pdf.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
        allPdfs.addAll(matchingPdfs);
      }

      return allPdfs;
    } catch (e) {
      print('Error searching PDFs: $e');
      return [];
    }
  }

  // Statistics
  Future<Map<String, int>> getContentStatistics() async {
    try {
      final chapters = await getAllChapters();
      int totalPdfs = 0;
      int totalFileSize = 0;

      for (final chapter in chapters) {
        totalPdfs += chapter.pdfs.length;
        totalFileSize += chapter.pdfs.fold(0, (sum, pdf) => sum + pdf.fileSize);
      }

      return {
        'totalChapters': chapters.length,
        'totalPdfs': totalPdfs,
        'totalFileSize': totalFileSize,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'totalChapters': 0,
        'totalPdfs': 0,
        'totalFileSize': 0,
      };
    }
  }
}
