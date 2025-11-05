import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/cache/table_emojiusage.dart';
import 'package:rxdart/rxdart.dart';

class EmojiUsageBloc {
  final PublishSubject<List<String?>> _usageLoaded = PublishSubject<List<String>>();
  Stream<List<String?>> get usageLoaded => _usageLoaded.stream;

  requestHighestUsedList() async {
    List<String?> sinkValue = [];

    List<EmojiUsage> emojis = await TableEmojiUsage.readHighestUsage();

    sinkValue = EmojiUsage.convertToStringList(emojis);

    _usageLoaded.add(sinkValue);
  }

  incrementEmoji(String emoji) async {
    await TableEmojiUsage.incrementCount(emoji);
  }

  dispose() async {
    await _usageLoaded.drain();
    _usageLoaded.close();
  }
}
