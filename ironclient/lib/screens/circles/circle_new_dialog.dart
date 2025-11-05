import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/circles/circle_new_wizard_name.dart';
import 'package:ironcirclesapp/screens/circles/circle_new_wizard_settings.dart';
import 'package:ironcirclesapp/screens/widgets/formatteddropdownobject.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class DialogNewCircle {
  //static AuthenticationBloc _authBloc = AuthenticationBloc();
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static show(
    BuildContext context,
    List<UserFurnace> userFurnaces,
    List<ListItem> circleTypeList,
  ) async {
    //bool _validPassword = false;
    //TextEditingController _password = TextEditingController();

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: ICText(AppLocalizations.of(context)!.shareOrDownloadQuestion,
              textScaleFactor: globalState.dialogScaleFactor,
              fontSize: 18,
              color: globalState.theme.textTitle),
          contentPadding: const EdgeInsets.all(10.0),
          content: SizedBox(
              height: 800,
              width: 500,
              child: Holder(
                userFurnaces: userFurnaces,
                circleTypeList: circleTypeList,
              )),
          actions: <Widget>[
            TextButton(child: const Text('NEXT'), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

class _SystemPadding extends StatelessWidget {
  final Widget? child;

  const _SystemPadding({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        //padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        duration: const Duration(milliseconds: 300),
        child: child);
  }
}

class Holder extends StatefulWidget {
  final List<UserFurnace> userFurnaces;
  final List<ListItem> circleTypeList;

  const Holder({required this.userFurnaces, required this.circleTypeList});

  @override
  _LocalState createState() => _LocalState();
}

enum Screen { name, settings, invitations }

class _LocalState extends State<Holder> {
  //bool _showPassword = false;
  Screen _screen = Screen.name;
  List<String> _timerValues = [];
  ListItem? _selected;
  WizardVariables _wizardVariables = WizardVariables(
      circle: Circle(
          dm: false,
          name: '',
          privacyShareImage: true,
          privacyShareGif: true,
          privacyCopyText: true,
          privacyShareURL: true,
          toggleEntryVote: false),
      members: []);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _screen == Screen.name
        ? CircleNewWizardName(
            userFurnaces: widget.userFurnaces,
            circleTypeList: widget.circleTypeList,
            // next: _next
    )
        : _screen == Screen.settings
            ? CircleNewWizardSettings(
                userFurnace: widget.userFurnaces.firstWhere(
                  (element) => element.pk == _selected!.object.pk,
                ),
                wizardVariables: _wizardVariables,
                timerValues: _timerValues,
              )
            : Container();
  }

  _next(WizardVariables wizardVariables, ListItem selected,
      List<String> timerValues) {
    setState(() {
      _wizardVariables = wizardVariables;
      _selected = selected;
      _timerValues = timerValues;
      _screen = Screen.settings;
    });
  }
}
