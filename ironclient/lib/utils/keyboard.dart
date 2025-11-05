import 'package:flutter/material.dart';

class KeyboardUtil {
  static closeKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }
}
