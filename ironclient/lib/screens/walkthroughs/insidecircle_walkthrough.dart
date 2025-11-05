import 'package:flutter/material.dart';
import 'package:ironcirclesapp/screens/walkthroughs/walkthrough.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class InsideCircleWalkthrough extends Walkthrough {
  GlobalKey keyButton = GlobalKey();
  GlobalKey keyButton0 = GlobalKey();
  GlobalKey keyButton1 = GlobalKey();
  GlobalKey keyButton2 = GlobalKey();
  GlobalKey keyButton3 = GlobalKey();
  GlobalKey keyButton4 = GlobalKey();
  GlobalKey keyButton5 = GlobalKey();
  GlobalKey keyButton6 = GlobalKey();
  GlobalKey keyButton7 = GlobalKey();
  GlobalKey keyButton8 = GlobalKey();

  InsideCircleWalkthrough(Function finish) {
    init(createTargets);
  }

  List<TargetFocus> createTargets() {
    List<TargetFocus> targets = [];
    targets.add(
      TargetFocus(
        identify: "Target 0",
        keyTarget: keyButton0,
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
                  tutorialLineItem("Inside a Circle or DM",
                      fontSize: 25),
                  tutorialLineItem(
                    "The icon bar at the bottom contains options to post.",
                  ),
                  tutorialLineItem(
                    "The first icon opens the multi-select image picker. Once selected, you can crop, rotate, and markup before posting.",
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
        identify: "Target 1",
        keyTarget: keyButton1,
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
                  tutorialLineItem("Videos", fontSize: 25),
                  tutorialLineItem(
                    "Select a video to post.",
                  ),
                  tutorialLineItem(
                    "Once selected, you can preview and choose a thumbnail frame before posting.",
                  ),
                  tapToContinue(),
                  const Padding(padding: EdgeInsets.only(top: 20)),
                ],
              );
            },
          ),
        ],
      ),
    );
    targets.add(
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
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  tutorialLineItem("Camera", fontSize: 25),
                  tutorialLineItem(
                    "Take and upload private photos and videos.",
                  ),
                  tutorialLineItem(
                    "The photos and videos are protected and can't be share without permission.",
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
        identify: "Target 3",
        keyTarget: keyButton3,
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
                  tutorialLineItem("Calendar", fontSize: 25),
                  tutorialLineItem(
                    "Schedule an event and invite members in the chat.",
                  ),
                  tutorialLineItem(
                    "You can set time, date, location, and RSVP options.",
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
        keyTarget: keyButton4,
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
                  tutorialLineItem("GIFs", fontSize: 25),
                  tutorialLineItem(
                    "Select a GIF to post.",
                  ),
                  tutorialLineItem(
                    "Filters include search, trending, and breakdown by category.",
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
        keyTarget: keyButton5,
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
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                  ),
                  tutorialLineItem("More Menu", fontSize: 25),
                  tutorialLineItem(
                    "Opens a menu of additional items that can be posted.",
                  ),
                  tutorialLineItem(
                    "Includes votes, credentials, lists, and recipes.",
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
        keyTarget: keyButton6,
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
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                  ),
                  tutorialLineItem("Disappearing Messages", fontSize: 25),
                  tutorialLineItem(
                    "Set the timer for the desired timeout.",
                  ),
                  tutorialLineItem(
                    "Timer stays on for subsequent messages until turned off or the Chat is exited.",
                  ),
                  tutorialLineItem(
                    "You can turn on Disappearing Messages permanently for a chat in Settings from the gear menu (upper right).",
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
        keyTarget: keyButton7,
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
                  tutorialLineItem("Search", fontSize: 25),
                  tutorialLineItem(
                    "Search a chat or vault by phrase.",
                  ),
                  tutorialLineItem(
                    "Tap a result to be taken directly to the post.",
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
        keyTarget: keyButton8,
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
                  tutorialLineItem("Gear Menu", fontSize: 25),
                  tutorialLineItem(
                    "The Members option allows you to see who is in a chat and invite members.",
                  ),
                  tutorialLineItem(
                    "The Setting option allows you to customize your chat or vault.",
                  ),
                  tutorialLineItem(
                    "Pinned Posts shows a list of all posts that have been pinned. Tap a result to be taken to the post.",
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
