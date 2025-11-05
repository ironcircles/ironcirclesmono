import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';

class CircleManageRow extends StatelessWidget {
  final UserCircleCache row;
  final Function close;
  final Function closeHidden;
  final Function pinCircle;
  final List<MemberCircle> memberCircles;
  final Function hide;
  final Function mute;
  final Function open;
  final Function pinCheck;
  final Function setCircleGuarded;
  final Function unhide;
  final Color rowItemColor;
  final Function openCircle;

  // FlutterManager({Key key, this.title}) : super(key: key);
  const CircleManageRow({
    Key? key,
    required this.row,
    required this.close,
    required this.closeHidden,
    required this.pinCircle,
    //required this.unpinCircle,
    required this.memberCircles,
    required this.hide,
    required this.mute,
    required this.open,
    required this.pinCheck,
    required this.setCircleGuarded,
    required this.unhide,
    required this.rowItemColor,
    required this.openCircle,
  }) : super(key: key);
  // final String title;

  final double _height = 50;

  @override
  Widget build(BuildContext context) {
    Color prefNameColor = globalState.theme.labelText;

    if (row.dm) {
      int mcIndex = memberCircles.indexWhere(
        (element) => element.circleID == row.circle!,
      );

      if (mcIndex > -1) {
        Member member = globalState.members.firstWhere(
          (element) => element.memberID == memberCircles[mcIndex].memberID,
          orElse: () => Member(alias: '', userID: '', memberID: ''),
        );

        if (member.userID.isNotEmpty) {
          prefNameColor = member.color;
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Expanded(
          //flex: 1,
          child: GestureDetector(
            onTap: () {
              openCircle(row);
            },
            child: Text(
              /*row.prefName!.length > 40
                              ? row.prefName!.substring(0, 39)
                              : row.prefName!,
                              */
              row.dmMember != null
                  ? globalState.members
                      .firstWhere(
                        (element) => element.memberID == row.dmMember,
                        orElse:
                            () => Member(alias: '', userID: '', memberID: ''),
                      )
                      .returnUsernameAndAlias()
                  : row.prefName == null
                  ? 'name missing'
                  : row.prefName!,
              textScaler: const TextScaler.linear(1.0),
              style: ICTextStyle.getStyle(
                context: context,
                fontSize: 15,
                color: prefNameColor,
              ) /*row.dm
                      ? Member.getMemberColor(row.userFurnace!, row.)
                      : globalState.theme.labelText)*/,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(
            left: 0.0,
            top: 0.0,
            bottom: 0.0,
            right: 5.0,
          ),
        ),
        row.hidden! && row.hiddenOpen!
            ? TextButton(
              onPressed: () {
                unhide(row);
              },
              child: Text(
                AppLocalizations.of(context)!.unhide,
                textScaler: const TextScaler.linear(1.0),
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: rowItemColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            )
            : globalState.userSetting.allowHidden
            ? TextButton(
              onPressed: () {
                hide(row);
              },
              child: Text(
                AppLocalizations.of(context)!.hide,
                textScaler: const TextScaler.linear(1.0),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: globalState.theme.unlock,
                  fontSize: 12,
                ),
              ),
            )
            : Container(),
        //Padding(padding: EdgeInsets.only(left:30),),
        /*SizedBox(
            width: 40,
            child: row.pinned
                ? IconButton(
                icon: Transform.rotate(
                  angle: 45 * math.pi / 180,
                  child: const Icon(Icons.push_pin_rounded,
                color: Colors.red)),//rowItemColor
                onPressed: () {
                  pinCircle(row);
              },
            )
                : IconButton(
                  icon: Transform.rotate(
                    angle: 45 * math.pi / 180,
                    child: Icon(Icons.push_pin_outlined,
                        color: globalState.theme.button)), //globalState.theme.button //rowItemColor
                onPressed: () {
                  //unpinCircle(row);
                  pinCircle(row);
              },
            )),*/
        Expanded(
          child:
              row.guarded!
                  ? TextButton(
                    onPressed: () {
                      pinCheck(row);
                    },
                    child: Text(
                      AppLocalizations.of(context)!.unguard,
                      textScaler: const TextScaler.linear(1.0),
                      textAlign: TextAlign.end,
                      style: TextStyle(color: rowItemColor, fontSize: 12),
                    ),
                  )
                  : TextButton(
                    onPressed: () {
                      setCircleGuarded(row);
                    },
                    child: Text(
                      AppLocalizations.of(context)!.guard,
                      textScaler: const TextScaler.linear(1.0),
                      textAlign: TextAlign.end,
                      style: TextStyle(color: rowItemColor, fontSize: 12),
                    ),
                  ),
        ),
        // //
        !row.hidden!
            ? row.closed
                ? TextButton(
                  onPressed: () {
                    open(row);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.open,
                    textScaler: const TextScaler.linear(1.0),
                    style: TextStyle(color: rowItemColor, fontSize: 12),
                  ),
                )
                : TextButton(
                  onPressed: () {
                    close(row);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.close,
                    textScaler: const TextScaler.linear(1.0),
                    style: TextStyle(color: rowItemColor, fontSize: 12),
                  ),
                )
            : TextButton(
              onPressed: () {
                closeHidden(row);
              },
              child: Text(
                AppLocalizations.of(context)!.close,
                textScaler: const TextScaler.linear(1.0),
                style: TextStyle(color: rowItemColor, fontSize: 12),
              ),
            ),

        // Expanded(child:IconButton(
        //         padding: EdgeInsets.zero,
        //         constraints: const BoxConstraints(),
        //         icon: const Icon(Icons.lock_rounded),
        //         iconSize: 25,
        //         color: rowItemColor,
        //         onPressed: () {
        //           closeHidden(row);
        //         },
        //       )),
        row.muted
            ? IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.volume_off_rounded, color: rowItemColor),
              onPressed: () {
                mute(row);
              },
            )
            : IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.volume_up_rounded, color: rowItemColor),
              onPressed: () {
                mute(row);
              },
            ),
      ],
    );
  }
}
