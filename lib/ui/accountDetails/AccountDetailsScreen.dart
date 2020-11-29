import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:instachatty/constants.dart';
import 'package:instachatty/main.dart';
import 'package:instachatty/model/User.dart';
import 'package:instachatty/services/FirebaseHelper.dart';
import 'package:instachatty/services/helper.dart';

class AccountDetailsScreen extends StatefulWidget {
  final User user;

  AccountDetailsScreen({Key key, @required this.user}) : super(key: key);

  @override
  _AccountDetailsScreenState createState() {
    return _AccountDetailsScreenState(user);
  }
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  User user;
  GlobalKey<FormState> _key = new GlobalKey();
  bool _validate = false;
  String firstName, email, mobile, lastName;
  TextEditingController _firstNameController = new TextEditingController();
  TextEditingController _lastNameController = new TextEditingController();
  TextEditingController _emailController = new TextEditingController();
  TextEditingController _phoneController = new TextEditingController();

  _AccountDetailsScreenState(this.user);

  @override
  Widget build(BuildContext context) {
    if (!_validate) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber;
    }

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(COLOR_PRIMARY),
          iconTheme: IconThemeData(
              color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white),
          title: Text(
            'accountDetails',
            style: TextStyle(
                color:
                    isDarkMode(context) ? Colors.grey.shade200 : Colors.white,
                fontWeight: FontWeight.bold),
          ).tr(),
          centerTitle: true,
        ),
        body: Builder(
            builder: (buildContext) => SingleChildScrollView(
              child: Form(
                key: _key,
                autovalidate: _validate,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16, bottom: 8, top: 24),
                        child: Text(
                          'publicInfo',
                          style:
                          TextStyle(fontSize: 16, color: Colors.grey),
                        ).tr(),
                      ),
                      Material(
                          elevation: 2,
                          color: isDarkMode(context)
                              ? Colors.black54
                              : Colors.white,
                          child: ListView(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              children: ListTile.divideTiles(
                                  context: buildContext,
                                  // Profile Info 부분
                                  tiles: [
                                    // FristName 타일
                                    ListTile(
                                      title: Text(
                                        'firstName',
                                        style: TextStyle(
                                          color: isDarkMode(context)
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ).tr(),
                                      trailing: ConstrainedBox(
                                        constraints:
                                        BoxConstraints(maxWidth: 100),
                                        child: TextFormField(
                                          onSaved: (String val) {
                                            firstName = val;
                                          },
                                          validator: validateName,
                                          textAlign: TextAlign.end,
                                          controller: _firstNameController,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black),
                                          cursorColor: Color(COLOR_ACCENT),
                                          textCapitalization:
                                          TextCapitalization.words,
                                          keyboardType: TextInputType.text,
                                          decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'firstName'.tr(),
                                              contentPadding:
                                              EdgeInsets.symmetric(
                                                  vertical: 5)),
                                        ),
                                      ),
                                    ),
                                    // LastName 타일
                                    ListTile(
                                      title: Text(
                                        'lastName',
                                        style: TextStyle(
                                            color: isDarkMode(context)
                                                ? Colors.white
                                                : Colors.black),
                                      ).tr(),
                                      trailing: ConstrainedBox(
                                        constraints:
                                        BoxConstraints(maxWidth: 100),
                                        child: TextFormField(
                                          onSaved: (String val) {
                                            lastName = val;
                                          },
                                          validator: validateName,
                                          textAlign: TextAlign.end,
                                          controller: _lastNameController,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black),
                                          cursorColor: Color(COLOR_ACCENT),
                                          textCapitalization:
                                          TextCapitalization.words,
                                          keyboardType: TextInputType.text,
                                          decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'lastName'.tr(),
                                              contentPadding:
                                              EdgeInsets.symmetric(
                                                  vertical: 5)),
                                        ),
                                      ),
                                    )
                                  ]).toList())),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16, bottom: 8, top: 24),
                        child: Text(
                          'privateDetails',
                          style:
                          TextStyle(fontSize: 16, color: Colors.grey),
                        ).tr(),
                      ),
                      Material(
                        elevation: 2,
                        color: isDarkMode(context)
                            ? Colors.black54
                            : Colors.white,
                        child: ListView(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            children: ListTile.divideTiles(
                              context: buildContext,
                              // Private Detail 부분
                              tiles: [
                                // 이메일 타일
                                ListTile(
                                  title: Text(
                                    'emailAddress',
                                    style: TextStyle(
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black),
                                  ).tr(),
                                  trailing: ConstrainedBox(
                                    constraints:
                                    BoxConstraints(maxWidth: 200),
                                    child: TextFormField(
                                      onSaved: (String val) {
                                        email = val;
                                      },
                                      validator: validateEmail,
                                      controller: _emailController,
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: isDarkMode(context)
                                              ? Colors.white
                                              : Colors.black),
                                      cursorColor: Color(COLOR_ACCENT),
                                      keyboardType:
                                      TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'emailAddress'.tr(),
                                          contentPadding:
                                          EdgeInsets.symmetric(
                                              vertical: 5)),
                                    ),
                                  ),
                                ),
                                // 핸드폰번호 타일
                                ListTile(
                                  title: Text(
                                    'phoneNumber',
                                    style: TextStyle(
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black),
                                  ).tr(),
                                  trailing: ConstrainedBox(
                                    constraints:
                                    BoxConstraints(maxWidth: 150),
                                    child: TextFormField(
                                      onSaved: (String val) {
                                        mobile = val;
                                      },
                                      validator: validateMobile,
                                      controller: _phoneController,
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: isDarkMode(context)
                                              ? Colors.white
                                              : Colors.black),
                                      cursorColor: Color(COLOR_ACCENT),
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'phoneNumber'.tr(),
                                          contentPadding:
                                          EdgeInsets.only(bottom: 2)),
                                    ),
                                  ),
                                ),
                              ],
                            ).toList()),
                      ),
                      // 저장 버튼
                      Padding(
                          padding:
                          const EdgeInsets.only(top: 32.0, bottom: 16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                minWidth: double.infinity),
                            child: Material(
                              elevation: 2,
                              color: isDarkMode(context)
                                  ? Colors.black54
                                  : Colors.white,
                              child: CupertinoButton(
                                padding: const EdgeInsets.all(12.0),
                                // 저장 버튼 클릭 시 이벤트
                                onPressed: () async {
                                  _validateAndSave(buildContext);
                                },
                                child: Text(
                                  'save',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Color(COLOR_PRIMARY)),
                                ).tr(),
                              ),
                            ),
                          )),
                    ]),
              ),
            )));
  }

  _validateAndSave(BuildContext buildContext) async {
    if (_key.currentState.validate()) {
      _key.currentState.save();
      if (user.email != email) {
        TextEditingController _passwordController = new TextEditingController();
        showDialog(
            context: context,
            child: Dialog(
              elevation: 16,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40)),
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'changeEmailSecurityMessage',
                        style: TextStyle(color: Colors.red, fontSize: 17),
                        textAlign: TextAlign.start,
                      ).tr(),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                              hintText: 'password'.tr()),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: RaisedButton(
                          color: Color(COLOR_ACCENT),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(12))),
                          onPressed: () async {
                            if (_passwordController.text.isEmpty) {
                              showAlertDialog(context, "emptyPassword".tr(),
                                  "passwordRequiredToUpdateEmail".tr());
                            } else {
                              Navigator.pop(context);
                              showProgress(context, 'verifying'.tr(), false);
                              AuthResult result = await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                  email: user.email,
                                  password: _passwordController.text)
                                  .catchError((onError) {
                                hideProgress();
                                showAlertDialog(context, 'couldNotVerify'.tr(),
                                    'doubleCheckPassword'.tr());
                              });
                              _passwordController.dispose();
                              if (result.user != null) {
                                await result.user.updateEmail(email);
                                updateProgress('savingDetails'.tr());
                                await _updateUser(buildContext);
                                hideProgress();
                              } else {
                                hideProgress();
                                Scaffold.of(buildContext).showSnackBar(SnackBar(
                                    content: Text(
                                      'couldNotVerifyPleaseTryAgain'.tr(),
                                      style: TextStyle(fontSize: 17),
                                    )));
                              }
                            }
                          },
                          child: Text(
                            'verify',
                            style: TextStyle(color: Colors.white),
                          ).tr(),
                        ),
                      )
                    ],
                  )),
            ));
      } else {
        showProgress(context, "savingDetails".tr(), false);
        await _updateUser(buildContext);
        hideProgress();
      }
    } else {
      setState(() {
        _validate = true;
      });
    }
  }

  _updateUser(BuildContext buildContext) async {
    user.firstName = firstName;
    user.lastName = lastName;
    user.email = email;
    user.phoneNumber = mobile;
    var updatedUser = await FireStoreUtils.updateCurrentUser(user);
    if (updatedUser != null) {
      MyAppState.currentUser = user;
      Scaffold.of(buildContext).showSnackBar(SnackBar(
          content: Text(
            'detailsSavedSuccessfully',
            style: TextStyle(fontSize: 17),
          ).tr()));
    } else {
      Scaffold.of(buildContext).showSnackBar(SnackBar(
          content: Text(
            'couldNotSaveDetailsPleaseTryAgain',
            style: TextStyle(fontSize: 17),
          ).tr()));
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
