import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/models/actionrequired.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/library/genericitem.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbuttondynamic.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

/// A ListItem that contains data to display a message.
class ActionRequiredItem implements GenericItem {
  @override
  int? type;
  @override
  String? id;
  @override
  int? userFurnacePK;
  Function? tapHandler;
  Function? dismiss;
  final ActionRequired? actionRequired;
  Function? joinNetwork;
  List<UserFurnace>? userFurnaces;
  HostedFurnaceBloc? hostedFurnaceBloc;

  ActionRequiredItem(
      {this.actionRequired,
      this.userFurnaces,
      this.type,
      this.userFurnacePK,
      this.id,
      this.tapHandler,
      this.joinNetwork,
      this.dismiss,
      this.hostedFurnaceBloc});

  @override
  Widget? buildCircleObject(BuildContext context, int index) => null;

  @override
  Widget? buildNetworkRequest(BuildContext context, int index) => Card(
    surfaceTintColor: Colors.transparent,
    color: globalState.theme.card,
    elevation: 8.0,
    margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 6.0),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
      leading: Container(
        padding: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              width: 1.0, color: globalState.theme.boxOutline))),
        child: Icon(Icons.priority_high,
        color: globalState.theme.cardLeadingIcon),
      ),
      title: Container(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          "${AppLocalizations.of(context)!.usersRequestedToJoin} ${actionRequired!.userFurnace!.alias!}",
          textScaler: TextScaler.linear(globalState.cardScaleFactor),
          style: TextStyle(
            color: globalState.theme.cardTitle,
            fontSize: globalState.userSetting.fontSize),
        )
      ),
      subtitle: Column(children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(
                        left: 5.0, bottom: 0, top: 10),
                    child: Text(
                      actionRequired!.userFurnace!.alias!,
                      textScaler: TextScaler.linear(globalState.cardScaleFactor),
                      style: TextStyle(color: globalState.theme.furnace),
                    ))),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
              //flex: 0,
                child: Padding(
                    padding:
                    const EdgeInsets.only(left: 5.0, bottom: 5, top: 0),
                    child: Text(actionRequired!.userFurnace!.username!,
                        textScaler: TextScaler.linear(globalState.cardScaleFactor),
                        style: TextStyle(
                          color: globalState.theme.username,
                        )))),
          ],
        ),
      ]),
        trailing:  Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GradientButtonDynamic(
            onPressed: () {
              tapHandler!(index, actionRequired);
            },
            text: AppLocalizations.of(context)!.viewRequests,
          )
        )
    )
  );

  @override
  Widget? buildRequestApproved(BuildContext context, int index) => Card(
      surfaceTintColor: Colors.transparent,
      color:
          actionRequired!.alertType == ActionRequiredAlertType.HELP_WITH_RESET
              ? globalState.theme.cardUrgent
              : globalState.theme.card,
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
            child: Icon(Icons.priority_high,
                color: globalState.theme.cardLeadingIcon),
          ),
          title: Container(
            padding: const EdgeInsets.only(top: 5.0),
            child: Text(
              _insertAlias(actionRequired!),
              textScaler: TextScaler.linear(globalState.cardScaleFactor),
              style: TextStyle(
                  color: globalState.theme.cardTitle,
                  fontSize: globalState.userSetting.fontSize),
            ),
          ),
          subtitle: Column(children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 5.0, bottom: 0, top: 10),
                        child: Text(
                          actionRequired!.userFurnace!.alias!,
                          textScaler: TextScaler.linear(globalState.cardScaleFactor),
                          style: TextStyle(color: globalState.theme.furnace),
                        ))),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                    //flex: 0,
                    child: Padding(
                        padding:
                            const EdgeInsets.only(left: 5.0, bottom: 5, top: 0),
                        child: Text(actionRequired!.userFurnace!.username!,
                            textScaler: TextScaler.linear(globalState.cardScaleFactor),
                            style: TextStyle(
                              color: globalState.theme.username,
                            )))),
              ],
            ),
          ]),
          trailing:  GradientButtonDynamic(
                onPressed: () {
                  joinNetwork!(actionRequired);
                },
                text: AppLocalizations.of(context)!.joinNow,
              )));

  @override
  Widget buildActionRequired(BuildContext context, int index) => Card(
      surfaceTintColor: Colors.transparent,
      color:
          actionRequired!.alertType == ActionRequiredAlertType.HELP_WITH_RESET
              ? globalState.theme.cardUrgent
              : globalState.theme.card,
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
          child: Icon(Icons.priority_high,
              color: globalState.theme.cardLeadingIcon),
        ),
        title: Container(
          padding: const EdgeInsets.only(top: 5.0),
          child: Text(
            _insertAlias(actionRequired!),
            textScaler: TextScaler.linear(globalState.cardScaleFactor),
            //circleObject.userFurnace.alias,
            style: TextStyle(
                color: globalState.theme.cardTitle,
                fontSize: globalState.userSetting.fontSize),
          ),
        ),
        subtitle: Column(children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                  child: Padding(
                      padding:
                          const EdgeInsets.only(left: 5.0, bottom: 0, top: 10),
                      child: Text(
                        actionRequired!.userFurnace!.alias!,
                        textScaler: TextScaler.linear(globalState.cardScaleFactor),
                        style: TextStyle(color: globalState.theme.furnace),
                      ))),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                  //flex: 0,
                  child: Padding(
                      padding:
                          const EdgeInsets.only(left: 5.0, bottom: 5, top: 0),
                      child: Text(actionRequired!.userFurnace!.username!,
                          textScaler: TextScaler.linear(globalState.cardScaleFactor),
                          style: TextStyle(
                            color: globalState.theme.username,
                          )))),
            ],
          ),
          dismiss != null
              ? Row(
                  children: <Widget>[
                    const Spacer(),
                    TextButton(
                        onPressed: () {
                          dismiss!(actionRequired!);
                        },
                        child: ICText(
                          AppLocalizations.of(context)!.dismiss,
                          color: globalState.theme.buttonDisabled,
                        )),
                  ],
                )
              : Container(),
        ]),
        trailing: Icon(Icons.keyboard_arrow_right,
            color: globalState.theme.cardTrailingIcon, size: 30.0),
        onTap: () {
          tapHandler!(index, actionRequired);
        },
      ));

  _insertAlias(ActionRequired actionRequired) {
    String alert = actionRequired.alert ?? '';

    if (actionRequired.resetUser != null) {
      if (alert.contains('User')) {
        alert = alert.replaceFirst(
            'User', actionRequired.resetUser!.getUsernameAndAlias(globalState));
      }
    }

    return alert;
  }
}
