// import 'dart:async';
//
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:ironcirclesapp/blocs/agora_bloc.dart';
// import 'package:ironcirclesapp/models/userfurnace.dart';
// import 'package:ironcirclesapp/models/circleagoracall.dart';
//
// const appId = "68797e8afc4949e5bf4d5aff30f27074";
//
// class Agora extends StatefulWidget {
//   final String circleID;
//   final UserFurnace userFurnace;
//   const Agora({required this.circleID, required this.userFurnace, Key? key})
//     : super(key: key);
//
//   @override
//   State<Agora> createState() => _AgoraState();
// }
//
// class _AgoraState extends State<Agora> {
//   int? _remoteUid;
//   bool _localUserJoined = false;
//   late RtcEngine _engine;
//   final TokenBloc _tokenBloc = TokenBloc();
//   final CircleAgoraCall _agoraCall = CircleAgoraCall();
//   bool _loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAndInit();
//   }
//
//   Future<void> _fetchAndInit() async {
//     await [Permission.microphone, Permission.camera].request();
//     _tokenBloc.tokenStream.listen((agoraCall) async {
//       if (agoraCall.channelName.isNotEmpty) {
//         setState(() {
//           _agoraCall.token = agoraCall.token;
//           _agoraCall.channelName = agoraCall.channelName;
//           _agoraCall.agoraUserID = agoraCall.agoraUserID;
//           _loading = false;
//         });
//         await _initAgora();
//       } else {
//         setState(() {
//           _loading = false;
//         });
//
//       }
//     });
//     _tokenBloc.startCall(widget.circleID, widget.userFurnace);
//   }
//
//   Future<void> _initAgora() async {
//     _engine = createAgoraRtcEngine();
//     await _engine.initialize(
//       const RtcEngineContext(
//         appId: appId,
//         channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
//       ),
//     );
//
//     _engine.registerEventHandler(
//       RtcEngineEventHandler(
//         onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
//           debugPrint("local user 27${connection.localUid}27 joined");
//           setState(() {
//             _localUserJoined = true;
//           });
//         },
//         onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
//           debugPrint("remote user $remoteUid joined");
//           setState(() {
//             _remoteUid = remoteUid;
//           });
//         },
//         onUserOffline: (
//           RtcConnection connection,
//           int remoteUid,
//           UserOfflineReasonType reason,
//         ) {
//           debugPrint("remote user $remoteUid left channel");
//           setState(() {
//             _remoteUid = null;
//           });
//         },
//         onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
//           debugPrint(
//             '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token',
//           );
//         },
//       ),
//     );
//
//     await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
//     await _engine.enableVideo();
//     await _engine.startPreview();
//
//     await _engine.joinChannel(
//       token: _agoraCall.token,
//       channelId: _agoraCall.channelName,
//       uid: _agoraCall.agoraUserID,
//       options: const ChannelMediaOptions(),
//     );
//   }
//
//   @override
//   void dispose() {
//     _tokenBloc.dispose();
//     _dispose();
//     super.dispose();
//   }
//
//   Future<void> _dispose() async {
//     await _engine.leaveChannel();
//     await _engine.release();
//   }
//
//   // Create UI with local view and remote view
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Agora Video Call')),
//       body:
//           _loading
//               ? const Center(child: CircularProgressIndicator())
//               : Stack(
//                 children: [
//                   Center(child: _remoteVideo()),
//                   Align(
//                     alignment: Alignment.topLeft,
//                     child: SizedBox(
//                       width: 100,
//                       height: 150,
//                       child: Center(
//                         child:
//                             _localUserJoined
//                                 ? AgoraVideoView(
//                                   controller: VideoViewController(
//                                     rtcEngine: _engine,
//                                     canvas: const VideoCanvas(uid: 0),
//                                   ),
//                                 )
//                                 : const CircularProgressIndicator(),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//     );
//   }
//
//   // Display remote user's video
//   Widget _remoteVideo() {
//     if (_remoteUid != null) {
//       return AgoraVideoView(
//         controller: VideoViewController.remote(
//           rtcEngine: _engine,
//           canvas: VideoCanvas(uid: _remoteUid),
//           connection: RtcConnection(channelId: widget.circleID),
//         ),
//       );
//     } else {
//       return const Text(
//         'Please wait for remote user to join',
//         textAlign: TextAlign.center,
//       );
//     }
//   }
// }
