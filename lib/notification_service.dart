import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // 🔔 ١. ئامادەکرن و وەگرتنا مۆڵەتێ ژ قوتابی
  static Future<void> initializeNotifications() async {
    // وەرگرتنا مۆڵەتێ
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // بەشداربوونا ئۆتۆماتیکی د ئاگادارییێن گشتی دا
      await _messaging.subscribeToTopic('all_students');
    }
  }

  // 🎯 ٢. بەشدارکرنا قوتابی د بەش و مەرحەلا وی دا (بۆ ئاگادارییێن تایبەت)
  static Future<void> subscribeToStudentClass({
    required String department,
    required String stage,
  }) async {
    // ئامادەکرنا ناڤی (پاککرنا بۆشاییان)
    String cleanDept = department.replaceAll(' ', '_').replaceAll('(', '').replaceAll(')', '');
    String cleanStage = stage.replaceAll(' ', '_').replaceAll('(', '').replaceAll(')', '');

    // بەشداربوونا Topic-ان
    await _messaging.subscribeToTopic('dept_$cleanDept');
    await _messaging.subscribeToTopic('stage_$cleanStage');
  }
}