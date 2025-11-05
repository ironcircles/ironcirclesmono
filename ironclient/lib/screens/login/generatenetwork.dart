import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/authentication_bloc.dart';
import 'package:ironcirclesapp/blocs/database_bloc.dart';
import 'package:ironcirclesapp/blocs/firebase_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/hostedfurnace_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/stablediffusionai_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/blocs/userfurnace_bloc.dart';
import 'package:ironcirclesapp/constants/export_constants.dart';
import 'package:ironcirclesapp/encryption/securerandomgenerator.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/hostedinvitation.dart';
import 'package:ironcirclesapp/models/stablediffusionprompt.dart';
import 'package:ironcirclesapp/screens/login/generatenetwork_account.dart';
import 'package:ironcirclesapp/screens/stablediffusion/stablediffusion_configuration.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/icprogressdialog.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';
import 'package:ironcirclesapp/services/securestorage_service.dart';
import 'package:ironcirclesapp/utils/imageutil.dart';
import 'package:ndialog/ndialog.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart' as Toggle;

enum GenerateNetworkCaller {
  applink,
  join_friends,
  network_manager,
  new_network,
  new_from_request,
}

class GenerateNetwork extends StatefulWidget {
  final String? toast;
  final GenerateNetworkCaller caller;
  final UserFurnace? userFurnace;
  final bool linkedAccount;
  final HostedInvitation? hostedInvitation;
  final bool fromNetworkManager;

  const GenerateNetwork(
      {Key? key,
      this.toast,
      required this.caller,
      this.userFurnace,
      required this.linkedAccount,
      this.fromNetworkManager = false,
      this.hostedInvitation})
      : super(key: key);

  @override
  _GenerateNetworkState createState() {
    return _GenerateNetworkState();
  }
}

