import 'dart:async';

import 'package:callkeep/callkeep.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:remote_private_tutoring/constants.dart';
import 'package:remote_private_tutoring/services/FirebaseHelper.dart';
import 'package:remote_private_tutoring/services/helper.dart';
import 'package:remote_private_tutoring/ui/chat/PlayerWidget.dart';
import 'package:remote_private_tutoring/ui/home/HomeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/User.dart';
import 'ui/auth/AuthScreen.dart';
import 'ui/onBoarding/OnBoardingScreen.dart';

final FlutterCallkeep callKeep = FlutterCallkeep();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    EasyLocalization(
        supportedLocales: [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: Locale('en'),
        preloaderWidget: Container(color: Color(COLOR_PRIMARY)),
        useOnlyLangCode: true,
        child: MyApp()),
  );
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static User currentUser;
  StreamSubscription tokenStream;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Color(COLOR_PRIMARY_DARK)));
    return MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        title: 'appName'.tr(),
        theme: ThemeData(
            sliderTheme: SliderThemeData(
                trackShape: CustomTrackShape(),
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5)),
            accentColor: Color(COLOR_PRIMARY),
            brightness: Brightness.light),
        darkTheme: ThemeData(
            sliderTheme: SliderThemeData(
                trackShape: CustomTrackShape(),
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5)),
            accentColor: Color(COLOR_PRIMARY),
            brightness: Brightness.dark),
        debugShowCheckedModeBanner: false,
        color: Color(COLOR_PRIMARY),
        home: OnBoarding());
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    FireStoreUtils.firebaseMessaging.configure(
      onBackgroundMessage: backgroundMessageHandler,
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );
    // IOS에서만 작동
    // -------------------- Start --------------------
    FireStoreUtils.firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: true));
    FireStoreUtils.firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    // --------------------- End ---------------------
    tokenStream =
        FireStoreUtils.firebaseMessaging.onTokenRefresh.listen((event) {
      if (currentUser != null && event != null) {
        print('token $event');
        currentUser.fcmToken = event;
        FireStoreUtils.updateCurrentUser(currentUser);
      }
    });
    callKeep.setup(<String, dynamic>{
      'ios': {
        'appName': 'appName'.tr(),
      },
      'android': {
        'alertTitle': 'Permissions required',
        'alertDescription':
            'This application needs to access your phone accounts',
        'cancelButton': 'Cancel',
        'okButton': 'ok',
      },
    });
  }

  @override
  void dispose() {
    tokenStream.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (FirebaseAuth.instance.currentUser() != null && currentUser != null) {
      if (state == AppLifecycleState.paused) {
        //user offline
        tokenStream.pause();
        currentUser.active = false;
        currentUser.lastOnlineTimestamp = Timestamp.now();
        FireStoreUtils.updateCurrentUser(currentUser);
      } else if (state == AppLifecycleState.resumed) {
        //user online
        tokenStream.resume();
        currentUser.active = true;
        FireStoreUtils.updateCurrentUser(currentUser);
      }
    }
  }
}

class OnBoarding extends StatefulWidget {
  @override
  State createState() {
    return OnBoardingState();
  }
}

class OnBoardingState extends State<OnBoarding> {
  Future hasFinishedOnBoarding() async {
    // 앱 안에 폴더에 저장할 데이터 생성 또는 이전에 저장된 데이터 불러오기
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool finishedOnBoarding = (prefs.getBool(FINISHED_ON_BOARDING) ?? false);

    // 이전 로그인 기록이 있으면 계정 정보에 따라 씬 이동
    if (finishedOnBoarding) {
      FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
      if (firebaseUser != null) {
        User user = await FireStoreUtils().getCurrentUser(firebaseUser.uid);
        if (user != null) {
          user.active = true;
          await FireStoreUtils.updateCurrentUser(user);
          MyAppState.currentUser = user;
          pushReplacement(context, new HomeScreen(user: user));
        } else {
          pushReplacement(context, new AuthScreen());
        }
      } else {
        pushReplacement(context, new AuthScreen());
      }
    } else {
      pushReplacement(context, new OnBoardingScreen());
    }
  }

  @override
  void initState() {
    super.initState();
    hasFinishedOnBoarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(COLOR_PRIMARY),
      body: Center(
        child: CircularProgressIndicator(
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

Future<dynamic> backgroundMessageHandler(Map<dynamic, dynamic> message) async {
  if (message.containsKey('data')) {
    // Handle data message
    final Map<dynamic, dynamic> data = message['data'];
    if (data.containsKey('callData')) {
      // Map<String, dynamic> callData = jsonDecode(data['callData']);
      callKeep.backToForeground();
      // callKeep.displayIncomingCall(
      //     callData['data']['from'],
      //     callData['callerName'],
      //     handleType: 'number',
      //     hasVideo: callData['callType'] == 'video');
    }
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }
}
