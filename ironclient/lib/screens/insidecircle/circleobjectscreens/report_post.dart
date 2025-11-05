import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/replyobject.dart';
import 'package:ironcirclesapp/models/violation.dart';
import 'package:ironcirclesapp/screens/login/terms_of_service.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class ReportPost extends StatefulWidget {
  final int type;
  final UserCircleCache? userCircleCache;
  final UserFurnace userFurnace;
  final CircleObject? circleObject;
  final CircleObjectBloc? circleObjectBloc;
  final User? member;
  final HostedFurnace? network;
  final ReplyObject? replyObject;

  const ReportPost(
      {Key? key,
      required this.type,
      required this.userCircleCache,
      required this.userFurnace,
      required this.circleObject,
      required this.circleObjectBloc,
      required this.member,
      required this.network,
      this.replyObject})
      : super(key: key);

  @override
  _ReportPostState createState() {
    return _ReportPostState();
  }
}

class _ReportPostState extends State<ReportPost> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  TextEditingController _comments = TextEditingController();

  String _violation = '';
  String _violationSelected = '';

  List<String> _violationsList = [""];

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _violationsList = [
          "",
          AppLocalizations.of(context)!.violationIllegal,
          AppLocalizations.of(context)!.violationHarassing,
          AppLocalizations.of(context)!.violationOffensive,
          AppLocalizations.of(context)!.violationBehavior,
          AppLocalizations.of(context)!.violationRights,
        ];
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.only(left: 10, top: 4, bottom: 0),
                    child: Text(
                      widget.type == ReportType.POST
                      ? widget.replyObject != null
                      ? '${AppLocalizations.of(context)!.violator}: ${widget.replyObject!.creator!.username!}'
                      : '${AppLocalizations.of(context)!.violator}: ${widget.circleObject!.creator!.username!}'
                      : widget.type == ReportType.PROFILE
                      ? '${AppLocalizations.of(context)!.violator}: ${widget.member!.username}'
                      : '${AppLocalizations.of(context)!.violator}: ${widget.network!.name}',
                      style: TextStyle(
                          color: globalState.theme.labelText, fontSize: 16),
                    )),
                Padding(
                    padding:
                        const EdgeInsets.only(left: 10, top: 10, bottom: 0),
                    child: Text(
                      widget.type == ReportType.POST
                      ? widget.replyObject != null
                      ? '${AppLocalizations.of(context)!.messageType}: ${CircleObjectTypeString.getCircleObjectTypeString(
                          widget.replyObject!.type!)}'
                      : '${AppLocalizations.of(context)!.messageType}: ${CircleObjectTypeString.getCircleObjectTypeString(
                              widget.circleObject!.type!)}'
                      : widget.type == ReportType.PROFILE
                      ? AppLocalizations.of(context)!.violationTypeProfileAvatar
                      : AppLocalizations.of(context)!.violationTypeNetworkAvatar,
                      style: TextStyle(
                          color: globalState.theme.labelText, fontSize: 15),
                    )),
                Padding(
                  padding: const EdgeInsets.only(left: 10, top:10, bottom: 0),
                  child: Row(children: <Widget>[
                    Expanded(
                      flex: 20,
                      child: FormField(
                        builder: (FormFieldState<String> state) {
                          return FormattedDropdown(fontSize: 14,
                            expanded: true,
                            dropdownTextColor:
                                globalState.theme.textTabFieldText,
                            hintText: AppLocalizations.of(context)!.selectReportableOffense,
                            list: _violationsList,//TermsOfService.violations,
                            selected: _violationSelected,
                            errorText: state.hasError ? state.errorText : null,
                            onChanged: (String? value) {
                              setState(() {
                                _violationSelected = value!;
                                _violation = TermsOfService.violations[_violationsList.indexOf(value!)];
                                if (value!.isEmpty) value = null;
                                state.didChange(value);
                              });
                            },
                          );
                        },
                        validator: (dynamic value) {
                          return _violationSelected == ''
                              ? AppLocalizations.of(context)!.selectReportableOffense
                              : null;
                        },
                      ),
                    )
                  ]),
                ),
        Padding(
            padding: const EdgeInsets.only(left: 10, top: 10, bottom: 0),
            child:ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: ExpandingLineText(
                      textColor: globalState.theme.textTabFieldText,
                      controller: _comments,
                      labelText: AppLocalizations.of(context)!.optionalComments,
                      expands: true)),
                ),
              ]),
        ),
      ),
    );

    final makeBottom = Container(
      height: 120.0,
      child: Padding(
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 0),
          child: Column(children: <Widget>[
            Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
              TextButton(
                  child: Text(
                    AppLocalizations.of(context)!.readTermsOfService,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: globalState.theme.buttonIcon,
                    ),
                  ),
                  onPressed: () {
                    _termsOfService();
                  })
            ]),
            Row(children: <Widget>[
              Expanded(
                child: GradientButton(
                  text: AppLocalizations.of(context)!.report.toUpperCase(),
                  onPressed: () {
                    _report();
                  },
                ),
              )
            ]),
          ])),
    );

    return Form(
        key: _formKey,
        child: Scaffold(
          backgroundColor: globalState.theme.background,
          key: _scaffoldKey,
          appBar: AppBar(
            iconTheme: IconThemeData(
              color: globalState.theme.menuIcons, //change your color here
            ),
            backgroundColor: globalState.theme.appBar,
            title: Text(
                AppLocalizations.of(context)!.termsOfServiceViolation,
                style: ICTextStyle.getStyle(context: context, color: globalState.theme.textTitle, fontSize: ICTextStyle.appBarFontSize)),
          ),
          body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: makeBody,
                    ),
                    Container(
                      padding: const EdgeInsets.all(0.0),
                      child: makeBottom,
                    ),
                  ],
                ),
                _showSpinner ? Center(child: spinkit) : Container(),
              ],
            ),
          ),
        ));
  }

  _termsOfService() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TermsOfService(
            readOnly: true,
          ),
        ));
  }

  void _report() async {
    if (_formKey.currentState!.validate()) {
      Violation violation;
      if (widget.type == ReportType.POST) {
        if (widget.replyObject != null) {
          violation = Violation(
              comments: _comments.text,
              violatedTerms: _violation,
              violator: widget.replyObject!.creator!.id!,
              reporter: widget.userFurnace.userid!,
              replyObject: widget.replyObject!.id!);
        } else {
          violation = Violation(
              comments: _comments.text,
              violatedTerms: _violation,
              violator: widget.circleObject!.creator!.id!,
              reporter: widget.userFurnace.userid!,
              circleObject: widget.circleObject!.id!);
        }
      } else if (widget.type == ReportType.PROFILE) {
        violation = Violation(
            comments: _comments.text,
            violatedTerms: _violation,
            violator: widget.member!.id!,
            reporter: widget.userFurnace.userid!,
        );
      } else {
        ///type is userfurnace
        violation = Violation(
          comments: _comments.text,
          violatedTerms: _violation,
          reporter: widget.userFurnace.userid!,
          hostedFurnace: widget.network,
        );
      }

      Navigator.pop(context, violation);
    }
  }
}
