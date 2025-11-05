// import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:intl/intl.dart';
// import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
// import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
// import 'package:ironcirclesapp/models/circleagoracall.dart';
// import 'package:ironcirclesapp/models/export_models.dart';
// import 'package:ironcirclesapp/screens/insidecircle/agora.dart';
// import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
// import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
// import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
// import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
// import 'package:provider/provider.dart';
//
// class CircleAgoraCallWidget extends StatelessWidget {
//   final CircleAgoraCall agoraCall;
//   final String circleID;
//   final UserFurnace userFurnace;
//
//   const CircleAgoraCallWidget({
//     Key? key,
//     required this.agoraCall,
//     required this.circleID,
//     required this.userFurnace,
//   }) : super(key: key);
//
//   void _joinCall(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => Agora(
//           circleID: circleID,
//           userFurnace: userFurnace,
//         ),
//       ),
//     );
//   }
//
//   String _formatDateTime(DateTime? dateTime) {
//     if (dateTime == null) return '';
//     return DateFormat('MMM dd, yyyy - h:mm a').format(dateTime);
//   }
//
//   String _formatDuration(DateTime? startTime, DateTime? endTime) {
//     if (startTime == null || endTime == null) return '';
//     final duration = endTime.difference(startTime);
//     final hours = duration.inHours;
//     final minutes = duration.inMinutes % 60;
//     final seconds = duration.inSeconds % 60;
//
//     if (hours > 0) {
//       return '${hours}h ${minutes}m ${seconds}s';
//     } else if (minutes > 0) {
//       return '${minutes}m ${seconds}s';
//     } else {
//       return '${seconds}s';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Call Status Row
//             Row(
//               children: [
//                 Icon(
//                   agoraCall.active ? Icons.videocam : Icons.videocam_off,
//                   color: agoraCall.active ? Colors.green : Colors.grey,
//                   size: 20,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   agoraCall.active ? "Active Video Call" : "Call Ended",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: agoraCall.active ? Colors.green : Colors.grey,
//                   ),
//                 ),
//                 const Spacer(),
//                 if (agoraCall.active)
//                   ElevatedButton.icon(
//                     onPressed: () => _joinCall(context),
//                     icon: const Icon(Icons.videocam, size: 16),
//                     label: const Text("Join"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       minimumSize: const Size(0, 32),
//                     ),
//                   ),
//               ],
//             ),
//
//             const SizedBox(height: 8),
//
//             // Call Details
//             if (agoraCall.startTime != null) ...[
//               Row(
//                 children: [
//                   Icon(
//                     Icons.schedule,
//                     color: globalState.theme.labelText,
//                     size: 14,
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     "Started: ${_formatDateTime(agoraCall.startTime)}",
//                     style: TextStyle(
//                       color: globalState.theme.labelText,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 4),
//             ],
//
//             if (agoraCall.endTime != null) ...[
//               Row(
//                 children: [
//                   Icon(
//                     Icons.schedule,
//                     color: globalState.theme.labelText,
//                     size: 14,
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     "Ended: ${_formatDateTime(agoraCall.endTime)}",
//                     style: TextStyle(
//                       color: globalState.theme.labelText,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 4),
//
//               // Duration
//               Row(
//                 children: [
//                   Icon(
//                     Icons.timer,
//                     color: globalState.theme.labelText,
//                     size: 14,
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     "Duration: ${_formatDuration(agoraCall.startTime, agoraCall.endTime)}",
//                     style: TextStyle(
//                       color: globalState.theme.labelText,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//
//             if (!agoraCall.active) ...[
//               const SizedBox(height: 8),
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: Text(
//                   "This call has ended",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }