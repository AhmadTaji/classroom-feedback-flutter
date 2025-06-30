

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';







class FeedbackForm extends StatefulWidget {
  const FeedbackForm({Key? key}) : super(key: key);
  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final nameController = TextEditingController();
  final commentController = TextEditingController();
  final teacherController = TextEditingController();

  // Multiple faculties, with CS having specific departments
  final Map<String, List<String>> facultyDepartments = {
    'CS': ['Software Engineering', 'Network', 'Database'],
    'Science': ['Math', 'Physics'],
    'Arts': ['History', 'Literature'],
    'Commerce': ['Business', 'Economics'],
  };

  // Department -> Subjects mapping
  final Map<String, List<String>> departmentSubjects = {
    'Software Engineering': ['Software Design', 'Testing'],
    'Network': ['Networking Basics', 'Security'],
    'Database': ['SQL', 'NoSQL'],
    'Math': ['Algebra', 'Calculus'],
    'Physics': ['Quantum', 'Mechanics'],
    'History': ['World History', 'Ancient History'],
    'Literature': ['Poetry', 'Drama'],
    'Business': ['Accounting', 'Management'],
    'Economics': ['Microeconomics', 'Macroeconomics'],
  };

  List<String> get faculties => facultyDepartments.keys.toList();
  List<String> get departments => facultyDepartments[selectedFaculty] ?? [];
  List<String> get subjects => departmentSubjects[selectedDepartment] ?? [];

  String selectedFaculty = 'CS';
  String selectedDepartment = 'Software Engineering';
  String selectedSubject = 'Software Design';
  double rating = 5.0;

  Future<void> sendFeedback() async {
    final url = Uri.parse('http://10.10.10.14:3000/api/submit-feedback');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text.trim(),
          'comments': commentController.text.trim(),
          'rating': rating.toInt(),
          'teacher': teacherController.text.trim(),
          'faculty': selectedFaculty,
          'department': selectedDepartment,
          'subject': selectedSubject,
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        nameController.clear();
        commentController.clear();
        teacherController.clear();
        setState(() {
          rating = 5;
          selectedFaculty = faculties.first;
          selectedDepartment = facultyDepartments[selectedFaculty]!.first;
          selectedSubject = departmentSubjects[selectedDepartment]!.first;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Feedback submitted!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Submit failed: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    selectedDepartment = facultyDepartments[selectedFaculty]!.first;
    selectedSubject = departmentSubjects[selectedDepartment]!.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Feedback'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      
        actions: [
  IconButton(
    icon: const Icon(Icons.admin_panel_settings),
    tooltip: 'Go to Dashboard',
    onPressed: () async {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (context.mounted) {
        if (token != null) {
          Navigator.pushNamed(context, '/dashboard');
        } else {
          Navigator.pushNamed(context, '/login');
        }
      }
    },
  ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Your Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: teacherController,
                        decoration: const InputDecoration(labelText: 'Teacher Name'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedFaculty,
                        decoration: const InputDecoration(labelText: 'Faculty'),
                        items: faculties
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedFaculty = val!;
                            selectedDepartment = facultyDepartments[selectedFaculty]!.first;
                            selectedSubject = departmentSubjects[selectedDepartment]!.first;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: departments.contains(selectedDepartment)
                            ? selectedDepartment
                            : departments.first,
                        decoration: const InputDecoration(labelText: 'Department'),
                        items: departments
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedDepartment = val!;
                            selectedSubject = departmentSubjects[selectedDepartment]!.first;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: subjects.contains(selectedSubject)
                            ? selectedSubject
                            : subjects.first,
                        decoration: const InputDecoration(labelText: 'Subject'),
                        items: subjects
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedSubject = val!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentController,
                        decoration: const InputDecoration(labelText: 'Comment'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Rating: ${rating.toInt()}'),
                          Expanded(
                            child: Slider(
                              value: rating,
                              min: 1,
                              max: 5,
                              divisions: 4,
                              label: rating.toInt().toString(),
                              onChanged: (val) => setState(() => rating = val),
                              activeColor: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: sendFeedback,
                          label: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}