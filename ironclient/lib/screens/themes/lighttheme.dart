import 'package:flutter/material.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';

class LightTheme implements MasterTheme {
  @override
  ICThemeMode themeMode = ICThemeMode.light;

  //these colors need a light version
  @override
  get getTheme {
    final originalTextTheme = ThemeData.light().textTheme;
    final originalBody1 = originalTextTheme.bodyMedium!;

    return ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.white,
          background: Colors.white,
          secondary: Colors.cyan[300],
        ),
        primaryColor: Colors.white, //Colors.grey[800],
        //accentColor: Colors.green[600],
        //buttonColor: Colors.greenAccent,
        unselectedWidgetColor: Colors.grey,
        //cardColor: Colors.grey[200],
        // textSelectionColor: Colors.pinkAccent,
        //backgroundColor: Colors.grey[800],
        //backgroundColor: Colors.white,
        //toggleableActiveColor: Colors.cyan[300],
        canvasColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
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
    //Colors.lightGreen[700],
    Colors.lightBlue[600],
    Colors.lightGreen[700],
    Colors.yellow[900],
    Colors.green[900],
    Colors.cyan[800],
    Colors.blue[800],
    Colors.brown,
    Colors.purple[800],
    Colors.orange[900],
    Colors.indigo[800],
  });


  @override
  Color desktopSideBarBackground = Colors.teal[100]!;
  @override
  Color desktopSideBarIcon = Colors.black;
  @override
  Color desktopSelectedSideBarIcon = ColorConstants.seaFoam;
  @override
  Color desktopSelectedItem = Colors.grey[400]!;
  @override
  Color desktopSelectedNetwork= Colors.teal[600]!;
  @override
  Color desktopUnselectedNetwork = Colors.teal[100]!;

  @override
  Color fileOutline = Colors.grey[300]!;

  @override
  Color overlay = const Color.fromRGBO(
      255, 255, 255, 0.95);

  //Color memberObjectText = Colors.black;
  @override
  Color tutorialBackground = Colors.black;
  @override
  Color memberObjectBackground = Colors.grey[200]!;
  @override
  Color userObjectText = Colors.black;
  @override
  Color userObjectBackground = Colors.teal[100]!;
  @override
  Color systemMessageText = Colors.black;
  @override
  Color systemMessageBackground = Colors.blue[100]!;
  @override
  Color systemMessageNotification = Colors.black;

  @override
  Color cameraOptionSelected = ColorConstants.seaFoam;
  @override
  Color cameraOptionNotSelected = Colors.grey[500]!;

  @override
  Color homeFAB = Colors.teal[600]!.withOpacity(.85);
  Color libraryFAB = Colors.teal[600]!.withOpacity(.9);

  @override
  Color slideUpPanelBackground = Colors.teal[100]!;

  @override
  Color calendarToday = Colors.grey[500]!;
  @override
  Color calendarDayOfWeek = Colors.black;
  @override
  Color calendarRangeStart = Colors.teal[600]!;
  @override
  Color calendarRangeEnd = Colors.teal[600]!;
  @override
  Color calendarRange = const Color(0xff0cbab8);

  @override
  Color tableBackground = Colors.grey[200]!;
  @override
  Color tableText = Colors.black;

  @override
  Color circleGlow = Colors.teal[600]!;

  @override
  Color createOrJoinBackground = Colors.teal[600]!;

  @override
  Color sliderActive = ColorConstants.seaFoam;
  @override
  Color sliderInactive = Colors.white;
  @override
  Color sliderThumb = ColorConstants.seaFoam;
  @override
  Color sliderLabel = Colors.white;

  Color taggedUserHighlight = Colors.amber;

  ///hidden circle key unlock
  @override
  Color unlock = Colors.amber;

  ///DM prefname color
  @override
  Color dmPrefName = Colors.blue;

  //long press lowerbackground
  @override
  Color longPressLower = Colors.white70;

  @override
  Color textOverOpacityImage = Colors.white;

  //Avatar
  @override
  Color avatarBackground = Colors.grey[50]!;

  //bottom navigation colors (InsideCircle)
  @override
  Color bottomIcon = Colors.teal[600]!;

  @override
  // Color bottomHighlightIcon = Colors.lightBlueAccent;
  Color bottomHighlightIcon = Colors.teal[600]!;
  @override
  Color inactive = Colors.grey[600]!;
  @override
  Color bottomBackgroundColor = Colors.grey[300]!;

  //button colors
  @override
  Color button = Colors.teal[600]!;
  @override
  Color buttonCancel = Colors.grey[500]!;
  @override
  Color buttonIcon = Colors.teal[600]!;
  @override
  Color buttonIconHighlight =  Colors.green[600]!;//const Color(0xff0cbab8);
  @override
  Color buttonGenerate =  Colors.blue[600]!;
  @override
  Color buttonIconSplash = Colors.grey;
  @override
  Color buttonDisabled = Colors.grey;
  @override
  Color buttonGradient1 = Colors.teal[800]!;
  @override
  Color buttonGradient2 = Colors.teal[500]!;
  @override
  Color buttonSplash = Colors.grey;
  @override
  Color buttonText = Colors.white;
  @override
  Color buttonIconUnselected = Colors.grey;
  @override
  Color buttonTextDefault = Colors.white;
  @override
  Color buttonLineBackground = Colors.grey;
  @override
  Color buttonLineForeground = const Color(0xff71eeb8);
  @override
  Color buttonBackground = Colors.white;

  //Card colors
  @override
  Color card = Colors.green[100]!; //Colors.grey[300];
  @override
  Color cardUrgent = Colors.yellow;
  @override
  Color cardAlternate = Colors.green;
  @override
  Color cardLeadingIcon = Colors.blueGrey;
  @override
  Color cardTrailingIcon = Colors.blueGrey;
  @override
  Color cardLabel = const Color(0xff0cbab8); //Colors.white;
  @override
  Color cardTitle = Colors.black; //Color(0xff0cbab8);
  @override
  Color cardSubTitle = Colors.blueGrey;
  @override
  Color cardSeparator = Colors.blueGrey;

  @override
  Color backlogCard = Colors.grey[100]!;
  @override
  Color backlogCardAlternate = Colors.teal[600]!;
  @override
  Color backlogCardLeadingDefectIcon = Colors.orange;
  @override
  Color backlogCardLeadingFeatureIcon = Colors.blueGrey;
  @override
  Color backlogCardTrailingIcon = Colors.teal[600]!;
  @override
  Color backlogCardSubTitle = Colors.teal[600]!;
  @override
  Color backlogCardSeparator = Colors.teal[600]!;
  @override
  Color backlogVoteButton = Colors.teal[600]!;
  @override
  Color backlogVoteButtonText = Colors.white;
  @override
  Color backlogCardLabel = Colors.grey[400]!;
  @override
  Color backlogCardTitle = Colors.blueGrey;

  @override
  Color trainingCard = Colors.grey[200]!;
  @override
  Color trainingCardAlternate = Colors.lightGreen;
  @override
  Color trainingCardLeadingIcon = Colors.grey[600]!;
  @override
  Color trainingCardTrailingIcon = Colors.grey[600]!;
  @override
  Color trainingCardLabel = Colors.grey[400]!;
  @override
  Color trainingCardTitle = Colors.teal[600]!;
  @override
  Color trainingCardSubTitle = Colors.green[100]!;
  @override
  Color trainingCardSeparator = Colors.grey[600]!;
  @override
  Color trainingCardTopic = Colors.green[800]!;

  //checkbox
  @override
  Color checkChecked = Colors.greenAccent;
  @override
  Color checkUnchecked = Colors.blueGrey;

  //Circle colors
  @override
  Color circleBackground = Colors.grey[50]!;
  @override
  Color circleBanner = Colors.black; //Colors.grey[100];
  @override
  Color circleNameBackground = Colors.green;
  @override
  Color circleText = Colors.white;

  //Circle Object Backgrounds
  @override
  Color circleListBackground = Colors.blueGrey[100]!;
  @override
  Color circleVoteBackground = Colors.teal[100]!;
  @override
  Color circleDefaultBackground = Colors.grey[800]!;
  @override
  Color circlePriorityBackground = Colors.grey[300]!;
  @override
  Color circleImageBackground = Colors.grey[300]!;

  //Circle Messages
  @override
  Color insertEmoji = Colors.grey[400]!;
  @override
  Color userTitleBody = Colors.grey[800]!;
  //Color userMessageBody =
  //  Colors.teal[600]; //Color(0xff0cbab8); //Colors.blueGrey;
  //Color memberMessageBody = Colors.black; //Color(0xffa6d608);
  //Color memberMessageBodyAlternate = Color(0xff0cbab8);

  //Color userUsername = Colors.grey;
  @override
  Color time = Colors.grey;
  @override
  Color date = Colors.grey; //const Color(0xFF404040);
  @override
  Color numberBackground = Colors.grey[50]!;
  Color numberForeground = Colors.blueGrey;
  //Color memberUsername = Colors.grey;
  //Color userObjectBackground = Colors.grey[200];
  @override
  Color messageBackground = Colors.teal[100]!; //Colors.grey[300]!;
  @override
  Color messageTextHint = Colors.blueGrey;
  //double? bodyFontSize = 16;
  //double? usernameFontSize = 16;
  //double? timeFontSize = 16;
  ////double? dateFontSize = 16;
  double? timeTopPadding = 0;
  @override
  Color objectDisabled = Colors.grey[600]!;

  //dialogue
  @override
  Color dialogBackground = Colors.grey[50]!;
  @override
  Color dialogPattern = ColorConstants.seaFoam;
  @override
  Color dialogTitle = Colors.teal[600]!;
  @override
  Color dialogButtons = Colors.teal[600]!;
  @override
  Color dialogTransparentBackground = Colors.grey[200]!.withOpacity(.95);
  @override
  Color dialogLabel = Colors.black;

  //Dropdown lists
  @override
  Color dropdownBackground = Colors.grey[50]!;
  @override
  Color dropdownText = Colors.teal[600]!;

  //general[
  @override
  Color textTitle = Colors.blueGrey[900]!;
  // Color urgentAction = Colors.black;//Colors.red[900];
  @override
  Color urgentAction = Colors.amber[700]!;
  @override
  Color urgentActionAlt = Colors.amber; //Colors.red[900];
  @override
  Color warning = Colors.black;
  @override
  Color hint = Colors.grey;
  @override
  Color screenLink = Colors.grey;
  @override
  Color divider = Colors.grey;
  @override
  Color boxOutline = Colors.white24;
  @override
  Color underline = Colors.greenAccent;
  @override
  Color furnace = Colors.amber[700]!;
  @override
  Color username = const Color(0xff0cbab8);
  @override
  Color snackbarText = Colors.blueGrey;

  //Image
  @override
  Color imageBackground = Colors.grey[50]!;
  @override
  Color imageMarkup = ColorConstants.seaFoam; //like that selection?
  @override
  Color imageMarkupSlider = Colors.teal[600]!;

  //label colors
  @override
  Color labelText = Colors.black;
  @override
  Color labelTextSubtle = Colors.grey;
  @override
  Color labelReadOnlyValue = Colors.blueGrey;
  @override
  Color labelHighlighted = ColorConstants.seaFoam;
  @override
  Color labelVoteOption = Colors.grey[500]!;

  //left navigation drawer
  @override
  Color drawerItemText = Colors.teal[600]!;
  @override
  Color drawerItemTextAlt = Colors.blueGrey;
  @override
  Color drawerCanvas = Colors.grey[200]!;
  @override
  Color drawerSplash = ColorConstants.seaFoam;
  @override
  Color drawerItemNotification = Colors.lime[600]!;

  //lists
  @override
  Color listIconForeground = Colors.grey[200]!;
  @override
  Color listIconBackground = Colors.blueGrey;
  @override
  Color listIconAltForeground = Colors.grey[300]!;
  @override
  Color listIconAltBackground = Colors.grey[50]!;
  @override
  Color listTitle = Colors.grey[800]!; //Colors.grey[800];
  @override
  Color checkBoxCheck = Colors.grey[50]!;
  @override
  Color listExpand = Colors.pinkAccent;
  @override
  Color listLoadMore = Colors.grey;
  Color list = Colors.grey;
  @override
  Color listLineText = Colors.black; //Colors.teal[600]; //Colors.blueGrey;

  //recipes
  @override
  Color recipeIconForeground = Colors.white;
  @override
  Color recipeIconBackground = Colors.blueGrey;
  @override
  Color recipeIconAltForeground = Colors.grey[300]!;
  @override
  Color recipeIconAltBackground = Colors.grey[600]!;
  @override
  Color recipeTitle = Colors.grey[800]!;
  @override
  Color recipeLineText = Colors.black;

  //loading things
  @override
  Color spinner = Colors.grey[700]!;
  @override
  Color threeBounce = Colors.blueGrey;
  @override
  Color progress = Colors.green;

  //menus
  @override
  Color menuIcons = Colors.grey;
  @override
  Color menuIconsAlt = Colors.teal[600]!;
  @override
  Color menuGlow = Colors.greenAccent;
  @override
  Color popUpBackground = Colors.grey[50]!;
  @override
  Color menuItemText = const Color(0xFFadbcdf);
  @override
  Color menuText = Colors.teal[600]!;
  @override
  Color menuBackground = Colors.grey[200]!;

  //notifications
  @override
  Color sentIndicator = Colors.redAccent;

  //password strength
  @override
  Color weakPassword = Colors.redAccent;
  @override
  Color mediumPassword = Colors.yellow[400]!;
  @override
  Color strongPassword = Colors.lightGreen[400]!;
  @override
  Color superStrongPassword = ColorConstants.seaFoam;

  //scaffold colors
  @override
  Color background = Colors.grey[50]!;
  @override
  Color appBar = Colors.grey[50]!;
  @override
  Color body = Colors.grey[50]!;

  //Tabs
  @override
  Color tabIndicator = Colors.teal[600]!;
  @override
  Color tabIndicatorRecipe = Colors.blueGrey;
  @override
  Color tabText = Colors.lightGreen;
  @override
  Color unselectedLabel = Colors.grey;
  @override
  Color tabBackground = Colors.grey[200]!;

  //TextFields`
  @override
  Color textField = Colors.teal[600]!;
  @override
  Color textFieldText =
      Colors.teal[600]!; //Colors.blueGrey;//Colors.black; //Color(0xff71eeb8);
  @override
  Color textTabFieldText = Colors.black;
  @override
  Color textFieldLabel = Colors.grey[700]!;
  @override
  Color textFieldPerson = Colors.blueGrey;
  @override
  Color objectTitle = Colors.blueGrey;

  //Toggle
  @override
  Color toggleAlignRight = Colors.blueGrey;
  @override
  Color toggleAlignLeft = Colors.grey;

  //url
  @override
  Color linkTitle = Colors.blueGrey;
  @override
  Color linkDescription = Colors.black;
  @override
  Color url = Colors.blueGrey;

  //Video colors
  @override
  Color initializingText = Colors.blueGrey;
  @override
  Color recordingIcons = Colors.white;
  @override
  Color recording = Colors.redAccent;
  @override
  Color chewiePlayBackground = Colors.grey[50]!;
  @override
  Color chewiePlayForeground = Colors.grey[800]!;
  @override
  Color chewieRipple = Colors.blueGrey;

  @override
  Color inactiveThumbColor = Colors.blue[200]!;
  @override
  Color inactiveTrackColor = Colors.blue[200]!.withOpacity(.2);

//RGB Color reference
//Color darkGrey = Color(0xFF404040);
//Color darkBlue = Color(0xFF0066CC);
}
