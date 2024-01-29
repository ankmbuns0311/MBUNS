import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> notificationsList = [];

  @override
  void initState() {
    super.initState();
    _configureFirebaseMessaging();
  }

  void _configureFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Tangani notifikasi saat aplikasi berjalan
      _handleNotification(message.data);
    });

    // Tangani notifikasi saat aplikasi diluncurkan
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        _handleNotification(message.data);
      }
    });

    // Tangani notifikasi saat aplikasi sedang berjalan dan dalam keadaan terbuka
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      _handleNotification(message.data);
    });

    // Tangani pesan latar belakang
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print("Handling background message: ${message.data}");
    // Anda dapat menambahkan logika penanganan pesan latar belakang di sini
  }

  void _handleNotification(Map<String, dynamic> message) {
    // Tangani notifikasi di sini
    print("Received notification: $message");

    // Simpan notifikasi ke Firestore
    _saveNotificationToFirestore(message);
  }

  void _saveNotificationToFirestore(Map<String, dynamic> message) async {
    await _firestore.collection('notifications').add(message);
    print("Notification saved to Firestore");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications Page'),
      ),
      body: ListView.builder(
        itemCount: notificationsList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(notificationsList[index]['notification']['title']),
            subtitle: Text(notificationsList[index]['notification']['body']),
          );
        },
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Notifications',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotificationsPage(),
    );
  }
}
