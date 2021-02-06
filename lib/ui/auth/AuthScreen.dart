import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:remote_private_tutoring/main.dart';
import 'package:remote_private_tutoring/ui/home/HomeScreen.dart';
import 'package:remote_private_tutoring/ui/login/LoginScreen.dart';
import 'package:remote_private_tutoring/ui/signUp/SignUpScreen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:remote_private_tutoring/constants.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:remote_private_tutoring/model/User.dart';
import 'package:remote_private_tutoring/services/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:remote_private_tutoring/services/FirebaseHelper.dart';
//import 'package:kakao_flutter_sdk/auth.dart';
//import 'package:kakao_flutter_sdk/user.dart' as kakaoUser;
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

// 카카오톡 https://theubermensch.tistory.com/66 참고

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _fireStoreUtils = FireStoreUtils();

  // -------------------- 페이스북 --------------------
  void _createUserFromFacebookLogin(
      FacebookLoginResult result, String userID) async {
    final token = result.accessToken.token;
    final graphResponse = await http.get('https://graph.facebook.com/v2'
        '.12/me?fields=name,first_name,last_name,email,picture.type(large)&access_token=$token');
    final profile = json.decode(graphResponse.body);
    User user = User(
        firstName: profile['first_name'],
        lastName: profile['last_name'],
        email: profile['email'],
        profilePictureURL: profile['picture']['data']['url'],
        fcmToken: await FireStoreUtils.firebaseMessaging.getToken(),
        active: true,
        userID: userID);
    await FireStoreUtils.firestore
        .collection(USERS)
        .document(userID)
        .setData(user.toJson())
        .then((onValue) {
      MyAppState.currentUser = user;
      hideProgress();
      pushAndRemoveUntil(context, HomeScreen(user: user), false);
    });
  }

  void _syncUserDataWithFacebookData(
      FacebookLoginResult result, User user) async {
    final token = result.accessToken.token;
    final graphResponse = await http.get('https://graph.facebook.com/v2'
        '.12/me?fields=name,first_name,last_name,email,picture.type(large)&access_token=$token');
    final profile = json.decode(graphResponse.body);
    user.profilePictureURL = profile['picture']['data']['url'];
    user.firstName = profile['first_name'];
    user.lastName = profile['last_name'];
    user.email = profile['email'];
    user.active = true;
    user.fcmToken = await FireStoreUtils.firebaseMessaging.getToken();
    await FireStoreUtils.updateCurrentUser(user);
    MyAppState.currentUser = user;
    hideProgress();
    pushAndRemoveUntil(context, HomeScreen(user: user), false);
  }
  // -------------------------------------------------

  // -------------------- 카카오톡 --------------------
  /*bool _isKakaoTalkInstalled = false;

  // 카카오톡 설치 여부 함수
  _initKakaoTalkInstalled() async {
    final installed = await isKakaoTalkInstalled();
    print('kakao Install : ' + installed.toString());

    setState(() {
      _isKakaoTalkInstalled = installed;
    });
  }

  // 카카오톡으로 로그인 했을 때 실제 유저 생성 함수
  _issueAccessToken(String authCode) async {
    try {
      var token = await AuthApi.instance.issueAccessToken(authCode);
      AccessTokenStore.instance.toStore(token);
      print(token);
      //push(context, LoginScreen());
    } catch (e) {
      print('error on issuing access token: $e');
    }
  }

  // 카카오톡이 설치되지 않았을 때의 로그인 함수
  _loginWithKakao() async {
    try {
      var code = await AuthCodeClient.instance.request();
      await _issueAccessToken(code);
    } on KakaoAuthException catch (e) {
      // some error happened during the course of user login... deal with it.
      print(e);
    } on KakaoClientException catch (e) {
      print(e);
    } catch (e) {
      print(e);
    }
  }

  // 카카오톡이 설치되어있을 때의 로그인 함수
  _loginWithTalk() async {
    try {
      var code = await AuthCodeClient.instance.requestWithTalk();
      await _issueAccessToken(code);
    } catch (e) {
      print(e);
    }
  }

  // 카카오톡 로그아웃
  logOutTalk() async {
    try {
      var code = await kakaoUser.UserApi.instance.logout();
      print(code.toString());
    } catch (e) {
      print(e);
    }
  }

  // 카카오톡 연결 끊기
  unlinkTalk() async {
    try {
      var code = await kakaoUser.UserApi.instance.unlink();
      print(code.toString());
    } catch (e) {
      print(e);
    }
  }*/
  // -------------------------------------------------

  @override
  void initState() {
    super.initState();
    //_initKakaoTalkInstalled();
  }

  @override
  Widget build(BuildContext context) {
    //KakaoContext.clientId = KAKAO_CLIENT_KEY;
    //KakaoContext.javascriptClientId = KAKAO_JAVASCRIPT_CLIENT_KEY;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 70.0, bottom: 20.0),
                child: SvgPicture.asset(
                  'assets/images/auth_image.svg',
                  width: 150.0,
                  height: 150.0,
                  color: Color(COLOR_PRIMARY),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // 카카오톡 로그인 - sdk 사용 방식
            AuthButtonWidget(
              title: '카카오톡으로 로그인',
              buttonColor: KAKAO_BUTTON_COLOR,
              image: 'assets/images/facebook_logo.png',
              onPressed: null // () => _isKakaoTalkInstalled ? _loginWithTalk : _loginWithKakao,
            ),

            // 페이스북 로그인
            AuthButtonWidget(
                title: 'facebookLogin',
                buttonColor: FACEBOOK_BUTTON_COLOR,
                image: 'assets/images/facebook_logo.png',
                onPressed: () async {
                  final facebookLogin = FacebookLogin();
                  final result = await facebookLogin.logIn(['email']);
                  switch (result.status) {
                    case FacebookLoginStatus.loggedIn:
                      showProgress(context, 'loggingInPleaseWait'.tr(), false);
                      await FirebaseAuth.instance
                          .signInWithCredential(
                              FacebookAuthProvider.getCredential(
                                  accessToken: result.accessToken.token))
                          .then((AuthResult authResult) async {
                        User user = await _fireStoreUtils
                            .getCurrentUser(authResult.user.uid);
                        if (user == null) {
                          _createUserFromFacebookLogin(
                              result, authResult.user.uid);
                        } else {
                          _syncUserDataWithFacebookData(result, user);
                        }
                      });
                      break;
                    case FacebookLoginStatus.cancelledByUser:
                      break;
                    case FacebookLoginStatus.error:
                      showAlertDialog(context, 'error'.tr(),
                          'couldNotLoginWithFacebook'.tr());
                      break;
                  }
                }),
            Padding(
              padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: double.infinity),
                child: RaisedButton(
                  color: Color(COLOR_PRIMARY),
                  child: Text(
                    'logIn',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ).tr(),
                  textColor: isDarkMode(context) ? Colors.black : Colors.white,
                  splashColor: Color(COLOR_PRIMARY),
                  onPressed: () {
                    push(context, LoginScreen());
                  },
                  padding: EdgeInsets.only(top: 12, bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      side: BorderSide(color: Color(COLOR_PRIMARY))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  right: 40.0, left: 40.0, top: 20, bottom: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: double.infinity),
                child: FlatButton(
                  child: Text(
                    'signUp',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(COLOR_PRIMARY)),
                  ).tr(),
                  onPressed: () {
                    push(context, SignUpScreen());
                  },
                  padding: EdgeInsets.only(top: 12, bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      side: BorderSide(color: Colors.black54)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class AuthButtonWidget extends StatelessWidget {
  final String title;
  final String image;
  final buttonColor;
  final Function onPressed;

  AuthButtonWidget(
      {@required this.title,
      @required this.buttonColor,
      @required this.image,
      @required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 40.0, left: 40.0, bottom: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: double.infinity),
        child: RaisedButton.icon(
          label: Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ).tr(),
          ),
          icon: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Image.asset(
              image,
              color: isDarkMode(context) ? Colors.black : Colors.white,
              height: 30,
              width: 30,
            ),
          ),
          color: Color(buttonColor),
          textColor: isDarkMode(context) ? Colors.black : Colors.white,
          splashColor: Color(buttonColor),
          onPressed: onPressed,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
              side: BorderSide(color: Color(buttonColor))),
        ),
      ),
    );
  }
}
