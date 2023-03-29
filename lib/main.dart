import 'package:fcm_flutter/View/notificationTest.dart';
import 'package:fcm_flutter/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// c: global method for bg notification handler
/* Future<void> _firebaseMessagingBackgroudHandler(
    RemoteMessage remoteMessage) async {
  print("Handling a background message ${remoteMessage.messageId} ");
} */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // c: to get notification
  await FirebaseMessaging.instance.getInitialMessage();
  // c: background notification handler
/*   FirebaseMessaging.onBackgroundMessage((RemoteMessage message) {
    return _firebaseMessagingBackgroudHandler(message);
  }); */
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const NotificationTestScreen(title: 'FCM Flutter Home Page'),
    );
  }
}
