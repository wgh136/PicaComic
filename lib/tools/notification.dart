import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/downloading_page.dart';

class Notifications{
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  final progressId = 72382;

  Future<bool?> requestPermission() async{
    if(!GetPlatform.isAndroid)  return false;
    return await flutterLocalNotificationsPlugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()!.requestPermission();
  }

  Future<void> init() async{
    if(GetPlatform.isWeb||!GetPlatform.isAndroid)  return;
    flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/notification');
    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );
    await flutterLocalNotificationsPlugin!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse
    );
  }

  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    if(GetPlatform.isWeb||!GetPlatform.isAndroid)  return;
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }
    Get.to(()=>const DownloadingPage());
  }

  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    Get.to(()=>const DownloadingPage());
  }

  void sendProgressNotification(int progress, int total, String title, String content) async{
    if(GetPlatform.isWeb||!GetPlatform.isAndroid)  return;
    if (await requestPermission() != true)  return;
    AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails('download', '下载漫画',
      channelDescription: '显示下载进度',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: total,
      progress: progress,
      ongoing: true,
      onlyAlertOnce: true,
      autoCancel: false
    );
    NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin!.show(
        progressId, title, content, notificationDetails,
        payload: 'item x');
  }

  void endProgress() async{
    if(GetPlatform.isWeb||!GetPlatform.isAndroid)  return;
    await requestPermission();
    await flutterLocalNotificationsPlugin!.cancel(progressId);
  }

  void sendNotification(String title, String content) async{
    if(GetPlatform.isWeb||!GetPlatform.isAndroid)  return;
    await requestPermission();
    AndroidNotificationDetails androidNotificationDetails =
    const AndroidNotificationDetails('PicaComic', '通知',
        channelDescription: '通知',
        importance: Importance.max,
        priority: Priority.max,
    );
    NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin!.show(
        1145140, title, content, notificationDetails,
        payload: 'item x');
  }
}