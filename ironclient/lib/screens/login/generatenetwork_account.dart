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
import 'package:ironcirclesapp/screens/login/generatenetwork.dart';
import 'package:ironcirclesapp/screens/login/terms_of_service.dart';
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

class GenerateNetworkAccount extends StatefulWidget {
  final String? toast;
  final GenerateNetworkCaller caller;
  final UserFurnace? userFurnace;
  final bool linkedAccount;
  final HostedInvitation? hostedInvitation;
  final bool fromNetworkManager;
  final Function callback;

  const GenerateNetworkAccount(
      {Key? key,
      this.toast,
      required this.caller,
      required this.callback,
      this.userFurnace,
      required this.linkedAccount,
      this.fromNetworkManager = false,
      this.hostedInvitation})
      : super(key: key);

  @override
  _GenerateNetworkAccountState createState() {
    return _GenerateNetworkAccountState();
  }
}

class _GenerateNetworkAccountState extends State<GenerateNetworkAccount> {
  final TextEditingController _username = TextEditingController();
  StableDiffusionPrompt stableDiffusionAIParams =
      StableDiffusionPrompt(promptType: PromptType.generate);
  StableDiffusionAIBloc stableDiffusionAIBloc = StableDiffusionAIBloc();
  int _seed = 0;

  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _authBloc = AuthenticationBloc();
  final UserFurnaceBloc _userFurnaceBloc = UserFurnaceBloc();
  late FirebaseBloc _firebaseBloc;
  late HostedFurnaceBloc _hostedFurnaceBloc;
  late GlobalEventBloc _globalEventBloc;
  final databaseBloc = DatabaseBloc();
  ProgressDialog? progressDialog;
  ProgressDialog? importingData;
  ICProgressDialog icProgressDialog = ICProgressDialog();
  String assigned = '';
  String? _toast;
  bool _showSpinner = false;
  bool _oldEnough = true;
  int? _radioValue = 1;
  bool _tos = true;
  bool validatedOnceAlready = false;
  File? _img;
  //double radius = 185 - (globalState.scaleDownTextFont * 2);
  bool _genImage = false;
  File? _imgTemp;
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
    //LogBloc.postLog('User opened screen', 'RegShort');
    stableDiffusionAIParams.setNegativePrompt(ImageType.avatar);

    if (kDebugMode && !Urls.testingReleaseMode) {
      if (widget.userFurnace != null) {
        _username.text = widget.userFurnace!.username ??
            'maven${SecureRandomGenerator.generateInt(max: 5)}';

        stableDiffusionAIParams.setPrompt(_username.text, ImageType.avatar);
      } else {
        _username.text = 'maven${SecureRandomGenerator.generateInt(max: 5)}';

        stableDiffusionAIParams.setPrompt(_username.text, ImageType.avatar);
      }
    } else {
      if (widget.userFurnace != null) {
        _username.text = widget.userFurnace!.username ?? '';
        stableDiffusionAIParams.prompt = _username.text;
      }
    }

    _radioValue = 2;
    _oldEnough = true;
    _tos = true;

    WidgetsBinding.instance.addPostFrameCallback((_) => _showToast(context));
    _firebaseBloc = Provider.of<FirebaseBloc>(context, listen: false);
    _globalEventBloc = Provider.of<GlobalEventBloc>(context, listen: false);
    _hostedFurnaceBloc = HostedFurnaceBloc(_globalEventBloc);

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
      icProgressDialog.dismiss();
      LogBloc.postLog('Error:$err', 'RegistrationShort');

