import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:remote_private_tutoring/constants.dart';
import 'package:remote_private_tutoring/main.dart';
import 'package:remote_private_tutoring/model/ConversationModel.dart';
import 'package:remote_private_tutoring/model/HomeConversationModel.dart';
import 'package:remote_private_tutoring/model/User.dart';
import 'package:remote_private_tutoring/services/FirebaseHelper.dart';
import 'package:remote_private_tutoring/services/helper.dart';
import 'package:remote_private_tutoring/ui/contacts/ContactsScreen.dart';
import 'package:remote_private_tutoring/ui/conversations/ConversationsScreen.dart';
import 'package:remote_private_tutoring/ui/createGroup/CreateGroupScreen.dart';
import 'package:remote_private_tutoring/ui/profile/ProfileScreen.dart';
import 'package:remote_private_tutoring/ui/search/SearchScreen.dart';
import 'package:remote_private_tutoring/ui/videoCall/VideoCallScreen.dart';
import 'package:remote_private_tutoring/ui/videoCallsGroupChat/VideoCallsGroupScreen.dart';
import 'package:remote_private_tutoring/ui/voiceCall/VoiceCallScreen.dart';
import 'package:remote_private_tutoring/ui/voiceCallsGroupChat/VoiceCallsGroupScreen.dart';
import 'package:provider/provider.dart';

enum DrawerSelection { Conversations, Contacts, Search, Profile }

class HomeScreen extends StatefulWidget {
  final User user;
  static bool onGoingCall = false;

  HomeScreen({Key key, @required this.user}) : super(key: key);

  @override
  _HomeState createState() {
    return _HomeState(user);
  }
}

class _HomeState extends State<HomeScreen> {
  final User user;
  DrawerSelection _drawerSelection = DrawerSelection.Conversations;
  String _appBarTitle = tr('conversations');

  _HomeState(this.user);

  Widget _currentWidget;

