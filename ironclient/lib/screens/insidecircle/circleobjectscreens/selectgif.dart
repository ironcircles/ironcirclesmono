import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ironcirclesapp/blocs/giphy_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/screens/widgets/formattedsnackbar.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/services/tenor_service.dart';

class SelectGif extends StatefulWidget {
  //final List<UserFurnace> userFurnaces;
  //final List<CircleObject> circleObjects;
  final Future<void> Function() refresh;

  const SelectGif({
    //this.circleObjects,
    Key? key,
    required this.refresh,
  }) : super(key: key);

  @override
  SelectGifState createState() => SelectGifState();
}

class SelectGifState extends State<SelectGif> {
  List<GiphyOption> _results = [];
  List<TenorCategory> _categoryResults = [];
  List<String> _autoComplete = [];

  final ScrollController _scrollController = ScrollController();
  //ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final GiphyBloc _giphyBloc = GiphyBloc();
  final TextEditingController _controller = TextEditingController();

  bool filter = false;
  //var _tapPosition;
  final double _iconSize = 45;
  int queryNumber = 0;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    //Listen for membership load
    _giphyBloc.giphyResults.listen((results) {
      if (mounted) {
        setState(() {
          if (_results.isNotEmpty) {
            _results += results;
          } else {
            _results = results;
          }
          _autoComplete = [];
        });
      }
    }, onError: (err) {
      debugPrint("SelectGif.initState: $err");
     if (mounted) FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2,  false);
    }, cancelOnError: false);

    _giphyBloc.categoryResult.listen((results) {
      if (mounted) {
        setState(() {
          _categoryResults = results;
        });
      }
    }, onError: (err) {
      debugPrint("SelectGif.initState: $err");
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2,  false);
    }, cancelOnError: false);

    _giphyBloc.autoCompleteResult.listen((results) {
      if (mounted) {
        setState(() {
          _autoComplete = results;
        });
      }
    }, onError: (err) {
      debugPrint("SelectGif.initState: $err");
      FormattedSnackBar.showSnackbarWithContext(context, err.toString(), "", 2,  false);
    }, cancelOnError: false);

    _giphyBloc.category(0);

    super.initState();
  }

  _return(GiphyOption preview) async {
    FocusScope.of(context).requestFocus(FocusNode());
    ///wait for half a second to allow the keyboard to close
    await Future.delayed(const Duration(milliseconds: 750));
    Navigator.of(context).pop(preview);
  }

  _showCategoryResults(TenorCategory category) {
    _controller.text = category.term;

    _search(category.term);
  }

  @override
  void dispose() {
    super.dispose();
  }

  final spinner = SpinKitThreeBounce(
    size: 20,
    color: globalState.theme.threeBounce,
  );

  _showGif(GiphyOption url) {
    //return Container();
    return Expanded(
        child: InkWell(
            onTap: () => {_return(url)},
            child: Container(
                width: 250,
                height: 250,
                color: globalState.theme.imageBackground,
                child: Image.network(
                  url.preview,
                  fit: BoxFit.cover,
                ))));
  }

  _showCategory(TenorCategory category) {
    //return Container();
    return Expanded(
        child: InkWell(
            onTap: () => {_showCategoryResults(category)},
            child: Stack(children: [
              Container(
                  color: Colors.black,
                  child: Opacity(
                      opacity: globalState.theme.themeMode == ICThemeMode.dark ? .4 : .5,
                      child: SizedBox(
                          width: 250,
                          height: 100,
                          //color: globalState.theme.imageBackground,
                          //color:  Colors.transparent,
                          child: CachedNetworkImage(
                            imageUrl: category.image,
                            fit: BoxFit.cover,
                          )))),
              Center(
                  child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: ICText(category.term,
                              textScaleFactor: globalState.labelScaleFactor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: globalState.theme.textOverOpacityImage)))),
            ])));
  }

  _search(String value) {
    if (_controller.text.isNotEmpty) {
      _results = [];
      queryNumber = 0;
      _giphyBloc.search(_controller.text.toString(), queryNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    ///calculate the half the screen size (2 columns) without the left/right padding
    double halfWidth = (MediaQuery.of(context).size.width - 35) / 2;

    double screenWidth = (MediaQuery.of(context).size.width);
    int previewColumns = 2; //portrait mode: phone
    int displayColumns = 2; //are columns the issue or column size?
    if (screenWidth >= 600) {
      previewColumns = 3; //landscape mode: phone ; portrait mode: tablet
      displayColumns = 3;
    }
    if (screenWidth >= 900) {
      previewColumns = 4; // landscape mode: tablet
      displayColumns = 4;
    }
    if (screenWidth >= 1600) {
      previewColumns = 6; // landscape mode: tablet
      displayColumns = 6  ;
    }
    if (screenWidth >= 2000) {
      previewColumns = 7; // landscape mode: tablet
      displayColumns = 7  ;
    }

    final _gifDisplayWidget = RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: widget.refresh,
        color: globalState.theme.buttonIcon,
        child: NotificationListener<ScrollEndNotification>(
          onNotification: onNotification,
          child: _results.isNotEmpty
              ? MasonryGridView.count(
                  itemCount: _results.length,
                  crossAxisCount: displayColumns,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  itemBuilder: (context, index) {
                    //print(index);
                    GiphyOption preview = _results[index];

                    double width = preview.previewWidth!.toDouble();
                    double height = preview.previewHeight!.toDouble();

                    ///figure out how wide the gif should be based on half the screen size and then calculate height
                    if (width > halfWidth) {
                      double ratio = width / halfWidth;
                      width = halfWidth;

                      height = height / ratio;
                    } else if (width < halfWidth) {
                      double ratio = width / halfWidth;
                      width = halfWidth;

                      height = height * ratio;
                    }

                    if (screenWidth >= 600) {
                      height = height * 2;
                      // portrait: tablet, no cuts ; landscape: phone, slight cuts
                    }
                    if (screenWidth >= 900) {
                      height = height * 2;
                      //landscape: tablet, no cuts
                    }

                    ///Use a cachednetworkimage for speed
                    return InkWell(
                        onTap: () => {_return(preview)},
                        child: SizedBox(
                            width: width,
                            height: height,
                            child: CachedNetworkImage(
                              imageUrl: preview.preview,
                              //preview.preview,
                              fit: BoxFit.fitHeight,
                            )));
                  })
              : Container(),
        ));

    final _autoCompleteWidget = Column(children: <Widget>[
      SizedBox(
          height: 45,
          width: MediaQuery.of(context).size.width - 35,
          child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                  itemCount: _autoComplete.length,
                  padding: const EdgeInsets.only(right: 0, left: 0),
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    String suggestion = _autoComplete[index];

                    return TextButton(
                        onPressed: () {
                          _controller.text = suggestion;
                          _search(suggestion);
                        },
                        child: Text(
                          suggestion,
                          textScaler: TextScaler.linear(globalState.labelScaleFactor),
                          style: TextStyle(
                              color: globalState.theme.buttonIconHighlight),
                        ));
                  }))),
    ]);

    final _categoryResultsWidget = GridView.builder(
        itemCount: _categoryResults.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: previewColumns, //2
          childAspectRatio: (3 / 1),
        ),
        itemBuilder: (BuildContext context, int index) {
          TenorCategory preview = _categoryResults[index];
          return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _showCategory(preview),
              ]);
        });

    final topAppBar = AppBar(
      elevation: 0,
      toolbarHeight: 45,
      centerTitle: false,
      titleSpacing: 0.0,
      iconTheme: IconThemeData(
        color: globalState.theme.menuIcons, //change your color here
      ),
      backgroundColor: globalState.theme.appBar,
      title: Text(AppLocalizations.of(context)!.gifSearch,
          textScaler: TextScaler.linear(globalState.screenNameScaleFactor),
          style: ICTextStyle.getStyle(context: context, 
              color: globalState.theme.textTitle,
              fontSize: ICTextStyle.appBarFontSize)),
      actions: <Widget>[
        Padding(
            padding: const EdgeInsets.only(top: 11, right: 10),
            child: TextButton(
                onPressed: () {
                  _controller.text = '';
                  _autoComplete = [];
                  _giphyBloc.trending();
                },
                child: Text(AppLocalizations.of(context)!.trending,
                    textScaler: TextScaler.linear(globalState.screenNameScaleFactor),
                    style: TextStyle(
                      color: globalState.theme.button,
                    ))))
      ],
    );

    return Scaffold(
      backgroundColor: globalState.theme.background,
      key: _scaffoldKey,
      appBar: topAppBar,
      //drawer: NavigationDrawer(),
      body: SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: true,
          child: Padding(
              padding: const EdgeInsets.only(left: 25, right: 10, bottom: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: TextField(
                        textInputAction: TextInputAction.search,
                        onSubmitted: _search,
                        onChanged: (text) {
                          _giphyBloc.autoComplete(text);
                        },
                        cursorColor: globalState.theme.textField,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: (18 / globalState.mediaScaleFactor) *
                              globalState.textFieldScaleFactor,
                          color: globalState.theme.textFieldText,
                        ),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.enterGifSearch,
                          counterText: '',
                          labelStyle: TextStyle(
                            color: globalState.theme.textFieldLabel,
                            fontSize: (18 / globalState.mediaScaleFactor) *
                                globalState.textFieldScaleFactor,
                          ),
                          //hintStyle: TextStyle(color: Colors.blue),
                          contentPadding: const EdgeInsets.only(
                              left: 14, bottom: 5, top: 5),
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: globalState.theme.textField),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: globalState.theme.textField),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 1,
                        controller: _controller,
                      ),
                    ),
                    ClipOval(
                      child: Material(
                        color: globalState.theme.background, // button color
                        child: InkWell(
                          splashColor: globalState
                              .theme.buttonIconSplash, // inkwell color
                          child: SizedBox(
                              width: _iconSize,
                              height: _iconSize,
                              child: Icon(
                                Icons.clear,
                                color: globalState.theme.buttonIcon,
                              )),
                          onTap: () {
                            setState(() {
                              _results = [];
                              _controller.text = '';
                              _categoryResults = [];

                              _giphyBloc.category(0);
                            });
                          },
                        ),
                      ),
                    ),
                    ClipOval(
                      child: Material(
                        color: globalState.theme.background, // button color
                        child: InkWell(
                          splashColor: globalState
                              .theme.buttonIconSplash, // inkwell color
                          child: SizedBox(
                              width: _iconSize,
                              height: _iconSize,
                              child: Icon(
                                Icons.search,
                                color: globalState.theme.buttonIcon,
                              )),
                          onTap: () {
                            _search('');
                          },
                        ),
                      ),
                    ),
                  ]),
                  _autoComplete.isNotEmpty ? _autoCompleteWidget : Container(),
                  Expanded(
                      child: _results.isNotEmpty
                          ? _gifDisplayWidget
                          : _categoryResults.isEmpty
                              ? Container()
                              : _categoryResultsWidget),
                ],
              ))),
    );
  }

  bool onNotification(ScrollEndNotification t) {
    try {
      if (t.metrics.pixels > 0 && t.metrics.atEdge) {
        if (_controller.text.isNotEmpty) {
          queryNumber = queryNumber + 1;
          _giphyBloc.scrollForMore(_controller.text.toString(), queryNumber);
        }
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint("selectGif.onNotification: $err");
    }
    return false;
  }

}
