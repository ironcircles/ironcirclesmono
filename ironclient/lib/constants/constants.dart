import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/models/globalstate.dart';

const String IRONFORGE = "IronForge";

enum DeleteAccountResult { success, transferNetwork, failed }

enum MagicCodeType { network, circle }

class ThemeSetting {
  static const int DARK = 0;
  static const int LIGHT = 1;
}

class Language {
  static const int ENGLISH = 1;
  static const int TURKISH = 2;
}


class ErrorMessages {
  static const String DEFAULT_ERROR_MESSAGE =
      'Something went wrong. Please try again.';
  static const String USER_BEING_VOTED_OUT =
      "You cannot post when there is an active vote to remove you from the Circle";
}

class PlatformType {
  static const String ANDROID = 'android';
  static const String IOS = 'iOS';
}

enum RatchetKeyType { user, signature }

class UserCircleFilterType {
  UserCircleFilterType({required this.context}) {
    PRIVATE_VAULT =
        AppLocalizations.of(context)!.privateVault; //'Private Vaults';
  }

  BuildContext context;
  static const String ALL = 'All';
  static const String DM = 'Direct Messages';
  static const String CIRCLES = 'Standard';
  static String PRIVATE_VAULT = '';
  static const String HIDDEN = 'Hidden';
}

class VerificationFailed {
  static const String NEW_USER = 'new_user';
  static const String DEVICE_NOT_FOUND = 'Unable to find device';
  static const String NEW_DEVICE =
      'Alert: Sender verification failed. Sender is using a new device:';
  static const String FAILED =
      'Alert: Sender verification failed. Sender is using a new device.';
}

class ICPadding {
  static const int GENERATE_BUTTONS = 200;
}

class TextLength {
  static const int Largest = 9000;
  static const int Large = 2000;
  // recipe overview,
  static const int Small = 500;
  //event location + description, credential url, recipe instruction
  static const int Smaller = 250;
  // voting question + answers, recipe ingredient, list task
  static const int Smallest = 100;
  //event title, list title, recipe name + servings + prep time + cook time + total time,
  // credential application name + username + password,
}

// class Calendar{
//   static double getPadding(width){
//     double screenWidth = width;
//     if (screenWidth >= 900) {
//       return LARGE_PADDING;
//     } if (screenWidth >= 400) {
//       return MEDIUM_PADDING;
//     } else {
//       return DEFAULT_PADDING;
//     }
//   }
//   static double MEDIUM_PADDING = 0; //100
//   static double LARGE_PADDING = 0; //300
//   static double DEFAULT_PADDING = 0; //12
// }

class Library {
  static double getPadding(width) {
    double screenWidth = width;
    double padding = 15; //35
    if (screenWidth >= 400) {
      padding = 15; //15
    }
    return padding;
  }

  static double getWidth(width) {
    double screenWidth = width;
    double boxWidth = screenWidth - 200;
    // if (screenWidth >= 400){
    //   boxWidth = 300;
    // } if (screenWidth >= 600) {
    //   boxWidth = 550;
    // }
    return boxWidth;
  }
}

// Used to make buttons responsive on tablet only
class ButtonType {
  static double getWidth(screenWidth) {
    double padding = 5.0;
    if (screenWidth >= 400) {
      padding = 10.0;
    }
    if (screenWidth >= 600) {
      padding = (screenWidth / 10);
    }
    return padding;
  }
}

class ReportType {
  static const int PROFILE = 0;
  static const int POST = 1;
  static const int NETWORK = 3;
}

class NotificationType {
  static const int MESSAGE = 0;
  static const int EVENT = 1;
  static const int DELETE = 2;
  static const int INVITATION = 3;
  static const int ACTION_NEEDED = 4;
  static const int WIPE_DEVICE = 5;
  static const int DEACTIVATE_DEVICE = 6;
  static const int USER_REQUEST_UPDATE = 7;
  static const int NETWORK_REQUEST_UPDATE = 8;
  static const int BACKLOG_REPLY = 9;
  static const int BACKLOG_ITEM = 10;
  static const int GIFTED_IRONCOIN = 11;
  static const int REACTION = 12;
  static const int REPLY = 13;
  static const int REPLY_REACTION = 14;
  static const int CIRCLEAGORACALL = 15;
}

