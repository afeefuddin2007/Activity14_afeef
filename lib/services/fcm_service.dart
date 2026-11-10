import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

/// Keeps the app's receipt/open listeners together and cancels them on dispose.
class FcmService {
  FcmService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  Future<AuthorizationStatus> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus;
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  void listen({required void Function(RemoteMessage, String) onMessage}) {
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      (message) => onMessage(message, 'onMessage'),
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => onMessage(message, 'onMessageOpenedApp'),
    );
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
  }
}
