import 'package:flutter/material.dart'; // تێبینی: هەکەر شاشی دا ئەڤ ژمارە 0 بکه ب : (package:flutter)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;
  String teacherDepartment = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacherDepartment();
  }

  // 🔍 وەرگرتنا بەشی مامۆستایی ڕاستەوخۆ ژ Firebase
  Future<void> _fetchTeacherDepartment() async {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          teacherDepartment = doc.data()!['department'] ?? 'تەکنۆلۆژیا زانیاری (IT)';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('داشبۆردێ مامۆستایان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('بەشێ تە: $teacherDepartment', style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: isDark ? Colors.amber : Colors.white),
              onPressed: () => ThemeManager.toggleTheme(),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.check_circle_outline_rounded), label: 'ئامادەنەبوون'),
            NavigationDestination(icon: Icon(Icons.grade_rounded), label: 'تۆمارکرنا نمران'),
            NavigationDestination(icon: Icon(Icons.menu_book_rounded), label: 'زێدەکرنا وانەکان'),
            NavigationDestination(icon: Icon(Icons.edit_calendar_rounded), label: 'زێدەکرنا خشتەی'),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildAbsencesTab(isDark),
            _buildAddGradesTab(isDark),
            _buildAddSubjectsTab(isDark),
            _buildAddScheduleTab(isDark),
          ],
        ),
      ),
    );
  }

  // 1️⃣ بەشێ ئامادەنەبوونان (تەنها بۆ قوتابییەکانی بەشی مامۆستاکە)
  Widget _buildAbsencesTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('department', isEqualTo: teacherDepartment)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(child: Text('هیچ قوتابییەک د بەشێ ($teacherDepartment) دا نینە.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            int currentAbsences = data['absences'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(data['name'] ?? 'بێ ناڤ', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ئامادەنەبوون: $currentAbsences ڕۆژ'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
                      onPressed: () {
                        FirebaseFirestore.instance.collection('users').doc(doc.id).update({'absences': currentAbsences + 1});
                      },
                    ),
                    Text('$currentAbsences', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.orange, size: 30),
                      onPressed: () {
                        if (currentAbsences > 0) {
                          FirebaseFirestore.instance.collection('users').doc(doc.id).update({'absences': currentAbsences - 1});
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2️⃣ بەشێ زێدەکرنا نمران
  Widget _buildAddGradesTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('department', isEqualTo: teacherDepartment)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(child: Text('هیچ قوتابییەک د بەشێ ($teacherDepartment) دا نینە.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('مەرحەلە: ${data['stage'] ?? 'دیارنەکری'}'),
                trailing: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('زێدەکرنا نمرێ'),
                  onPressed: () => _showAddGradeDialog(doc.id, data['name'] ?? ''),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 3️⃣ 📚 بەشێ زێدەکرنا وانان دگەڵ تێبینییان
  Widget _buildAddSubjectsTab(bool isDark) {
    final subjectNameController = TextEditingController();
    final teacherNameController = TextEditingController();
    final noteController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('زێدەکرنا وانەکا نوو بۆ بەشی: $teacherDepartment', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: subjectNameController,
            decoration: const InputDecoration(
              labelText: 'ناڤێ وانێ (نموونە: Flutter UI / Programming)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.book_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: teacherNameController,
            decoration: const InputDecoration(
              labelText: 'ناڤێ مامۆستایێ وانێ',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'تێبینی / ئاگاداری بۆ قوتابیان (نموونە: خوێندنی بابەتەکە پێویستە)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note_alt_rounded),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF)),
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
              label: const Text('زێدەکرنا وانێ', style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: () async {
                if (subjectNameController.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('subjects').add({
                    'name': subjectNameController.text,
                    'teacher': teacherNameController.text.isEmpty ? 'نەدیار بویە' : teacherNameController.text,
                    'note': noteController.text.isEmpty ? 'هیچ تێبینییەک نینە' : noteController.text,
                    'department': teacherDepartment,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وانە ب سەرکەفتنی هاتە زێدەکرن!')));
                    subjectNameController.clear();
                    teacherNameController.clear();
                    noteController.clear();
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 30),
          const Text('لیستا وانێن تۆمارکری و تێبینییان:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('subjects')
                .where('department', isEqualTo: teacherDepartment)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final docs = snapshot.data!.docs;

              if (docs.isEmpty) return const Text('هیچ وانەیەک نەهاتیە زێدەکرن.');

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  String note = data['note'] ?? 'هیچ تێبینییەک نینە';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF0066FF).withOpacity(0.12), shape: BoxShape.circle),
                          child: const Icon(Icons.book_rounded, color: Color(0xFF0066FF)),
                        ),
                        title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('مامۆستا: ${data['teacher'] ?? ''}'),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade700, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber.shade900),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'تێبینی: $note',
                                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => FirebaseFirestore.instance.collection('subjects').doc(doc.id).delete(),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // 4️⃣ بەشێ زێدەکرنا خشتەی
  Widget _buildAddScheduleTab(bool isDark) {
    final titleController = TextEditingController();
    final timeController = TextEditingController();
    final dayController = TextEditingController();
    String scheduleType = 'exam_schedule';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تۆمارکرنا خشتەی بۆ بەشی: $teacherDepartment', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'ناڤێ بابەت / ئەزموونێ', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dayController,
            decoration: const InputDecoration(labelText: 'ڕۆژ / ڕێکەوت (نموونە: 2026/08/01)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: timeController,
            decoration: const InputDecoration(labelText: 'کاتژمێر (نموونە: 09:00 AM)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: scheduleType,
            decoration: const InputDecoration(labelText: 'جۆرێ خشتەی', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'exam_schedule', child: Text('خشتەی ئەزموونان (Exams)')),
              DropdownMenuItem(value: 'weekly_schedule', child: Text('خشتەی حەفتانە')),
            ],
            onChanged: (val) => scheduleType = val!,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF)),
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection(scheduleType).add({
                    'title': titleController.text,
                    'day_or_date': dayController.text,
                    'time': timeController.text,
                    'department': teacherDepartment,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خشتە ب سەرکەفتنی هاتە زێدەکرن!')));
                    titleController.clear();
                    dayController.clear();
                    timeController.clear();
                  }
                }
              },
              child: const Text('تۆمارکرنا خشتەی', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGradeDialog(String studentId, String studentName) {
    final subjectController = TextEditingController();
    final markController = TextEditingController();
    String examType = 'نیوەی وەرز (Midterm)';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('زێدەکرنا نمرێ بۆ: $studentName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'ناڤێ وانەیێ')),
            TextField(controller: markController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'نمرە (لە 100)')),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: examType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'نیوەی وەرز (Midterm)', child: Text('نیوەی وەرز (Midterm)')),
                DropdownMenuItem(value: 'کۆتایی وەرز (Final)', child: Text('کۆتایی وەرز (Final)')),
                DropdownMenuItem(value: 'کوێز (Quiz)', child: Text('کوێز (Quiz)')),
              ],
              onChanged: (val) => examType = val!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە')),
          ElevatedButton(
            onPressed: () async {
              if (subjectController.text.isNotEmpty && markController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(studentId).collection('grades').add({
                  'subject': subjectController.text,
                  'mark': int.tryParse(markController.text) ?? 0,
                  'exam_type': examType,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('تۆمارکرن'),
          ),
        ],
      ),
    );
  }
}