      if (err.toString().contains('username') &&
          err.toString().contains('unique')) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!
                .usernameExists, //'Username already exists',
            AppLocalizations.of(context)!.usernameDifferent,
            null,
            null,
            null,
            false);
      } else if (err.toString().contains('reserved')) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!.usernameReserved,
            AppLocalizations.of(context)!.usernameDifferent,
            null,
            null,
            null,
            false);
      } else if (err.toString().contains('unauthorized')) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!.tryAgain,
            AppLocalizations.of(context)!.invalidNetworkNameOrCode,
            null,
            null,
            null,
            false);
      } else if (err.toString().toLowerCase().contains('failed last attempt')) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!
                .errorFailedLastAttempt, //'Failed Last Attempt',
            AppLocalizations.of(context)!
                .canNoLongerTryToJoinThisNetwork, //'You can no longer try to join this network',
            null,
            null,
            null,
            false);
      } else if (err.toString().contains('exceeded')) {
        DialogNotice.showNotice(
            context,
            AppLocalizations.of(context)!
                .exceededAllowedAttempts, //'Exceeded Allowed Attempts',
            AppLocalizations.of(context)!.cannotTryToJoinThisNetwork,
            null,
            null,
            null,
            false);
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
            AppLocalizations.of(context)!.tryAgain,
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

    final avatar = Padding(
        padding: const EdgeInsets.only(top: 5, left: 0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Column(children: [
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
                                    'assets/images/avatar.jpg',
                                    // height: radius,
                                    //width: radius,
                                    fit: BoxFit.fitWidth,
                                  )),
                        )))),
              ]),
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
                        : AppLocalizations.of(context)!.generateImage,
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
                                imageGenType: ImageType.avatar),
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
                    text: AppLocalizations.of(context)!.selectFromDevice,
                    fontSize: 14,
                    color: globalState.theme.buttonGenerate,
                    onPressed: () async {
                      _imgTemp = await ImageUtil.selectImage(context);
                      if (_imgTemp != null) {
                        _img = _imgTemp;
                        widget.callback(_username.text, _img);
                      }

                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                ]),
              ])
            ]));

    Widget _ageWidgets(BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
            top: 0,
            left: 15,
            right: globalState.isDesktop() ? ScreenSizes.formRightMargin : 10,
            bottom: 0),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.only(left: 10, top: 0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Spacer(),
                    ICText(
                      AppLocalizations.of(context)!.age,
                      color: globalState.theme.dialogLabel,
                      fontSize: 12,
                    ),
                    SizedBox(
                        height: 23,
                        width: 23,
                        child: Theme(
                            data: ThemeData(
                              //here change to your color
                              unselectedWidgetColor:
                                  globalState.theme.unselectedLabel,
                            ),
                            child: Radio(
                              activeColor: globalState.theme.dialogButtons,
                              value: 1,
                              groupValue: _radioValue,
                              onChanged: _handleRadioValueChange,
                            ))),
                    const Padding(
                        padding: EdgeInsets.only(
                      right: 10,
                    )),
                    InkWell(
                        onTap: () {
                          _handleRadioValueChange(1);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 10, right: 20),
                          child: ICText("16-17",
                              fontSize: 12,
                              color: globalState.theme.dialogLabel),
                        )),
                    SizedBox(
                        height: 23,
                        width: 23,
                        child: Theme(
                            data: ThemeData(
                              //here change to your color
                              unselectedWidgetColor:
                                  globalState.theme.unselectedLabel,
                            ),
                            child: Radio(
                              activeColor: globalState.theme.dialogButtons,
                              value: 2,
                              groupValue: _radioValue,
                              onChanged: _handleRadioValueChange,
                            ))),
                    const Padding(
                        padding: EdgeInsets.only(
                      right: 10,
                    )),
                    InkWell(
                        onTap: () {
                          _handleRadioValueChange(2);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          child: ICText("18+",
                              fontSize: 12,
                              color: globalState.theme.dialogLabel),
                        )),
                  ])),
        ]),
      );
    }

    final tos = Padding(
      padding: EdgeInsets.only(
          left: 10,
          right: globalState.isDesktop() ? ScreenSizes.formRightMargin : 10,
          top: 0,
          bottom: 0),
      child: Column(children: [
        Row(children: <Widget>[
          const Spacer(),
          Theme(
            data: ThemeData(
                unselectedWidgetColor: globalState.theme.checkUnchecked),
            child: Checkbox(
              activeColor: globalState.theme.buttonIcon,
              checkColor: globalState.theme.checkBoxCheck,
              value: _tos,
              onChanged: (newValue) {
                setState(() {
                  _tos = newValue!;
                  //_scrollBottom();
                });
              },
            ),
          ),
          ICText(
            AppLocalizations.of(context)!.iAgree,
            fontSize: 12,
          ),
          const Padding(padding: EdgeInsets.only(left: 5)),
          InkWell(
            onTap: _showTOS,
            child: ICText(AppLocalizations.of(context)!.termsOfService,
                color: globalState.theme.buttonIcon, fontSize: 12),
          ),
        ]),
      ]),
    );

    final desktopGenerateButton = Padding(
      padding: const EdgeInsets.only(left: 0, right: 10, top: 10, bottom: 12),
      child: Row(children: <Widget>[
        const Spacer(),
        SizedBox(
            height: 55,
            width: 300,
            child: GradientButton(
              text: widget.caller == GenerateNetworkCaller.new_network
                  ? AppLocalizations.of(context)!.generateEncryptedNetwork
                  : AppLocalizations.of(context)!.joinNetwork,
              onPressed: _register,
            )),
      ]),
    );

    final generateButton = SizedBox(
      // height: 100.0,
      child: Padding(
          padding: const EdgeInsets.only(left: 0, right: 0, top: 10, bottom: 0),
          child: Column(children: <Widget>[
            Row(children: <Widget>[
              Expanded(
                child: GradientButton(
                  text: widget.caller == GenerateNetworkCaller.new_network
                      ? AppLocalizations.of(context)!.generateEncryptedNetwork
                      : AppLocalizations.of(context)!.joinNetwork,
                  onPressed: _register,
                ),
              )
            ]),
          ])),
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
                                left: 25, top: 0, bottom: 10, right: 15),
                            child: Row(children: <Widget>[
                              ICText(
                                AppLocalizations.of(context)!.networkName,
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
                        : Container(),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 11, top: 5, bottom: 10, right: 15),
                      child: Row(children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: FormattedText(
                            controller: _username,
                            maxLength: 25,
                            labelText: AppLocalizations.of(context)!
                                .createAnAnonymousUsername,
                            maxLines: 1,
                            onChanged: _revalidate,
                            validator: (value) {
                              if (value.toString().endsWith(' ')) {
                                return AppLocalizations.of(context)!
                                    .errorCannotEndWithASpace;
                              } else if (value.toString().isEmpty) {
                                return AppLocalizations.of(context)!
                                    .errorCannotBeEmpty;
                              } else if (value.toString().startsWith(' ')) {
                                return AppLocalizations.of(context)!
                                    .errorCannotStartWithASpace;
                              }

                              return null;
                            },
                          ),
                        ),
                      ]),
                    ),
                    Row(children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 25, top: 0, bottom: 0, right: 15),
                        child: ICText(
                          AppLocalizations.of(context)!.setYourAvatarOptional,
                          fontSize: 16,
                          color: globalState.theme.labelText,
                        ),
                      ),
                    ]),
                    avatar,
                    tos,
                    _ageWidgets(context),
                    Platform.isMacOS || Platform.isWindows || Platform.isLinux
                        ? desktopGenerateButton
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
                      .landingAccountHelpTitle // 'Create Your Account'
                  : AppLocalizations.of(context)!
                      .joinFriendsNetwork, //'Join Friend\'s Network',
              actions: <Widget>[
                IconButton(
                  padding: EdgeInsets.only(right: _iconPadding),
                  constraints: const BoxConstraints(),
                  iconSize: 27 - globalState.scaleDownIcons,
                  onPressed: () {
                    widget.caller == GenerateNetworkCaller.new_network
                        ? DialogNotice.showLandingAccountHelp(context)
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
                          ? Container()
                          : generateButton
                    ],
                  ),
                  _showSpinner ? Center(child: spinkit) : Container(),
                ],
              ))),
    );
  }

  _handleRadioValueChange(int? value) {
    setState(() {
      _radioValue = value;
      _oldEnough = true;
    });
  }

  void _showTOS() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TermsOfService(
            readOnly: true,
          ),
        ));
  }

  void _register() async {
    try {
      if (_formKey.currentState!.validate()) {
        //globalState.userSetting.setFirstTimeInCircle(false);
        //globalState.userSetting.setAskedToGuardVault(false);

        if (_username.text.trim().isEmpty) {
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.pleaseEnterAUsername, "", 2, false);
        } else if (_tos == false) {
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.acceptTermsOfService, "", 2, false);
        } else if (!_oldEnough) {
          FormattedSnackBar.showSnackbarWithContext(context,
              AppLocalizations.of(context)!.selectAgeOption, "", 2, false);
        } else {
          _closeKeyboard();
          icProgressDialog.show(
              context,
              AppLocalizations.of(context)!
                  .generatingNetwork); //'Generating network');

          if (widget.caller == GenerateNetworkCaller.new_network) {
            _userFurnaceBloc.generateNetworkWithImages(
                _globalEventBloc,
                widget.userFurnace!.alias!,
                _username.text,
                _radioValue == 1,
                _hostedFurnaceBloc,
                widget.userFurnace!.image,
                _img, widget.userFurnace!.url, widget.userFurnace!.apikey);
          } else if (widget.caller == GenerateNetworkCaller.applink) {
            UserFurnace _userFurnace =
                _userFurnaceBloc.prepUserFurnaceForRegistration(
                    widget.userFurnace!, _username.text);

            _userFurnaceBloc.register(_userFurnace, null,
                globalState.user.minor, widget.linkedAccount,
                inviter: widget.hostedInvitation!.inviter,
                hostedInvitation: widget.hostedInvitation, primaryNetwork: globalState.userFurnace);
          }
        }
      } else {
        validatedOnceAlready = true;
      }
    } catch (error, trace) {
      icProgressDialog.dismiss();
      LogBloc.postLog('Error:$error', 'RegistrationShort');
      LogBloc.insertError(error, trace);
      FormattedSnackBar.showSnackbarWithContext(
          context, AppLocalizations.of(context)!.errorGeneric2, "", 2, false);
    }
  }

  void _revalidate(String value) {
    if (validatedOnceAlready) {
      _formKey.currentState!.validate();
    }

    widget.callback(_username.text, _img);
    stableDiffusionAIParams.setPrompt(value, ImageType.avatar);
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

        //_genImage = await _imagineAIBloc.generateImage(params);
        _img = await stableDiffusionAIBloc.generateImage(
            imageGeneratorParams: stableDiffusionAIParams, registering: true);
        //_genImage = await _imagineAIBloc.generateImage(params);

        widget.callback(_username.text, _img);

        icProgressDialog.dismiss();
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
}
