import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:provider/provider.dart';

class SettingsGeneralTransfer extends StatefulWidget {
  final UserFurnace userFurnace;
  final List<User> members;

  const SettingsGeneralTransfer({
    Key? key,
    required this.userFurnace,
    required this.members,
  }) : super(key: key);

  @override
  _SettingsGeneralState createState() => _SettingsGeneralState();
}

class _SettingsGeneralState extends State<SettingsGeneralTransfer> {
  late HostedFurnaceBloc _hostedFurnaceBloc;
  late GlobalEventBloc _globalEventBloc;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  List<ListItem> _members = [];
  ListItem? _selectedOne;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);
    _members.clear();

    _hostedFurnaceBloc.roleUpdated.listen((success) {
      Navigator.pop(context, _selectedOne!.object.id);

      FormattedSnackBar.showSnackbarWithContext(context,
          AppLocalizations.of(context)!.networkTransferred, "", 2, false);
    }, onError: (err) {
      debugPrint("MemberProfile._memberBloc.saved.listen: $err");

      if (mounted)
        setState(() {
          _showSpinner = false;
        });

      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
    }, cancelOnError: false);

    for (User user in widget.members) {
      _members.add(
          ListItem(object: user, name: user.getUsernameAndAlias(globalState)));
    }

    _selectedOne = _members[0];

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = Container(
        padding:
            const EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 20),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(
                        top: 4, bottom: 4, left: 10, right: 10),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: ICText(
                                'This account is the owner of a Network that contains other members.\n\nYou need to transfer ownership before you can delete your account and all of your account\'s associated data.'),
                          ),
                        ]),
                  ),
                  Row(children: <Widget>[
                    Expanded(
                        flex: 1,
                        child: Padding(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, bottom: 0),
                            child: FormattedDropdownObject(
                              hintText: 'transfer to',
                              selected: _selectedOne ?? _members[0],
                              list: _members,
                              // selected: _selectedOne,
                              underline: globalState.theme.bottomHighlightIcon,
                              onChanged: (ListItem? value) {
                                setState(() {
                                  _selectedOne = value;
                                });
                              },
                            ))),
                  ]),
                  const Padding(
                    padding: EdgeInsets.only(
                      top: 10,
                    ),
                  ),
                  Row(children: <Widget>[
                    /*Expanded(
                        flex: 1,
                        child:Padding(
                      padding: EdgeInsets.only(left: 1),
                    )),*/

                    Expanded(
                      flex: 2,
                      child: GradientButton(
                          text: 'TRANSFER OWNERSHIP',
                          onPressed: () {
                            _askTransferOwnership();
                          }),
                    ),
                  ]),
                ]),
          ),
        ));

    return Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            appBar: const ICAppBar(
              title: 'Transfer Network Ownership',
            ),
            body: Stack(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: makeBody,
                  ),
                  Container(
                    //  color: Colors.white,
                    padding: const EdgeInsets.all(0.0),
                    //child: makeBottom,
                  ),
                ],
              ),
              _showSpinner ? Center(child: spinkit) : Container(),
            ])));
  }

  void _askTransferOwnership() {
    if (_selectedOne == null) return;

    DialogYesNo.askYesNo(
        context,
        AppLocalizations.of(context)!.deleteAccountTitle,
        '${AppLocalizations.of(context)!.deleteAccountMessage}\n\n ${AppLocalizations.of(context)!.network}:${widget.userFurnace.alias!} - ${AppLocalizations.of(context)!.user}:${_selectedOne!.name}.',
        _transferOwnershipYes,
        null,
        false);
  }

  void _transferOwnershipYes() async {
    Navigator.pop(context, _selectedOne!.object.id);
    /*_hostedFurnaceBloc.setRole(
        widget.userFurnace, _selectedOne!.object, Role.OWNER);

    setState(() {
      _showSpinner = true;
    });

     */
  }
}
