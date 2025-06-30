


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


// Show only 5 feedbacks per page
const int pageSize = 5;

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  //added
  final _storage = FlutterSecureStorage();
//
  List<dynamic> fullFeedbackList = [];
  List<dynamic> filteredList = [];

  String searchQuery = '';
  String selectedFaculty = 'All';
  String selectedDepartment = 'All';
  String selectedSubject = 'All';
  String selectedTeacher = 'All';
  DateTimeRange? selectedDateRange;

  bool isLoading = true;
  String? errorMsg;

  int currentPage = 0;

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

  List<String> get faculties => ['All', ...facultyDepartments.keys];
  List<String> get departments {
    if (selectedFaculty == 'All') {
      final all = facultyDepartments.values.expand((d) => d).toSet().toList();
      all.sort();
      return ['All', ...all];
    }
    return ['All', ...facultyDepartments[selectedFaculty]!];
  }

  List<String> get subjects {
    if (selectedDepartment == 'All') {
      final all = departmentSubjects.values.expand((s) => s).toSet().toList();
      all.sort();
      return ['All', ...all];
    }
    return ['All', ...departmentSubjects[selectedDepartment]!];
  }

  List<String> get teachers {
    final allTeachers = fullFeedbackList
        .map((fb) => (fb['teacher'] ?? '').toString().trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    allTeachers.sort();
    return ['All', ...allTeachers];
  }

  @override
  void initState() {
    super.initState();
    fetchFeedbacks();
  }

  // Future<void> fetchFeedbacks() async {
  //   setState(() {
  //     isLoading = true;
  //     errorMsg = null;
  //   });
  //   final url = Uri.parse('http://10.10.10.14:3000/api/get-feedback');
  //   try {
  //     final res = await http.get(url).timeout(const Duration(seconds: 10));
  //     if (res.statusCode == 200) {
  //       final data = jsonDecode(res.body);
  //       setState(() {
  //         fullFeedbackList = List.from(data);
  //         filteredList = List.from(data);
  //         if (!teachers.contains(selectedTeacher)) selectedTeacher = 'All';
  //         isLoading = false;
  //         currentPage = 0;
  //       });
  //     } else {
  //       setState(() {
  //         isLoading = false;
  //         errorMsg = 'Failed to load data: ${res.statusCode}';
  //       });
  //     }
  //   } on http.ClientException catch (e) {
  //     setState(() {
  //       isLoading = false;
  //       errorMsg = 'Network error: ${e.message}';
  //     });
  //   } on FormatException {
  //     setState(() {
  //       isLoading = false;
  //       errorMsg = 'Invalid response format from server.';
  //     });
  //   } on Exception catch (e) {
  //     setState(() {
  //       isLoading = false;
  //       errorMsg = 'Error: ${e.toString()}';
  //     });
  //   }
  // }
//added
Future<void> fetchFeedbacks() async {
  setState(() {
    isLoading = true;
    errorMsg = null;
  });

  final token = await _storage.read(key: 'token');
  final url = Uri.parse('http://10.10.10.14:3000/api/get-feedback');

  try {
    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        fullFeedbackList = List.from(data);
        filteredList = List.from(data);
        if (!teachers.contains(selectedTeacher)) selectedTeacher = 'All';
        isLoading = false;
        currentPage = 0;
      });
    } else {
      setState(() {
        isLoading = false;
        errorMsg = 'Failed to load data: ${res.statusCode}';
      });
    }
  } catch (e) {
    setState(() {
      isLoading = false;
      errorMsg = 'Error: ${e.toString()}';
    });
  }
}

