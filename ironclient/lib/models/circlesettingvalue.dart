// class CircleSettingValue {
//   String? setting;
//   String? settingValue;
//   String? originalValue;
//   String? displayValue;
//
//   CircleSettingValue({
//     this.setting,
//     this.settingValue,
//     this.originalValue,
//     this.displayValue,
//   });
//
//   Map<String, dynamic> toJson() => {
//     "setting": setting,
//     "settingValue": settingValue,
//   };
//
// }

class CircleSettingValue {
  String setting;
  int numericSetting;
  bool boolSetting;
  int priorNumberSetting;
  bool priorBoolSetting;

  CircleSettingValue({
    required this.setting,
    this.numericSetting = 0,
    this.boolSetting = false,
    this.priorNumberSetting = 0,
    this.priorBoolSetting = false,
  });

  Map<String, dynamic> toJson() => {
        "setting": setting,
        "numericSetting": numericSetting,
        "boolSetting": boolSetting,
        "priorNumberSetting": priorNumberSetting,
        "priorBoolSetting": priorBoolSetting,
      };
}
