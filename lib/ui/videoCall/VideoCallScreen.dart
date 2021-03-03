import 'dart:ui';
import 'dart:core';
//import 'dart:io' show Platform;
import 'package:flutter/services.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:remote_private_tutoring/constants.dart';
import 'package:remote_private_tutoring/model/HomeConversationModel.dart';
import 'package:remote_private_tutoring/services/helper.dart';
import 'package:remote_private_tutoring/ui/videoCall/VideoCallsHandler.dart';
import 'package:wakelock/wakelock.dart';
import 'package:remote_private_tutoring/ui/whiteboard/whiteboardHandler.dart';
import 'package:remote_private_tutoring/ui/pen/penHandler.dart';
import 'package:painter/painter.dart';

class VideoCallScreen extends StatefulWidget {
  final HomeConversationModel homeConversationModel;
  final bool isCaller;
  final String sessionDescription;
  final String sessionType;

  const VideoCallScreen(
      {Key key,
      @required this.homeConversationModel,
      @required this.isCaller,
      @required this.sessionDescription,
      @required this.sessionType})
      : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  VideoCallsHandler _signaling;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer(); // 자신 화면
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer(); // 상대방 화면
  MediaStream _localStream;
  bool _isCallActive = true,
      _micOn = true,
      _speakerOn = true,
      _chatOn = true,
      _loadedFile = false;
  ValueNotifier<bool> _fileOn = ValueNotifier(false);
  List<bool> buttonState = List(VIDEO_SCREEN_BUTTON_COUNT);
  int selectedButton = 2;
  WhiteboardHandler _whiteboardHandler;

  bool testAnim = true;

  initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([]); // 상태바와 네비게이션바 감추는 함수
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    _whiteboardHandler = WhiteboardHandler();

