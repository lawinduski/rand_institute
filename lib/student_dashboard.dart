import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class StudentDashboard extends StatefulWidget {
  final String userName;

  const StudentDashboard({super.key, required this.userName});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  // 📝 لیستا ID یێن ئەو ئاگاداری و وانەیێن کو قوتابی دیتینە (پشتی کلیک ل سەر دکەت نەنوو دبن)
  final Set<String> _seenAnnouncements = {};
  final Set<String> _seenSubjects = {};

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('ئاریشەیەک هەیە د بارکرنا داتایان دا!'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          Map<String, dynamic> userData = {};
          if (snapshot.hasData && snapshot.data!.data() != null) {
            userData = snapshot.data!.data() as Map<String, dynamic>;
          }

          String name = userData['name'] ?? widget.userName;
          String department = userData['department'] ?? 'تەکنۆلۆژیا زانیاری (IT)';
          String stage = userData['stage'] ?? 'قۆناغا 1 (مەرحەلا ئێکێ)';
          int absences = userData['absences'] ?? 0;

          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 70,
              title: const Text(
                'پەیمانگەی ڕەند - بەشی قوتابیان',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: isDark ? Colors.amber : Colors.white,
                  ),
                  onPressed: () => ThemeManager.toggleTheme(),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.person_pin_rounded),
                  label: 'پرۆفایل',
                ),
                NavigationDestination(
                  icon: Icon(Icons.campaign_rounded),
                  label: 'ئاگاداری',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_rounded),
                  label: 'وانەکان',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_rounded),
                  label: 'خشتە',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grade_rounded),
                  label: 'نمرەکان',
                ),
              ],
            ),
            body: IndexedStack(
              index: _currentIndex,
              children: [
                _buildProfileTab(context, name, department, stage, absences, isDark),
                _buildAnnouncementsTab(department, absences, isDark),
                _buildSubjectsTab(department, stage, isDark),
                _buildSchedulesTab(department, stage, isDark),
                _buildGradesTab(currentUserId, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  // 1️⃣ پرۆفایلا قوتابی
  Widget _buildProfileTab(BuildContext context, String name, String department, String stage, int absences, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0066FF), Color(0xFF0044B3)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066FF).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person_rounded, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'قوتابییێ فەرمی',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoTile(
                        icon: Icons.school_rounded,
                        label: 'بەش',
                        value: department,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoTile(
                        icon: Icons.auto_awesome_mosaic_rounded,
                        label: 'مەرحەلە',
                        value: stage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ئامارێن ئەکادیمی',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'کۆیا ئامادەنەبوونان',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'تۆ ب تەمامی $absences ڕۆژ ئامادەنەبووی د ڤی وەرزی دا.',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$absences',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2️⃣ بەشێ ئاگادارییان (دگەڵ بەدجا "نوو")
  Widget _buildAnnouncementsTab(String studentDepartment, int absences, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String targetDept = data['department'] ?? 'هەموو بەشەکان';
          return targetDept == 'هەموو بەشەکان' || targetDept == studentDepartment;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (absences >= 3)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.redAccent, width: 2),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'ئاگادارییا دوماهیێ (تەمبیها ٣ ڕۆژان)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'کۆیا ئامادەنەبوونا تە گەهشتییە ٣ ڕۆژان! تکایە ب زووترین کات سەردانا ژوورا ڕێڤەبەرییا پەیمانگەھێ بکه بۆ چارەسەرکرنا ڤێ ئاریشەیێ و لابڕینا ڤێ ئاگادارییێ.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                    ),
                  ],
                ),
              ),
            if (docs.isEmpty && absences < 3)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text('هیچ ئاگادارییەک بۆ بەشێ تە نینە د نوکە دا.'),
                ),
              ),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              String docId = doc.id;
              bool isNew = !_seenAnnouncements.contains(docId);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _seenAnnouncements.add(docId);
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: isNew ? Border.all(color: Colors.redAccent, width: 1.5) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.campaign_rounded, color: Color(0xFF0066FF)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['title'] ?? 'ئاگاداری',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          if (isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'نوو 🔥',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['body'] ?? '',
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // 3️⃣ 📚 بەشێ وانەکان (دگەڵ بەدجا "نوو" + تێبینییا مامۆستایان)
  Widget _buildSubjectsTab(String department, String stage, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subjects')
          .where('department', isEqualTo: department)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text('هیچ وانەیەک بۆ بەشێ تە زێدە نەبوویە.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            String docId = doc.id;
            String note = data['note'] ?? 'هیچ تێبینییەک نینە';
            bool isNew = !_seenSubjects.contains(docId);

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _seenSubjects.add(docId);
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: isNew ? Border.all(color: Colors.green, width: 1.5) : null,
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.book_rounded, color: Color(0xFF0066FF)),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'وانەیا نوو ✨',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('مامۆستا: ${data['teacher'] ?? 'دیارنەکریە'}'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade700, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber.shade900),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'تێبینییا مامۆستای: $note',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 4️⃣ بەشێ خشتەی حەفتانە و ئەزموونان
  Widget _buildSchedulesTab(String department, String stage, bool isDark) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'خشتەی حەفتانە'),
              Tab(text: 'خشتەی ئەزموونان (Exams)'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildScheduleList('weekly_schedule', department, stage),
                _buildScheduleList('exam_schedule', department, stage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(String collectionName, String department, String stage) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String targetDept = data['department'] ?? 'هەموو بەشەکان';
          return targetDept == 'هەموو بەشەکان' || targetDept == department;
        }).toList();

        if (docs.isEmpty) return const Center(child: Text('هیچ خشتەیەک بۆ بەشێ تە بەردەست نینە.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                leading: const Icon(Icons.event_note_rounded, color: Color(0xFF0066FF)),
                title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${data['day_or_date']} - کاتژمێر: ${data['time']}'),
              ),
            );
          },
        );
      },
    );
  }

  // 5️⃣ بەشێ نمرەکان
  Widget _buildGradesTab(String userId, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('grades')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text('هیچ نمرەیەک تۆمارنەکراوە د نوکە دا.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                title: Text(data['subject'] ?? 'وانە', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('تاقیکردنەوە: ${data['exam_type'] ?? 'نیوەی وەرز'}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${data['mark']} / 100',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0066FF),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoTile({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}