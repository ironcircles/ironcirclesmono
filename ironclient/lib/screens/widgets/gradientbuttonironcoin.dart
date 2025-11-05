import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/payment/ironstore_ironcoin.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class GradientButtonIronCoin extends StatelessWidget {
  final Function onPressed;
  final Color? textColor;
  final double fontSize;
  final double height;
  final double opacity;
  final String cost;
  final Function() configure;
  bool genImage;
  double balance;

  final NumberFormat formatter = NumberFormat.decimalPatternDigits(
    locale: 'en_us',
    decimalDigits: 0,
  );

  GradientButtonIronCoin({
    Key? key,
    required this.onPressed,
    this.textColor,
    this.fontSize = 16,
    this.height = 60,
    required this.genImage,
    this.opacity = .2,
    required this.configure,
    required this.cost,
    required this.balance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            const Spacer(),
            Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: globalState.theme.background,
              ),
              child: Column(children: [
                Row(children: [
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: globalState.theme.buttonGenerate.withOpacity(opacity)),
                    child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.transparent,
                        ),
                        onPressed: onPressed as void Function()?,
                        child: Row(children: [
                          Text(
                            genImage ? AppLocalizations.of(context)!.regenerate : ' ${AppLocalizations.of(context)!.generate} ',
                            textScaler: const TextScaler.linear(1.0),
                            style: TextStyle(
                              fontSize:
                                  fontSize - globalState.scaleDownTextFont,
                              fontFamily: 'Righteous',
                              fontWeight: FontWeight.w700,
                              color: globalState.theme.buttonGenerate,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 3, left: 5),
                            child: ClipOval(
                                child: Image.asset(
                              'assets/images/ironcoin.png',
                              height: 20, //20
                              width: 20, //20
                              fit: BoxFit.fitHeight,
                            )),
                          ),
                          Text(
                            cost,
                            textScaler: const TextScaler.linear(1.0),
                            style: TextStyle(
                              fontSize:
                                  fontSize - globalState.scaleDownTextFont,
                              fontFamily: 'Righteous',
                              fontWeight: FontWeight.w700,
                              color: globalState.theme.buttonGenerate,
                            ),
                          ),
                        ])),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 0, bottom: 10),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune),
                    color: globalState.theme.buttonGenerate,
                    onPressed: configure,
                  ),
                ]),
                InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const IronStoreIronCoin(),
                          ));
                    },
                    child: Padding(
                        padding: const EdgeInsets.only(
                          right: 0,
                        ),
                        child: ICText(
                          "${AppLocalizations.of(context)!.balance}: ${formatter.format(balance)}",
                          color: globalState.theme.buttonGenerate,
                          fontSize: 14,
                        ))),
              ]),
            )
          ])
        ]));
  }
}