class DeviceOnlyCircle {
  static const String circleID = 'device_only_circle_id';
  static const String userCircleID = 'device_only_usercircle_id';
  static const String prefName = 'DEVICE';
}

class UIPadding {
  static const double BETWEEN_MESSAGES = 20;
}

class FontSize {
  static const double SMALL = 14;
  static const double DEFAULT = 16;
  static const double LARGE = 20;
  static const double LARGEST = 24;
}

class CircleObjectType {
  static const String CIRCLEMESSAGE = 'circlemessage';
  static const String CIRCLEGIF = 'circlegif';
  static const String CIRCLEIMAGE = 'circleimage';
  static const String CIRCLEALBUM = 'circlealbum';
  static const String CIRCLELINK = 'circlelink';
  static const String CIRCLEEVENT = 'circleevent';
  static const String CIRCLEQUILLTEXT = 'circlequilltext';
  static const String CIRCLELIST = 'circlelist';
  static const String CIRCLECREDENTIAL = 'circlecredential';
  static const String CIRCLEFILE = 'circlefile';
  static const String CIRCLEVOTE = 'circlevote';
  static const String CIRCLEVIDEO = 'circlevideo';
  static const String CIRCLERECIPE = 'circlerecipe';
  static const String CIRCLEAGORACALL = 'circleagoracall';
  static const String UNABLETODECRYPT = 'unabletodecrypt';
  static const String DELETED = 'deleted';
  static const String SYSTEMMESSAGE = 'systemmessage';
}

class RETRIES {
  //static const MAX_UPLOAD_RETRIES = 100;
  static const MAX_VIDEO_DOWNLOAD_RETRIES = 100;
  static const MAX_VIDEO_UPLOAD_RETRIES = 100;
  static const MAX_FILE_DOWNLOAD_RETRIES = 100;
  static const MAX_FILE_UPLOAD_RETRIES = 100;
  static const MAX_IMAGE_DOWNLOAD_RETRIES = 50;
  static const MAX_IMAGE_UPLOAD_RETRIES = 50;
  static const MAX_IMAGE_UPLOAD_RETRIES_BEFORE_HOTSWAP = 5;
  static const MAX_OBJECT_DOWNLOAD_RETRIES = 100;
  static const MAX_OBJECT_UPLOAD_RETRIES = 100;
  static const MAX_MESSAGE_RETRIES = 500;
  static const MAX_FETCH_RETRY = 10;
  static const HTTP_RETRY = 3;
  static const MAX_HIDDEN_RETRIES = 100;
  static const RATCHET_RETRIES = 10;
  static const TIMEOUT = 50;
  static const TIMEOUT_API_IMAGE = 15;
  //static const TIMEOUT_API = 10;
}

class CircleObjectTypeString {
  static const String CIRCLEMESSAGE = 'message';
  static const String CIRCLEGIF = 'gif';
  static const String CIRCLEIMAGE = 'image';
  static const String CIRCLEALBUM = 'album';
  static const String CIRCLELINK = 'link';
  static const String CIRCLELIST = 'list';
  static const String CIRCLEVOTE = 'vote';
  static const String CIRCLEFILE = 'file';
  static const String CIRCLEVIDEO = 'video';
  static const String CIRCLERECIPE = 'recipe';
  static const String CIRCLEAGORACALL = 'agora call';

  static String getCircleObjectTypeString(String type) {
    if (type == CircleObjectType.CIRCLEMESSAGE)
      return CIRCLEMESSAGE;
    else if (type == CircleObjectType.CIRCLEGIF)
      return CIRCLEGIF;
    else if (type == CircleObjectType.CIRCLEIMAGE)
      return CIRCLEIMAGE;
    else if (type == CircleObjectType.CIRCLEALBUM)
      return CIRCLEALBUM;
    else if (type == CircleObjectType.CIRCLELINK)
      return CIRCLELINK;
    else if (type == CircleObjectType.CIRCLELIST)
      return CIRCLELIST;
    else if (type == CircleObjectType.CIRCLEVOTE)
      return CIRCLEVOTE;
    else if (type == CircleObjectType.CIRCLEVIDEO)
      return CIRCLEVIDEO;
    else if (type == CircleObjectType.CIRCLERECIPE)
      return CIRCLERECIPE;
    else if (type == CircleObjectType.CIRCLEAGORACALL)
      return CIRCLEAGORACALL;
    else if (type == CircleObjectType.CIRCLEFILE)
      return CIRCLEFILE;
    else
      return 'unknown';
  }
}

