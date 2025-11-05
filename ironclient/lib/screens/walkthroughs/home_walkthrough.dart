import 'package:flutter/material.dart';
import 'package:ironcirclesapp/screens/walkthroughs/walkthrough.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class HomeWalkthrough extends Walkthrough {
  GlobalKey keyButton = GlobalKey();
  GlobalKey homeButton = GlobalKey();
  GlobalKey keyButton1 = GlobalKey();
  GlobalKey keyButton2 = GlobalKey();
  GlobalKey keyButton3 = GlobalKey();
  GlobalKey invitationsTarget = GlobalKey();
  GlobalKey keyButton5 = GlobalKey();
  GlobalKey unreadMessagesTab = GlobalKey();
  GlobalKey circlesTab = GlobalKey();
  GlobalKey dmTab = GlobalKey();
  GlobalKey firstCircle = GlobalKey();
  GlobalKey hamburger = GlobalKey();
  GlobalKey wrench = GlobalKey();
  GlobalKey add = GlobalKey();
  GlobalKey network = GlobalKey();

  HomeWalkthrough(Function finish) {
    init(createTargets, finish: finish);
  }

  List<TargetFocus> createTargets() {
    List<TargetFocus> targets = [];
    targets.add(
      TargetFocus(
        identify: "Target 0",
        keyTarget: homeButton,
        /*alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        enableTargetTab: false,
        shape: ShapeLightFocus.RRect,
        paddingFocus: 50,

         */
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  tutorialTitle("Welcome to IronCircles!", 1, 7),
                  tutorialLineItem(
                    "You are in a secure private network. No one can join or access your data without permission.",
                  ),
                  tutorialLineItem(
                    "This short guide will walk you through the layout of the Home screen.",
                  ),
                  tapToContinue(),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        //identify: "Target 5",
        keyTarget: circlesTab,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                  ),
                  tutorialTitle("Circles", 2, 7),
                  tutorialLineItem(
                    "Circles are secure places to store information or create private conversations.",
                  ),
                  tutorialLineItem(
                    "A Circle called Private Vault has been created for your personal use.",
                  ),
                  tapToContinue(),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        //identify: "Target 5",
        keyTarget: dmTab,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                  ),
                  tutorialTitle("Direct Messages", 3, 7),
                  tutorialLineItem(
                    "DMs are private chats between you and one other person on a shared network.",
                  ),
                  tapToContinue(),
                ],
              );
            },
          ),
        ],
      ),
    );

    /*targets.add(
      TargetFocus(
        //identify: "Target 5",
        keyTarget: unreadMessagesTab,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(bottom: 20),
                    ),
                    tutorialLineItem("Unread Messages", fontSize: 25),
                    tutorialLineItem(
                      "The Unread Messages tab displays messages you have not yet viewed across open Circles and DMs.",
                    ),
                    tutorialLineItem(
                      "Tap a message to go directly into that chat.",
                    ),
                    tutorialLineItem(
                      "Mark a single conversation read by swiping away that conversation\'s icon.",
                    ),
                    tutorialLineItem(
                      "Mark all unread messages read by tapping the bottom right icon.",
                    ),
                    tapToContinue(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );*/

    targets.add(
      TargetFocus(
        //identify: "Target 49",
        keyTarget: add,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  tutorialTitle("Create New", 4, 7),
                  tutorialLineItem(
                    "Use this icon to create Circles and DMs.",
                  ),
                  tutorialLineItem(
                    "You can create Circles for yourself, or you can invite others.",
                  ),
                  tapToContinue(),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "Target 4",
        keyTarget: invitationsTarget,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  tutorialTitle("Friends", 5, 7),
                  tutorialLineItem(
                    "Central place to view people you are connected to and send or receive invitations.",
                  ),
                  tutorialLineItem(
                    "You can also ignore or block other people from contacting you.",
                  ),
                  tapToContinue(),
                ],
              );
            },
          ),
        ],
      ),
    );

    /*targets.add(
      TargetFocus(
        identify: "Target 3",
        keyTarget: keyButton3,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    tutorialLineItem("Action Required", fontSize: 25),
                    tutorialLineItem(
                      "Action Required lets you know about anything that is waiting on you.",
                    ),
                    tutorialLineItem(
                      "For example, helping a friend with a password reset, an invitation you have not voted on yet, or a open task on a ToDo list.",
                    ),
                    tapToContinue(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );*/

    /*targets.add(
      TargetFocus(
        identify: "Target 1",
        keyTarget: keyButton1,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    tutorialLineItem("Library", fontSize: 25),
                    tutorialLineItem(
                      "The Library is a central place to view images, videos, links, and recipes from open Circles and DMs.",
                    ),
                    tutorialLineItem(
                      "You can filter, shuffle, swipe, and zoom.",
                    ),
                    tapToContinue(),
                    Padding(padding: EdgeInsets.only(top: 20)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );*/

    /* targets.add(
      TargetFocus(
        identify: "Target 2",
        keyTarget: keyButton2,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    tutorialLineItem("Central Calendar", fontSize: 25),
                    tutorialLineItem(
                      "View scheduled events across open Circles and DMs.",
                    ),
                    tutorialLineItem(
                      "You can also create events from here.",
                    ),
                    tapToContinue(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );*/

    targets.add(
      TargetFocus(
        //identify: "Target 49",
        keyTarget: network,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                  ),
                  tutorialTitle("Networks", 6, 7),
                  tutorialLineItem(
                    "Use this icon to filter your networks, if you are connected to more than one.",
                  ),
                  tutorialLineItem(
                    "You can also open the Network Manager to create, join, or leave a network.",
                  ),
                  tapToContinue(),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        //identify: "Target 49",
        keyTarget: hamburger,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                  ),
                  tutorialTitle("Navigation Menu", 7, 7),
                  tutorialLineItem(
                    "This menu has links to your profile, settings, and feature requests.",
                  ),
                  tutorialLineItem(
                    "The question mark icon will take you to the Help Center.",
                  ),
                  tutorialLineItem(
                    "The gear icon will take you to Settings.",
                  ),
                  tapToExit(),
                ],
              );
            },
          ),
        ],
      ),
    );

    return targets;
  }
}
