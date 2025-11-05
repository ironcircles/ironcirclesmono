import 'package:flutter/services.dart';

class StringHelper {
  static String truncate(String target, int length) {
    String retValue = target;

    if (retValue.length > length) {
      retValue = retValue.substring(0, length - 4);
      retValue += "...";
    }

    return retValue;
  }

  static String getMagicCodeFromString(String data) {
    String retValue = '';

    if (data.length == 40 && data.startsWith('MGC'))
      return data;

    List<String> magicArray = data.split(':');

    if (magicArray.length > 1) retValue = magicArray.last;

    return retValue;
  }

  static Future<String> testClipboardForMagicCode() async {
    String retValue = '';
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);

    if (data != null && data.text != null) {
      ///the user either copied the entire message, partial, or just the code
      String magicCode = '';
      if (data.text!.length == 40 && data.text!.startsWith('MGC'))
        magicCode = data.text!;
      else {
        List<String> magicArray = data.text!.split(':');

        if (magicArray.length > 1) magicCode = magicArray.last;
      }

      if (magicCode.length == 40 && magicCode.startsWith('MGC')) {
        retValue = magicCode;
      }
    }

    return retValue;
  }
}
