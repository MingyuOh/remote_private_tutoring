import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:remote_private_tutoring/constants.dart';
import 'package:remote_private_tutoring/main.dart';
import 'package:remote_private_tutoring/model/ConversationModel.dart';
import 'package:remote_private_tutoring/model/HomeConversationModel.dart';
import 'package:remote_private_tutoring/model/MessageData.dart';
import 'package:remote_private_tutoring/model/User.dart';
import 'package:remote_private_tutoring/services/FirebaseHelper.dart';
import 'package:remote_private_tutoring/services/helper.dart';

enum SignalingState {
  CallStateNew,
  CallStateRinging,
  CallStateInvite,
  CallStateConnected,
  CallStateBye,
  ConnectionOpen,
  ConnectionClosed,
  ConnectionError,
}

/*
 * callbacks for Signaling API.
 */
typedef void SignalingStateCallback(SignalingState state);
typedef void StreamStateCallback(MediaStream stream);
typedef void OtherEventCallback(dynamic event);

class VideoCallsHandler {
  Timer countdownTimer;
  var _peerConnections = new Map<String, RTCPeerConnection>();
  var _remoteCandidates = [];
  List<dynamic> _localCandidates = [];
  StreamSubscription hangupSub; // StreamSubscription : 스트림과 이벤트의 연결고리, 이벤트에 변경이 생기면 처리한다
  MediaStream _localStream;
  List<MediaStream> _remoteStreams;
  SignalingStateCallback onStateChange;
  StreamStateCallback onLocalStream;
  StreamStateCallback onAddRemoteStream;
  StreamStateCallback onRemoveRemoteStream;
  OtherEventCallback onPeersUpdate;
  String _selfId = MyAppState.currentUser.userID; // 현재 유저
  final bool isCaller;
  final HomeConversationModel homeConversationModel;
  bool _isTest = false;
  String get sdpSemantics =>
      WebRTC.platformIsWindows ? 'plan-b' : 'unified-plan';

  FireStoreUtils _fireStoreUtils = FireStoreUtils();

  StreamSubscription<DocumentSnapshot> messagesStreamSubscription;

  VideoCallsHandler(
      {@required this.isCaller, @required this.homeConversationModel});

