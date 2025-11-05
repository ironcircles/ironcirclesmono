class DropDownPair {
  String id;
  String value;

  DropDownPair({
    required this.id,
    required this.value,
  });

  factory DropDownPair.fromJson(Map<String, dynamic> json) => DropDownPair(
        id: json["id"],
        value: json["value"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "value": value,
      };

  static DropDownPair blank(){
    return DropDownPair(id: 'blank', value: '');

  }
}
