import 'dart:async';
import 'package:ironcirclesapp/services/agora_service.dart';
import 'package:ironcirclesapp/models/userfurnace.dart';
import 'package:ironcirclesapp/models/circleagoracall.dart';

class TokenBloc {
  final TokenService _tokenService = TokenService();
  final _tokenController = StreamController<CircleAgoraCall>.broadcast();
  Stream<CircleAgoraCall> get tokenStream => _tokenController.stream;

  TokenBloc();

  Future<void> startCall(String circleID, UserFurnace userFurnace) async {
    final agoraCall = await _tokenService.startCall(circleID, userFurnace);
    _tokenController.sink.add(agoraCall);
  }

  void dispose() {
    _tokenController.close();
  }
} 