import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _logger = Logger();

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();

    _logger.i('Token: $fCMToken');
  }
}
