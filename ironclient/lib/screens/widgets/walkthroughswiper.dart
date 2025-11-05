import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';

class WalkthroughSwiper extends StatefulWidget {
  const WalkthroughSwiper({
    Key? key,
  });

  @override
  _WalkthroughSwiperState createState() => _WalkthroughSwiperState();
}

class _WalkthroughSwiperState extends State<WalkthroughSwiper>
    with SingleTickerProviderStateMixin {
  final int height = 800;
  final int width = 800;
  bool hiRes = false;

  late TabController _tabController;
  int _activeIndex = 0;

  List<String> androidImages = [
    'assets/images/android_walkthrough/1.png',
    'assets/images/android_walkthrough/2.png',
    'assets/images/android_walkthrough/3.png',
    'assets/images/android_walkthrough/4.png',
    'assets/images/android_walkthrough/5.png',
    'assets/images/android_walkthrough/6.png',
    'assets/images/android_walkthrough/7.png',
    'assets/images/android_walkthrough/8.png',
  ];

  List<String> iosImages = [
    'assets/images/ios_walkthrough/1.png',
    'assets/images/ios_walkthrough/2.png',
    'assets/images/ios_walkthrough/3.png',
    'assets/images/ios_walkthrough/4.png',
    'assets/images/ios_walkthrough/5.png',
    'assets/images/ios_walkthrough/6.png',
    'assets/images/ios_walkthrough/7.png',
    'assets/images/ios_walkthrough/8.png',
  ];

  late List<String> chosenList;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      vsync: this,
      length: 8,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _activeIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    chosenList = Platform.isIOS == true
        ? iosImages
        : Platform.isAndroid == true
            ? androidImages
            : androidImages;

    return SizedBox(
        width: 0.9 * width,
        height: 0.7 * height,
        child: DefaultTabController(
            length: 8,
            initialIndex: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(
                    child: TabBarView(
                  viewportFraction: 0.9,
                  children: [
                    Image.asset(chosenList[0]),
                    Image.asset(chosenList[1]),
                    Image.asset(chosenList[2]),
                    Image.asset(chosenList[3]),
                    Image.asset(chosenList[4]),
                    Image.asset(chosenList[5]),
                    Image.asset(chosenList[6]),
                    Image.asset(chosenList[7]),
                  ],
                )),
                TabBar(
                    padding: const EdgeInsets.all(0),
                    dividerHeight: 0.0,
                    labelPadding: const EdgeInsets.all(1.0),
                    isScrollable: false,
                    indicatorColor: Colors.transparent,
                    tabAlignment: TabAlignment.center,
                    labelColor: globalState.theme.buttonIcon,
                    unselectedLabelColor: globalState.theme.buttonDisabled,
                    tabs: const [
                      Tab(
                          child: Align(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.circle,
                                size: 15.0,
                              ))),
                      Tab(
                          child: Align(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.circle,
                                size: 15.0,
                              ))),
                      Tab(
                          child: Align(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.circle,
                                size: 15.0,
                              ))),
                      Tab(
                          child: Align(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.circle,
                                size: 15.0,
                              ))),
                      Tab(
                          child: Align(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.circle,
                                size: 15.0,
                              ))),
                      Tab(
                          child: Align(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.circle,
                                size: 15.0,
                              ))),
                      Tab(
                          child: Align(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.circle,
                                size: 15.0,
                              ))),
                      Tab(
                          child: Align(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.circle,
                                size: 15.0,
                              ))),
                    ])
              ],
            )));
  }
}
