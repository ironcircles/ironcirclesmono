import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/expandinglinetext.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';

class DialogCaption {
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  static getCaption(
      {required BuildContext context,
      required String existingCaption,
      required Function callback}) async {
    final TextEditingController _captionController = TextEditingController();

    await showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(.8),
      builder: (BuildContext context) => _SystemPadding(
        child: AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor: globalState.theme.dialogTransparentBackground,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0))),
          title: Center(
            child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ICText(
                  AppLocalizations.of(context)!.setCaption,
                  textScaleFactor: globalState.dialogScaleFactor,
                  color: globalState.theme.bottomIcon,
                  fontSize: 20,
                )),
          ),
          contentPadding: const EdgeInsets.all(5.0),
          content: SetCaption(scaffoldKey, existingCaption, callback),
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

class SetCaption extends StatefulWidget {
  final Key scaffoldKey;
  final Function callback;
  final String existingCaption;

  const SetCaption(
    this.scaffoldKey,
    this.existingCaption,
    this.callback,
  );

  @override
  _SetCaptionState createState() => _SetCaptionState();
}

class _SetCaptionState extends State<SetCaption> {
  final TextEditingController _captionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    _captionController.text = widget.existingCaption;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = globalState.setScale(MediaQuery.of(context).size.width);

    return SizedBox(
        width: (width >= 350 ? 350 : width),
        height: 200, //widget.firstTime ? 340  : 340,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                  child: Scrollbar(
                      controller: _scrollController,
                      //thumbVisibility: true,
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        controller: _scrollController,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(children: [
                                const Padding(
                                    padding: EdgeInsets.only(top: 10)),
                                ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxHeight: 125),
                                    child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                        ),
                                        child: ExpandingLineText(
                                            maxLines: 3,
                                            onFieldSubmitted: (value) {
                                              if (globalState.isDesktop())
                                                _done();
                                            },
                                            textInputAction:
                                                globalState.isDesktop()
                                                    ? TextInputAction.done
                                                    : TextInputAction.newline,
                                            maxLength: 500,
                                            autoFocus: true,
                                            controller: _captionController,
                                            labelText:
                                                AppLocalizations.of(context)!
                                                    .caption))),
                              ]),
                            ]),
                      ))),
              Row(children: [
                const Spacer(),
                IconButton(
                  color: globalState.theme.buttonIcon,
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    _done();
                  },
                ),
              ])
            ]));
  }

  _done() {
    widget.callback(_captionController.text);
    Navigator.pop(context);
  }
}
