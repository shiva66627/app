import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleDriveService {
  static const List<String> scopes = [
    drive.DriveApi.driveReadonlyScope,
  ];

  drive.DriveApi? _driveApi;
  static GoogleSignIn? _googleSignIn;
  
  /// Get or create GoogleSignIn instance
  GoogleSignIn _getGoogleSignIn() {
    _googleSignIn ??= GoogleSignIn(scopes: scopes);
    return _googleSignIn!;
  }
  
  /// Check if user is already signed in to Google
  Future<bool> isSignedIn() async {
    final googleSignIn = _getGoogleSignIn();
    return await googleSignIn.isSignedIn();
  }
  
  /// Initialize Google Drive API with authentication
  Future<bool> initialize() async {
    try {
      // Get authenticated HTTP client using Google Sign-In
      final googleSignIn = _getGoogleSignIn();
      
      // First try to get the already signed in account (silent sign-in)
      GoogleSignInAccount? account = await googleSignIn.signInSilently();
      
      // If no account is signed in silently, try interactive sign-in
      if (account == null) {
        account = await googleSignIn.signIn();
        if (account == null) {
          print('Google Sign-In cancelled');
          return false;
        }
      }
      
      print('Using Google account: ${account.email}');
      final GoogleSignInAuthentication authentication = await account.authentication;
      
      // Create authenticated HTTP client
      final authClient = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken(
            'Bearer',
            authentication.accessToken!,
            DateTime.now().add(const Duration(hours: 1)).toUtc(),
          ),
          authentication.idToken,
          scopes,
        ),
      );

      _driveApi = drive.DriveApi(authClient);
      return true;
    } catch (e) {
      print('Failed to initialize Google Drive: $e');
      return false;
    }
  }

  /// Search for a PDF file by name in Google Drive
  Future<String?> searchPDFByName(String fileName) async {
    try {
      if (_driveApi == null) {
        final initialized = await initialize();
        if (!initialized) {
          return null;
        }
      }

      // Search for PDF files with the given name
      final searchQuery = "mimeType='application/pdf' and trashed=false and (name contains '$fileName' or name='$fileName')";
      
      final fileList = await _driveApi!.files.list(
        q: searchQuery,
        spaces: 'drive',
        $fields: 'files(id,name)',
        orderBy: 'modifiedTime desc',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final file = fileList.files!.first;
        print('Found PDF: ${file.name} with ID: ${file.id}');
        return file.id;
      }
      
      print('No PDF found with name: $fileName');
      return null;
    } catch (e) {
      print('Error searching for PDF: $e');
      return null;
    }
  }

  /// Get direct download URL for a Google Drive file
  String getDirectDownloadUrl(String fileId) {
    return 'https://drive.google.com/uc?export=download&id=$fileId';
  }

  /// Download PDF from Google Drive and save to local storage
  Future<String?> downloadPdf(String fileId, String fileName) async {
    try {
      if (_driveApi == null) {
        final initialized = await initialize();
        if (!initialized) {
          throw Exception('Failed to initialize Google Drive API');
        }
      }

      // Get file metadata first
      final fileResponse = await _driveApi!.files.get(fileId);
      final file = fileResponse as drive.File;
      final actualFileName = fileName.isEmpty ? (file.name ?? 'document.pdf') : fileName;

      // Download the file content
      final drive.Media media = await _driveApi!.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      
      // Convert stream to bytes
      final List<int> bytes = [];
      await for (var chunk in media.stream) {
        bytes.addAll(chunk);
      }

      // Save to local storage
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$actualFileName';
      final localFile = File(filePath);
      
      await localFile.writeAsBytes(bytes);
      
      print('PDF downloaded successfully: $filePath');
      return filePath;
    } catch (e) {
      print('Error downloading PDF: $e');
      return null;
    }
  }

  /// Alternative method using direct HTTP download (no authentication required for public files)
  Future<String?> downloadPublicPdf(String fileId, String fileName) async {
    try {
      final url = getDirectDownloadUrl(fileId);
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        
        await file.writeAsBytes(response.bodyBytes);
        print('PDF downloaded successfully: $filePath');
        return filePath;
      } else {
        print('Failed to download PDF: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      return null;
    }
  }

  /// Get file information from Google Drive
  Future<drive.File?> getFileInfo(String fileId) async {
    try {
      if (_driveApi == null) {
        final initialized = await initialize();
        if (!initialized) return null;
      }
      
      final result = await _driveApi!.files.get(fileId);
      return result as drive.File;
    } catch (e) {
      print('Error getting file info: $e');
      return null;
    }
  }

  /// Check if file exists locally
  Future<bool> isFileDownloaded(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      return File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Get local file path
  Future<String> getLocalFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }
}