    /*if (!widget.isCaller) {
      // 전화를 받을 사람일 경우
      FlutterRingtonePlayer.playRingtone();
      print('_VideoCallScreenState.initState');
    }
    initRenderers(); // 원격화면 초기화
    _connect();
    if (!widget.isCaller) {
      // 전화를 받을 사람일 경우
      _signaling.listenForMessages();

      _signaling.startCountDown(context);
      _signaling.setupOnRemoteHangupListener(context);
    }
    Wakelock.enable();*/
  }

  /*initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  deactivate() {
    super.deactivate();
    if (_signaling != null)
      _signaling.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  @override
  void dispose() {
    _signaling.hangupSub.cancel();
    _signaling.countdownTimer.cancel();
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    if (!widget.isCaller) {
      print('FlutterRingtonePlayer dispose lets stop');
      FlutterRingtonePlayer.stop();
    }
    super.dispose();
    Wakelock.disable();
  }

  void _connect() async {
    if (_signaling == null) {
      _signaling = VideoCallsHandler(
          isCaller: widget.isCaller,
          homeConversationModel: widget.homeConversationModel);

      _signaling.onStateChange = (SignalingState state) {
        switch (state) {
          case SignalingState.CallStateNew:
            break;
          case SignalingState.CallStateBye:
            this.setState(() {
              _localRenderer.srcObject = null;
              _remoteRenderer.srcObject = null;
              _isCallActive = false;
            });
            break;
          case SignalingState.CallStateInvite:
          case SignalingState.CallStateConnected:
            {
              if (mounted)
                setState(() {
                  _isCallActive = true;
                });
              break;
            }
          case SignalingState.CallStateRinging:
          case SignalingState.ConnectionClosed:
          case SignalingState.ConnectionError:
          case SignalingState.ConnectionOpen:
            break;
        }
      };
      _signaling.onLocalStream = ((stream) {
        if (mounted) {
          _localStream = stream;
          _localStream.getAudioTracks()[0].enableSpeakerphone(_speakerOn);
          _localStream.getAudioTracks()[0].setMicrophoneMute(!_micOn);
          setState(() {
            _localRenderer.srcObject = _localStream;
          });
        }
      });

      _signaling.onAddRemoteStream = ((stream) {
        if (mounted)
          setState(() {
            _isCallActive = true;
            _remoteRenderer.srcObject = stream;
          });
      });

      _signaling.onRemoveRemoteStream = ((stream) {
        if (mounted)
          setState(() {
            _isCallActive = false;
            _remoteRenderer.srcObject = null;
          });
      });
      if (widget.isCaller)
        _signaling.initCall(widget.homeConversationModel.members.first.fcmToken,
            widget.homeConversationModel.members.first.userID, context);
    }
  }*/

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).unfocus();
    return Material(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: _isCallActive
            ? Column(
                children: skipNulls([
                  Expanded(
                    flex: TOP_MENU_VIDEO_SCREEN_FLEX,
                    child: Container(
                      color: Colors.grey[900],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 와이파이 시간
                          Row(
                            children: [
                              Icon(Icons.wifi, color: Colors.white),
                              SizedBox(width: 10),
                              Text('00 : 00',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),

                          // 펜 기능 메뉴
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 파일 버튼
                              MenuButton(
                                icon: Icons.insert_drive_file,
                                name: '파일',
                                color: selectedButton == 1 ? Colors.black : Colors.white,
                                splashColor: Colors.grey,
                                backgroundColor: selectedButton == 1 ? Colors.white : Colors.grey[900],
                                onPressed: () async {
                                  // 이미 불러온 파일이 있을 경우 초기화
                                  if (_loadedFile == true) {
                                    _loadedFile = false;
                                    _whiteboardHandler.documentHandler.releaseDocument();
                                  }
                                  // 파일 선택
                                  _loadedFile = await _whiteboardHandler.documentHandler.selectFile();
                                },
                              ),

                              // 펜 버튼
                              DropDownMenuButton(
                                icon: Icons.create_outlined,
                                name: '펜',
                                color: selectedButton == 2 ? Colors.black : Colors.white,
                                backgroundColor: selectedButton == 2 ? Colors.white : Colors.grey[900],
                                dropDownBackgroundColor: Colors.grey[900],
                                onPressed: () {
                                  _whiteboardHandler.penHandler.controller.eraseMode = false;
                                  _buttonToggle(menuNumber: 2);
                                },
                                bodyBuilderWidget: PenListItems(controller: _whiteboardHandler.penHandler.controller),
                              ),

                              // 지우개 버튼
                              MenuButton(
                                icon: Icons.auto_fix_high,
                                name: '지우개',
                                color: selectedButton == 3 ? Colors.black : Colors.white,
                                backgroundColor: selectedButton == 3 ? Colors.white : Colors.grey[900],
                                onPressed: () {
                                  _whiteboardHandler.penHandler.controller.eraseMode = true;
                                  _buttonToggle(menuNumber: 3);
                                },
                              ),

                              // 클리어 버튼
                              MenuButton(
                                icon: Icons.fiber_new,
                                name: '초기화',
                                color: Colors.white,
                                splashColor: Colors.grey,
                                backgroundColor: Colors.grey[900],
                                onPressed: () {
                                  _whiteboardHandler.penHandler.controller.clear();
                                },
                              ),

                              // 이전 버튼
                              MenuButton(
                                icon: Icons.undo,
                                name: '이전',
                                color: Colors.white,
                                splashColor: Colors.grey,
                                backgroundColor: Colors.grey[900],
                                onPressed: () {
                                  _whiteboardHandler.penHandler.controller.undo();
                                },
                              ),
                            ],
                          ),

                          // 수업 종료 버튼
                          RaisedButton(
                            color: Colors.grey[900],
                            child: Text('수업 종료',
                                style: TextStyle(color: Colors.pink, fontSize: 15.0)),
                            onPressed: () => _hangUp(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 화이트보드 및 영상
                  Expanded(
                    flex: VIDEO_SCREEN_FLEX,
                    child: Row(children: [
                      // 화상화면
                      Expanded(
                        flex: VIDEO_SCREEN_AREA_FLEX,
                        child: Container(
                          color: Colors.black,
                          child: Column(
                              children: skipNulls([
                            // ================== Remote Renderer ==================
                            // ======================= Start =======================
                            Expanded(
                              flex: REMOTE_VIDEO_SCREEN_FLEX,
                              child: Container(
                                color: Colors.black,
                                child: Center(
                                  child: Text('선생님이 입장하지 않았습니다.',
                                      style: TextStyle(color: Colors.white, fontSize: 10.0)),
                                ),
                              ),
                            ), //VideoScreenRenderer(renderer: _remoteRenderer)),
                            // ======================= End ========================

                            Divider(height: 1, indent: 5, endIndent: 5, color: Colors.white),

                            // ================== Local Renderer ===================
                            // ======================= Start =======================
                            Expanded(
                              flex: LOCAL_VIDEO_SCREEN_FLEX,
                              child: Container(
                                color: Colors.black,
                                child: Center(
                                  child: Text('학생이 입장하지 않았습니다.',
                                      style: TextStyle(color: Colors.white, fontSize: 10.0)),
                                ),
                              ),
                            ) //VideoScreenRenderer(renderer: _localRenderer))
                            // ======================= End =======================
                          ])),
                        ),
                      ),

                      // 화이트보드
                      Expanded(
                        flex: WHITEBOARD_SCREEN_FLEX,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 화이트보드
                              Expanded(
                                child: Stack(
                                    children: skipNulls([
                                  _loadedFile
                                      ? Positioned(
                                          top: 0,
                                          right: 0,
                                          bottom: 0,
                                          left: 0,
                                          child: FutureBuilder(
                                            future: _whiteboardHandler.documentHandler.loadFile().then((isLoad) => _fileOn.value = isLoad),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData == true) {
                                                return _whiteboardHandler.documentHandler.openFile();
                                              } else {
                                                return Center(child: CircularProgressIndicator());
                                              }
                                            },
                                          ))
                                      : Container(),
                                  Painter(_whiteboardHandler.penHandler.controller),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: _fileOn,
                                      builder: (context, value, _) {
                                        return value
                                            ? Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                    IconButton(
                                                      icon: Icon(Icons.arrow_left),
                                                      iconSize: 70.0,
                                                      color: Colors.grey[300],
                                                      onPressed: () {
                                                        _whiteboardHandler.documentHandler.changeDocumentPage(isNext: false);
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.arrow_right),
                                                      iconSize: 70.0,
                                                      color: Colors.grey[300],
                                                      onPressed: () {
                                                        _whiteboardHandler.documentHandler.changeDocumentPage(isNext: true);
                                                      },
                                                    ),
                                                  ])
                                            : Container();
                                      },
                                    ),
                                  ),
                                ])),
                              ),
                            ]),
                      ),
                    ]),
                  ),

                  Expanded(
                    flex: BOTTOM_MENU_VIDEO_SCREEN_FLEX,
                    child: Container(
                      color: Colors.grey[900],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 채팅 버튼
                          MenuButton(
                              color: Colors.white,
                              splashColor: Colors.grey,
                              backgroundColor: Colors.grey[900],
                              icon: Icons.chat,
                              name: '채팅',
                              onPressed: _chatToggle),

                          SizedBox(width: 20),

                          // 스피커 버튼
                          MenuButton(
                              color: Colors.white,
                              splashColor: Colors.grey,
                              backgroundColor: Colors.grey[900],
                              icon: _speakerOn
                                  ? Icons.volume_up
                                  : Icons.volume_off,
                              name: '스피커',
                              onPressed: _speakerToggle),

                          SizedBox(width: 20),

                          // 마이크 버튼
                          MenuButton(
                              color: Colors.white,
                              splashColor: Colors.grey,
                              backgroundColor: Colors.grey[900],
                              icon: _micOn ? Icons.mic : Icons.mic_off,
                              name: '마이크',
                              onPressed: _micToggle),
                        ],
                      ),
                    ),
                  ),
                ]), // 앱 전체 - End
              )

            // 현재 통화 연결이 안되었을 때
            : Stack(
                children: skipNulls([
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(widget.homeConversationModel.members
                            .first.profilePictureURL),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        decoration:
                            BoxDecoration(color: Colors.black.withOpacity(0.3)),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: skipNulls([
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: SizedBox(width: double.infinity),
                      ),
                      displayCircleImage(
                          widget.homeConversationModel.members.first.profilePictureURL,
                          75,
                          true),
                      SizedBox(height: 10),
                      Text(
                        widget.isCaller
                            ? 'videoCallingName'.tr(args: [
                                '${widget.homeConversationModel.members.first.fullName()}'
                              ])
                            : 'isVideoCalling'.tr(args: [
                                '${widget.homeConversationModel.members.first.fullName()}'
                              ]),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ]),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: skipNulls([
                        widget.isCaller
                            ? null
                            : FloatingActionButton(
                                backgroundColor: Colors.green,
                                heroTag: 'answerFAB',
                                child: Icon(Icons.call),
                                onPressed: () {
                                  FlutterRingtonePlayer.stop();
                                  _signaling.countdownTimer.cancel();
                                  _signaling.acceptCall(widget.sessionDescription, widget.sessionType);
                                  setState(() {
                                    _isCallActive = true;
                                  });
                                }),
                        FloatingActionButton(
                          heroTag: 'hangupFAB',
                          onPressed: () => _hangUp(),
                          tooltip: 'hangup'.tr(),
                          child: Icon(Icons.call_end),
                          backgroundColor: Colors.pink,
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
      ),
    );
  }

  // 전화 끊을 때 실행되는 함수
  _hangUp() {
    if (_signaling != null) {
      _signaling.countdownTimer.cancel();
      _whiteboardHandler.releaseWhiteboard();
      _signaling.bye();
    }
    if (!widget.isCaller) {
      print('FlutterRingtonePlayer _hangUp lets stop');
      FlutterRingtonePlayer.stop();
    }
    Navigator.pop(context);
  }

  // 마이크 on/off
  _micToggle() {
    setState(() {
      _micOn = _micOn ? false : true;
      _localStream.getAudioTracks()[0].setMicrophoneMute(!_micOn);
    });
  }

  // 스피커 on/off
  _speakerToggle() {
    setState(() {
      _speakerOn = _speakerOn ? false : true;
      _localStream.getAudioTracks()[0].enableSpeakerphone(_speakerOn);
    });
  }

  // 채팅 on/off
  _chatToggle() {
    setState(() {
      _chatOn = _chatOn ? false : true;
    });
  }

  // 버튼 토글
  _buttonToggle({int menuNumber}) {
    setState(() {
      (selectedButton == menuNumber) ? selectedButton = 0 : selectedButton = menuNumber;
    });
  }
}

class VideoScreenRenderer extends StatelessWidget {
  VideoScreenRenderer({@required this.renderer});

  final RTCVideoRenderer renderer;

  @override
  Widget build(BuildContext context) {
    return (renderer != null)
        // 수정해야함
        ? Container(
            margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
            /*child: RTCVideoView(
            _remoteRenderer,
            //mirror: _isVideoActive,
            objectFit: RTCVideoViewObjectFit
                .RTCVideoViewObjectFitCover,
          ),*/
            decoration: BoxDecoration(color: Color(COLOR_PRIMARY)),
          )
        : null;
  }
}
