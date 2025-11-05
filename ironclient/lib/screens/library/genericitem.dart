import 'package:flutter/material.dart';

abstract class GenericItem {
  int? type;
  String? id;
  int? userFurnacePK;

  /// The title line to show in a list item.
  Widget? buildCircleObject(BuildContext context, int index);

  /// The display for having a request to join your network as action required
  Widget? buildNetworkRequest(BuildContext context, int index);

  /// The display for an accepted network request as action required
  Widget? buildRequestApproved(BuildContext context, int index);

  /// The subtitle line, if any, to show in a list item.
  Widget? buildActionRequired(BuildContext context, int index);
}
