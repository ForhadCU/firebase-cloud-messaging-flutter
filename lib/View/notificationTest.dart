// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fcm_flutter/const/keywords.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationTestScreen extends StatefulWidget {
  final String title;
  const NotificationTestScreen({super.key, required this.title});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  TextEditingController _username = TextEditingController();
  TextEditingController _title = TextEditingController();
  TextEditingController _body = TextEditingController();

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  String? _deviceToken;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    requestPermission();
    getDeviceToken();
    initInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(hintText: "User name"),
              ),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(hintText: "Title"),
              ),
              TextFormField(
                controller: _body,
                decoration: const InputDecoration(hintText: "Body"),
              ),
              const SizedBox(
                height: 24,
              ),
              ElevatedButton(
                  onPressed: () async {
                    String usernameText = _username.text.trim();
                    String titleText = _title.text;
                    String bodyText = _body.text;

                    if (usernameText != "") {
                      DocumentSnapshot snapshot = await FirebaseFirestore
                          .instance
                          .collection(MyKewords.collectionUser)
                          .doc(usernameText)
                          .get();
                      String targetDeviceToken =
                          snapshot[MyKewords.deviceToken];
                      print("TargetDeviceToken: $targetDeviceToken");

                      mSendPushMessage(targetDeviceToken, titleText, bodyText);
                    }
                  },
                  child: const Text("Submit"))
            ],
          ),
        ),
      ),
    );
  }

  void requestPermission() async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

    // c: request permission for alert message componants
    NotificationSettings notificationSettings =
        await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // c: get different kinds of authorization from user
    if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      print("User granted permission");
    } else if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("User granted provisional permission");
    } else {
      print("User rejected permission");
    }
  }

  void getDeviceToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        _deviceToken = token;
        print("My device token is: $_deviceToken");
      });
      mSaveToken(_deviceToken);
    });
  }

  void mSaveToken(String? deviceToken) async {
    await FirebaseFirestore.instance
        .collection(MyKewords.collectionUser)
        .doc("User 2")
        .set({MyKewords.deviceToken: deviceToken});
  }

  void initInfo() async {
    // c: for android setting
    var androidInitialize =
        const AndroidInitializationSettings("@mipmap-hdpi/ic_launcher.png");
    // c: for IOS setting
    var iosInitialize = const DarwinInitializationSettings();
    // c: now combine the two settings
    var initializationSettings =
        InitializationSettings(android: androidInitialize, iOS: iosInitialize);

    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        try {
          if (notificationResponse.payload != null) {
            print("OnDidReciNotiResponse callback func payload is not empty");
          } else {
            print(
                "Click on OnDidReciNotiResponse callback func payload is empty");
          }
        } catch (e) {}
      },
    );

    // c: initialize and listen notification which is triggered from firebase itself
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("..................onMessage..................");
      print(
          "onMessage: ${message.notification!.title}/${message.notification!.body}");

      // c: basic settings
      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
          message.notification!.body.toString(),
          htmlFormatBigText: true,
          contentTitle: message.notification!.title.toString(),
          htmlFormatContentTitle: true);
      // c: for android notification channel
      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        "fcmchannelid",
        "fcmchannelname",
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: bigTextStyleInformation,
        playSound: true,
      );
      NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: const DarwinNotificationDetails());

      // c: now
      await _flutterLocalNotificationsPlugin.show(
          0,
          message.notification!.title,
          message.notification!.body,
          platformChannelSpecifics,
          payload: message.data['body']);
    });
  }

  void mSendPushMessage(
      String targetDeviceToken, String titleText, String bodyText) async {
    try {
      await http.post(Uri.parse("https://fcm.googleapis.com/fcm/send"),
          headers: <String, String>{
            'Content-type': 'application/json',
            'Authorization':
                'key=AAAAUQmg-XM:APA91bF6lN3LTu8UeaSPZkMJq3uzZ99IKvIP7YCl3_leeqi--OGzPwmN9Hyv3zhDvnX2fgwQdyoq4rv3oubzUBeAO11qztPVJS4H5GiQS-SWTh46EuE02Z4TCbUzjRI9XCFSrHry5s2U',
          },
          body: jsonEncode(<String, dynamic>{
            'priority': 'high',
            // c: optional: for go to specific screen with data
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': bodyText,
              'title': titleText,
            },
            // c: needed
            "notification": <String, dynamic>{
              "title": titleText,
              "body": bodyText,
              "android_channel_id": "fcmchannelid"
            },
            "to": targetDeviceToken,
          }));
    } catch (e) {
      print(e);
    }
  }
}
