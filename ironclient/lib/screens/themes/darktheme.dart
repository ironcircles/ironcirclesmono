import 'package:flutter/material.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';

class DarkTheme implements MasterTheme {
  @override
  // String? mode = MasterTheme.DARK_MODE;
  ICThemeMode themeMode = ICThemeMode.dark;

  @override
  get getTheme {
    final originalTextTheme = ThemeData.dark().textTheme;
    final originalBody1 = originalTextTheme.bodyMedium!;

    return ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            background: Colors.black,
            secondary: Colors.cyan[300]),
        primaryColor: Colors.black, //Colors.grey[800],
        //accentColor: Colors.cyan[300],
        // buttonColor: Colors.grey[800],
        // textSelectionColor: Colors.cyan[100],
        //backgroundColor: Colors.grey[800],
        //backgroundColor: Colors.black,
        //toggleableActiveColor: Colors.cyan[300],
        unselectedWidgetColor: Colors.white70,
        canvasColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xff0cbab8),
          selectionColor: Color(0xff0cbab8),
          selectionHandleColor: Color(0xff0cbab8),
        ),
        textTheme: originalTextTheme.copyWith(
            bodyMedium:
                originalBody1.copyWith(decorationColor: Colors.transparent)));
  }

  ///add all the other colors here

  //alternating user colors
  @override
  List<Color>? messageColorOptions = List.from({
    Colors.blue[200],
    const Color(0xffa6d608),
    Colors.purple[200],
    Colors.orange[300],
    const Color(0xff0cbab8),
    Colors.brown[200],
    Colors.green[400],
    Colors.lightGreen[300],
    Colors.cyanAccent,
    Colors.blue[500],
  });


  @override
  Color desktopSideBarBackground = Colors.black;
  @override
  Color desktopSideBarIcon = Colors.white;
  @override
  Color desktopSelectedSideBarIcon = const Color(0xff0cbab8);
  @override
  Color desktopSelectedItem = ColorConstants.darkGrey;
  @override
  Color desktopSelectedNetwork = ColorConstants.seaFoam;
  @override
  Color desktopUnselectedNetwork = ColorConstants.darkGrey;

  @override
  Color tutorialBackground = Colors.blue.shade900;

  @override
  Color fileOutline = Colors.grey[800]!;

  @override
  Color overlay = const Color.fromRGBO(0, 0, 0, 0.95);

  @override
  Color buttonGenerate = Colors.blue[200]!;

  //Color memberObjectText = Colors.amber; //Colors.purpleAccent;
  @override
  Color memberObjectBackground = Colors.grey[900]!;
  @override
  Color userObjectText = ColorConstants.seaFoam;
  @override
  Color userObjectBackground = Colors.grey[800]!; //Color(0xFF404040);
  @override
  Color systemMessageText = Colors.black;
  @override
  Color systemMessageNotification = Colors.white;
  @override
  Color systemMessageBackground = Colors.grey[500]!;

  @override
  Color homeFAB = ColorConstants.seaFoam.withOpacity(.85);
  Color libraryFAB = ColorConstants.seaFoam.withOpacity(.85);

  @override
  Color cameraOptionSelected = ColorConstants.seaFoam;
  @override
  Color cameraOptionNotSelected = Colors.grey[500]!;
  @override
  Color createOrJoinBackground = ColorConstants.seaFoam;

  @override
  Color slideUpPanelBackground = Colors.blueGrey[900]!;

  @override
  Color calendarToday = Colors.grey[900]!;
  @override
  Color calendarDayOfWeek = Colors.white;
  @override
  Color calendarRangeStart = const Color(0xff0cbab8);
  @override
  Color calendarRangeEnd = const Color(0xff0cbab8);
  @override
  Color calendarRange = ColorConstants.seaFoam;

  @override
  Color tableBackground = Colors.grey[800]!;
  @override
  Color tableText = Colors.white;

  @override
  Color circleGlow = ColorConstants.seaFoam;

  @override
  Color sliderActive = ColorConstants.seaFoam;
  @override
  Color sliderInactive = Colors.white;
  @override
  Color sliderThumb = ColorConstants.seaFoam;
  @override
  Color sliderLabel = Colors.grey[900]!;

  Color taggedUserHighlight = Colors.amber;

  ///hidden circle key unlock
  @override
  Color unlock = Colors.yellow;

  ///DM prefname color
  @override
  Color dmPrefName = Colors.lightBlueAccent;

  //long press lowerbackground
  @override
  Color longPressLower = Colors.grey[900]!;

  @override
  Color textOverOpacityImage = Colors.white;

  //Avatar
  @override
  Color avatarBackground = Colors.black;

  //bottom navigation colors (InsideCircle)
  @override
  Color bottomIcon = ColorConstants.seaFoam;
  //Color bottomHighlightIcon = Color(0xff0cbab8);
  @override
  // Color bottomHighlightIcon = Colors.lightBlueAccent;
  Color bottomHighlightIcon = ColorConstants.seaFoam;

  @override
  Color inactive = Colors.grey[200]!;
  @override
  Color bottomBackgroundColor = Colors.grey[900]!;

  //button colors
  @override
  Color button = ColorConstants.seaFoam;
  @override
  Color buttonCancel = Colors.grey[500]!;
  @override
  Color buttonIcon = ColorConstants.seaFoam;
  @override
  Color buttonIconHighlight = const Color(0xff0cbab8);
  @override
  Color buttonIconSplash = Colors.grey;
  @override
  Color buttonDisabled = Colors.grey;
  @override
  Color buttonGradient2 = Colors.teal[400]!;
  @override
  Color buttonGradient1 = Colors.teal[700]!;
  @override
  Color buttonSplash = Colors.grey;
  @override
  Color buttonText = Colors.white;
  @override
  Color buttonIconUnselected = Colors.grey;
  @override
  Color buttonTextDefault = Colors.white; //Colors.black; //Colors.white;
  @override
  Color buttonLineBackground = Colors.grey;
  @override
  Color buttonLineForeground = Colors.grey[800]!;
  @override
  Color buttonBackground = Colors.black;

  //FurCard colors
  @override
  Color card = Colors.grey[900]!;
  @override
  Color cardUrgent = Colors.deepOrange;
  @override
  Color cardAlternate = Colors.lightGreen;
  @override
  Color cardLeadingIcon = Colors.white;
  @override
  Color cardTrailingIcon = Colors.white;
  @override
  Color cardLabel = Colors.grey[400]!;
  @override
  Color cardTitle = Colors.white;
  @override
  Color cardSubTitle = Colors.white;
  @override
  Color cardSeparator = Colors.white24;

  @override
  Color backlogCard = Colors.grey[900]!;
  @override
  Color backlogCardAlternate = ColorConstants.seaFoam;
  Color backlogCardLeadingIcon = Colors.blueGrey;
  @override
  Color backlogCardTrailingIcon = ColorConstants.seaFoam;
  @override
  Color backlogCardLeadingDefectIcon = Colors.amber;
  @override
  Color backlogCardLeadingFeatureIcon = Colors.blueGrey;
  @override
  Color backlogCardSubTitle = Colors.grey[400]!;
  @override
  Color backlogCardSeparator = Colors.blueGrey;
  @override
  Color backlogCardLabel = Colors.grey[400]!;
  @override
  Color backlogVoteButton = ColorConstants.seaFoam;
  @override
  Color backlogVoteButtonText = Colors.black;
  @override
  Color backlogCardTitle = Colors.white;

  //Training Card Colors
  @override
  Color trainingCard = Colors.grey[900]!;
  @override
  Color trainingCardAlternate = Colors.lightGreen;
  @override
  Color trainingCardLeadingIcon = Colors.green[100]!;
  @override
  Color trainingCardTrailingIcon = Colors.green;
  @override
  Color trainingCardLabel = Colors.grey[400]!;
  @override
  Color trainingCardTitle = Colors.green[100]!;
  @override
  Color trainingCardSubTitle = Colors.green[200]!;
  @override
  Color trainingCardSeparator = Colors.green[100]!;
  @override
  Color trainingCardTopic = Colors.green;

  //checkbox
  @override
  Color checkChecked = Colors.black;
  @override
  Color checkUnchecked = Colors.white;

  //Circle colors
  @override
  Color circleNameBackground = Colors.green;
  @override
  Color circleBackground = Colors.black;
  @override
  Color circleBanner = Colors.black;
  @override
  Color circleText = Colors.white;

  //Circle Object Backgrounds
  //Color circleListBackground = Colors.grey[800];
  @override
  Color circleListBackground = Colors.grey[800]!;
  @override
  Color circleVoteBackground = Colors.green[800]!;
  @override
  Color circleDefaultBackground = Colors.grey[800]!;
  @override
  Color circlePriorityBackground = Colors.blueGrey;
  @override
  Color circleImageBackground = Colors.grey[900]!;

  //Circle Messages
  @override
  Color insertEmoji = Colors.grey[500]!;
  @override
  Color userTitleBody = Colors.white;
  //Color userMessageBody = ColorConstants.seaFoam;
  //Color memberMessageBody = Color(0xffa6d608);
  //Color memberMessageBodyAlternate = Color(0xff0cbab8);

  Color userUsername = Colors.grey;
  @override
  Color time = Colors.grey;
  @override
  Color date = Colors.grey; //const Color(0xFF404040);
  @override
  Color numberBackground = ColorConstants.darkGrey;
  Color numberForeground = Colors.white;
  Color memberUsername = Colors.grey;
  //Color userObjectBackground = Color(0xFF2f2c2c);
  @override
  Color messageBackground = const Color(0xFF404040);
  @override
  Color messageTextHint = Colors.grey;
  //double? bodyFontSize = 16;
  @override
  Color objectDisabled = Colors.grey[600]!;

  //dialogue
  @override
  Color dialogBackground = ColorConstants.darkGrey;
  @override
  Color dialogPattern = ColorConstants.seaFoam;
  @override
  Color dialogButtons = ColorConstants.seaFoam;
  @override
  Color dialogTransparentBackground = Colors.grey[900]!.withOpacity(.95);
  @override
  Color dialogLabel = Colors.white;
  @override
  Color dialogTitle = ColorConstants.seaFoam;

  //Dropdown lists
  @override
  Color dropdownBackground = const Color(0xFF191919);
  @override
  Color dropdownText = ColorConstants.seaFoam;

  //general
  @override
  Color textTitle = Colors.white;
  @override
  Color screenLink = Colors.grey;
  @override
  Color divider = Colors.grey;
  @override
  Color boxOutline = Colors.white24;
  @override
  Color underline = Colors.black;
  @override
  Color hint = Colors.grey;
  @override
  Color furnace = Colors.amber;
  @override
  Color urgentAction = Colors.amber;
  @override
  Color urgentActionAlt = Colors.white;
  @override
  Color warning = Colors.red;
  @override
  Color username = ColorConstants.seaFoam; //Color(0xff0cbab8);
  @override
  Color snackbarText = Colors.white;

  //Image
  @override
  Color imageBackground = Colors.grey[900]!;
  @override
  Color imageMarkup = Colors.white;
  @override
  Color imageMarkupSlider = Colors.white;

  //label colors
  @override
  Color labelText = Colors.white;
  @override
  Color labelTextSubtle = Colors.grey;
  @override
  Color labelReadOnlyValue = const Color(0xff0cbab8);
  @override
  Color labelHighlighted = ColorConstants.seaFoam;
  @override
  Color labelVoteOption = Colors.grey[500]!;

  //left navigation drawer
  @override
  Color drawerItemText =
      ColorConstants.seaFoam; //Colors.white; //ColorConstants.seaFoam;
  @override
  Color drawerItemTextAlt = Colors.white;
  @override
  Color drawerItemNotification = Colors.white;
  @override
  Color drawerCanvas = const Color(0xFF191919);
  @override
  Color drawerSplash = Colors.blueGrey;

  //lists
  @override
  Color listIconForeground = Colors.grey[800]!;
  @override
  Color listIconBackground = ColorConstants.seaFoam;
  @override
  Color listIconAltForeground = Colors.grey[800]!;
  @override
  Color listIconAltBackground = Colors.white;
  @override
  Color listTitle = Colors.white;
  @override
  Color checkBoxCheck = Colors.black;
  @override
  Color listExpand = Colors.amber;
  @override
  Color listLoadMore = Colors.grey;
  @override
  Color listLineText = ColorConstants.seaFoam;

  //recipes
  @override
  Color recipeIconForeground = Colors.grey[800]!;
  @override
  Color recipeIconBackground = ColorConstants.seaFoam;
  @override
  Color recipeIconAltForeground = Colors.grey[800]!;
  @override
  Color recipeIconAltBackground = Colors.white;
  @override
  Color recipeTitle = Colors.white;
  @override
  Color recipeLineText = ColorConstants.seaFoam;

  //loading things
  @override
  Color spinner = Colors.grey[400]!;
  @override
  Color threeBounce = Colors.white;
  @override
  Color progress = Colors.green;

  //menus
  @override
  Color menuItemText = const Color(0xFFadbcdf);
  @override
  Color menuGlow = Colors.white;
  @override
  Color menuIcons = Colors.white;
  @override
  Color menuIconsAlt = ColorConstants.seaFoam;
  @override
  Color popUpBackground = ColorConstants.darkGrey;
  @override
  Color menuText = ColorConstants.seaFoam; //Color(0xff0cbab8);
  @override
  Color menuBackground =
      Colors.grey[900]!.withOpacity(.95); //Colors.grey[800]!;

  //notifications
  @override
  Color sentIndicator = Colors.red;

  //password strength
  @override
  Color weakPassword = Colors.red;
  @override
  Color mediumPassword = Colors.yellow;
  @override
  Color strongPassword = Colors.green;
  @override
  Color superStrongPassword = ColorConstants.seaFoam;

  //scaffold colors
  @override
  Color background = Colors.black;
  @override
  Color appBar = Colors.black;
  //Color appBar = Color(0xff0c0a0a); 0xff0c0a0a, 0xff230a0a
  @override
  Color body = Colors.black;

  //Tabs
  @override
  Color tabIndicator = ColorConstants.seaFoam;
  @override
  Color tabIndicatorRecipe = ColorConstants.seaFoam;
  @override
  Color tabText = Colors.lightGreen;
  @override
  Color unselectedLabel = Colors.white.withOpacity(0.5);
  @override
  Color tabBackground = Colors.grey[800]!;

  //TextFields
  @override
  Color textField = const Color(0xff0cbab8);
  @override
  Color textFieldText = ColorConstants.seaFoam;
  @override
  Color textTabFieldText = ColorConstants.seaFoam;
  @override
  Color textFieldLabel = Colors.grey;
  @override
  Color textFieldPerson = Colors.white;
  @override
  Color objectTitle = Colors.white;

  //Toggle
  @override
  Color toggleAlignRight = Colors.white;
  @override
  Color toggleAlignLeft = Colors.grey;

  //url
  @override
  Color linkTitle = Colors.white;
  @override
  Color linkDescription = Colors.grey;
  @override
  Color url = Colors.lightBlue;

  //Video colors
  @override
  Color chewiePlayBackground = Colors.grey[800]!;
  @override
  Color chewiePlayForeground = Colors.white;
  @override
  Color initializingText = ColorConstants.seaFoam;
  @override
  Color recordingIcons = Colors.white;
  @override
  Color recording = Colors.red;
  @override
  Color chewieRipple = Colors.grey;

  @override
  Color inactiveThumbColor = Colors.blue[200]!;
  @override
  Color inactiveTrackColor = Colors.blue[200]!.withOpacity(.2);

  //RGB Color reference
  //Color darkGrey = Color(0xFF404040);
  //Color darkBlue = Color(0xFF0066CC);
}
