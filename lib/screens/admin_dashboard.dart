import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_hierarchical_content_manager.dart' as hierarchical;
import 'manage_admins_page.dart';
import 'admin_quiz_uploader.dart';

class AdminDashboard extends StatefulWidget {
  final void Function(bool)? onThemeChanged;

  const AdminDashboard({super.key, this.onThemeChanged});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String adminName = '';
  String adminEmail = '';
  String? adminPhotoUrl;
  bool isLoading = true;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc['role'] == "admin") {
          setState(() {
            adminName = doc['fullName'] ?? 'Admin';
            adminEmail = doc['email'] ?? user.email ?? '';
            adminPhotoUrl = doc['photoUrl'] ?? '';
            isDarkMode = doc['isDarkMode'] ?? false;
            isLoading = false;
          });

          widget.onThemeChanged?.call(isDarkMode);
        } else {
          await _auth.signOut();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // ✅ Prevent back navigation (Back button won’t log out)
      onWillPop: () async {
        return false; // disables going back
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "MBBS FREAKS",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          centerTitle: true,
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
        ),
        drawer: _buildDrawer(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildDashboardContent(),
      ),
    );
  }

  /// Drawer
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.red[600]),
            accountName: Text(adminName),
            accountEmail: Text(adminEmail),
            currentAccountPicture: GestureDetector(
              onTap: _showProfileLinkDialog,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: adminPhotoUrl != null &&
                        adminPhotoUrl!.isNotEmpty
                    ? NetworkImage(adminPhotoUrl!)
                    : null,
                child: (adminPhotoUrl == null || adminPhotoUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.red)
                    : null,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text("Promote Admin"),
            onTap: () {
              Navigator.pop(context);
              _showPromoteDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text("Manage Admins"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageAdminsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bolt, color: Colors.purple),
            title: const Text("Add Daily Question"),
            onTap: () {
              Navigator.pop(context);
              _showDailyQuestionDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Colors.orange,
            ),
            title: Text(
                isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode"),
            onTap: _toggleTheme,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  /// Dashboard main content
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome, $adminName!",
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(adminEmail,
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 24),
          const Text("Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildActionCard(
                      "Upload Notes", Icons.upload_file, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildActionCard(
                      "Upload PYQs", Icons.upload_file, Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildActionCard("Upload Question Bank",
                      Icons.upload_file, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildActionCard(
                      "Upload Quiz", Icons.quiz, Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Manage Content",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildManageCard(
                    "Manage Notes", Icons.book, Colors.blue, "notes"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildManageCard("Manage PYQs", Icons.description,
                    Colors.green, "pyqs"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildManageCard("Manage Question Bank",
                    Icons.library_books, Colors.orange, "question_banks"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildManageCard(
                    "Manage Quiz", Icons.quiz, Colors.purple, "quiz"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Upload Action Card
  Widget _buildActionCard(String title, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (title == "Upload Notes") {
            _showUploadDialog("notes");
          } else if (title == "Upload PYQs") {
            _showUploadDialog("pyqs");
          } else if (title == "Upload Question Bank") {
            _showUploadDialog("question_banks");
          } else if (title == "Upload Quiz") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminQuizUploader(),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  /// Manage Content Card
  Widget _buildManageCard(
      String title, IconData icon, Color color, String category) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  hierarchical.AdminHierarchicalContentManager(
                category: category,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  // Upload Dialog for Notes / PYQs / QB
  // ======================================================
  void _showUploadDialog(String category) {
    final subjectController = TextEditingController();
    final subjectImageController = TextEditingController();
    final chapterController = TextEditingController();
    final titleController = TextEditingController();
    final linkController = TextEditingController();

    String selectedYear = "1st Year";

    final collectionMap = {
      "notes": {
        "subjects": "notesSubjects",
        "chapters": "notesChapters",
        "pdfs": "notesPdfs"
      },
      "pyqs": {
        "subjects": "pyqsSubjects",
        "chapters": "pyqsChapters",
        "pdfs": "pyqsPdfs"
      },
      "question_banks": {
        "subjects": "qbSubjects",
        "chapters": "qbChapters",
        "pdfs": "qbPdfs"
      },
    };

    final collections = collectionMap[category]!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("Upload ${category.toUpperCase()}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedYear,
                decoration: const InputDecoration(labelText: "Select Year"),
                items: const [
                  DropdownMenuItem(value: "1st Year", child: Text("1st Year")),
                  DropdownMenuItem(value: "2nd Year", child: Text("2nd Year")),
                  DropdownMenuItem(value: "3rd Year", child: Text("3rd Year")),
                  DropdownMenuItem(value: "4th Year", child: Text("4th Year")),
                ],
                onChanged: (val) => selectedYear = val!,
              ),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: "Subject Name"),
              ),
              TextField(
                controller: subjectImageController,
                decoration: const InputDecoration(
                    labelText: "Subject Image Link (Drive/URL)"),
              ),
              TextField(
                controller: chapterController,
                decoration: const InputDecoration(labelText: "Chapter Name"),
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "PDF Title"),
              ),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(
                    labelText: "Paste Google Drive Link"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (subjectController.text.isEmpty ||
                  subjectImageController.text.isEmpty ||
                  chapterController.text.isEmpty ||
                  titleController.text.isEmpty ||
                  linkController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("⚠️ Please fill all fields")),
                );
                return;
              }

              try {
                final subjectName = subjectController.text.trim();
                final subjectQuery = await _firestore
                    .collection(collections["subjects"]!)
                    .where("name", isEqualTo: subjectName)
                    .where("year", isEqualTo: selectedYear)
                    .limit(1)
                    .get();

                String subjectId;
                if (subjectQuery.docs.isEmpty) {
                  // ✅ Added premium defaults here
                  final docRef = await _firestore
                      .collection(collections["subjects"]!)
                      .add({
                    "name": subjectName,
                    "imageUrl": subjectImageController.text.trim(),
                    "year": selectedYear,
                    "createdAt": FieldValue.serverTimestamp(),
                    "isPremium": false,        // ✅ default Free
                    "premiumAmount": 100,      // ✅ default ₹100
                    "unlockedUsers": [],       // ✅ empty list
                  });
                  subjectId = docRef.id;
                } else {
                  subjectId = subjectQuery.docs.first.id;
                }

                final chapterName = chapterController.text.trim();
                final chapterQuery = await _firestore
                    .collection(collections["chapters"]!)
                    .where("name", isEqualTo: chapterName)
                    .where("subjectId", isEqualTo: subjectId)
                    .limit(1)
                    .get();

                String chapterId;
                if (chapterQuery.docs.isEmpty) {
                  final docRef = await _firestore
                      .collection(collections["chapters"]!)
                      .add({
                    "name": chapterName,
                    "subjectId": subjectId,
                    "createdAt": FieldValue.serverTimestamp(),
                  });
                  chapterId = docRef.id;
                } else {
                  chapterId = chapterQuery.docs.first.id;
                }

                await _firestore.collection(collections["pdfs"]!).add({
                  "title": titleController.text.trim(),
                  "downloadUrl": linkController.text.trim(),
                  "chapterId": chapterId,
                  "uploadedBy": adminEmail,
                  "uploadedAt": FieldValue.serverTimestamp(),
                  "isFree": true,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("✅ ${category.toUpperCase()} uploaded!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // Add Daily Question
  // ======================================================
  void _showDailyQuestionDialog() {
    final questionController = TextEditingController();
    final optionControllers = List.generate(4, (_) => TextEditingController());
    String correctOption = "A";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Add Daily Question"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(labelText: "Question"),
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < 4; i++)
                TextField(
                  controller: optionControllers[i],
                  decoration: InputDecoration(labelText: "Option ${i + 1}"),
                ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: correctOption,
                decoration: const InputDecoration(labelText: "Correct Answer"),
                items: const [
                  DropdownMenuItem(value: "A", child: Text("Option A")),
                  DropdownMenuItem(value: "B", child: Text("Option B")),
                  DropdownMenuItem(value: "C", child: Text("Option C")),
                  DropdownMenuItem(value: "D", child: Text("Option D")),
                ],
                onChanged: (val) => correctOption = val ?? "A",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (questionController.text.trim().isEmpty ||
                  optionControllers.any((c) => c.text.trim().isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("⚠️ Fill all fields")),
                );
                return;
              }

              final options =
                  optionControllers.map((c) => c.text.trim()).toList();
              final answerMap = {
                "A": options[0],
                "B": options[1],
                "C": options[2],
                "D": options[3],
              };

              await FirebaseFirestore.instance
                  .collection("daily_question")
                  .add({
                "question": questionController.text.trim(),
                "options": options,
                "correctAnswer": answerMap[correctOption],
                "createdAt": FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Daily Question Added!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // Admin Management
  // ======================================================
  void _showPromoteDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Promote to Admin"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Admin Email"),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Admin Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                UserCredential userCredential =
                    await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                );

                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(userCredential.user!.uid)
                    .set({
                  "email": emailController.text.trim(),
                  "role": "admin",
                  "createdAt": FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("✅ New Admin created successfully!"),
                      backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Promote"),
          ),
        ],
      ),
    );
  }

  void _showProfileLinkDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Set Profile Picture"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Paste Image Link (Drive/URL)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final link = controller.text.trim();
              if (link.isNotEmpty && _auth.currentUser != null) {
                await _firestore
                    .collection("users")
                    .doc(_auth.currentUser!.uid)
                    .update({"photoUrl": link});

                setState(() {
                  adminPhotoUrl = link;
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Profile picture updated!")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });

    widget.onThemeChanged?.call(isDarkMode);

    final user = _auth.currentUser;
    if (user != null) {
      _firestore.collection("users").doc(user.uid).update({
        "isDarkMode": isDarkMode,
      });
    }
  }
}
