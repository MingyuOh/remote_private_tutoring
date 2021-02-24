import 'dart:io';
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
//import 'package:flutter_foreground_plugin/flutter_foreground_plugin.dart';
import 'package:wakelock/wakelock.dart';
import 'package:remote_private_tutoring/ui/documentViewer/documentHandler.dart';

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
  bool _isCallActive = true,
      _noteOn = false,
      _micOn = true,
      _speakerOn = true,
      _chatOn = true,
      _loadFile = false;
  ValueNotifier<bool> _fileOn = ValueNotifier(false);
  //ValueNotifier<Map<bool, bool>> _fileOn = ValueNotifier({false:false});
  MediaStream _localStream;
  DocumentHandler _documentHandler;

  bool testAnim = true;

  initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([]); // 상태바와 네비게이션바 감추는 함수
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    _documentHandler = DocumentHandler();

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

  */ /*Future<bool> startForegroundService() async {
    await FlutterForegroundPlugin.setServiceMethodInterval(seconds: 5);
    await FlutterForegroundPlugin.setServiceMethod(globalForegroundService);
    await FlutterForegroundPlugin.startForegroundService(
      holdWakeLock: false,
      onStarted: () {
        print('Foreground on Started');
      },
      onStopped: () {
        print('Foreground on Stopped');
      },
      title: 'Tcamera',
      content: 'Tcamera sharing your screen.',
      iconName: 'ic_stat_mobile_screen_share',
    );
    return true;
  }

  void globalForegroundService() {
    debugPrint('current datetime is ${DateTime.now()}');
  }*/ /*

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
                    flex: VIDEO_SCREEN_FLEX,
                    child: Row(children: [
                      // 화이트보드
                      Expanded(
                        flex: WHITEBOARD_SCREEN_FLEX,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 300.0,
                                height: 30.0,
                                color: Colors.grey[800],
                                child: InkWell(onTap: () async {
                                  _fileOn.value =
                                      await _documentHandler.loadFile();
                                  setState(() {
                                    _loadFile = !_loadFile;
                                  });
                                }),
                              ),
                            ),
                            Expanded(
                              child: Stack(children: [
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  bottom: 0,
                                  left: 0,
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: _fileOn,
                                    builder: (context, value, _) {
                                      if (_loadFile == true) {
                                        return _documentHandler.openFile(
                                            isLoadFile: value);
                                      } else {
                                        return Container();
                                      }
                                    },
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  //heightFactor: 500.0,
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: _fileOn,
                                    builder: (context, value, _) {
                                      return value
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                  IconButton(
                                                    icon: Icon(Icons.arrow_left),
                                                    iconSize: 70.0,
                                                    color: Colors.grey[300],
                                                    onPressed: () {
                                                      _documentHandler.changeDocumentPage(isNext: false);
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.arrow_right),
                                                    iconSize: 70.0,
                                                    color: Colors.grey[300],
                                                    onPressed: () {
                                                      _documentHandler.changeDocumentPage(isNext: true);
                                                    },
                                                  ),
                                                ])
                                          : Container();
                                    },
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),

                      // 화상화면
                      Expanded(
                        flex: VIDEO_SCREEN_AREA_FLEX,
                        child: Column(
                            children: skipNulls([
                          // ================== Remote Renderer ==================
                          // ======================= Start =======================
                          Expanded(
                              flex: REMOTE_VIDEO_SCREEN_FLEX,
                              child: Container(
                                  color: Colors
                                      .blueGrey)), //VideoScreenRenderer(renderer: _remoteRenderer)),
                          // ======================= End =======================

                          // ================== Local Renderer ===================
                          // ======================= Start =======================
                          Expanded(
                              flex: LOCAL_VIDEO_SCREEN_FLEX,
                              child: Container(
                                  color: Colors
                                      .deepPurple)) //VideoScreenRenderer(renderer: _localRenderer))
                          // ======================= End =======================
                        ])),
                      ),
                    ]),
                  ),
                  Expanded(
                    flex: MENU_VIDEO_SCREEN_FLEX,
                    child: Container(
                      color: Colors.grey[900],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 채팅 FloatingButton
                          FloatingActionButton(
                            backgroundColor: Colors.blueAccent,
                            heroTag: 'chatFAB',
                            child: Icon(_chatOn ? Icons.chat : Icons.close),
                            onPressed: _chatToggle,
                          ),

                          SizedBox(width: 30),

                          FloatingActionButton(
                            backgroundColor: Color(COLOR_ACCENT),
                            heroTag: 'speakerFAB',
                            child: Icon(_speakerOn
                                ? Icons.volume_up
                                : Icons.volume_off),
                            onPressed: _speakerToggle,
                          ),

                          SizedBox(width: 30),

                          FloatingActionButton(
                            heroTag: 'hangupFAB',
                            onPressed: () => _hangUp(),
                            tooltip: 'hangup'.tr(),
                            child: Icon(Icons.call_end),
                            backgroundColor: Colors.pink,
                          ),

                          SizedBox(width: 30),

                          FloatingActionButton(
                            backgroundColor: Color(COLOR_ACCENT),
                            heroTag: 'micFAB',
                            child: Icon(_micOn ? Icons.mic : Icons.mic_off),
                            onPressed: _micToggle,
                          )
                        ],
                      ),
                    ),
                  ),
                ]), // 앱 전체 - End
              )
            /*: Stack(
                    // 노트 PDF, PPT 등 + 펜 + Sharing screen
                    children: [
                      _documentHandler.openFile(isLoadFile: _fileOn.value),
                      // 화면
                      Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _fileOn,
                            builder: (context, value, _) {
                              if (_loadFile == true) {
                                return _documentHandler.openFile(isLoadFile: value);
                              } else
                                return Container();
                            },
                          )
                      ),

                      // 뒤로가기 버튼
                      Positioned(
                        top: 10,
                        left: 10,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back),
                          iconSize: 30.0,
                          color: Colors.white54,
                          onPressed: () async {
                            setState(() {
                              _isVideoActive = true;
                            });
                            _documentHandler.releaseDocument();
                          },
                        ),
                      ),

                      // 파일 버튼(Test 용)
                      Positioned(
                        right: 20.0,
                        bottom: 10.0,
                        child: FloatingActionButton(
                            heroTag: 'fileLoadFAB',
                            child: Icon(
                                _loadFile
                                    ? Icons.upload_file
                                    : Icons.insert_drive_file,
                                color: Colors.white),
                            backgroundColor: Colors.purpleAccent,
                            onPressed: () async {
                              _fileOn.value = await _documentHandler.loadFile();

                              setState(() {
                                _loadFile = !_loadFile;
                              });
                            }),
                      ),
                    ],
                  )*/

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
                          widget.homeConversationModel.members.first
                              .profilePictureURL,
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
                                  _signaling.acceptCall(
                                      widget.sessionDescription,
                                      widget.sessionType);
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
}

bool equalsIgnoreCase(String a, String b) =>
    (a == null && b == null) ||
    (a != null && b != null && a.toLowerCase() == b.toLowerCase());

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