class CoinPaymentType {
  static const String IMAGE_GENERATION = "Generated Image";
  static const String INPAINTING = "Inpainting Image";
  static const String PURCHASED_COINS = "Purchased IronCoins";
  static const String GAVE_COINS = "Gave IronCoin";
  static const String GIFTED_COINS = "Gifted IronCoin";
  static const String SUBSCRIBER_COINS = "Subscription IronCoin";
  static const String REFUND_IRONCOIN = "Refunded IronCoin";
}

class UserDisappearingTimer {
  static const int OFF = 0;
  static const int ONE_TIME_VIEW = 1;
  static const int SCHEDULED = 2;
  static const int TEN_SECONDS = 10;
  static const int THIRTY_SECONDS = 30;
  static const int ONE_MINUTE = 60;
  static const int FIVE_MINUTES = 300;
  static const int ONE_HOUR = 3600;
  static const int EIGHT_HOURS = 28800;
  static const int ONE_DAY = 86400;
}

class UserDisappearingTimerStrings {
  static const String OFF = 'off';
  static const String ONE_TIME_VIEW = '1';
  static const String TEN_SECONDS = '10s';
  static const String THIRTY_SECONDS = '30s';
  static const String ONE_MINUTE = '1m';
  static const String FIVE_MINUTES = '5m';
  static const String ONE_HOUR = '1h ';
  static const String EIGHT_HOURS = '8h ';
  static const String ONE_DAY = '24h';

  static String getUserTimerString(int timer) {
    if (timer == UserDisappearingTimer.OFF) return OFF;
    if (timer == UserDisappearingTimer.ONE_TIME_VIEW)
      return ONE_TIME_VIEW;
    else if (timer == UserDisappearingTimer.TEN_SECONDS)
      return TEN_SECONDS;
    else if (timer == UserDisappearingTimer.THIRTY_SECONDS)
      return THIRTY_SECONDS;
    else if (timer == UserDisappearingTimer.ONE_MINUTE)
      return ONE_MINUTE;
    else if (timer == UserDisappearingTimer.FIVE_MINUTES)
      return FIVE_MINUTES;
    else if (timer == UserDisappearingTimer.ONE_HOUR)
      return ONE_HOUR;
    else if (timer == UserDisappearingTimer.EIGHT_HOURS)
      return EIGHT_HOURS;
    else if (timer == UserDisappearingTimer.ONE_DAY) return ONE_DAY;

    return '';
  }
}

class CircleDisappearingTimer {
  static const int OFF = 0;
  static const int FOUR_HOURS = 4;
  static const int EIGHT_HOURS = 8;
  static const int ONE_DAY = 24;
  static const int ONE_WEEK = 168;
  static const int THIRTY_DAYS = 720;
  static const int NINETY_DAYS = 2160;
  static const int SIX_MONTHS = 4320;
  static const int ONE_YEAR = 8760;
}

class CircleDisappearingTimerAPIStrings {
  static const String OFF = 'off';
  static const String FOUR_HOURS = '4 hours';
  static const String EIGHT_HOURS = '8 hours';
  static const String ONE_DAY = '1 day';
  static const String ONE_WEEK = '1 week';
  static const String THIRTY_DAYS = '30 days';
  static const String NINETY_DAYS = '90 days';
  static const String SIX_MONTHS = '6 months';
  static const String ONE_YEAR = '1 year';
}

class ImageConstants {
  static const int THUMBNAIL_QUALITY = 10;
  static const int CIRCLEBACKGROUND_QUALITY = 20;
  static const int THUMBNAIL_WIDTH = 270; //500
  static const int VIDEO_THUMBNAIL_WIDTH = 270; //500
  static const int VIDEO_WIDTH = 200; //500
}

class VideoStateIC {
  static const int UNKNOWN = 0;
  static const int DOWNLOADING_PREVIEW = 1;
  static const int PREVIEW_DOWNLOADED = 2;
  static const int DOWNLOADING_VIDEO = 3;
  static const int VIDEO_DOWNLOADED = 4;
  static const int INITIALIZING_CHEWIE = 5;
  static const int VIDEO_READY = 6;
  static const int UPLOADING_VIDEO = 7;
  static const int VIDEO_UPLOADED = 8;
  static const int NEEDS_CHEWIE = 9;
  static const int FAILED = 10;
  static const int BUFFERING = 11;
}

