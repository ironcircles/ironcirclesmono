import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/dialogselectnetwork.dart';
import 'package:ironcirclesapp/screens/widgets/gradientbutton.dart';

class SelectNetworkTextButton extends StatelessWidget {
  final List<UserFurnace> userFurnaces;
  final List<UserFurnace> selectedNetworks;
  final Function callback;

  static String noNetworksSelected = "networks: no networks selected";

  const SelectNetworkTextButton({
    Key? key,
    required this.userFurnaces,
    required this.selectedNetworks,
    required this.callback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String networks = noNetworksSelected;

    if (selectedNetworks.isNotEmpty) {
      networks = "networks: ";
      for (var network in selectedNetworks) {
        networks += "${network.alias}, ";
      }
      networks = networks.substring(0, networks.length - 2);
    }

    return GradientButton(
        color1: globalState.theme.labelTextSubtle,
        color2: globalState.theme.labelTextSubtle,
        height: 40,
        onPressed: () {
          DialogSelectNetworks.selectNetworks(
              context: context,
              networks: userFurnaces,
              callback: callback,
              existingNetworksFilter: selectedNetworks);
        },
        text: networks);
  }

}
