import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:instachatty/constants.dart';
import 'package:instachatty/services/helper.dart';
import 'package:instachatty/ui/login/LoginScreen.dart';
import 'package:instachatty/ui/signUp/SignUpScreen.dart';
import 'package:kakao_flutter_sdk/auth.dart';

// 카카오톡 https://kyungsnim.tistory.com/112 참고

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isKakaoTalkInstalled = false;

  _initKakaoTalkInstalled() async{
    final installed = await isKakaoTalkInstalled();
    print('kakao Install : ' + installed.toString());

    setState(() {
      _isKakaoTalkInstalled = installed;
    });
  }

  @override
  void initState() {
    super.initState();
    _initKakaoTalkInstalled();
  }

  @override
  Widget build(BuildContext context) {
    KakaoContext.clientId = '32b8163a175cce9a9db6a7eb7c53a801';
    KakaoContext.javascriptClientId = '83b33f0c933cc32b0416c82467ffbb9d';

    _issueAccessToken(String authCode) async{
      try{
        var token = await AuthApi.instance.issueAccessToken(authCode);
        AccessTokenStore.instance.toStore(token);
        print(token);
        push(context, LoginScreen());
      }catch(e){
        print('error on issuing access token: $e');
      }
    }

    _loginWithKakao() async{
      try{
        var code = await AuthCodeClient.instance.request();
        await _issueAccessToken(code);
      }catch(e){
        print(e);
      }
    }

    _loginWithTalk() async{
      try{
        var code = await AuthCodeClient.instance.requestWithTalk();
        await _issueAccessToken(code);
      }catch(e){
        print(e);
      }
    }

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
            // 기존 텍스트
            // Padding(
            //   padding: const EdgeInsets.only(
            //       left: 32, top: 32, right: 32, bottom: 8),
            //   child: Text(
            //     'welcome',
            //     textAlign: TextAlign.center,
            //     style: TextStyle(
            //         color: Color(COLOR_PRIMARY),
            //         fontSize: 24.0,
            //         fontWeight: FontWeight.bold),
            //   ).tr(),
            // ),
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: Text(
            //     'welcomeSubtitle',
            //     style: TextStyle(fontSize: 18),
            //     textAlign: TextAlign.center,
            //   ).tr(),
            // ),
            SignButtonWidget(
              title: 'logIn',
              onPressed: () {
                push(context, LoginScreen());
              },
            ),
            SignButtonWidget(
              title: 'signUp',
              onPressed: () {
                push(context, SignUpScreen());
              },
            ),
            Padding(
                padding:
                    const EdgeInsets.only(right: 40.0, left: 40.0, top: 40),
              child: RaisedButton(
                onPressed:
                  _isKakaoTalkInstalled ? _loginWithTalk : _loginWithKakao
                ,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignButtonWidget extends StatelessWidget {
  final String title;
  final Function onPressed;

  SignButtonWidget({@required this.title, @required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: double.infinity),
        child: RaisedButton(
          color: Color(COLOR_PRIMARY),
          child: Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ).tr(),
          textColor: isDarkMode(context) ? Colors.black : Colors.white,
          splashColor: Color(COLOR_PRIMARY),
          onPressed: onPressed,
          padding: EdgeInsets.only(top: 12, bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
              side: BorderSide(color: Color(COLOR_PRIMARY))),
        ),
      ),
    );
  }
}

// 원본 SignIn버튼
// Padding(
// padding: const EdgeInsets.only(
// right: 40.0, left: 40.0, top: 20, bottom: 20),
// child: ConstrainedBox(
// constraints: const BoxConstraints(minWidth: double.infinity),
// child: FlatButton(
// child: Text(
// 'signUp',
// style: TextStyle(
// fontSize: 20,
// fontWeight: FontWeight.bold,
// color: Color(COLOR_PRIMARY)),
// ).tr(),
// onPressed: () {
// push(context, SignUpScreen());
// },
// padding: EdgeInsets.only(top: 12, bottom: 12),
// shape: RoundedRectangleBorder(
// borderRadius: BorderRadius.circular(25.0),
// side: BorderSide(color: Colors.black54)),
// ),
// ),
// )