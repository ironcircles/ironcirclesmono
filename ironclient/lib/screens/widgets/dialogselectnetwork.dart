import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class DialogSelectNetworks {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static selectNetworks(
      {required BuildContext context,
      required List<UserFurnace> networks,
      required List<UserFurnace> existingNetworksFilter,
      required Function callback}) async {
    await showDialog(
      barrierColor: Colors.black.withOpacity(.8),
      context: context,
      builder: (ctx) {
        return MultiSelectDialog(
          title: ICText(
            'Post to which networks?',
            color: globalState.theme.buttonIcon,
          ),
          items: networks
              .map((network) =>
                  MultiSelectItem<UserFurnace>(network, network.alias!))
              .toList(),
          backgroundColor: globalState.theme.drawerCanvas,
          unselectedColor: globalState.theme.labelText,
          selectedColor: globalState.theme.buttonIcon,
          selectedItemsTextStyle: TextStyle(
              color: globalState.theme.buttonIcon,
              fontSize: 16,
              fontWeight: FontWeight.bold),
          itemsTextStyle: TextStyle(
            color: globalState.theme.labelText,
            fontSize: 16,
          ),
          height: 350,
          initialValue: existingNetworksFilter,
          cancelText: Text(
            'Cancel',
            style: TextStyle(color: globalState.theme.labelTextSubtle),
          ),
          confirmText: Text(
            'Ok',
            style: TextStyle(color: globalState.theme.buttonIcon),
          ),
          checkColor: globalState.theme.checkBoxCheck,
          onConfirm: (values) {
            List<UserFurnace> _networkFilter =
                []; //values as List<UserFurnace>;

            for (Object? selected in values) {
              //  MultiSelectItem<UserFurnace> item =
              //       selected as MultiSelectItem<UserFurnace>;
              UserFurnace userFurnace = selected as UserFurnace;
              _networkFilter.add(userFurnace);
            }
            callback(_networkFilter);
          },
        );
      },
    );
  }
}
