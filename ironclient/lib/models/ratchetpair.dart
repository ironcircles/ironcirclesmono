import 'package:ironcirclesapp/models/ratchetindex.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';

class RatchetPair{

  RatchetKey ratchetKey;
  RatchetIndex ratchetIndex;

  RatchetPair({required this.ratchetKey, required this.ratchetIndex});

  factory RatchetPair.blank() => RatchetPair(
      ratchetKey: RatchetKey.blank(), ratchetIndex: RatchetIndex.blank(),
  );
}