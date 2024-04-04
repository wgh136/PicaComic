import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/downloading_page.dart';
import '../foundation/app.dart';

class Notifications {
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  final progressId = 72382;

  Future<bool?> requestPermission() async {
    try {
      if (App.isAndroid) {
        return await flutterLocalNotificationsPlugin!
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()!
            .requestNotificationsPermission();
      } else if (App.isIOS) {
        return await flutterLocalNotificationsPlugin
            ?.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> init() async {
    if (!(App.isAndroid || App.isIOS)) return;
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/notification');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin!.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    if (!(App.isAndroid || App.isIOS)) return;
    final String? payload = notificationResponse.payload;
    if (payload != "item y") {
      App.globalTo(() => const DownloadingPage());
    }
  }

  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    if (payload != "item y") {
      App.globalTo(() => const DownloadingPage());
    }
  }

  void sendProgressNotification(
      int progress, int total, String title, String content) async {
    if (!(App.isAndroid || App.isIOS)) return;
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('download', '下载漫画'.tl,
            channelDescription: '显示下载进度'.tl,
            importance: Importance.low,
            priority: Priority.low,
            showProgress: true,
            maxProgress: total,
            progress: progress,
            ongoing: true,
            onlyAlertOnce: true,
            autoCancel: false);
    DarwinNotificationDetails ios = const DarwinNotificationDetails(
        presentSound: false, presentAlert: false, presentBadge: false,
        presentBanner: false);
    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails, iOS: ios);
    await flutterLocalNotificationsPlugin!.show(
        progressId, title, content, notificationDetails,
        payload: 'item x');
  }

  void endProgress() async {
    if (!(App.isAndroid || App.isIOS)) return;
    await flutterLocalNotificationsPlugin!.cancel(progressId);
  }

  void cancelAll() async {
    if (!(App.isAndroid || App.isIOS)) return;
    try {
      await flutterLocalNotificationsPlugin!.cancelAll();
    } catch (e) {
      // ignore
    }
  }

  void sendNotification(String title, String content) async {
    if (!(App.isAndroid || App.isIOS)) return;
    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails(
      'PicaComic',
      'notification',
      channelDescription: 'notification',
      importance: Importance.max,
      priority: Priority.max,
    );
    DarwinNotificationDetails ios = const DarwinNotificationDetails();
    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails, iOS: ios);
    await flutterLocalNotificationsPlugin!
        .show(1145140, title, content, notificationDetails, payload: 'item x');
  }

  void sendUnimportantNotification(String title, String content) async {
    if (!(App.isAndroid || App.isIOS)) return;
    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails(
      'punchIN',
      '打卡',
      channelDescription: '打卡',
      importance: Importance.low,
      priority: Priority.low,
    );

    DarwinNotificationDetails ios = const DarwinNotificationDetails(
        presentAlert: false, presentSound: false, presentBadge: false);

    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails, iOS: ios);
    await flutterLocalNotificationsPlugin!
        .show(51515568, title, content, notificationDetails, payload: 'item y');
  }
}