//
  void applyFilters() {
    setState(() {
      filteredList = fullFeedbackList.where((fb) {
        final matchesFaculty = selectedFaculty == 'All' || fb['faculty'] == selectedFaculty;
        final matchesDepartment = selectedDepartment == 'All' || fb['department'] == selectedDepartment;
        final matchesSubject = selectedSubject == 'All' || fb['subject'] == selectedSubject;
        final matchesTeacher = selectedTeacher == 'All' || (fb['teacher'] ?? '') == selectedTeacher;
        final matchesSearch = searchQuery.isEmpty ||
            (fb['name']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (fb['teacher']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (fb['subject']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (fb['comments']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
        final matchesDate = selectedDateRange == null ||
            (fb['createdAt'] != null &&
                DateTime.tryParse(fb['createdAt']) != null &&
                DateTime.parse(fb['createdAt']).isAfter(selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                DateTime.parse(fb['createdAt']).isBefore(selectedDateRange!.end.add(const Duration(days: 1))));
        return matchesFaculty && matchesDepartment && matchesSubject && matchesTeacher && matchesSearch && matchesDate;
      }).toList();
      currentPage = 0;
    });
  }

  int get totalFeedbacks => filteredList.length;

  double get averageRating {
    if (filteredList.isEmpty) return 0;
    final total = filteredList.fold<double>(
      0,
      (sum, item) => sum + ((item['rating'] ?? 0).toDouble()),
    );
    return total / filteredList.length;
  }

  int get totalUniqueUsers {
    final names = filteredList
        .map((fb) => (fb['name'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty && name.toLowerCase() != 'anonymous')
        .toSet();
    return names.length;
  }

  Map<String, Map<String, dynamic>> get subjectSummary {
    final Map<String, List<dynamic>> grouped = {};
    for (var fb in filteredList) {
      final subject = fb['subject'] ?? 'Unknown';
      grouped.putIfAbsent(subject, () => []).add(fb);
    }
    final Map<String, Map<String, dynamic>> summary = {};
    grouped.forEach((subject, list) {
      final avg = list.fold<double>(0, (sum, item) => sum + ((item['rating'] ?? 0).toDouble())) / list.length;
      summary[subject] = {
        'average': avg,
        'count': list.length,
      };
    });
    return summary;
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDateRange = picked);
      applyFilters();
    }
  }

  void clearFilters() {
    setState(() {
      searchQuery = '';
      selectedFaculty = 'All';
      selectedDepartment = 'All';
      selectedSubject = 'All';
      selectedTeacher = 'All';
      selectedDateRange = null;
      filteredList = List.from(fullFeedbackList);
      currentPage = 0;
    });
  }

  List<dynamic> get paginatedFeedbacks {
    final start = currentPage * pageSize;
    final end = (start + pageSize) > filteredList.length ? filteredList.length : (start + pageSize);
    return filteredList.sublist(start, end);
  }

  void prevPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
    }
  }

  void nextPage() {
    if ((currentPage + 1) * pageSize < filteredList.length) {
      setState(() {
        currentPage++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Color(0xFFF5F7FB),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
  title: const Text('Admin Dashboard'),
  backgroundColor: Colors.indigo,
  foregroundColor: Colors.white,
  actions: [
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: fetchFeedbacks,
      tooltip: 'Reload',
    ),
    IconButton(
      icon: const Icon(Icons.clear_all),
      onPressed: clearFilters,
      tooltip: 'Clear Filters',
    ),
//logout button
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () async {
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'token');
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      tooltip: 'Logout',
    ),
  ],
),

        // appBar: AppBar(
        //   title: const Text('Admin Dashboard'),
        //   backgroundColor: Colors.indigo,
        //   foregroundColor: Colors.white,
        //   actions: [
        //     IconButton(
        //       icon: const Icon(Icons.refresh),
        //       onPressed: fetchFeedbacks,
        //       tooltip: 'Reload',
        //     ),
        //     IconButton(
        //       icon: const Icon(Icons.clear_all),
        //       onPressed: clearFilters,
        //       tooltip: 'Clear Filters',
        //     ),
        //   ],
        // ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMsg != null
                  ? Center(
                      key: const ValueKey('error'),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                            const SizedBox(height: 16),
                            Text(
                              errorMsg!,
                              style: const TextStyle(fontSize: 16, color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: fetchFeedbacks,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SafeArea(
                      key: const ValueKey('content'),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Filters Card
                            Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            decoration: const InputDecoration(
                                              labelText: 'Search (name, teacher, subject, comment)',
                                              prefixIcon: Icon(Icons.search),
                                            ),
                                            onChanged: (val) {
                                              searchQuery = val;
                                              applyFilters();
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.date_range),
                                          onPressed: pickDateRange,
                                          tooltip: 'Filter by Date',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: selectedFaculty,
                                            items: faculties
                                                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                                                .toList(),
                                            onChanged: (val) {
                                              setState(() {
                                                selectedFaculty = val!;
                                                selectedDepartment = 'All';
                                                selectedSubject = 'All';
                                              });
                                              applyFilters();
                                            },
                                            decoration: const InputDecoration(labelText: 'Faculty'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: departments.contains(selectedDepartment)
                                                ? selectedDepartment
                                                : 'All',
                                            items: departments
                                                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                                .toList(),
                                            onChanged: (val) {
                                              setState(() {
                                                selectedDepartment = val!;
                                                selectedSubject = 'All';
                                              });
                                              applyFilters();
                                            },
                                            decoration: const InputDecoration(labelText: 'Department'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: subjects.contains(selectedSubject)
                                                ? selectedSubject
                                                : 'All',
                                            items: subjects
                                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                                .toList(),
                                            onChanged: (val) {
                                              setState(() {
                                                selectedSubject = val!;
                                              });
                                              applyFilters();
                                            },
                                            decoration: const InputDecoration(labelText: 'Subject'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: teachers.contains(selectedTeacher)
                                                ? selectedTeacher
                                                : 'All',
                                            items: teachers
                                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                                .toList(),
                                            onChanged: (val) {
                                              setState(() {
                                                selectedTeacher = val!;
                                              });
                                              applyFilters();
                                            },
                                            decoration: const InputDecoration(labelText: 'Teacher'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (selectedDateRange != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Row(
                                          children: [
                                            Text(
                                              'From: ${selectedDateRange!.start.toString().split(' ')[0]}  To: ${selectedDateRange!.end.toString().split(' ')[0]}',
                                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() => selectedDateRange = null);
                                                applyFilters();
                                              },
                                              tooltip: 'Clear Date Filter',
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Summary Cards Row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildMiniCard(
                                    icon: Icons.feedback,
                                    color: Colors.indigo,
                                    label: 'Total Reviews',
                                    value: totalFeedbacks.toString(),
                                  ),
                                  _buildMiniCard(
                                    icon: Icons.people,
                                    color: Colors.teal,
                                    label: 'Has Given Feedback',
                                    value: totalUniqueUsers.toString(),
                                  ),
                                  _buildMiniCard(
                                    icon: Icons.star,
                                    color: Colors.amber[800]!,
                                    label: 'Avg Rating',
                                    value: averageRating.toStringAsFixed(1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Subject Summary Grid
                            if (subjectSummary.isNotEmpty) ...[
                              const Text(
                                '📊 Average Rating per Subject',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: subjectSummary.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                                  childAspectRatio: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemBuilder: (context, idx) {
                                  final subject = subjectSummary.keys.elementAt(idx);
                                  final avg = subjectSummary[subject]!['average'] as double;
                                  final count = subjectSummary[subject]!['count'] as int;
                                  return _buildSubjectTile(subject, avg.toStringAsFixed(1), count);
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                            // Feedback List with Pagination
                            const Text(
                              '📋 Recent Feedbacks',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            filteredList.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.inbox, size: 48, color: Colors.indigo[200]),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'No feedbacks found.',
                                            style: TextStyle(fontSize: 16, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: paginatedFeedbacks.length,
                                        itemBuilder: (context, index) {
                                          final fb = paginatedFeedbacks[index];
                                          return Card(
                                            margin: const EdgeInsets.symmetric(vertical: 6),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: Colors.indigo[100],
                                                child: Text(
                                                  (fb['name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                                                  style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              title: Text(
                                                '${fb['name'] ?? 'Anonymous'}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.star, color: Colors.amber[700], size: 18),
                                                      const SizedBox(width: 2),
                                                      Text('${fb['rating'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  if (fb['comments'] != null && fb['comments'].toString().trim().isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4),
                                                      child: Text(
                                                        fb['comments'],
                                                        style: const TextStyle(fontSize: 14),
                                                      ),
                                                    ),
                                                  if (fb['teacher'] != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 2),
                                                      child: Text('👩‍🏫 Teacher: ${fb['teacher']}',
                                                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                    ),
                                                  if (fb['subject'] != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 2),
                                                      child: Text('📘 Subject: ${fb['subject']}',
                                                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                    ),
                                                  if (fb['faculty'] != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 2),
                                                      child: Text('🏫 Faculty: ${fb['faculty']}',
                                                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                    ),
                                                  if (fb['department'] != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 2),
                                                      child: Text('🏢 Department: ${fb['department']}',
                                                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                    ),
                                                ],
                                              ),
                                              trailing: Text(
                                                fb['createdAt']?.toString().split('T').first ?? '',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Pagination controls
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.chevron_left),
                                            onPressed: currentPage > 0 ? prevPage : null,
                                          ),
                                          Text(
                                            'Page ${currentPage + 1} of ${((filteredList.length - 1) ~/ pageSize) + 1}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.chevron_right),
                                            onPressed: (currentPage + 1) * pageSize < filteredList.length ? nextPage : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  value,
                  key: ValueKey(value),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.black87),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectTile(String subject, String avg, int count) {
    return Card(
      color: Colors.indigo[25],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: FittedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              Text('⭐ $avg', style: const TextStyle(fontSize: 16, color: Colors.amber)),
              Text('$count feedbacks', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}