

/*abstract class UsernameGenImpl {
  void setNames(List<String> _names);
  void setAdjectives(List<String> _adjectives);
  void setSeparator(String separator);

  String random();
}

class UsernameGen {
  var separator = '-';

  UsernameGenData data = UsernameGenData(
    names: names,
    adjectives: adjectives,
  );

  void setNames(_names) {
    data.names = _names;
  }

  void setAdjectives(_adjectives) {
    data.adjectives = _adjectives;
  }

  void setSeparator(String separator) {
    this.separator = separator;
  }

  static String generateWith({UsernameGenData? data, String separator = '-'}) {
    data ??= UsernameGenData(
      names: names,
      adjectives: adjectives,
    );

    final ran_a = (Random().nextDouble() * data.names.length).floor();
    final ran_b = (Random().nextDouble() * data.adjectives.length).floor();
    final ran_suffix = (Random().nextDouble() * 100).floor();
    return "${data.adjectives[ran_b]}$separator${data.names[ran_a]}$ran_suffix";
  }
}

extension RandomUsernameGen on UsernameGen {
  String generate() {
    final ran_a = (Random().nextDouble() * data.names.length).floor();
    final ran_b = (Random().nextDouble() * data.adjectives.length).floor();
    final ran_suffix = (Random().nextDouble() * 100).floor();
    return "${data.adjectives[ran_b]}$separator${data.names[ran_a]}$ran_suffix";
  }
}

class UsernameGenData {
  List<String> names;
  List<String> adjectives;

  UsernameGenData({
    required this.names,
    required this.adjectives,
  });

  UsernameGenData copyWith({
    List<String>? names,
    List<String>? adjectives,
  }) {
    return UsernameGenData(
      names: names ?? this.names,
      adjectives: adjectives ?? this.adjectives,
    );
  }
}

 */
