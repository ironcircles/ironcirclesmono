import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/library/genericitem.dart';

/// A ListItem that contains data to display a heading.
class CircleObjectItem implements GenericItem {
  @override
  int? type;
  @override
  String? id;
  @override
  int? userFurnacePK;
  final CircleObject? circleObject;
  final Function? showFullList;
  final Function? showFullVote;

  CircleObjectItem({
    this.circleObject,
    this.showFullList,
    this.showFullVote,
    this.type,
    this.id,
    this.userFurnacePK,
  });

  @override
  Widget buildCircleObject(BuildContext context, int index) => Card(
      surfaceTintColor: Colors.transparent,
      color: getColor(circleObject!),
      elevation: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 6.0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
        leading: Container(
          padding: const EdgeInsets.only(right: 12.0),
          decoration: BoxDecoration(
              border: Border(
                  right: BorderSide(
                      width: 1.0, color: globalState.theme.boxOutline))),
          child: Icon(getIcon(circleObject!),
              color: globalState.theme.cardLeadingIcon),
        ),
        title: Container(
          padding: const EdgeInsets.only(top: 5.0),
          child: Row(children: [
            Expanded(
                child: Text(
              getTitle(circleObject!),
              textScaler: TextScaler.linear(globalState.cardScaleFactor),
              //circleObject.userFurnace.alias,

                style: TextStyle(
                    color: globalState.theme.cardTitle,
                    fontSize: globalState.userSetting.fontSize),
            )),
          ]),
        ),
        subtitle: Column(children: <Widget>[
          Row(crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                  child: Padding(
                      padding:
                          const EdgeInsets.only(left: 5.0, bottom: 5, top: 5),
                      child: Text(
                        circleObject!.userFurnace!.alias!,
                        style: TextStyle(
                            color: globalState.theme.furnace,
                            fontSize: globalState.userSetting.fontSize -
                                globalState.scaleDownTextFont),
                        textScaler: const TextScaler.linear(1.0)
                      ))),
            ],
          ),
          Row(crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                      padding:
                          const EdgeInsets.only(left: 5.0, bottom: 5, top: 0),
                      child: Text(
                        "${AppLocalizations.of(context)!.circle}:",
                        textScaler: const TextScaler.linear(1.0),
                        style: TextStyle(
                            color: globalState.theme.cardLabel,
                            fontSize: globalState.userSetting.fontSize -
                                globalState.scaleDownTextFont),
                      )),
              Expanded(

                  child: Padding(
                      padding:
                          const EdgeInsets.only(left: 4, bottom: 5, top: 0),
                      child: Text(
                        circleObject!.userCircleCache == null
                            ? ''
                            : circleObject!.userCircleCache!.prefName == null
                                ? ''
                                : circleObject!.userCircleCache!.prefName!,
                        textScaler: const TextScaler.linear(1.0),
                        style: TextStyle(
                            color: globalState.theme.textTitle,
                            fontSize: globalState.userSetting.fontSize -
                                globalState.scaleDownTextFont),
                      ))),
            ],
          ),
        ]),
        trailing: Icon(Icons.keyboard_arrow_right,
            color: globalState.theme.cardTrailingIcon, size: 30.0),
        onTap: () {
          //openDetail(context, userFurnace);
          _tapHandler(index, circleObject!);
        },
      ));

  @override
  Widget? buildRequestApproved(BuildContext context, int index) => null;

  @override
  Widget? buildNetworkRequest(BuildContext context, int index) => null;

  @override
  Widget? buildActionRequired(BuildContext context, int index) => null;

  void _tapHandler(int index, CircleObject circleObject) async {
    if (circleObject.type == CircleObjectType.CIRCLELIST) {
      showFullList!(index, circleObject);
    } else if (circleObject.type == CircleObjectType.CIRCLEVOTE) {
      showFullVote!(index, circleObject);
    }
  }

  String getTitle(CircleObject circleObject) {
    String retValue = '';

    if (circleObject.type == CircleObjectType.CIRCLELIST) {
      if (circleObject.list!.name != null) retValue = circleObject.list!.name!;
    } else if (circleObject.type == CircleObjectType.CIRCLEVOTE) {
      if (circleObject.vote!.question != null)
        retValue = circleObject.vote!.question!;
    }

    if (retValue.length > 20) retValue.substring(0, 19);

    return retValue;
  }

  IconData? getIcon(CircleObject circleObject) {
    IconData? retValue;

    if (circleObject.type == CircleObjectType.CIRCLELIST) {
      retValue = Icons.assignment;
    } else if (circleObject.type == CircleObjectType.CIRCLEVOTE) {
      retValue = Icons.poll;
    }

    return retValue;
  }

  Color? getColor(CircleObject circleObject) {
    Color? retValue = globalState.theme.circleDefaultBackground;

    if (circleObject.type == CircleObjectType.CIRCLELIST) {
      retValue = globalState.theme.circleListBackground;
    } else if (circleObject.type == CircleObjectType.CIRCLEVOTE) {
      retValue = globalState.theme.circleVoteBackground;
    }

    return retValue;
  }

  String getType(CircleObject circleObject) {
    String retValue = '';

    if (circleObject.type == CircleObjectType.CIRCLELIST) {
      retValue = "";
    } else if (circleObject.type == CircleObjectType.CIRCLEVOTE) {
      retValue = "Vote: ";
    }

    return retValue;
  }
}
