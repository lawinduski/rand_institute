import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  int _adminTab = 0;

  final List<String> departments = ['تەکنۆلۆژیا زانیاری (IT)', 'بەشێ پەرستاری', 'بەشێ کارگێڕی', 'بەشێ ئینگلیزی'];
  final List<String> stages = ['قۆناغا 1 (مەرحەلا ئێکێ)', 'قۆناغا 2 (مەرحەلا دووێ)'];

  String _selectedDepartment = 'تەکنۆلۆژیا زانیاری (IT)';
  String _selectedStage = 'قۆناغا 1 (مەرحەلا ئێکێ)';
  String _selectedRole = 'student';
  bool _isLoading = false;

  // 🧹 پاککرن و لابڕینا ئاگادارییا ٣ ڕۆژان ژ سەر قوتابی
  Future<void> _resetStudentAbsences(String userId, String studentName) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'absences': 0,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ئاگادارییا ٣ ڕۆژان ژ سەر قوتابی ($studentName) ب سەرکەفتن هاتە لابڕین!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('زێدەکرنا ئاگادارییا نوو'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'سەردێڕی ئاگاداری')),
              const SizedBox(height: 10),
              TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'ناوەڕۆکی ئاگاداری')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isNotEmpty && bodyCtrl.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('announcements').add({
                    'title': titleCtrl.text.trim(),
                    'body': bodyCtrl.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('بڵاوبکەرەوە'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          bool isDark = Theme.of(context).brightness == Brightness.dark;
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('زێدەکرنا ئەندامێ نوو', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'ناو و پاشناو',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'ئیمەیل',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'پاسوۆرد',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'ڕۆڵ (دەسەڵات)',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('قوتابی')),
                        DropdownMenuItem(value: 'teacher', child: Text('مامۆستا')),
                        DropdownMenuItem(value: 'admin', child: Text('ڕێڤەبەر')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      decoration: InputDecoration(
                        labelText: 'بەشێ پەیمانگەھێ',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDepartment = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedStage,
                      decoration: InputDecoration(
                        labelText: 'قۆناغ / مەرحەلە',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: stages.map((stg) => DropdownMenuItem(value: stg, child: Text(stg))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStage = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF)),
                  onPressed: _isLoading ? null : () => _createUser(dialogContext),
                  child: const Text('تۆماربکە', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createUser(BuildContext dialogContext) async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'department': _selectedDepartment,
        'stage': _selectedStage,
        'absences': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();

      if (!mounted) return;
      Navigator.pop(dialogContext);
    } catch (e) {
      //
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 75,
          title: const Text('پانێلا کارگێڕیا پەیمانگەھێ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
          selectedIndex: _adminTab,
          onDestinationSelected: (idx) => setState(() => _adminTab = idx),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.people_alt_rounded), label: 'ئەندامان'),
            NavigationDestination(icon: Icon(Icons.campaign_rounded), label: 'ئاگاداری'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _adminTab == 0 ? _showCreateUserDialog : _showAddAnnouncementDialog,
          backgroundColor: const Color(0xFF0066FF),
          icon: Icon(_adminTab == 0 ? Icons.person_add_alt_1_rounded : Icons.add_alert_rounded, color: Colors.white),
          label: Text(_adminTab == 0 ? 'زێدەکرنا کەسی' : 'زێدەکرنا ئاگاداری', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: _adminTab == 0 ? _buildUsersList(isDark) : _buildAnnouncementsAdminList(isDark),
      ),
    );
  }

  Widget _buildUsersList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;

            String roleText = userData['role'] == 'admin' ? 'ڕێڤەبەر' : (userData['role'] == 'teacher' ? 'مامۆستا' : 'قوتابی');
            String deptText = userData['department'] ?? 'دیارنەکریە';
            int absences = userData['absences'] ?? 0;
            bool hasWarning = absences >= 3 && userData['role'] == 'student';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: hasWarning ? Border.all(color: Colors.redAccent, width: 1.5) : null,
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: hasWarning ? Colors.redAccent : const Color(0xFF0066FF),
                  child: Icon(hasWarning ? Icons.warning_rounded : Icons.person_rounded, color: Colors.white),
                ),
                title: Text(userData['name'] ?? 'بێ ناڤ', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$roleText • $deptText\nئامادەنەبوون: $absences ڕۆژ'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () async => await FirebaseFirestore.instance.collection('users').doc(userId).delete(),
                ),
                children: [
                  if (hasWarning)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: const Text('لابڕینی ئاگادارییا ٣ ڕۆژان (پاککرن)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () => _resetStudentAbsences(userId, userData['name'] ?? ''),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnnouncementsAdminList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('announcements').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['body'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () async => await FirebaseFirestore.instance.collection('announcements').doc(id).delete(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}