import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/models/dropdownpair.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class NetworkDetailStorage extends StatefulWidget {
  final UserFurnace userFurnace;
  final HostedFurnaceBloc hostedFurnaceBloc;
  final List<DropDownPair> dropDownList;

  const NetworkDetailStorage({
    Key? key,
    required this.userFurnace,
    required this.hostedFurnaceBloc,
    required this.dropDownList,
  }) : super(key: key);

  @override
  _NetworkDetailStorageState createState() => _NetworkDetailStorageState();
}

class _NetworkDetailStorageState extends State<NetworkDetailStorage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accessKey = TextEditingController();
  final TextEditingController _secretKey = TextEditingController();
  final TextEditingController _mediaBucket = TextEditingController();
  final TextEditingController _region = TextEditingController();


  late DropDownPair _selected;
  HostedFurnaceStorage _hostedFurnaceStorage =
      HostedFurnaceStorage(location: '');
  bool _showS3AndWasabi = false;
  bool _showKeys = false;
  bool _showSpinner = true;
  bool _loaded = false;
  final _spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _selected = widget.dropDownList[0];

    widget.hostedFurnaceBloc.storageSet.listen((result) {
      if (mounted) {
        setState(() {
          _showSpinner = false;
          _hostedFurnaceStorage = HostedFurnaceStorage(location: _selected.id);
        });

        FormattedSnackBar.showSnackbarWithContext(
            context, AppLocalizations.of(context)!.storageSet, "", 2, false);

        /*_mediaBucket.text = '';
        _avatarBucket.text = '';
        _accessKey.text = '';
        _secretKey.text = '';

         */
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    widget.hostedFurnaceBloc.storageLoaded.listen((hostedFurnaceStorage) {
      if (mounted) {
        setState(() {
          _showSpinner = false;
          _loaded = true;
          _hostedFurnaceStorage = hostedFurnaceStorage;
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, true);
      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    widget.hostedFurnaceBloc.getStorage(widget.userFurnace);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = Container(
        padding: const EdgeInsets.only(left: 10, right: 0, top: 10, bottom: 20),
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
                constraints: const BoxConstraints(),
                child: WrapperWidget(child:Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(children: <Widget>[
                        Padding(
                            padding:
                                const EdgeInsets.only(left: 20, bottom: 10),
                            child: ICText(
                              AppLocalizations.of(context)
                                  !.dataRetention, //'Data Retention:',
                              fontSize: 15,
                            )),
                      ]),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        child: Row(children: <Widget>[
                          Expanded(
                            flex: 20,
                            child: InputDecorator(

                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.all(10),
                                //hintText: 'change the member\'s role',
                                hintStyle: TextStyle(
                                    color: globalState.theme.textFieldLabel),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: globalState.theme.button),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: globalState.theme.labelTextSubtle),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              //isEmpty: _furnace == 'first match',
                              child: DropdownButtonHideUnderline(

                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                      canvasColor:
                                          globalState.theme.dropdownBackground),
                                  child: DropdownButton<DropDownPair>(
                                    padding: const EdgeInsets.all(0),
                                    value: _selected,
                                    isDense: true,
                                    onChanged: (DropDownPair? newValue) async {
                                      String selected = newValue!.id;

                                      if (selected ==
                                              BlobLocation.PRIVATE_WASABI ||
                                          selected == BlobLocation.PRIVATE_S3) {
                                        if (mounted) {
                                          bool canChangeStorage =
                                              await PremiumFeatureCheck
                                                  .canChangeStorage(context,
                                                      widget.userFurnace);

                                          if (canChangeStorage) {
                                            _showS3AndWasabi = true;
                                          }
                                        }
                                      } else {
                                        _showS3AndWasabi = false;
                                      }

                                      if (_showS3AndWasabi == true) {
                                        setState(() {
                                          _selected = newValue;
                                        });
                                      }
                                    },
                                    items: widget.dropDownList
                                        .map<DropdownMenuItem<DropDownPair>>(
                                            (DropDownPair value) {
                                      return DropdownMenuItem<DropDownPair>(
                                        value: value,
                                        child: Container(
                                          padding:
                                              const EdgeInsets.only(left: 16),
                                          child: Text(
                                            value.value,
                                            textScaler: TextScaler.linear(globalState.dropdownScaleFactor),
                                            style: ICTextStyle.getDropdownStyle(context: context,
                                                fontSize: 14,
                                                color: globalState
                                                    .theme.dropdownText),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    isExpanded: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                      _showS3AndWasabi
                          ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 20, top: 20, bottom: 4),
                              child: Row(children: <Widget>[
                                Expanded(
                                  child: FormattedText(
                                    labelText: 'access key',
                                    maxLength: 25,
                                    obscureText: !_showKeys,
                                    readOnly: (widget.userFurnace.role ==
                                                Role.OWNER ||
                                            widget.userFurnace.role ==
                                                Role.ADMIN)
                                        ? false
                                        : true,
                                    controller: _accessKey,
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return 'field is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: _showKeys
                                        ? IconButton(
                                            icon: Icon(Icons.visibility,
                                                color: globalState
                                                    .theme.buttonIcon),
                                            onPressed: () {
                                              setState(() {
                                                _showKeys = false;
                                              });
                                            })
                                        : IconButton(
                                            icon: Icon(Icons.visibility,
                                                color: globalState
                                                    .theme.buttonDisabled),
                                            onPressed: () {
                                              setState(() {
                                                _showKeys = true;
                                              });
                                            }))
                              ]))
                          : Container(),
                      _showS3AndWasabi
                          ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 20, top: 4, bottom: 4, right: 20),
                              child: Row(children: <Widget>[
                                Expanded(
                                  child: FormattedText(
                                    labelText: 'secret key',
                                    maxLength: 50,
                                    obscureText: !_showKeys,
                                    readOnly: (widget.userFurnace.role ==
                                                Role.OWNER ||
                                            widget.userFurnace.role ==
                                                Role.ADMIN)
                                        ? false
                                        : true,
                                    controller: _secretKey,
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return 'field is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ]))
                          : Container(),
                      _showS3AndWasabi
                          ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 20, top: 4, bottom: 4, right: 20),
                              child: Row(children: <Widget>[
                                Expanded(
                                  child: FormattedText(
                                    labelText: 'region (ie: us-east-2)',
                                    maxLength: 50,
                                    controller: _region,
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return 'field is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ]))
                          : Container(),
                      _showS3AndWasabi
                          ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 20, top: 4, bottom: 4, right: 20),
                              child: Row(children: <Widget>[
                                Expanded(
                                  child: FormattedText(
                                    labelText: 'media bucket',
                                    maxLength: 50,
                                    controller: _mediaBucket,
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return 'field is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ]))
                          : Container(),
                      _showS3AndWasabi
                          ? Padding(
                              padding: const EdgeInsets.only(
                                  left: 20, top: 4, bottom: 4, right: 20),
                              child: Row(children: <Widget>[
                                const Spacer(),
                                GradientButtonDynamic(
                                  text:
                                      AppLocalizations.of(context)!.set, //'set',
                                  onPressed: _setStorage,
                                )
                              ]))
                          : Container()
                    ])))));

    final showStorage = Container(
        padding: const EdgeInsets.only(left: 10, right: 0, top: 10, bottom: 20),
        child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
                constraints: const BoxConstraints(),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(children: <Widget>[
                        Padding(
                            padding: const EdgeInsets.only(left: 20, right: 10),
                            child: ICText(
                              _hostedFurnaceStorage.location ==
                                      BlobLocation.PRIVATE_S3
                                  ? 'Private S3 Blob Storage Set'
                                  : _hostedFurnaceStorage.location ==
                                          BlobLocation.PRIVATE_WASABI
                                      ? 'Private Wasabi Blob Storage Set'
                                      : 'Storage Set',
                              fontSize: 18,
                            )),
                        Icon(Icons.check_circle,
                            color: globalState.theme.buttonIcon),
                      ]),
                      Row(children: <Widget>[
                        const Spacer(),
                        Padding(
                            padding: const EdgeInsets.only(top: 10, right: 20),
                            child: GradientButtonDynamic(
                              text: AppLocalizations.of(context)
                                  !.change, //'change',
                              onPressed: () {
                                setState(() {
                                  _hostedFurnaceStorage =
                                      HostedFurnaceStorage(location: '');
                                });
                              },
                            )),
                      ]),
                    ]))));

    return Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            appBar: ICAppBar(
              title: AppLocalizations.of(context)
                  !.mediaStorageOptions, // 'Media Storage Options',
            ),
            body: Stack(children: [
              _loaded
                  ? _hostedFurnaceStorage.location.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: makeBody,
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: showStorage,
                            ),
                          ],
                        )
                  : Container(),
              _showSpinner ? Center(child: _spinkit) : Container(),
            ])));
  }

  _setStorage() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _showSpinner = true;
      });

      widget.hostedFurnaceBloc.setStorage(widget.userFurnace, _selected.id,
          _accessKey.text, _secretKey.text, _region.text, _mediaBucket.text);
    }
  }
}