  @override
  void initState() {
    super.initState();
    _currentWidget = ConversationsScreen(
      user: user,
    );
    if (CALLS_ENABLED) _listenForCalls();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: user,
      child: Scaffold(
        // 홈 스크린에 메뉴 버튼 클릭 시 왼쪽에 나오는 위젯(드로워 = 서랍)
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Consumer<User>(
                builder: (context, user, _) {
                  // 드로워 머리 부분
                  return DrawerHeader(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        displayCircleImage(user.profilePictureURL, 75, false),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            user.fullName(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              user.email,
                              style: TextStyle(color: Colors.white),
                            )),
                      ],
                    ),
                    decoration: BoxDecoration(
                      color: Color(COLOR_PRIMARY),
                    ),
                  );
                },
              ),
              // Conversation 메뉴
              // ( ※ ListTile : 하나의 타일에 여러개 요소들을 배치할 수 있게 해주는 위젯 )
              ListTile(
                selected: _drawerSelection == DrawerSelection.Conversations,
                title: Text('conversations').tr(),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _drawerSelection = DrawerSelection.Conversations;
                    _appBarTitle = 'conversations'.tr();
                    _currentWidget = ConversationsScreen(
                      user: user,
                    );
                  });
                },
                leading: Icon(Icons.chat_bubble),
              ),
              // 친구목록? 채팅방? 메뉴
              ListTile(
                  selected: _drawerSelection == DrawerSelection.Contacts,
                  leading: Icon(Icons.contacts),
                  title: Text('contacts').tr(),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _drawerSelection = DrawerSelection.Contacts;
                      _appBarTitle = 'contacts'.tr();
                      _currentWidget = ContactsScreen(
                        user: user,
                      );
                    });
                  }),
              // 사용자 검색 메뉴
              ListTile(
                  selected: _drawerSelection == DrawerSelection.Search,
                  title: Text('search').tr(),
                  leading: Icon(Icons.search),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _drawerSelection = DrawerSelection.Search;
                      _appBarTitle = 'search'.tr();
                      _currentWidget = SearchScreen(
                        user: user,
                      );
                    });
                  }),
              // 프로필 메뉴
              ListTile(
                selected: _drawerSelection == DrawerSelection.Profile,
                leading: Icon(Icons.account_circle),
                title: Text('profile').tr(),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _drawerSelection = DrawerSelection.Profile;
                    _appBarTitle = 'profile'.tr();
                    _currentWidget = ProfileScreen(
                      user: user,
                    );
                  });
                },
              ),
            ],
          ),
        ),
        // ------------------- 상단 앱바 -------------------
        appBar: AppBar(
          title: Text(
            _appBarTitle,
            style: TextStyle(
                color:
                    isDarkMode(context) ? Colors.grey.shade200 : Colors.white,
                fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            _appBarTitle == 'conversations'.tr()
                ? IconButton(
                    icon: Icon(Icons.message),
                    onPressed: () {
                      push(context, CreateGroupScreen());
                    },
                    color: isDarkMode(context)
                        ? Colors.grey.shade200
                        : Colors.white,
                  )
                : Container(
                    height: 0,
                    width: 0,
                  )
          ],
          iconTheme: IconThemeData(
              color: isDarkMode(context) ? Colors.grey.shade200 : Colors.white),
          backgroundColor: Color(COLOR_PRIMARY),
          centerTitle: true,
        ),
        body: _currentWidget,
      ),
    );
  }

  void _listenForCalls() {
    Stream callStream = FireStoreUtils.firestore
        .collection(USERS)
        .document(user.userID)
        .collection(CALL_DATA)
        .snapshots();
    // ignore: cancel_subscriptions
    final callSubscription = callStream.listen((event) async {
      if (event.documents.isNotEmpty) {
        DocumentSnapshot callDocument = event.documents.first;
        if (callDocument.documentID != user.userID) {
          DocumentSnapshot userSnapShot = await FireStoreUtils.firestore
              .collection(USERS)
              .document(event.documents.first.documentID)
              .get();
          User caller = User.fromJson(userSnapShot.data);
          print('${caller.fullName()} called you');
          print('${callDocument.data['type'] ?? 'null'}');
          String type = callDocument.data['type'] ?? '';
          bool isGroupCall = callDocument.data['isGroupCall'] ?? false;
          String callType = callDocument.data['callType'] ?? '';
          Map<String, dynamic> connections =
              callDocument.data['connections'] ?? Map<String, dynamic>();
          List<dynamic> groupCallMembers =
              callDocument.data['members'] ?? <dynamic>[];
          if (type == 'offer') {
            if (callType == VIDEO) {
              if (isGroupCall) {
                if (!HomeScreen.onGoingCall &&
                    connections.keys.contains(getConnectionID(caller.userID)) &&
                    connections[getConnectionID(caller.userID)]['description']['type']
                        == 'offer') {
                  HomeScreen.onGoingCall = true;
                  List<User> members = [];
                  groupCallMembers.forEach((element) {
                    members.add(User.fromJson(element));
                  });
                  push(
                    context,
                    VideoCallsGroupScreen(
                        homeConversationModel: HomeConversationModel(
                            isGroupChat: true,
                            conversationModel: ConversationModel.fromJson(
                                callDocument.data['conversationModel']),
                            members: members),
                        isCaller: false,
                        caller: caller,
                        sessionDescription:
                            connections[getConnectionID(caller.userID)]
                                ['description']['sdp'],
                        sessionType: connections[getConnectionID(caller.userID)]
                            ['description']['type']),
                  );
                }
              } else {
                push(
                  context,
                  VideoCallScreen(
                      homeConversationModel: HomeConversationModel(
                          isGroupChat: false,
                          conversationModel: null,
                          members: [caller]),
                      isCaller: false,
                      sessionDescription: callDocument.data['data']
                          ['description']['sdp'],
                      sessionType: callDocument.data['data']['description']
                          ['type']),
                );
              }
            } else if (callType == VOICE) {
              if (isGroupCall) {
                if (!HomeScreen.onGoingCall &&
                    connections.keys.contains(getConnectionID(caller.userID)) &&
                    connections[getConnectionID(caller.userID)]['description']
                            ['type'] ==
                        'offer') {
                  HomeScreen.onGoingCall = true;
                  List<User> members = [];
                  groupCallMembers.forEach((element) {
                    members.add(User.fromJson(element));
                  });
                  push(
                    context,
                    VoiceCallsGroupScreen(
                        homeConversationModel: HomeConversationModel(
                            isGroupChat: true,
                            conversationModel: ConversationModel.fromJson(
                                callDocument.data['conversationModel']),
                            members: members),
                        isCaller: false,
                        caller: caller,
                        sessionDescription:
                            connections[getConnectionID(caller.userID)]
                                ['description']['sdp'],
                        sessionType: connections[getConnectionID(caller.userID)]
                            ['description']['type']),
                  );
                }
              } else {
                push(
                  context,
                  VoiceCallScreen(
                      homeConversationModel: HomeConversationModel(
                          isGroupChat: false,
                          conversationModel: null,
                          members: [caller]),
                      isCaller: false,
                      sessionDescription: callDocument.data['data']
                          ['description']['sdp'],
                      sessionType: callDocument.data['data']['description']
                          ['type']),
                );
              }
            }
          }
        } else {
          print('you called someone');
        }
      }
    });
    FirebaseAuth.instance.onAuthStateChanged.listen((event) {
      if (event == null) {
        callSubscription.cancel();
      }
    });
  }

  String getConnectionID(String friendID) {
    String connectionID;
    String selfID = MyAppState.currentUser.userID;
    if (friendID.compareTo(selfID) < 0) {
      connectionID = friendID + selfID;
    } else {
      connectionID = selfID + friendID;
    }
    return connectionID;
  }
}
