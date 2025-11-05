import 'package:flutter/material.dart';

class ColorConstants {
  static const Color seaFoam = Color(0xff71eeb8);
  static const Color indigo = Color(0xff4b0082);
  static const Color darkGrey = Color(0xff424242);
}

 enum ICThemeMode  {dark, light}

abstract class MasterTheme {
  // static const DARK_MODE = 'dark';
  // static const LIGHT_MODE = 'light';

  late ICThemeMode themeMode;
  //String? mode;
  get getTheme;

  ///add all the other colors here///

  //alternating user colors
  List<Color>? messageColorOptions;

  late Color fileOutline;

  late Color overlay;

  late Color buttonGenerate;

  late Color desktopSideBarBackground;
  late Color desktopSideBarIcon;
  late Color desktopSelectedSideBarIcon;
  late Color desktopSelectedItem;
  late Color desktopSelectedNetwork;
  late Color desktopUnselectedNetwork;

  //late Color memberObjectText;  //dynamic
  late Color  memberObjectBackground;
  late Color  systemMessageText;
  late Color  systemMessageBackground;
  late Color  systemMessageNotification;
  late Color  userObjectText;
  late Color  userObjectBackground;
  late Color  messageBackground;  //Text box to send message
  late Color  homeFAB;
  late Color  libraryFAB;

  //late Color userColorMessage;
  //late Color userColorBackground;

  late Color  tutorialBackground;
  late Color  calendarToday;
  late Color  calendarDayOfWeek;
  late Color  calendarRangeStart;
  late Color  calendarRangeEnd;
  late Color  calendarRange;

  late Color slideUpPanelBackground;

  late Color  cameraOptionSelected;
  late Color  cameraOptionNotSelected;

  late Color  tableBackground;
  late Color  tableText;
  
  late Color taggedUserHighlight;
    

  //Avatar
  late Color  avatarBackground;

  //long press lowerbackground
  late Color  longPressLower;


  late Color  textOverOpacityImage;


  late Color  sliderActive;
  late Color  sliderInactive;
  late Color  sliderThumb;
  late Color  sliderLabel;

  late Color   createOrJoinBackground;

  ///hidden circle key unlock
  late Color   unlock;

  ///DM prefname color
  late Color   dmPrefName;

  //bottom navigation colors (InsideCircle)
  late Color   bottomIcon;
  late Color   bottomHighlightIcon;
  late Color   inactive;
  late Color   bottomBackgroundColor;

  //button colors
  late Color button;
  late Color   buttonCancel;
  late Color   buttonDisabled;
  late Color   buttonGradient1;
  late Color   buttonGradient2;
  late Color   buttonSplash;
  late Color   buttonText;
  late Color   snackbarText;
  late Color   buttonIcon;
  late Color   buttonIconHighlight;
  late Color   buttonIconSplash;
  late Color   buttonIconUnselected;
  late Color   buttonTextDefault;
  late Color   buttonLineBackground;
  late Color   buttonLineForeground;
  late Color   buttonBackground;

  //Card colors
  late Color   card;
  late Color   cardUrgent;
  late Color   cardAlternate;
  late Color   cardLeadingIcon;
  late Color   cardTrailingIcon;
  late Color   cardLabel;
  late Color   cardTitle;
  late Color   cardSubTitle;
  late Color   cardSeparator;

  late Color   backlogCard;
  late Color   backlogCardAlternate;
  late Color   backlogCardLeadingDefectIcon;
  late Color   backlogCardLeadingFeatureIcon;
  late Color   backlogCardTrailingIcon;
  late Color   backlogCardLabel;
  late Color   backlogVoteButton;
  late Color   backlogVoteButtonText;
  late Color   backlogCardTitle;
  late Color   backlogCardSubTitle;
  late Color   backlogCardSeparator;

  //Training Video Card Colors
  late Color  trainingCard;
  late Color  trainingCardAlternate;
  late Color  trainingCardLeadingIcon;
  late Color  trainingCardTrailingIcon;
  late Color  trainingCardLabel;
  late Color  trainingCardTopic;
  late Color  trainingCardTitle;
  late Color  trainingCardSubTitle;
  late Color  trainingCardSeparator;

