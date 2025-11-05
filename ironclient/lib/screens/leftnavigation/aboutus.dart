import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/login/terms_of_service.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/utils/launchurls.dart';


class AboutUs extends StatefulWidget {
  const AboutUs({
    Key? key,
  }) : super(key: key);

  @override
  _AboutUsState createState() => _AboutUsState();
}

/*class VideoUrl {
  String name = '';
  String url = '';
  String description = '';

  VideoUrl({required this.name, required this.url, required this.description});
}*/

class _AboutUsState extends State<AboutUs> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final spinner = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,

        appBar: ICAppBar(
          title: AppLocalizations.of(context)!.about , //'About',

        ),
        //drawer: NavigationDrawer(),
        body: SafeArea(
            left: false,
            top: false,
            right: false,
            bottom: true,
            child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    controller: _scrollController,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Row(children: [Spacer()],),
                        SizedBox(
                            width: 150,
                            height: 150,
                            child: Image.asset('assets/images/ios_icon.png')),
                        Padding(
                            padding: const EdgeInsets.only(top: 15, bottom:5),
                            child: Text(
                              'IronCircles Inc',
                              textScaler: TextScaler.linear(globalState.labelScaleFactor),
                              style:
                                  TextStyle(color: globalState.theme.labelText),
                            )),
                        TextButton(
                            onPressed: () {
                              LaunchURLs.openExternalBrowserUrl(
                                  context, 'https://ironcircles.com');
                            },
                            child: Text(
                              'www.ironcircles.com',
                              textScaler: TextScaler.linear(globalState.labelScaleFactor),
                              style: const TextStyle(color: Colors.blue),
                            )),
                        TextButton(
                          onPressed: () {
                            LaunchURLs.openExternalBrowserUrl(
                                context, 'https://ironcircles.com/policies');
                          },
                          child: Text(
                            AppLocalizations.of(context)!.privacyPolicy.toLowerCase(),
                            textAlign: TextAlign.right,
                            textScaler: TextScaler.linear(globalState.labelScaleFactor),
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsOfService(
                                    readOnly: true,
                                  ),
                                ));
                          },
                          child: Text(
                            AppLocalizations.of(context)!.termsOfService.toLowerCase(),
                            textAlign: TextAlign.right,
                            textScaler: TextScaler.linear(globalState.labelScaleFactor),
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    )))));
  }
}