class SubType {
  static const int LOGIN_INFO = 0;
  static const int CREDIT_CARD = 1;
  static const int ROUTING_INFO = 2;
}

class BlobAuthType {
  static const CIRCLE = 0;
  static const USER = 1;
  static const USERCIRCLE = 2;
}

class BlobType {
  static const IMAGE = 0;
  static const VIDEO = 1;
  static const FILE = 2;
  static const AVATAR = 3;
  static const BACKGROUND = 4;
  static const KEYCHAIN_BACKUP = 5;
  static const LOG_DETAIL = 6;
}

class BlobLocation {
  static const UNKNOWN = '';
  static const DEVICE_ONLY = 'Device';
  static const S3 = 'S3';
  static const GRIDFS = 'GRIDFS';
  static const FILE = 'FILE';
  static const PRIVATE_S3 = 'PS3';
  static const PRIVATE_WASABI = 'PW';
}

class BlobState {
  static const int BLOB_UPLOAD_FAILED = -2;
  static const int BLOB_DOWNLOAD_FAILED = -1;
  static const int UNKNOWN = 0;
  static const int CACHED = 1;
  static const int ENCRYPTING = 2;
  static const int DECRYPTING = 3;
  static const int ENCRYPTED = 4;
  static const int DECRYPTED = 5;
  static const int UPLOADING = 6;
  static const int DOWNLOADING = 7;
  static const int UPLOADED_BLOB_ONLY = 8;
  static const int READY = 9;
  static const int NOT_DOWNLOADED = 10;
}

class BlobFailed {
  static const int UNKNOWN = 0;
  static const int FILETOOLARGE = 1;
}

class ScreenSizes {
  static double getFormScreenWidth(double screenWidth) {
    return screenWidth < 900 ? screenWidth : 900;
  }

  static double getFormMinScreenWidth(double screenWidth) {
    return screenWidth < 800 ? screenWidth : 800;
  }

  static double getMaxImageWidth(double screenWidth) {
    return screenWidth > 500 ? 500 : screenWidth;
  }

  static double getMaxButtonWidth(double screenWidth, bool centered) {
    return screenWidth > 600 ? centered? 400 : 200 : screenWidth;
  }

  static double formRightMargin = 70;
  static double maskPreviewToolbar = 35;
}

class InsideConstants {
  static const double BODYFONTSIZE = 16;
  static const double USERNAMEFONTSIZE = 14;
  static const double TIMEFONTSIZE = 14;
  static const double DATEFONTSIZE = 16;
  static const double TIMEPADDINGTOP = 0;
  static const double MESSAGEBOXSIZE = 270; //270, 500
  static const double SUPRESSTIMEDURATION = 900;
  static const double DATEPADDINGTOP = 5;
  static const double DATEPADDINGBOTTOM = 5;
  static const double MESSAGEPADDING = 8.5;

  static double getReplyPreviewWidth(double screenWidth) {
    double preview = 60; //100
    if (screenWidth >= 500) {
      preview = 125; //200
    }
    return preview;
  }

  /*static double getImageSize(width, height, screenWidth) {
    double finalWidth = 270;
    if (height > width) {
      finalWidth = (screenWidth);
    }
    if (screenWidth >= 500) {
      finalWidth = (screenWidth / 4) * 3;
    }
    return finalWidth;
  }

  static double getImageWidth(width) {
    double screenWidth = width;
    double finalWidth = 270;
    if (screenWidth >= 400) {
      finalWidth = (screenWidth / 4) * 3;
    }
    return finalWidth;
  }

  static double getTextWidth(width) {
    double screenWidth = width;
    double finalWidth = 270;
    if (screenWidth >= 400) {
      finalWidth = (screenWidth / 4) * 3;
    }
    return finalWidth;
  }*/

  static double getDisappearingMessagesWidth(double screenWidth) {
    double finalWidth = screenWidth * .67;
    if (finalWidth < 300) {
      finalWidth = 300;
    }
    return finalWidth;
  }

  static double getCircleObjectSize(double screenWidth) {
    double finalWidth = screenWidth * .67;

    /*if (screenWidth <= globalState.screenWidthBeforeScaleDown) {
      finalWidth = screenWidth - 100;
    } else {
      finalWidth = screenWidth * .67;
    }

    */

    return finalWidth;
  }