  //checkbox
  late Color  checkChecked;
  late Color checkUnchecked;

  //circle colors
  late Color circleBackground;
  late Color circleText;
  late Color circleBanner;
  late Color circleNameBackground;
  late Color circleGlow;

  //Circle Object Backgrounds
  late Color circleListBackground;
  late Color circleVoteBackground;
  late Color circleDefaultBackground;
  late Color circlePriorityBackground;
  late Color circleImageBackground;

  //Circle Messages
  late Color insertEmoji;
  late Color userTitleBody;
  //late Color userMessageBody;
  //late Color memberMessageBody;
  //late Color memberMessageBodyAlternate;

  //late Color userUsername;
  late Color time;
  late Color date;
  late Color numberBackground;
  //late Color memberUsername;
  late Color messageTextHint;
  late Color objectDisabled;

  //dialogue
  late Color dialogBackground;
  late Color dialogTitle;
  late Color dialogPattern;
  late Color dialogButtons;
  late Color dialogTransparentBackground;
  late Color dialogLabel;

  //Dropdown lists
  late Color dropdownBackground;
  late Color dropdownText;


  //general
  late Color furnace;
  late Color textTitle;
  late Color urgentAction;
  late Color urgentActionAlt;
  late Color warning;
  late Color screenLink;
  late Color hint;
  late Color divider;
  late Color boxOutline;
  late Color underline;
  late Color username;

  //Image
  late Color imageBackground;
  late Color imageMarkup;
  late Color imageMarkupSlider;

  //label colors
  late Color labelText;
  late Color labelTextSubtle;
  late Color labelReadOnlyValue;
  late Color labelHighlighted;
  late Color labelVoteOption;

  //left navigation drawer
  late Color drawerItemText;
  late Color drawerItemTextAlt;
  late Color drawerCanvas;
  late Color drawerSplash;
  late Color drawerItemNotification;

  //lists
  late Color listIconForeground;
  late Color listIconBackground;
  late Color listIconAltForeground;
  late Color listIconAltBackground;
  late Color listTitle;
  late Color checkBoxCheck;
  late Color listExpand;
  late Color listLoadMore;
  late Color listLineText;

  //recipes
  late Color recipeIconForeground;
  late Color recipeIconBackground;
  late Color recipeIconAltForeground;
  late Color recipeIconAltBackground;
  late Color recipeTitle;
  late Color recipeLineText;

  //loading things
  late Color spinner;
  late Color threeBounce;
  late Color progress;

  //menus
  late Color menuIcons;
  late Color menuIconsAlt;
  late Color menuItemText;
  late Color menuGlow;
  late Color popUpBackground;
  late Color menuText;
  late Color menuBackground;

  //notifications
  late Color sentIndicator;

  //password strength
  late Color weakPassword;
  late Color mediumPassword;
  late Color strongPassword;
  late Color superStrongPassword;

  //scaffold colors
  late Color background;
  late Color appBar;
  late Color body;

  //Tabs
  late Color tabIndicator;
  late Color tabIndicatorRecipe;
  late Color tabText;
  late Color unselectedLabel;
  late Color tabBackground;

  //TextFields
  late Color textField;
  late Color textFieldText;
  late Color textTabFieldText;
  late Color textFieldLabel;
  late Color textFieldPerson;
  late Color objectTitle;

  //Toggle
  late Color toggleAlignRight;
  late Color toggleAlignLeft;

  //url
  late Color linkTitle;
  late Color linkDescription;
  late Color url;

  //Video colors
  late Color initializingText;
  late Color recording;
  late Color recordingIcons;
  late Color chewiePlayBackground;
  late Color chewiePlayForeground;
  late Color chewieRipple;

  late Color inactiveThumbColor;
  late Color inactiveTrackColor;

  //RGB Color reference
  //late Color darkGrey;
  //late Color darkBlue;

}
