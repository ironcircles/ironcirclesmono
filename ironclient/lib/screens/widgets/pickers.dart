import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';

class Pickers {
  static bool blankDate(DateTime? initialDate) {
    if (initialDate == null) return true;

    return (initialDate.difference(DateTime(1)).inSeconds == 0);
  }

  static Future<DateTime?> getDate(
      BuildContext context, DateTime? initialDate) async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 40),
      initialDate: blankDate(initialDate) ? DateTime.now() : initialDate!,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1),
            ),
            child: globalState.theme.themeMode == ICThemeMode.dark
                ? Theme(
                    data: ThemeData.dark().copyWith(
                      primaryColor: globalState.theme.button,
                      //accentColor:  globalState.theme.button,
                      colorScheme:
                          ColorScheme.dark(primary: globalState.theme.button),
                      buttonTheme: const ButtonThemeData(
                          textTheme: ButtonTextTheme.primary),
                    ),
                    child: child!,
                  )
                : Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor: globalState.theme.button,
                      //accentColor:  globalState.theme.button,
                      colorScheme:
                          ColorScheme.light(primary: globalState.theme.button),
                      buttonTheme: const ButtonThemeData(
                          textTheme: ButtonTextTheme.primary),
                    ),
                    child: child!,
                  ));
      },
    );

    return date;
  }

  static Future<TimeOfDay?> pickTime(
      BuildContext context, TimeOfDay timeOfDay) async {
    TimeOfDay? time = await showTimePicker(
        initialTime: timeOfDay,
        context: context,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1),
              ),
              child: globalState.theme.themeMode == ICThemeMode.dark
                  ? Theme(
                      data: ThemeData.dark().copyWith(
                        primaryColor: globalState.theme.button,
                        //accentColor:  globalState.theme.button,
                        colorScheme:
                            ColorScheme.dark(primary: globalState.theme.button),
                        buttonTheme:
                            const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                      ),
                      child: child!,
                    )
                  : Theme(
                      data: ThemeData.light().copyWith(
                        primaryColor: globalState.theme.button,
                        //accentColor:  globalState.theme.button,
                        colorScheme: ColorScheme.light(
                            primary: globalState.theme.button),
                        buttonTheme:
                            const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                      ),
                      child: child!,
                    ));
        });

    return time;
  }
}