  // ICE(Interactive Connectivity Establishment) 개념 참고
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
      {
        'url': 'turn:95.217.132.49:80?transport=udp',
        'username': 'c38d01c8',
        'credential': 'f7bf2454'
      },
      {
        'url': 'turn:95.217.132.49:80?transport=tcp',
        'username': 'c38d01c8',
        'credential': 'f7bf2454'
      },
    ],
    'sdpSemantics':  WebRTC.platformIsWindows ? 'plan-b' : 'unified-plan'
  };

  final Map<String, dynamic> _config = {
    'mandatory':  {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true, },
    ],
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  final Map<String, dynamic> _userMediaConstraints = {
    'audio': true,
    'video': {
      'mandatory': {
        'minWidth':
        '640', // Provide your own width, height and frame rate here
        'minHeight': '480',
        'minFrameRate': '30',
      },
      'facingMode': 'user',
      'optional': [],
    }
  };

  final Map<String, dynamic> _displayMediaConstraints = {
    'audio': true,
    'video': true
  };

  close() {
    if (_localStream != null) {
      _localStream.dispose();
      _localStream = null;
    }
    hangupSub.cancel();
    if (messagesStreamSubscription != null) {
      messagesStreamSubscription.cancel();
    }
    _peerConnections.forEach((key, pc) {
      pc.close();
    });
  }

  void switchCamera() {
    if (_localStream != null) {
      _localStream.getVideoTracks()[0].switchCamera();
    }
  }

  void initCall(String token, String peerID, BuildContext context) async {
    if (this.onStateChange != null) {
      this.onStateChange(SignalingState.CallStateNew);
    }

    _createPeerConnection(peerID).then((pc) async {
      _peerConnections[peerID] = pc;
      await _createOffer(token, peerID, pc, context);
      startCountDown(context);
      listenForMessages();
      setupOnRemoteHangupListener(context);
    });
  }

  setupOnRemoteHangupListener(BuildContext context) {
    Stream<DocumentSnapshot> hangupStream = FireStoreUtils.firestore
        .collection(USERS)
        .document(homeConversationModel.members.first.userID)
        .collection(CALL_DATA)
        .document(
            isCaller ? _selfId : homeConversationModel.members.first.userID)
        .snapshots();
    print('${isCaller ? _selfId : homeConversationModel.members.first.userID}');
    hangupSub = hangupStream.listen((event) {
      if (!event.exists) {
        print('VideoCallsHandler.setupOnRemoteHangupListener');
        Navigator.pop(context);
      }
    });
  }

  void bye() async {
    print('VideoCallsHandler.bye');
    await FireStoreUtils.firestore
        .collection(USERS)
        .document(_selfId)
        .collection(CALL_DATA)
        .document(
            isCaller ? _selfId : homeConversationModel.members.first.userID)
        .delete();
    await FireStoreUtils.firestore
        .collection(USERS)
        .document(homeConversationModel.members.first.userID)
        .collection(CALL_DATA)
        .document(
            isCaller ? _selfId : homeConversationModel.members.first.userID)
        .delete();
  }

  void onMessage(Map<String, dynamic> message) async {
    Map<String, dynamic> mapData = message;
    var data = mapData['data'];

    switch (mapData['type']) {
      case 'offer':
        {
          var id = data['from'];
          if (id != _selfId) {
            print('VideoCallsHandler.onMessage offer');
          } else {
            print('VideoCallsHandler.onMessage you offered a call');
          }
        }
        break;
      case 'answer':
        {
          var id = data['from'];

          if (id != _selfId) {
            countdownTimer.cancel();
            print('VideoCallsHandler.onMessage answer');
            var description = data['description'];
            if (this.onStateChange != null)
              this.onStateChange(SignalingState.CallStateConnected);
            var pc = _peerConnections[id];
            if (pc != null) {
              await pc.setRemoteDescription(new RTCSessionDescription(
                  description['sdp'], description['type']));
            }

            _sendCandidate('candidate',
                {'to': id, 'from': _selfId, 'candidate': _localCandidates});
          } else {
            print('VideoCallsHandler.onMessage you answered the call');
          }
        }
        break;
      case 'candidate':
        {
          var id = data['from'];
          if (id != _selfId) {
            print('VideoCallsHandler.onMessage candidate');
            List<dynamic> candidates = data['candidate'];
            var pc = _peerConnections[id];
            candidates.forEach((candidateMap) async {
              RTCIceCandidate candidate = new RTCIceCandidate(
                  candidateMap['candidate'],
                  candidateMap['sdpMid'],
                  candidateMap['sdpMLineIndex']);
              if (pc != null) {
                await pc.addCandidate(candidate);
              } else {
                _remoteCandidates.add(candidate);
              }
            });

            if (this.onStateChange != null)
              this.onStateChange(SignalingState.CallStateConnected);
          } else {
            print('VideoCallsHandler.onMessage you sent candidate');
          }
        }
        break;
      default:
        break;
    }
  }

  Future<void> replaceVideoStreamTrack({bool isVideoCall}) async {
    /*final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': true
    };*/
    if(isVideoCall == true)
      {
        print("Start video call");
        await navigator.mediaDevices.getUserMedia(_userMediaConstraints).then((stream) {
          var videoTrack = stream.getVideoTracks()[0];
          _peerConnections.forEach((key, pc) async {
            pc.getSenders().then((senders) {
              senders.forEach((s) {
                s.track.stop();
                if (s.track.kind == videoTrack.kind) {
                  print("found sender:, $s");
                  switch (sdpSemantics) {
                    case 'plan-b':
                      pc.removeStream(_localStream);
                      break;
                    case 'unified-plan':
                      print("Replace track in unified-plan");
                      s.replaceTrack(videoTrack);
                      break;
                  }
                  print("Replace track success");
                }
              });
            }
            ).catchError((onError) {
              print("Error happens:', ${onError.toString()}");
            });
          });
        });
      }
    else {
      print("Start screen sharing");
      await navigator.mediaDevices.getDisplayMedia(_displayMediaConstraints).then((stream) {
        var screenTrack = stream.getVideoTracks()[0];
        _peerConnections.forEach((key, pc) async {
          pc.getSenders().then((senders) {
            senders.forEach((s) {
              if (s.track.kind == screenTrack.kind) {
                print("found sender:, $s");
                switch (sdpSemantics) {
                  case 'plan-b':
                    pc.removeStream(_localStream);
                    break;
                  case 'unified-plan':
                    print("Replace track in unified-plan");
                    s.replaceTrack(screenTrack);
                    break;
                }
                print("Replace track success");
              }
            });
          }
          ).catchError((onError) {
            print("Error happens:', ${onError.toString()}");
          });
        });
      });
    }
    print("Replace videoStreamTrack done");
  }

  Future<MediaStream> createStream() async {
    MediaStream stream = await navigator.mediaDevices.getUserMedia(_userMediaConstraints);
    if (this.onLocalStream != null) {
      this.onLocalStream(stream);
    }
    return stream;
  }

  Future<RTCPeerConnection> _createPeerConnection(id) async {
    _localStream = await createStream();

    // 통신 연결
    RTCPeerConnection pc = await createPeerConnection(_iceServers, _config);
    // 자신의 스트림 추가
    //pc.addStream(_localStream);
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      _localCandidates.add(candidate.toMap());
    };

    pc.onAddStream = (stream) {
      if (this.onAddRemoteStream != null) this.onAddRemoteStream(stream);
      //_remoteStreams.add(stream);
    };
    pc.onRemoveStream = (stream) {
      if (this.onRemoveRemoteStream != null) this.onRemoveRemoteStream(stream);
      _remoteStreams.removeWhere((MediaStream it) {
        return (it.id == stream.id);
      });
    };

    switch (sdpSemantics) {
      case 'plan-b':
        await pc.addStream(_localStream);
        break;
      case 'unified-plan':
        _localStream.getTracks().forEach((track) {
          pc.addTrack(track, _localStream);
        });
        break;
    }

    return pc;
  }

  _createOffer(String token, String id, RTCPeerConnection pc,
      BuildContext context) async {
    try {
      RTCSessionDescription s = await pc.createOffer(_constraints);
      pc.setLocalDescription(s);
      await _sendOffer(
          token,
          'offer',
          {
            'to': id,
            'from': _selfId,
            'description': {'sdp': s.sdp, 'type': s.type},
          },
          context);
    } catch (e) {
      print(e.toString());
    }
  }

  _createAnswer(String id, RTCPeerConnection pc) async {
    try {
      RTCSessionDescription s = await pc.createAnswer(_constraints);
      pc.setLocalDescription(s);
      await _sendAnswer('answer', {
        'to': id,
        'from': _selfId,
        'description': {'sdp': s.sdp, 'type': s.type},
      });
    } catch (e) {
      print(e.toString());
    }
  }

  _sendOffer(String token, String event, Map<String, dynamic> data,
      BuildContext context) async {
    var request = new Map<String, dynamic>();
    request["type"] = event;
    request["data"] = data;
    request['callerName'] = MyAppState.currentUser.fullName();
    request['callType'] = 'video';
    request['isGroupCall'] = false;
    await FireStoreUtils.firestore
        .collection(USERS)
        .document(homeConversationModel.members.first.userID)
        .collection(CALL_DATA)
        .getDocuments(source: Source.server)
        .then((value) async {
      if (value.documents.isEmpty) {
        //send offer to call
        await FireStoreUtils.firestore
            .collection(USERS)
            .document(_selfId)
            .collection(CALL_DATA)
            .document(_selfId)
            .setData(request);
        await FireStoreUtils.firestore
            .collection(USERS)
            .document(data['to'])
            .collection(CALL_DATA)
            .document(_selfId)
            .setData(request);
        if(_isTest == false) {
          updateChat(context);
          sendFCMNotificationForCalls(request, token);
        }
      } else {
        if(_isTest == false)
          showAlertDialog(context, 'call'.tr(), 'userHasAnOnGoingCall'.tr());
      }
    });
  }

  listenForMessages() {
    Stream<DocumentSnapshot> messagesStream = FireStoreUtils.firestore
        .collection(USERS)
        .document(
            isCaller ? _selfId : homeConversationModel.members.first.userID)
        .collection(CALL_DATA)
        .document(
            isCaller ? _selfId : homeConversationModel.members.first.userID)
        .snapshots();
    messagesStreamSubscription = messagesStream.listen((call) {
      if (call != null && call.exists) onMessage(call.data);
    });
  }

  void startCountDown(BuildContext context) {
    print('VideoCallsHandler.startCountDown');
    countdownTimer = Timer(Duration(minutes: 1), () {
      print('VideoCallsHandler.startCountDown bye');
      bye();
      if (!isCaller) {
        print('FlutterRingtonePlayer _hangUp lets stop');
        FlutterRingtonePlayer.stop();
      }
      Navigator.of(context).pop();
    });
  }

  acceptCall(String sessionDescription, String sessionType) async {
    if (this.onStateChange != null) {
      this.onStateChange(SignalingState.CallStateNew);
    }
    String id = homeConversationModel.members.first.userID;
    RTCPeerConnection pc = await _createPeerConnection(id);
    _peerConnections[id] = pc;
    await pc.setRemoteDescription(
        new RTCSessionDescription(sessionDescription, sessionType));
    await _createAnswer(id, pc);
    if (this._remoteCandidates.length > 0) {
      _remoteCandidates.forEach((candidate) async {
        await pc.addCandidate(candidate);
      });
      _remoteCandidates.clear();
    }
  }

  _sendAnswer(String event, Map<String, dynamic> data) async {
    var request = new Map<String, dynamic>();
    request["type"] = event;
    request["data"] = data;

    //send answer to call
    await FireStoreUtils.firestore
        .collection(USERS)
        .document(_selfId)
        .collection(CALL_DATA)
        .document(data['to'])
        .setData(request);
    await FireStoreUtils.firestore
        .collection(USERS)
        .document(data['to'])
        .collection(CALL_DATA)
        .document(data['to'])
        .setData(request);
    _sendCandidate('candidate',
        {'to': data['to'], 'from': _selfId, 'candidate': _localCandidates});
  }

  _sendCandidate(String event, Map<String, dynamic> data) async {
    var request = new Map<String, dynamic>();
    request["type"] = event;
    request["data"] = data;

    await FireStoreUtils.firestore
        .collection(USERS)
        .document(_selfId)
        .collection(CALL_DATA)
        .document(isCaller ? _selfId : data['to'])
        .setData(request);
    await FireStoreUtils.firestore
        .collection(USERS)
        .document(data['to'])
        .collection(CALL_DATA)
        .document(isCaller ? _selfId : data['to'])
        .setData(request);
  }

  void updateChat(BuildContext context) async {
    MessageData message = MessageData(
        content: 'startedAVideoCall'
            .tr(args: ['${MyAppState.currentUser.fullName()}']),
        created: Timestamp.now(),
        recipientFirstName: homeConversationModel.members.first.firstName,
        recipientID: homeConversationModel.members.first.userID,
        recipientLastName: homeConversationModel.members.first.lastName,
        recipientProfilePictureURL:
            homeConversationModel.members.first.profilePictureURL,
        senderFirstName: MyAppState.currentUser.firstName,
        senderID: MyAppState.currentUser.userID,
        senderLastName: MyAppState.currentUser.lastName,
        senderProfilePictureURL: MyAppState.currentUser.profilePictureURL,
        url: Url(mime: '', url: ''),
        videoThumbnail: '');

    if (await _checkChannelNullability(
        homeConversationModel.conversationModel)) {
      await _fireStoreUtils.sendMessage(
          homeConversationModel.members,
          homeConversationModel.isGroupChat,
          message,
          homeConversationModel.conversationModel, false);
      homeConversationModel.conversationModel.lastMessageDate = Timestamp.now();
      homeConversationModel.conversationModel.lastMessage = message.content;

      await _fireStoreUtils
          .updateChannel(homeConversationModel.conversationModel);
    } else {
      showAlertDialog(context, 'anErrorOccurred'.tr(),
          'failedToSendMessage'.tr());
    }
  }

  Future<bool> _checkChannelNullability(
      ConversationModel conversationModel) async {
    if (conversationModel != null) {
      return true;
    } else {
      String channelID;
      User friend = homeConversationModel.members.first;
      User user = MyAppState.currentUser;
      if (friend.userID.compareTo(user.userID) < 0) {
        channelID = friend.userID + user.userID;
      } else {
        channelID = user.userID + friend.userID;
      }

      ConversationModel conversation = ConversationModel(
          creatorId: user.userID,
          id: channelID,
          lastMessageDate: Timestamp.now(),
          lastMessage: 'sentAMessage'.tr(args: ['${user.fullName()}']));
      bool isSuccessful =
      await _fireStoreUtils.createConversation(conversation);
      if (isSuccessful) {
        homeConversationModel.conversationModel = conversation;
      }
      return isSuccessful;
    }
  }


  void sendFCMNotificationForCalls(Map<String, dynamic> request,
      String fcmToken) {
    sendPayLoad(fcmToken, callData: request);
  }
}