  static double getVisualWidth(width) {
    double screenWidth = width;
    double finalWidth = 270;
    if (screenWidth >= 400) {
      //landscape: phone ; portrait: tablet
      finalWidth = (screenWidth / 2);
    }
    if (screenWidth >= 900) {
      //landscape: tablet
      finalWidth = (screenWidth / 3);
    }
    return finalWidth;
  }

  static int getGalleryWidth(width) {
    double screenWidth = width;
    int galleryWidth = 3;
    if (screenWidth >= 400) {
      galleryWidth = (screenWidth / 170).floor();
    }

    if (globalState.isDesktop()) {
      galleryWidth = (galleryWidth /2).floor();
    }
    return galleryWidth;
  }

  static int getVaultWidth(width, height) {
    int vaultWidth = 2;
    if (width > height) {
      vaultWidth = 4;
    }

    if (globalState.isDesktop()){
      vaultWidth = 6;
    }
    return vaultWidth;
  }
}

class NetworkRequestStatus {
  static const int PENDING = 0;
  static const int ACCEPTED = 1;
  static const int DECLINED = 2;
  static const int CANCELED = 3;
}

class InvitationStatus {
  static const String CANCELED = 'canceled';
  static const String DECLINED = 'declined';
  static const String ACCEPTED = 'accepted';
  static const String BLOCKED = 'blocked';
  static const String PENDING = 'pending';
}

class ScreenMode {
  static const int ADD = 0;
  static const int EDIT = 1;
  static const int READONLY = 2;
  static const int TEMPLATE = 3;
}

class PassScreenType {
  static const int CHANGE_PASSWORD = 0;
  static const int PASSWORD_EXPIRED = 1;
  static const int RESET_CODE = 2;
}

class CircleVoteType {
  static const String STANDARD = 'standard';
  static const String ADDMEMBER = 'invitation';
  static const String REMOVEMEMBER = 'remove_member';
  static const String DELETECIRCLE = 'delete_circle';
  static const String SECURITY_SETTING = 'security_setting';
  static const String PRIVACY_SETTING = 'privacy_setting';
  static const String SECURITY_SETTING_MODEL = 'security_setting_model';
  static const String PRIVACY_SETTING_MODEL = 'privacy_setting_model';
}

class CircleSetting {
  static const String toggleEntryVote = 'toggleEntryVote';
  static const String toggleMemberPosting = 'toggleMemberPosting';
  static const String toggleMemberReacting = 'toggleMemberReacting';
  static const String privacyShareImage = 'privacyShareImage';
  static const String privacyVotingModel = 'privacyVotingModel';
  static const String privacyShareURL = 'privacyShareURL';
  static const String privacyShareGif = 'privacyShareGif';
  static const String privacyCopyText = 'privacyCopyText';
  static const String privacyDisappearingTimer = 'privacyDisappearingTimer';
  static const String securityVotingModel = 'securityVotingModel';
  static const String security2FA = 'security2FA';
  static const String securityMinPassword = 'securityMinPassword';
  static const String securityDaysPasswordValid = 'securityDaysPasswordValid';
  static const String securityTokenExpirationDays =
      'securityTokenExpirationDays';
  static const String securityLoginAttempts = 'securityLoginAttempts';
}

class CircleSettingChangeType {
  static const int PRIVACY = 0;
  static const int SECURITY = 1;
}

class BottomNavigationOptions {
  static const int CIRCLES = 0;
  static const int NETWORKS = 3;
  static const int ACTIONS = 2;
  static const int LIBRARY = 1;
}

class CircleOwnership {
  static const OWNER = "owner";
  static const MEMBERS = "members";
}

class CircleVoteModel {
  static const UNANIMOUS = "unanimous";
  static const MAJORITY = "majority";
  static const POLL = "poll";
}

class AlbumItemType {
  static const IMAGE = 'image';
  static const GIF = 'gif';
  static const VIDEO = 'video';
}

class ActionRequiredType {
  static const ACTIONNEEDED = 0;
  static const CIRCLEOBJECT = 1;
  static const REQUESTAPPROVED = 2;
  static const REQUESTMADE = 3;
}

