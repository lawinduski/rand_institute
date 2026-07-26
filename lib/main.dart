import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';
import 'teacher_dashboard.dart';
import 'notification_service.dart';
import 'dart:io';

class ThemeManager {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  static void toggleTheme() {
    themeMode.value = themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyD336wudsccLID4IgyYVSXlzOy6vQTYm3g",
      authDomain: "rand-institute-10055.firebaseapp.com",
      projectId: "rand-institute-10055",
      storageBucket: "rand-institute-10055.firebasestorage.app",
      messagingSenderId: "366249114990",
      appId: Platform.isIOS 
          ? "1:366249114990:ios:2b98c01982c8f5427fd57f" // 🔥 App ID یێ نوو یێ ئایفۆنێ
          : "1:366249114990:web:f787ccce2f8258257fd57f", // App ID یێ Android/Web
      measurementId: "G-XC0YDH03J1",
    ),
  );

  await NotificationService.initializeNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'سیستەمێ پەیمانگەھێ',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: const Color(0xFF0066FF),
            scaffoldBackgroundColor: const Color(0xFFF4F7FC),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0066FF),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF0066FF),
            scaffoldBackgroundColor: const Color(0xFF0A0F1D),
            cardTheme: CardThemeData(
              color: const Color(0xFF131C31),
              elevation: 8,
              shadowColor: Colors.black54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF131C31),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
          ),
          themeMode: currentMode,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: LoginScreen(),
          ),
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تکایە هەموو خانەکان پڕبکەرەوە!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        String role = userDoc['role'] ?? 'student';
        String userName = userDoc['name'] ?? 'بەکارھێنەر';

        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
        } else if (role == 'teacher') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherDashboard()));
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentDashboard(userName: userName)),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خەتا ل لۆگینکرنێ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.25 : 0.15),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🖼️ لۆگۆیا پەیمانگەھێ ل لێرەیە
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0066FF), Color(0xFF00C6FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.asset(
                                'assets/logo.png', // 👈 ڕێڕەوی وێنەکەت
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // ئەگەر وێنەکە نەدۆزرایەوە ئەم ئایکۆنە نیشان دەدات
                                  return const Icon(Icons.school_rounded, size: 50, color: Colors.white);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'پەیمانگەھا ڕەند',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'سیستەمێ بڕێڤەبرنا ئەکادیمی',
                            style: TextStyle(color: isDark ? Colors.blueGrey[200] : Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 36),
                          TextField(
                            controller: _emailController,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: 'ئیمەیل',
                              prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFF0066FF)),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: 'پاسوۆرد',
                              prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF0066FF)),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : Container(
                                  width: double.infinity,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: const Text(
                                      'چوونا ژووری',
                                      style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: isDark ? Colors.amber : const Color(0xFF0A0F1D)),
              onPressed: () => ThemeManager.toggleTheme(),
            ),
          ),
        ],
      ),
    );
  }
}