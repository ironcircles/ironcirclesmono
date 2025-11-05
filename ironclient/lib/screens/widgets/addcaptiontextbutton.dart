import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/dialogcaption.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class AddCaptionTextButton extends StatelessWidget {
  final Function callback;
  final String existingCaption;

  //static String noCaption = "tap to add a caption";

  const AddCaptionTextButton({
    Key? key,
    required this.existingCaption,
    required this.callback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String caption = existingCaption.isNotEmpty
        ? '${AppLocalizations.of(context)!.caption}: $existingCaption'
        : AppLocalizations.of(context)!.tapToAddCaption;

    return InkWell(
        onTap: () {
          DialogCaption.getCaption(
              context: context,
              existingCaption: existingCaption,
              callback: callback);
        },
        child: Row(children: [
          Expanded(
              child: caption == AppLocalizations.of(context)!.tapToAddCaption
                  ?  ICText(
                      caption,
                      color: globalState.theme.labelTextSubtle,
                      fontSize: 16,
                      fontFamily: 'Righteous',
                      fontWeight: FontWeight.w700,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    )
                  : ICText(
                      caption,
                      fontFamily: 'Righteous',
                      fontWeight: FontWeight.w700,
                      color: globalState.theme.userObjectText,
                      fontSize: 16,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    )),

          // GradientButton(
          //     color1: globalState.theme.labelTextSubtle,
          //     color2: globalState.theme.labelTextSubtle,
          //     height: 45,
          //     onPressed: () {
          //       DialogCaption.getCaption(
          //           context: context,
          //           existingCaption: existingCaption,
          //           callback: callback);
          //     },
          //     text: caption)
        ]));
  }
}
