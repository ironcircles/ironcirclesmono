import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/device_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/models/device.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/payment/premiumfeaturecheck.dart';
import 'package:ironcirclesapp/screens/settings/settings_devices_remotewipehelpers.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class SettingsDevices extends StatefulWidget {
  const SettingsDevices({
    Key? key,
  }) : super(key: key);

  @override
  _SettingsDevicesState createState() => _SettingsDevicesState();
}

class _SettingsDevicesState extends State<SettingsDevices> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _formKey = GlobalKey<FormState>();
  final DeviceBloc _deviceBloc = DeviceBloc();
  List<Device> _devices = [];
  final ScrollController _scrollController = ScrollController();
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();

  bool _showSpinner = true;
  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  @override
  void initState() {
    _deviceBloc.devicesLoaded.listen((devices) {
      if (mounted) {
        setState(() {
          _devices = devices;
          _showSpinner = false;
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

    _deviceBloc.deactivated.listen((device) {
      if (mounted) {
        setState(() {
          _devices.removeWhere((element) => element.id == device.id);
          _showSpinner = false;
          FormattedSnackBar.showSnackbarWithContext(
              context, AppLocalizations.of(context)!.deactivated.toLowerCase(), "", 2, false);
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

    _deviceBloc.wiped.listen((device) {
      if (mounted) {
        setState(() {
          _devices.removeWhere((element) => element.id == device.id);
          _showSpinner = false;
          FormattedSnackBar.showSnackbarWithContext(
              context, AppLocalizations.of(context)!.deviceWiped.toLowerCase(), "", 2, false);
        });
      }
    }, onError: (err) {
      FormattedSnackBar.showSnackbarWithContext(
          context, err.toString(), "", 2, false);
      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    _userFurnaceBloc.userfurnaces.listen((userFurnaces) {
      _deviceBloc.get(userFurnaces!);
    }, onError: (err) {
      // FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 1);
      //_clearSpinner();
      debugPrint("error $err");
    }, cancelOnError: false);

    _userFurnaceBloc.requestConnected(globalState.user.id);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width - 20;

    final showHelpers = Row(children: [
      const Spacer(),
      GradientButtonDynamic(
          text: AppLocalizations.of(context)!.remoteWipeHelpersTitle,
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SettingsDevicesRemoteWipeHelpers()));
            //_updateMembers();
          }),
    ]);

    ListView _showDevices() => ListView.builder(
        //reverse: isUser ? true : false,
        itemCount: _devices.length,
        padding: const EdgeInsets.only(right: 10, left: 10),
        controller: _scrollController,
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        //gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // crossAxisCount: 1,
        //  ),
        itemBuilder: (BuildContext context, int index) {
          return Column(mainAxisSize: MainAxisSize.min, children: [
            index == 0
                ? Column(children: [
                    Row(
                      children: [
                        SizedBox(
                            width: width * 0.2,
                            child: ICText(
                              AppLocalizations.of(context)!.oS,
                              fontWeight: FontWeight.bold,
                            )),
                        //Spacer(),
                        SizedBox(
                            width: width * 0.4,
                            child: ICText(
                              AppLocalizations.of(context)!.model,
                              fontWeight: FontWeight.bold,
                            )),
                        //Spacer(),
                        SizedBox(
                            width: width * 0.4,
                            child: ICText(
                              AppLocalizations.of(context)!.lastAuth,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                    ),
                    const Divider(
                      color: Colors.grey,
                      height: 2,
                      thickness: 2,
                      indent: 0,
                      endIndent: 0,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                    ),
                  ])
                : Container(),
            Row(
              children: [
                SizedBox(
                    width: width * 0.2,
                    child: ICText(_devices[index].platform == null
                        ? ''
                        : _devices[index].platform!)),
                //Spacer(),
                SizedBox(
                    width: width * 0.4,
                    child: ICText(_devices[index].model == null
                        ? AppLocalizations.of(context)!.unknown
                        : _devices[index].model!)),
                // Spacer(),
                SizedBox(
                    width: width * 0.4,
                    child: ICText(_devices[index].lastAccessed == null
                        ? ''
                        : '${DateFormat.yMMMd().format(_devices[index].lastAccessed!)}, ${DateFormat.jm().format(_devices[index].lastAccessed!)}')),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 5),
            ),
            Row(
              children: [
                const Spacer(),
                GradientButtonDynamic(
                  color: globalState.theme.labelTextSubtle,
                  text: AppLocalizations.of(context)!.remoteWipe,
                  onPressed: () {
                    _askRemoteWipe(_devices[index]);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 5),
                ),
                GradientButtonDynamic(
                  color: globalState.theme.labelTextSubtle,
                  text: AppLocalizations.of(context)!.deactivate,
                  onPressed: () {
                    _askDeactivate(_devices[index]);
                  },
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 5),
            ),
            const Divider(
              color: Colors.grey,
              height: 2,
              thickness: 2,
              indent: 0,
              endIndent: 0,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 5),
            ),
          ]);
          //  return Text(_releases[index].version);
        });

    return Form(
        key: _formKey,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: globalState.theme.background,
            appBar: ICAppBar(title: AppLocalizations.of(context)!.devices),
            body: Stack(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  showHelpers,
                  const Padding(
                    padding: EdgeInsets.only(top: 15),
                  ),
                  _devices.isNotEmpty
                      ? Expanded(
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              //mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                              Expanded(flex: 1, child: _showDevices())
                            ]))
                      : Container()
                ],
              ),
              _showSpinner ? Center(child: spinkit) : Container(),
            ])));
  }

  void _askDeactivate(Device deactivateDevice) async {
    Device device = await globalState.getDevice();

    if (mounted) {
      if (deactivateDevice.uuid == device.uuid) {
        DialogNotice.showNoticeOptionalLines(
            context,
            AppLocalizations.of(context)!.cannotDeactivateTitle,
            AppLocalizations.of(context)!.cannotDeactivateMessage,
            false);
      } else
        DialogYesNo.askYesNo(
            context,
            AppLocalizations.of(context)!.askDeactivateDeviceTitle,
            AppLocalizations.of(context)!.askDeactivateDeviceMessage,
            _deactivateYes,
            null,
            false,
            deactivateDevice);
    }
  }

  void _deactivateYes(Device device) {
    setState(() {
      _showSpinner = true;
    });
    _deviceBloc.deactivate(device);
  }

  void _askRemoteWipe(Device wipeDevice) async {
    if (PremiumFeatureCheck.remoteWipeOn(context)) {
      Device device = await globalState.getDevice();

      if (mounted) {
        if (wipeDevice.uuid == device.uuid) {
          DialogYesNo.askYesNo(
              context,
              AppLocalizations.of(context)!.wipeCurrentDeviceTitle,
              AppLocalizations.of(context)!.wipeCurrentDeviceMessage,
              _remoteWipeYes,
              null,
              false,
              wipeDevice);
        } else
          DialogYesNo.askYesNo(
              context,
              AppLocalizations.of(context)!.wipeRemoteDeviceTitle,
              AppLocalizations.of(context)!.wipeRemoteDeviceMessage,
              _remoteWipeYes,
              null,
              false,
              wipeDevice);
      }
    }
  }

  void _remoteWipeYes(Device device) {
    _deviceBloc.remoteWipe(device);
  }
}
