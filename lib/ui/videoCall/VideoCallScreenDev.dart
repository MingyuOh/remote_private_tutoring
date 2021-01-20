import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:remote_private_tutoring/constants.dart';
import 'package:remote_private_tutoring/model/HomeConversationModel.dart';
import 'package:remote_private_tutoring/services/helper.dart';
import 'package:remote_private_tutoring/ui/videoCall/VideoCallsHandler.dart';
import 'package:remote_private_tutoring/model/ChatModel.dart';
import 'package:wakelock/wakelock.dart';

class VideoCallScreenDev extends StatefulWidget {
  final HomeConversationModel homeConversationModel;
  final bool isCaller;
  final String sessionDescription;
  final String sessionType;

  const VideoCallScreenDev(
      {Key key,
      @required this.homeConversationModel,
      @required this.isCaller,
      @required this.sessionDescription,
      @required this.sessionType})
      : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreenDev> {
  VideoCallsHandler _signaling;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer(); // 자신 화면
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer(); // 상대방 화면
  bool _isCallActive = true, _micOn = true, _speakerOn = true;
  MediaStream _localStream;
  ChatModel chatModel;
  String message = '이것은 화상통화에서 사용될 테스트 텍스트입니다.';

  initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([]); // 상태바와 네비게이션바 감추는 함수
    /*if (!widget.isCaller) {
      // 전화를 받을 사람일 경우
      FlutterRingtonePlayer.playRingtone();
      print('_VideoCallScreenState.initState');
    }
    initRenderers(); // 원격화면 초기화
    _connect(); //
    if (!widget.isCaller) {
      // 전화를 받을 사람일 경우
      _signaling.listenForMessages();

      _signaling.startCountDown(context);
      _signaling.setupOnRemoteHangupListener(context);
    }
    Wakelock.enable();*/
  }
  /*
  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  deactivate() {
    super.deactivate();
    if (_signaling != null) _signaling.close();
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
    //SystemChrome.setEnabledSystemUIOverlays([]);

    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    bool isRemote = true;
    Color activeColor = Colors.redAccent;

    return Material(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Row(
          children: [
            // 왼쪽 메뉴
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.blueAccent,
                child: Column(
                  children: [
                    // 화상 탭(아이콘 및 텍스트)
                    Expanded(
                      flex: 5,
                      child: Container(
                        width: double.infinity,
                        color: activeColor,
                        child: InkWell(
                          onTap: () {
                            isRemote = true;
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                IconData(0xeab3, fontFamily: 'MaterialIcons'),
                                color: Colors.white,
                                size: 30.0,
                              ),
                              Text(
                                '화상',
                                style: TextStyle(
                                    fontSize: 10.0, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 노트 탭(아이콘 및 텍스트)
                    Expanded(
                      flex: 5,
                      child: Container(
                        width: double.infinity,
                        color: Colors.black,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              IconData(0xe70a,
                                  fontFamily: 'MaterialIcons',
                                  matchTextDirection: true),
                              color: Colors.white,
                              size: 30.0,
                            ),
                            Text(
                              '노트',
                              style: TextStyle(
                                  fontSize: 10.0, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 화상화면
            Expanded(
              flex: 6,
              child: Stack(
                  children: skipNulls([
                // ================== Remote Renderer ==================
                // ======================= Start =======================
                _isCallActive
                    ? Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                          /*child: RTCVideoView(
                            _remoteRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                          ),*/
                          decoration:
                              BoxDecoration(color: Color(COLOR_PRIMARY)),
                        ),
                      )
                    : null,
                // ======================= End =======================

                Positioned(
                  bottom: 40,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: skipNulls(
                      [
                        widget.isCaller || _isCallActive
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
                        _isCallActive
                            ? FloatingActionButton(
                                backgroundColor: Color(COLOR_ACCENT),
                                heroTag: 'speakerFAB',
                                child: Icon(_speakerOn
                                    ? Icons.volume_up
                                    : Icons.volume_off),
                                onPressed: _speakerToggle,
                              )
                            : null,
                        FloatingActionButton(
                          heroTag: 'hangupFAB',
                          onPressed: () => _hangUp(),
                          tooltip: 'hangup'.tr(),
                          child: Icon(Icons.call_end),
                          backgroundColor: Colors.pink,
                        ),
                        _isCallActive
                            ? FloatingActionButton(
                                backgroundColor: Color(COLOR_ACCENT),
                                heroTag: 'micFAB',
                                child: Icon(_micOn ? Icons.mic : Icons.mic_off),
                                onPressed: _micToggle,
                              )
                            : null
                      ],
                    ),
                  ),
                ),
              ])),
            ),

            // 내 화면 및 채팅
            Expanded(
              flex: 3,
              child: Column(
                  children: [
                // ================== Local Renderer ===================
                // ======================= Start =======================
                _isCallActive
                    ? Expanded(
                      flex: 4,
                      child: Container(
                          color: Colors.black,
                                /*child: RTCVideoView(
                                  _localRenderer,
                                  mirror: true,
                                  objectFit: RTCVideoViewObjectFit
                                      .RTCVideoViewObjectFitCover,
                                ),*/
                        ),
                    )
                    : null,
                // ======================= End =======================,

                // 채팅 - 여기서부터 ChatScreen Code Load
                Expanded(
                  flex: 6,
                  child: Container(
                      child: _isCallActive
                          ? Column(children: [
                              Expanded(
                                child: Container(
                                  color: Colors.black26,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    IconButton(
                                      icon: Icon(
                                        Icons.camera_alt,
                                        color: Color(COLOR_PRIMARY),
                                      ),
                                    ),
                                    Expanded(
                                        child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 2.0, right: 2),
                                            child: Container(
                                              padding: EdgeInsets.all(2),
                                              decoration: ShapeDecoration(
                                                shape: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(360),
                                                    ),
                                                    borderSide: BorderSide(
                                                        style: BorderStyle.none)),
                                                color: isDarkMode(context)
                                                    ? Colors.grey[700]
                                                    : Colors.grey.shade200,
                                              ),
                                              child: Row(
                                                children: <Widget>[
                                                  Expanded(
                                                    child: TextField(
                                                      onChanged: (s) {
                                                        setState(() {});
                                                      },
                                                      textAlignVertical:
                                                          TextAlignVertical
                                                              .center,
                                                      decoration: InputDecoration(
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                                vertical: 8,
                                                                horizontal: 8),
                                                        hintText:
                                                            'startTyping'.tr(),
                                                        hintStyle: TextStyle(
                                                            color:
                                                                Colors.grey[400]),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .all(
                                                                  Radius.circular(
                                                                      360),
                                                                ),
                                                                borderSide: BorderSide(
                                                                    style:
                                                                        BorderStyle
                                                                            .none)),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .all(
                                                                  Radius.circular(
                                                                      360),
                                                                ),
                                                                borderSide: BorderSide(
                                                                    style:
                                                                        BorderStyle
                                                                            .none)),
                                                      ),
                                                      textCapitalization:
                                                          TextCapitalization
                                                              .sentences,
                                                      maxLines: 5,
                                                      minLines: 1,
                                                      keyboardType:
                                                          TextInputType.multiline,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ))),
                                    IconButton(
                                      icon: Icon(
                                        Icons.send,
                                        color: Color(COLOR_PRIMARY),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ])
                          : null),
                ),
             ]), // 내 화면 및 채팅 - End
            ),
          ]), // 앱 전체 - End
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
}
