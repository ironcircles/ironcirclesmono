import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ratchetkey.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ndialog/ndialog.dart';

class UserKeyView extends StatefulWidget {
  final UserFurnace userFurnace;
  final User user;
  const UserKeyView({required this.userFurnace, required this.user});

  _KeychainViewState createState() => _KeychainViewState();
}

class _KeychainViewState extends State<UserKeyView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  //KeychainBackupBloc _keychainBackupBloc = KeychainBackupBloc();

  //TextEditingController _passcodeController = TextEditingController();
  ProgressDialog? progressDialog;
  ProgressDialog? importingData;

  final String _numberOfKeys = '';

  bool _showSpinner = true;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  List<RatchetKey> _keys = [];


  _populateKeys() async {
    _keys = await RatchetKey.findRatchetKeysForAllUsers();

    setState(() {

      _showSpinner = false;
    });

  }
  @override
  void initState() {
   _populateKeys();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar: AppBar(
          actions: const <Widget>[],
          iconTheme: IconThemeData(
            color: globalState.theme.menuIcons, //change your color here
          ),
          backgroundColor: globalState.theme.background,
          title: Text(AppLocalizations.of(context)!.rawKeychainData + ': ' + _numberOfKeys,
              style: ICTextStyle.getStyle(context: context, color: globalState.theme.textTitle, fontSize: ICTextStyle.appBarFontSize)),
        ),
        body: SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: true,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    //mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Expanded(
                        child: _keys.isNotEmpty
                            ? ListView.separated(
                                separatorBuilder: (context, index) {
                                  return Divider(
                                    height: 10,
                                    color: globalState.theme.background,
                                  );
                                },
                                itemCount: _keys.length,
                                itemBuilder: (BuildContext context, int index) {
                                  var row = _keys[index];

                                  return Text('$index: ${row.user}\n${row.keyIndex}\n${row.public}\n${row.private}\n\n');
                                })
                            : Container(),
                      )
                    ]),
              ),
              _showSpinner ? Center(child: spinkit) : Container(),
            ],
          ),
        ));
  }
}