class _GenerateNetworkState extends State<GenerateNetwork> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _networkName = TextEditingController();
  final TextEditingController _networkUrl = TextEditingController();
  final TextEditingController _networkApiKey = TextEditingController();
  StableDiffusionPrompt stableDiffusionAIParams =
      StableDiffusionPrompt(promptType: PromptType.generate);
  StableDiffusionAIBloc stableDiffusionAIBloc = StableDiffusionAIBloc();
  late HostedFurnaceBloc _hostedFurnaceBloc;
  late GlobalEventBloc _globalEventBloc;

  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _authBloc = AuthenticationBloc();
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  late FirebaseBloc _firebaseBloc;
  final databaseBloc = DatabaseBloc();
  ProgressDialog? importingData;
  String assigned = '';
  String? _toast;
  bool _showSpinner = false;
  bool validatedOnceAlready = false;
  File? _img;
  File? _imgTemp;
  //double radius = 171;
  int _initialIndex = 0;
  bool _boolSelfHosted = false;

  bool _genImage = false;
  int _seed = 0;
  final UserFurnace _userFurnace = UserFurnace(alias: '');
  ICProgressDialog icProgressDialog = ICProgressDialog();
  final double _iconPadding = 12;

  final spinkit = SpinKitDualRing(
    color: globalState.theme.spinner,
    size: 60,
  );

  _goHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (Route<dynamic> route) => false,
      arguments: globalState.user,
    );
  }

  @override
  void initState() {
    //_networkUrl.text = "https://iron.ferrumcirculus.com";

    if (kDebugMode) {
      _networkUrl.text = "https://ironfurny.herokuapp.com/";
      _networkApiKey.text = "J73Hpqj362J4psX7jyhXdftbxSPYkE9CrjWShz9r";
    }

    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

    stableDiffusionAIParams.setNegativePrompt(ImageType.network);

    if (kDebugMode && !Urls.testingReleaseMode) {
      _username.text = 'maven${SecureRandomGenerator.generateInt(max: 5)}';

      _networkName.text = '${_username.text}\'s network';

      stableDiffusionAIParams.setPrompt(_networkName.text, ImageType.network);
    }

    if (widget.userFurnace != null) {
      _networkName.text = widget.userFurnace!.alias!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _showToast(context));
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);

    super.initState();
    //handleAppLifecycleState();

    UserCircleBloc.closeHiddenCircles(_firebaseBloc);

    globalState.loggingOut = false;

    _userFurnaceBloc.userFurnace.listen((success) {
      if (widget.caller == GenerateNetworkCaller.new_network ||
          widget.caller == GenerateNetworkCaller.join_friends ||
          widget.caller == GenerateNetworkCaller.applink) {
        globalState.showHomeTutorial = true;
        globalState.showPrivateVaultPrompt = true;
      }

      _goHome();
    }, onError: (err) {
      //FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2);
      LogBloc.postLog('Error:$err', 'RegistrationShort');

      if (err.toString().contains('username') &&
          err.toString().contains('unique')) {
        DialogNotice.showNotice(context, 'Username already exists',
            'Please select a different username', null, null, null, false);
      } else if (err.toString().contains('reserved')) {
        DialogNotice.showNotice(context, 'Username is reserved',
            'Please select a different username', null, null, null, false);
      } else if (err.toString().contains('unauthorized')) {
        DialogNotice.showNotice(context, 'Please try again',
            'Network name or access code invalid', null, null, null, false);
      } else if (err.toString().contains('failed')) {
        DialogNotice.showNotice(
            context,
            'Failed Last Attempt',
            'You can no longer try to join this network',
            null,
            null,
            null,
            false);
      } else if (err.toString().contains('exceeded')) {
        DialogNotice.showNotice(context, 'Exceeded Allowed Attempts',
            'You cannot try to join this network', null, null, null, false);
      } else if (err.toString().contains('wait')) {
        String trimmedMessage =
            " ${err.message.toString().substring(4, err.message.toString().length)}";
        FormattedSnackBar.showSnackbarWithContext(
            context,
            AppLocalizations.of(context)!.joinWait1 +
                trimmedMessage +
                AppLocalizations.of(context)!.joinWait2,
            "",
            2,
            false);
      } else {
        DialogNotice.showNotice(
            context,
            'Please try again',
            err.toString().replaceAll('Exception: ', ''),
            null,
            null,
            null,
            true);
      }

      debugPrint("error $err");
      setState(() {
        _showSpinner = false;
      });
    }, cancelOnError: false);

    if (widget.toast != null) _toast = widget.toast;
  }

  _showToast(BuildContext context) {
    if (_toast != null) {
      FormattedSnackBar.showSnackbarWithContext(
          context, widget.toast!, "", 2, true);
      _toast = null;
    }
  }

  @override
  void dispose() {
    _username.dispose();

    _authBloc.dispose();
    databaseBloc.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double textScale = MediaQuery.textScalerOf(context).scale(1);

    final networkImage = Padding(
        padding: const EdgeInsets.only(top: 5, left: 10),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InkWell(
                  splashColor: Colors.transparent,
                  onTap: () async {
                    File? cropped = await ImageUtil.cropImage(context, _img);
                    if (cropped != null) {
                      setState(() {
                        _img = cropped;
                      });
                    }
                  },
                  child: Container(
                      width: ScreenSizes.getMaxImageWidth(width) -
                          ICPadding.GENERATE_BUTTONS,
                      height: ScreenSizes.getMaxImageWidth(width) -
                          ICPadding.GENERATE_BUTTONS,
                      constraints: BoxConstraints(
                          maxHeight: ScreenSizes.getMaxImageWidth(width) -
                              ICPadding.GENERATE_BUTTONS,
                          maxWidth: ScreenSizes.getMaxImageWidth(width) -
                              ICPadding.GENERATE_BUTTONS),
                      child: ClipOval(
                          child: InkWell(
                        splashColor: Colors.transparent,
                        child: _img != null
                            ? Image.file(_img!,
                                //height: radius,
                                //width: radius,
                                fit: BoxFit.cover)
                            : Opacity(
                                opacity: .1,
                                child: Image.asset(
                                  'assets/images/ios_icon.png',
                                  // height: radius,
                                  //width: radius,
                                  fit: BoxFit.fitWidth,
                                )),
                      )))),
              const Padding(
                padding: EdgeInsets.only(
                  right: 5,
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  GradientButtonDynamic(
                    text: _genImage
                        ? AppLocalizations.of(context)!.regenerate
                        : AppLocalizations.of(context)!
                            .generateImage, // 'regenerate' : 'generate image',
                    fontSize: 14,
                    color: globalState.theme.buttonGenerate,
                    onPressed: _generateImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune),
                    color: globalState.theme.buttonGenerate,
                    onPressed: () {
                      _closeKeyboard();

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StableDiffusionConfiguration(
                                prompt: stableDiffusionAIParams,
                                freeGen: true,
                                imageGenType: ImageType.network),
                          ));
                    },
                  ),
                ]),
                stableDiffusionAIParams.visualOnlySeed != -1
                    ? Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          children: [
                            //const Spacer(),
                            ICText(
                              "Seed: ",
                              color: globalState.theme.labelText,
                            ),
                            SelectableText(
                              stableDiffusionAIParams.visualOnlySeed.toString(),
                              textScaler: const TextScaler.linear(1),
                              style:
                                  TextStyle(color: globalState.theme.labelText),
                            ),
                            // const Spacer()
                          ],
                        ))
                    : Container(),
                const Padding(
                  padding: EdgeInsets.only(top: 0, bottom: 10),
                ),
                Row(children: [
                  GradientButtonDynamic(
                    text: AppLocalizations.of(context)!
                        .selectFromDevice, //'select from device',
                    fontSize: 14,
                    color: globalState.theme.buttonGenerate,
                    onPressed: () async {
                      _imgTemp = await ImageUtil.selectImage(context);
                      if (_imgTemp != null) {
                        _genImage = false;
                        _img = _imgTemp;
                      }

                      setState(() {});
                    },
                  ),
                ]),
              ]),
              const Spacer(),
            ]));

    final nextButton = Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Row(children: <Widget>[
          Expanded(
              child: GradientButton(
            text: AppLocalizations.of(context)!.next, //'NEXT',
            onPressed: _next,
          )),
        ]));

    final desktopNextButton = Padding(
      padding: const EdgeInsets.only(left: 0, right: 10, top: 10, bottom: 12),
      child: Row(children: <Widget>[
        const Spacer(),
        SizedBox(
            height: 55,
            width: 300,
            child: GradientButton(
              text: AppLocalizations.of(context)!.next, //'LOGIN',
              onPressed: _next,
            )),
      ]),
    );

    final makeBody = Container(
        padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 5),
        child: Scrollbar(
            controller: _scrollController,
            //thumbVisibility: true,
            child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                controller: _scrollController,
                child: WrapperWidget(
                  child: Column(children: <Widget>[
                    widget.caller == GenerateNetworkCaller.applink
                        ? Padding(
                            padding: const EdgeInsets.only(
                                left: 25, top: 10, bottom: 10, right: 15),
                            child: Row(children: <Widget>[
                              const ICText(
                                'Network name: ',
                                fontSize: 16,
                              ),
                              Expanded(
                                child: ICText(
                                  widget.userFurnace!.alias!,
                                  color: globalState.theme.buttonIcon,
                                  fontSize: 16,
                                ),
                              ),
                            ]))
                        : Padding(
                            padding: const EdgeInsets.only(
                                left: 11, top: 15, bottom: 0, right: 15),
                            child: Row(children: <Widget>[
                              Expanded(
                                flex: 1,
                                child: FormattedText(
                                  //hintText: 'Enter a name for your network',
                                  controller: _networkName,
                                  maxLength: 50,
                                  labelText: widget.caller ==
                                          GenerateNetworkCaller.new_network
                                      ? AppLocalizations.of(context)!
                                          .enterANameForYourSocialNetwork //'Enter a name for your social network'
                                      : AppLocalizations.of(context)!
                                          .enterNetworkName, //'enter network name',
                                  maxLines: 1,
                                  onChanged: _revalidate,
                                  validator: (value) {
                                    if (value.toString().endsWith(' ')) {
                                      return 'cannot end with a space';
                                    } else if (value.toString().isEmpty) {
                                      return AppLocalizations.of(context)!
                                          .errorCannotBeEmpty; //'cannot be empty';
                                    } else if (value
                                        .toString()
                                        .startsWith(' ')) {
                                      return AppLocalizations.of(context)!
                                          .errorCannotStartWithASpace;
                                      'cannot start with a space';
                                    }

                                    return null;
                                  },
                                ),
                              ),
                            ])),
                    Align(
                        alignment: Alignment.center,
                        child: Toggle.ToggleSwitch(
                          minWidth: 150.0,
                          //minHeight: 70.0,
                          initialLabelIndex: _initialIndex,
                          cornerRadius: 20.0,
                          activeFgColor: Colors.white,
                          inactiveBgColor: Colors.grey,
                          inactiveFgColor: Colors.white,
                          totalSwitches: 2,
                          radiusStyle: true,
                          labels: const [
                            "IronCircles hosted", "Self hosted"
                            // AppLocalizations.of(context)!.efficient,
                            // AppLocalizations.of(context)!.hires
                          ],
                          customTextStyles: [
                            TextStyle(fontSize: 12 / textScale),
                            TextStyle(fontSize: 12 / textScale)
                          ],
                          //iconSize: 30.0,
                          activeBgColors: const [
                            [
                              Colors.tealAccent,
                              Colors.teal,
                            ],
                            [Colors.yellow, Colors.orange]
                          ],
                          animate: true,
                          // with just animate set to true, default curve = Curves.easeIn
                          curve: Curves.bounceInOut,
                          // animate must be set to true when using custom curve
                          onToggle: (index) {
                            debugPrint('switched to: $index');
                            //_hiRes = !_hiRes;

                            setState(() {
                              _boolSelfHosted = !_boolSelfHosted;
                              _initialIndex = index!;
                            });
                          },
                        )),
                    _boolSelfHosted
                        ? Padding(
                            padding: const EdgeInsets.only(
                                left: 11, top: 15, bottom: 0, right: 15),
                            child: Row(children: <Widget>[
                              Expanded(
                                flex: 1,
                                child: FormattedText(
                                  //hintText: 'Enter a name for your network',
                                  controller: _networkUrl,
                                  maxLength: 50,
                                  labelText: 'API URL', //'enter network name',
                                  maxLines: 1,
                                  //onChanged: _revalidate,
                                  // validator: (value) {
                                  //   if (value.toString().endsWith(' ')) {
                                  //     return 'cannot end with a space';
                                  //   } else if (value.toString().isEmpty) {
                                  //     return AppLocalizations.of(context)!
                                  //         .errorCannotBeEmpty; //'cannot be empty';
                                  //   } else if (value.toString().startsWith(' ')) {
                                  //     return AppLocalizations.of(context)!
                                  //         .errorCannotStartWithASpace;
                                  //     'cannot start with a space';
                                  //   }
                                  //
                                  //   return null;
                                  // },
                                ),
                              ),
                            ]))
                        : Container(),
                    _boolSelfHosted
                        ? Padding(
                            padding: const EdgeInsets.only(
                                left: 11, top: 15, bottom: 0, right: 15),
                            child: Row(children: <Widget>[
                              Expanded(
                                flex: 1,
                                child: FormattedText(
                                  //hintText: 'Enter a name for your network',
                                  controller: _networkApiKey,
                                  maxLength: 50,
                                  labelText: 'API key', //'enter network name',
                                  maxLines: 1,
                                  //onChanged: _revalidate,
                                  // validator: (value) {
                                  //   if (value.toString().endsWith(' ')) {
                                  //     return 'cannot end with a space';
                                  //   } else if (value.toString().isEmpty) {
                                  //     return AppLocalizations.of(context)!
                                  //         .errorCannotBeEmpty; //'cannot be empty';
                                  //   } else if (value.toString().startsWith(' ')) {
                                  //     return AppLocalizations.of(context)!
                                  //         .errorCannotStartWithASpace;
                                  //     'cannot start with a space';
                                  //   }
                                  //
                                  //   return null;
                                  // },
                                ),
                              ),
                            ]))
                        : Container(),
                    Row(children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 25, top: 10, bottom: 0, right: 15),
                        child: ICText(
                          AppLocalizations.of(context)!
                              .setAnImageForYourNetworkOptional, //'Set an image for your network (optional)',
                          fontSize: 16,
                          color: globalState.theme.labelText,
                        ),
                      ),
                    ]),
                    networkImage,
                    Platform.isMacOS || Platform.isWindows || Platform.isLinux
                        ? desktopNextButton
                        : Container()
                  ]),
                ))));

    return Form(
      key: _formKey,
      child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: globalState.theme.background,
          appBar: ICAppBar(
              title: widget.caller == GenerateNetworkCaller.new_network
                  ? AppLocalizations.of(context)!
                      .nameYourNetwork //'Name Your Network'
                  : AppLocalizations.of(context)!
                      .joinAFriendsNetwork, //'Join Friend\'s Network',
              actions: <Widget>[
                IconButton(
                  padding: EdgeInsets.only(right: _iconPadding),
                  constraints: const BoxConstraints(),
                  iconSize: 27 - globalState.scaleDownIcons,
                  onPressed: () {
                    widget.caller == GenerateNetworkCaller.new_network
                        ? DialogNotice.showLandingNetworkHelp(context)
                        : DialogNotice.showLandingFriendHelp(context);
                  },
                  icon: Icon(Icons.help, color: globalState.theme.menuIcons),
                )
              ]),
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
                    const Padding(padding: EdgeInsets.only(bottom: 5)),
                    Expanded(
                      child: makeBody,
                    ),
                    Platform.isMacOS || Platform.isWindows || Platform.isLinux
                        ? Container() // inside the body
                        : nextButton
                  ],
                ),
                _showSpinner ? Center(child: spinkit) : Container(),
              ],
            ),
          )),
    );
  }

  void _revalidate(String value) {
    if (validatedOnceAlready) {
      _formKey.currentState!.validate();
    }
    //params.prompt = '$value, social network, creative';
    stableDiffusionAIParams.setPrompt(value, ImageType.network);
  }

  _generateImage() async {
    try {
      _closeKeyboard();

      if (_formKey.currentState!.validate()) {
        ///prompt is required
        if (stableDiffusionAIParams.prompt.isEmpty) {
          icProgressDialog.dismiss();
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.pleaseEnterAPrompt, '', 2, true);
          return;
        }

        String coins =
            await globalState.secureStorageService.readKey(KeyType.FREE_COINS);
        if (coins != null && coins.isEmpty) {
          throw ("Something went wrong. Please try again later");
        } else {
          int numCoins = int.parse(coins);

          if (numCoins > 0) {
            numCoins = numCoins - 1;

            await globalState.secureStorageService
                .writeKey(KeyType.FREE_COINS, numCoins.toString());
          } else {
            DialogNotice.showNoticeOptionalLines(
                context,
                "Limit Reached",
                "You have reached the limit of free image generations before you create an account. You can change your network image and avatar after you register.",
                false);

            return;
          }
        }

        icProgressDialog.show(
            context, AppLocalizations.of(context)!.generatingImage,
            barrierDismissable: true);

        _genImage = true;
        _img = await stableDiffusionAIBloc.generateImage(
            imageGeneratorParams: stableDiffusionAIParams, registering: true);

        icProgressDialog.dismiss();

        setState(() {});
      }
    } catch (error, trace) {
      icProgressDialog.dismiss();
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, error.toString(), "", 2, false);
    }
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  _stableDiffusionConfigureCallback(StableDiffusionPrompt newParams) {
    setState(() {
      stableDiffusionAIParams = newParams;
    });
  }

  _generateNetworkAccountCallback(String username, File? avatar) {
    _userFurnace.username = username;
    _userFurnace.userAvatar = avatar;
  }

  _next() async {
    try {
      if (_formKey.currentState!.validate()) {
        if (_networkName.text.trim().toLowerCase() == 'ironforge' &&
            (widget.caller != GenerateNetworkCaller.join_friends &&
                widget.caller != GenerateNetworkCaller.applink)) {
          DialogNotice.showNoticeOptionalLines(
              context,
              AppLocalizations.of(context)!.nameInUse, //'Name in use',
              AppLocalizations.of(context)!.networkNameInUse,
              //'The network name you selected is already in use. Please choose a different name.',
              false);
        } else {
          _closeKeyboard();

          icProgressDialog.show(
              context,
              AppLocalizations.of(context)!
                  .checkingNetworkName); //'Checking network name');

          ///see if the name is already in use
          bool available = false;

          if (_boolSelfHosted) {
            String networkUrl = _networkUrl.text;

            _networkUrl.text = networkUrl.trim();

            if (!networkUrl.endsWith("/")) {
              networkUrl = "$networkUrl/";
            } else if (networkUrl.startsWith("http://")) {
              throw ("Url must contain a cert and use https");
            } else if (!networkUrl.startsWith("https://")) {
              networkUrl = "https://$networkUrl/";
            }

            available = await _hostedFurnaceBloc.checkName(_networkName.text,
                networkUrl: networkUrl, networkApiKey: _networkApiKey.text);

            _userFurnace.apikey = _networkApiKey.text;
            _userFurnace.url = networkUrl;
          } else {
            available = await _hostedFurnaceBloc.checkName(_networkName.text);
          }

          icProgressDialog.dismiss();

          if (available) {
            _userFurnace.alias = _networkName.text;
            _userFurnace.image = _img;

            await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GenerateNetworkAccount(
                    caller: GenerateNetworkCaller.new_network,
                    linkedAccount: false,
                    userFurnace: _userFurnace,
                    callback: _generateNetworkAccountCallback,
                  ),
                ));
          } else {
            DialogNotice.showNoticeOptionalLines(
                context,
                AppLocalizations.of(context)!.nameInUse, //   'Name in use',
                AppLocalizations.of(context)!.networkNameInUse,
                //'The network name you selected is already in use. Please choose a different name.',
                false);
          }
        }
      }
    } catch (err) {
      icProgressDialog.dismiss();
      DialogNotice.showNoticeOptionalLines(
          context,
          err.toString(), //   'Name in use',
          "Please ensure the url and apikey are accurate",
          //'The network name you selected is already in use. Please choose a different name.',
          false);
    }
  }
}