class ActionRequiredAlertType {
  static const SETUP_PASSWORD_ASSIST = 1;
  static const HELP_WITH_RESET = 2;
  static const EXPORT_KEYS = 3;
  static const CHANGE_GENERATED = 4;
  static const USER_JOINED_NETWORK = 5;
  static const NETWORK_REQUEST_APPROVED = 6;
  static const USER_REQUESTED_JOIN_NETWORK = 7;
  static const USER_REQUESTED_EMPTY = 8;
}

class CircleRetention {
  static const PASSTHROUGH = 0;
  static const TEN_GB = 10;
  static const TWENTY_FIVE_GB = 25;
  static const FIFTY_GB = 50;
  static const SEVENTY_FIVE_GB = 75;
  static const ONE_HUNDRED_GB = 100;
  static const TWO_HUNDRED_GB = 250;
  static const FIVE_HUNDRED_GB = 500;
  static const ONE_TB = 1000;
  static const TWO_TB = 2000;
}

class NetworkJoinAttemptMessage {
  static const String INVALID = 'invalid';
  static const String VALID = 'valid';
  static const String EXCEEDED = 'exceeded';
  static const String FAILED = 'failed';
}

class AccountType {
  static const FREE = 0;
  static const PREMIUM = 1;
}

class Role {
  static const MEMBER = 0;
  static const ADMIN = 1;
  static const OWNER = 2;
  static const IC_ADMIN = 3;
  static const DEBUG = 4;
}

class CircleType {
  static const String STANDARD = 'standard';
  static const TEMPORARY = 'temporary';
  static const VAULT = 'vault';
  static const EVERYONE = 'everyone';
  static const WALL = 'wall';
  static const OWNER = 'owner';
}

List<String> circleTypes = [
  CircleType.STANDARD,
  CircleType.VAULT,
  CircleType.OWNER,
  CircleType.TEMPORARY,
];

class Purchases {
  static const String _IRONCOIN_ANDROID = 'ironcoins';
  static const String _IRONCOIN_IOS = 'ironcoins_ios';

  static String getIronCoinProductID() {
    if (Platform.isAndroid) {
      return _IRONCOIN_ANDROID;
    } else {
      return _IRONCOIN_IOS;
    }
  }
}

class Subscriptions {
  //Should directly match play and app store
  static const String _PRIVACY_PLUS_ANDROID = 'privacy_plus';
  static const String _PRIVACY_PLUS_IOS = 'privacy_plus_ios';

  static String getSubscriptionProductID() {
    if (Platform.isAndroid)
      return _PRIVACY_PLUS_ANDROID;
    else
      return _PRIVACY_PLUS_IOS;
  }
}

class SubscriptionStatus {
  static const int PENDING = 0;
  static const int ACTIVE = 1;
  static const int PAUSED = 2;
  static const int CANCELED = 3;
}

class PurchaseObjectStatus {
  static const int PENDING = 0;
  static const int PURCHASED = 1;
  static const int CANCELED = 2;
}


const List<String> ALLOWED_MEDIA_TYPES = [
  'avi',
  'flv',
  'mkv',
  'mov',
  'mp4',
  'mpeg',
  'webm',
  'wmv',
  'bmp',
  'gif',
  'jpeg',
  'jpg',
  'png',
];


const List<String> ALLOWED_FILE_TYPES = [
  'zip',
  'pdf',
  'doc',
  'docx',
  'ppt',
  'pptx',
  'xls',
  'xlsx',
  'odp',
  'otp',
  'tar',
  'gz',
  'apk',
  'txt',
  'db',
  'torrent',
  'csv',
  'iso',
  'js',
  'cs',
  'dart',
  'rar',
  'rtf',
  'vcf',
  'plist',
  'yaml',
  'json',
  'jks'
];

/*
enum ActionRequiredAlertType {
  SETUP_PASSWORD_ASSIST,
  HELP_WITH_RESET,
  EXPORT_KEYS,
}
const relationships = <ActionRequiredAlertType, int>{
  ActionRequiredAlertType.SETUP_PASSWORD_ASSIST: 1,
  ActionRequiredAlertType.HELP_WITH_RESET: 2,
  ActionRequiredAlertType.EXPORT_KEYS: 3,
};

 */

/*
class CircleSettingSecurityValue{
  static const ALLOWED = "allowed";
  static const DISALLOWED = "disallowed";

}*/
