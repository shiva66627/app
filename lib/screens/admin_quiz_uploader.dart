import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminQuizUploader extends StatefulWidget {
  const AdminQuizUploader({super.key});

  @override
  State<AdminQuizUploader> createState() => _AdminQuizUploaderState();
}

class _AdminQuizUploaderState extends State<AdminQuizUploader> {
  final _firestore = FirebaseFirestore.instance;

  String? selectedYear;
  String? selectedSubjectId;
  String? selectedChapterId;
  String? selectedQuizId;

  final subjectController = TextEditingController();
  final subjectImageController = TextEditingController();
  final chapterController = TextEditingController();
  final totalQuestionsController = TextEditingController();

  final questionController = TextEditingController();
  final questionImageController = TextEditingController(); // optional image
  final optionAController = TextEditingController();
  final optionBController = TextEditingController();
  final optionCController = TextEditingController();
  final optionDController = TextEditingController();
  String correctOption = "A";

  int addedQuestions = 0;
  int totalQuestions = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Quiz"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Select Year
            DropdownButtonFormField<String>(
              value: selectedYear,
              hint: const Text("Select Year"),
              items: const [
                DropdownMenuItem(value: "1st Year", child: Text("1st Year")),
                DropdownMenuItem(value: "2nd Year", child: Text("2nd Year")),
                DropdownMenuItem(value: "3rd Year", child: Text("3rd Year")),
                DropdownMenuItem(value: "4th Year", child: Text("4th Year")),
              ],
              onChanged: (val) => setState(() => selectedYear = val),
            ),
            const SizedBox(height: 16),

            // ✅ Subject + Image
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: "Subject Name"),
            ),
            TextField(
              controller: subjectImageController,
              decoration: const InputDecoration(labelText: "Subject Image URL"),
            ),
            const SizedBox(height: 16),

            // ✅ Chapter + Total Questions
            TextField(
              controller: chapterController,
              decoration: const InputDecoration(labelText: "Chapter Name"),
            ),
            TextField(
              controller: totalQuestionsController,
              decoration: const InputDecoration(labelText: "Total Questions"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saveSubjectAndChapter,
              child: const Text("Save Subject & Chapter"),
            ),

            const Divider(height: 40),

            // ✅ Add Questions
            if (totalQuestions > 0)
              Column(
                children: [
                  Text(
                    "Added: $addedQuestions / $totalQuestions",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: questionController,
                    decoration: const InputDecoration(labelText: "Question"),
                  ),
                  TextField(
                    controller: questionImageController,
                    decoration: const InputDecoration(
                        labelText: "Question Image URL (optional)"),
                  ),
                  TextField(
                    controller: optionAController,
                    decoration: const InputDecoration(labelText: "Option A"),
                  ),
                  TextField(
                    controller: optionBController,
                    decoration: const InputDecoration(labelText: "Option B"),
                  ),
                  TextField(
                    controller: optionCController,
                    decoration: const InputDecoration(labelText: "Option C"),
                  ),
                  TextField(
                    controller: optionDController,
                    decoration: const InputDecoration(labelText: "Option D"),
                  ),

                  DropdownButtonFormField<String>(
                    value: correctOption,
                    items: const [
                      DropdownMenuItem(value: "A", child: Text("Correct: A")),
                      DropdownMenuItem(value: "B", child: Text("Correct: B")),
                      DropdownMenuItem(value: "C", child: Text("Correct: C")),
                      DropdownMenuItem(value: "D", child: Text("Correct: D")),
                    ],
                    onChanged: (val) => setState(() => correctOption = val!),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: addedQuestions >= totalQuestions
                        ? null
                        : () async {
                            await _saveQuestion();
                            if (addedQuestions == totalQuestions) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("✅ All questions uploaded!")),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: addedQuestions == totalQuestions - 1
                          ? Colors.green
                          : Colors.blue,
                    ),
                    child: Text(
                      addedQuestions == totalQuestions - 1
                          ? "Submit Quiz"
                          : "Save & Next",
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ✅ Save Subject & Chapter
  Future<void> _saveSubjectAndChapter() async {
    if (selectedYear == null ||
        subjectController.text.isEmpty ||
        chapterController.text.isEmpty ||
        totalQuestionsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Fill all fields")),
      );
      return;
    }

    totalQuestions = int.tryParse(totalQuestionsController.text) ?? 0;

    // ✅ Subject
    final subjectRef = await _firestore.collection("quizSubjects").add({
      "year": selectedYear,
      "name": subjectController.text.trim(),
      "imageUrl": subjectImageController.text.trim(),
      "createdAt": FieldValue.serverTimestamp(),
    });
    selectedSubjectId = subjectRef.id;

    // ✅ Chapter
    final chapterRef = await _firestore.collection("quizChapters").add({
      "subjectId": selectedSubjectId,
      "name": chapterController.text.trim(),
      "totalQuestions": totalQuestions,
      "createdAt": FieldValue.serverTimestamp(),
    });
    selectedChapterId = chapterRef.id;

    // ✅ Quiz Doc
    final quizRef = await _firestore.collection("quizPdfs").add({
      "title": "${chapterController.text.trim()} Quiz",
      "chapterId": selectedChapterId,
      "questions": [],
      "totalQuestions": totalQuestions,
      "createdAt": FieldValue.serverTimestamp(),
    });
    selectedQuizId = quizRef.id;

    setState(() {
      addedQuestions = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Subject, Chapter & Quiz created")),
    );
  }

  // ✅ Save Question
  Future<void> _saveQuestion() async {
    if (selectedQuizId == null || questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Save subject & chapter first")),
      );
      return;
    }

    final questionData = {
      "question": questionController.text.trim(),
      "imageUrl": questionImageController.text.trim(),
      "options": {
        "A": optionAController.text.trim(),
        "B": optionBController.text.trim(),
        "C": optionCController.text.trim(),
        "D": optionDController.text.trim(),
      },
      "correctAnswer": correctOption,
    };

    await _firestore.collection("quizPdfs").doc(selectedQuizId).update({
      "questions": FieldValue.arrayUnion([questionData])
    });

    // Clear fields for next question
    questionController.clear();
    questionImageController.clear();
    optionAController.clear();
    optionBController.clear();
    optionCController.clear();
    optionDController.clear();

    setState(() {
      addedQuestions++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "✅ Question Added ($addedQuestions / $totalQuestions)"),
      ),
    );
  }
}
