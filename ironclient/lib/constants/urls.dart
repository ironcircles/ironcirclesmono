import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

enum RunLocation { local, qa, staging, production }

class Urls {
  static const String PROD = 'https://www.ironcladcircles.com/';
  static const String OLDPROD = 'https://ironcirclesforge.herokuapp.com/';
  static const String QA = 'https://ironfurny.herokuapp.com/';
  static const String STAGING = 'https://ironcirclesforge.herokuapp.com/';

  late String forge;
  late String spinFurnace;
  // late String spinFurnaceVisual;

  String forgeAPIKEY = 'J73Hpqj362J4psX7jyhXdftbxSPYkE9CrjWShz9r';
  String spinFurnaceAPIKEY = 'J73Hpqj362J4psX7jyhXdftbxSPYkE9CrjWShz9r';

  static bool testingReleaseMode = false;

  ///ATTENTION - CHANGE THIS VARIABLE TO CHANGE THE DEBUG OR STAGING RUN LOCATION
  static RunLocation runLocation = RunLocation.local;

  Urls() {
    if (kReleaseMode) {
      ///checked in version should only ever point to prod
      forge = PROD;
      spinFurnace = PROD;

      ///if you uncomment this, don't check it in!
      ///   forge = QA;
      ///   spinFurnace = QA;
    } else {
      if (runLocation == RunLocation.local) {
        if (Platform.isAndroid) {
          forge = "http://10.0.2.2:3001/";
        } else if (Platform.isIOS || Platform.isMacOS) {
          forge = "http://localhost:3001/";
        } else if (Platform.isWindows || Platform.isLinux) {
          forge = QA;
        }
      } else if (runLocation == RunLocation.qa) {
        forge = QA;
      } else if (runLocation == RunLocation.staging) {
        forge = STAGING;
      } else if (runLocation == RunLocation.production) {
        forge = PROD;
      }
      spinFurnace = forge;
    }
  }

  ///kyber ready
  static const String DEVICE_KYBERTEST = 'device/kybertest/';
  static const String LOGS_FORGE = 'log/forge/';
  static const String HOSTEDFURNACE_CHECKNAME = 'hostedfurnace/checkname/';
  static const String DEZGO_KEY = 'settings/dezgokey/';
  static const String DEZGO_KEY_FOR_REGISTRATION =
      'settings/dezgoregistration/';
  static const String KEYCHAINBACKUP = 'keychainbackup/';
  static const String KEYCHAINRESTORE = 'keychainbackup/restore/';
  static const String KEYCHAINBACKUP_TOGGLE = 'keychainbackup/toggle/';
  static const String KEYCHAINFULLBACKUP = 'keychainbackup/fullbackup/';
  static const String USERCIRCLE_SET_LAST_ACCESSED =
      'usercircle/setlastaccessed/';
  static const String USERCIRCLE_BY_USERID = 'usercircle/byuser/';
  static const String USERCIRCLE = 'usercircle/';
  static const String USERCIRCLEMUTED = 'usercircle/muted/';
  static const String USERCIRCLE_HISTORY = 'usercircle/history/';
  static const String USERCIRCLEBACKGROUNDCOLOR = 'usercircle/backgroundcolor/';
  static const String USERCIRCLECLOSED = 'usercircle/closed/';
  static const String USERCIRCLECLOSEOPENHIDDEN = 'usercircle/closeopenhidden/';
  static const String USERCIRCLE_SWIPE_ATTEMPT = 'usercircle/swipe-attempt/';
  static const String USERCIRCLE_SWIPE_ATTEMPTS = 'usercircle/swipe-attempts/';
  static const String USERCIRCLE_HIDDENCIRCLE = 'usercircle/hiddencircle/';
  static const String USERCIRCLE_TEMPOPEN = 'usercircle/tempopen/';
  static const String CIRCLEVOTE = 'circlevote/';
  static const String CIRCLEVOTE_SUBMIT = 'circlevote/uservoted/';
  static const String LOGIN = 'user/signin/';
  static const String REGISTER = 'user/register/';
  static const String REGISTERLINKEDACCOUNT = 'user/registerlinkedaccount/';
  static const String PASSWORD_NONCE = 'user/nonce/';
  static const String REGISTER_STANDALONE = 'user/registerstandalone/';
  //static const String BACKUPUSERKEY = 'user/backupuserkey/';
  static const String PASSWORDHELPERS_GET= 'user/getpasswordhelpers/';
  static const String PASSWORDHELPERS_POST = 'user/setpasswordhelpers/';
  static const String USER_RECOVERYINDEX = 'user/recoveryindex/';
  static const String GETREMOTEWIPEHELPERS = 'user/getremotewipehelpers/';
  static const String UPDATEREMOTEWIPEHELPERS = 'user/updateremotewipehelpers/';
  static const String USER_KEYS_EXPORTED = 'user/keysexported/';
  static const String CHANGEPASSWORD = 'user/changepassword/';
  static const String CHANGEPASSWORDFROMTOKEN = 'user/changepasswordfromtoken/';
  static const String USER_GENERATE_RESET_CODE = 'user/generateresetcode/';
  static const String RATCHET_FOR_PASSCODE_RESET =
      'user/passcodeforpasscodereset/';
  static const String ENCRYPTED_FRAG_FOR_PASSCODE_RESET =
      'user/encryptedfragforpasscodereset/';
  static const String USER_CONNECTED = 'user/connected/';
  static const String USER_RESET_CODE = 'user/resetcode/';
  static const String USER_DELETE_ACCOUNT = 'user/deleteaccount/';
  static const String USER_DELETE_PREP = 'user/deleteprep/';
  static const String USER_IDENTITY = 'user/identity/';
  // static const String USER_CLEAR_PATTERN_FLAG = 'user/clearpatternflag/';
  static const String USER_RESET_CODE_RATCHETINDEXES =
      'user/resetcoderatchetindexes/';
  static const String USER_DISMISS_NOTIFICATION = 'user/dismissnotification/';
  static const String USER_UPDATE_BLOCK_STATUS = 'user/updateblockstatus/';
  static const String USER_RESET_CODE_AVAILABLE = 'user/resetcodeavailable/';
  static const String AUTHTOKEN = 'user/';
  static const String VALIDATE_LINKED_ACCOUNT = 'user/validatelinkedaccount/';
  //static const String LINK_ACCOUNT = 'user/linkaccount/';
  static const String SET_REMOTE_PUBLIC = 'user/setremotepublic/';
  static const String LOGOUT = 'user/logout/';
  static const String UPDATEUSER = 'user/profile/';
  static const String USER_RESERVE_USERNAME = 'user/reserveusername/';
  static const String ACCEPT_TOS = 'user/tos/';
  static const String REPORT_VIOLATION = 'circleobject/violation/';
  static const String CIRCLEOBJECTS = 'circleobject/';
  static const String CIRCLEOBJECTS_FILE = 'circleobject/file/';
  static const String CIRCLEOBJECT_HIDE = 'circleobject/hide/';
  static const String CIRCLEOBJECTSBYCIRCLE = 'circleobject/bycircle/';
  static const String CIRCLEOBJECTS_GET_SINGLE = 'circleobject/getsingle/';
  static const String CIRCLEOBJECTSALLUSERCIRCLES = 'circleobject/usercircles/';
  static const String CIRCLEOBJECTSMARKDELIVERED =
      'circleobject/markdelivered/';
  static const String CIRCLEOBJECT_REACTION = 'circleobject/reaction/';
  static const String CIRCLEOBJECT_UNPINOBJECT = 'circleobject/unpinobject/';
  static const String CIRCLEOBJECT_PINOBJECT = 'circleobject/pinobject/';
  static const String CIRCLEOBJECTSBYCIRCLENEW = 'circleobject/circlenew/';
  static const String CIRCLEOBJECTSBYCIRCLEOLDER = 'circleobject/circleolder/';
  static const String CIRCLEOBJECTSBYCIRCLEJUMPTDATE =
      'circleobject/circlejumpdate/';
  static const String CIRCLEOBJECTSONETIMEVIEW = 'circleobject/onetimeview/';
  static const String GET_CURRENCY = 'ironcoin/getcurrencyp/';
  static const String COIN_PAYMENT = 'ironcoin/coinpayment/';
  static const String COIN_PAYMENT_REFUND = 'ironcoin/refundcoinpayment/';
  static const String FETCH_COIN_LEDGER = 'ironcoin/fetchledgerp/';
  static const String GIVE_COINS = 'ironcoin/givecoins/';
  static const String GET_COINS = 'ironcoin/getcoinsp/';
  static const String PURCHASE_COINS = 'ironcoin/purchasecoins/';
  static const String DELETE_PROMPT = 'ironcoin/prompt/';
  static const String UPDATE_PROMPT = 'ironcoin/prompt/';
  static const String DEVICE_GET = 'device/fetch/';
  static const String DEVICE_REMOTEWIPE = 'device/remotewipe/';
  static const String DEVICE_DEACTIVATE = 'device/deactivate/';
  static const String CIRCLE_GET = 'circle/getcircle/';
  static const String CIRCLE = 'circle/';
  static const String CIRCLESETTING = 'circle/setting/';
    static const String CIRCLESETTING_VOTING_MODEL = 'circle/settingvotingmodel/';
  static const String CIRCLESETTING_EXPIRATION = 'circle/settingexpiration/';
  static const String CIRCLEMEMBERS_GET = 'circle/getmembers/';
  //static const String CIRCLEMEMBERS2 = 'circle/members/';
  static const String CIRCLEREMOVEMEMBER = 'circle/removemember/';
  static const String INVITATIONS_ALL_FOR_CIRCLE = "invitation/bycircle/";
  static const String INVITATIONS = "invitation/";
  static const String INVITATIONS_CANCEL_DM = "invitation/canceldm/";
  static const String INVITATIONS_FINDUSER = "invitation/finduser/";
  static const String INVITATIONS_DECLINE = "invitation/decline/";
  static const String INVITATIONS_ALL_FOR_USER = "invitation/foruser/";
  static const String INVITATIONS_ACCEPT = "invitation/accept/";
  static const String INVITATIONS_GETCOUNT = "invitation/getcount/";
  static const String RATCHETPUBLICKEY_GETPUBLIC = 'ratchetpublickey/getpublic/';
  static const String RATCHETPUBLICKEY = 'ratchetpublickey/';
  static const String PUBLICMEMBERKEY = 'ratchetpublickey/getpublicmemberkey/';
  static const String PUBLICMEMBERKEYS = 'ratchetpublickey/getpublicmemberkeys/';
  static const String BLOB_UPLOAD_DUAL_LINKS = 'blob/getuploadlinks/';
  static const String BLOB_DOWNLOAD_DUAL_LINKS = 'blob/getdownloadlinks/';
  static const String BLOB_UPLOAD_LINK = 'blob/getcircleobjectuploadlink/';
  static const String BLOB_DOWNLOAD_LINK = 'blob/getcircleobjectdownloadlink/';
  static const String BLOB_UPLOAD_USER_LINK = 'blob/getuseruploadlink/';
  static const String BLOB_DOWNLOAD_USER_LINK = 'blob/getuserdownloadlink/';
  static const String BLOB_DOWNLOAD_UNAUTHORIZED_LINK =
      'blob/getnetworkavatardownloadlink/';
  static const String ACTIONREQUIRED_DISMISS = 'actionrequired/dismiss/';
  static const String CIRCLEEVENT = 'circleevent/';
  static const String CIRCLERECIPE = 'circlerecipe/';
  static const String CIRCLELIST = 'circlelist/';
  static const String REGISTER_DEVICE = "gcmcontroller/registerdevice/";
  static const String CIRCLEBACKGROUND = "circlebackground/";
  static const String USERCIRCLEBACKGROUND = "usercirclebackground/";
  static const String CIRCLEFILE_OBJECT_ONLY = 'circlefile/objectonly/';
  static const String CIRCLEIMAGE_OBJECT_ONLY = 'circleimage/objectonly/';
  static const String BLOCKEDLIST_GET = "blockedlist/get/";
  static const String BLOCKEDLIST = "blockedlist/";
  static const String AVATAR = "avatar/";
  static const String CIRCLEVIDEO_S3 = 'circlevideos3/';
  static const String CIRCLEALBUM_OBJECT_ONLY = 'circlealbum/objectonly/';
  static const String CIRCLEALBUM_SORT = 'circlealbum/sort/';
  static const String LOGS = 'log/iclog/';
  static const String LOGS_TOGGLE = 'log/toggle/';
  static const String LOGS_DETAIL = 'log/detail/';
  static const String SUBSCRIPTIONS_SUBSCRIBE = 'subscriptions/subscribe/';
  static const String SUBSCRIPTIONS_CANCEL = 'subscriptions/cancel/';
  static const String NETWORKREQUEST = 'networkrequest/';
  static const String NETWORKREQUEST_USERREQUESTS =
      'networkrequest/getmyrequests/';
  static const String NETWORKREQUEST_FORNETWORK = 'networkrequest/getforowner/';
  static const String HOSTEDFURNACE_VALID = 'hostedfurnace/valid/';
  static const String HOSTEDFURNACE_REQUEST_APPROVED =
      'hostedfurnace/requestapproved/';
  static const String HOSTEDFURNACE_GETSTORAGE = 'hostedfurnace/getstorage/';
  static const String HOSTEDFURNACE_SETSTORAGE = 'hostedfurnace/setstorage/';
  static const String HOSTEDFURNACE_SETROLE = 'hostedfurnace/setrole/';
  static const String HOSTEDFURNACE_LOCKOUT = 'hostedfurnace/lockout/';
  static const String HOSTEDFURNACE_ALLDISCOVERABLE =
      'hostedfurnace/getalldiscoverable/';
  static const String HOSTEDFURNACE_DISCOVERABLE =
      'hostedfurnace/getdiscoverable/';
  static const String HOSTEDFURNACE_PENDINGDISCOVERABLE =
      'hostedfurnace/getpendingdiscoverable/';
  static const String HOSTEDFURNACE_APPROVED = 'hostedfurnace/setapproved/';
  static const String HOSTEDFURNACE_OVERRIDE = 'hostedfurnace/setoverride/';
  static const String HOSTEDFURNACE_IMAGE = 'hostedfurnace/networkimage/';
  static const String HOSTEDFURNACE = 'hostedfurnace/';
  static const String HOSTEDFURNACE_CONFIG = 'hostedfurnace/config/';
  // static const String HOSTEDFURNACE_NAMEANDACCESSCODE2 =
  //     'hostedfurnace/nameandaccesscode/';
  static const String HOSTEDFURNACE_MAGICLINKTOCIRCLE =
      'hostedfurnace/magiclinktocircle/';
  static const String HOSTEDFURNACE_MAGICLINKTONETWORK =
      'hostedfurnace/magiclinktonetwork/';
  static const String HOSTEDFURNACE_REPORTPROFILE =
      'hostedfurnace/reportprofile/';
  static const String HOSTEDFURNACE_REPORTNETWORK =
      'hostedfurnace/reportnetwork/';
  static const String HOSTEDFURNACE_INVITATION = 'hostedfurnace/invitation/';
  static const String HOSTEDFURNACE_MEMBERS = 'hostedfurnace/members/';
  static const String MAGICLINK_NETWORK = 'magiclink/magiclinktonetwork/';
  static const String MAGICLINK_NETWORK_VALIDATE =
      'magiclink/magiclinktonetworkvalidate/';
  static const String WALLREPLY = 'replyobject/';
  static const String WALLREPLY_DELETE = 'replyobject/delete/';
  static const String WALLREPLY_BYOLDER = 'replyobject/getbyolder/';
  static const String WALLREPLY_BYNEWER = 'replyobject/getbynewer/';
  static const String WALLREPLY_HIDE = 'replyobject/hide/';
  static const String WALLREPLY_GETSINGLE = 'replyobject/getsingle/';
  static const String WALLREPLY_REPORT= 'replyobject/violation/';
  static const String WALLREPLY_REACTION = 'replyobject/reaction/';
  static const String WALLREPLY_BYOBJECT = 'replyobject/getbyobject/';
    static const String START_AGORA_CALL = 'agora/startcall/';
  // static const String MAGICLINK_FROM_FIREBASELINK =
  //     'magiclink/magiclinkfromfirebaselink/';
  //static const String WALLREPLY_GETREPLIES = 'replyobject/getreplies/';


  /// not kyber on purpose
    static const String CIRCLERECIPETEMPLATE = 'circlerecipe/template/';
    static const String CIRCLELISTTEMPLATE = 'circlelist/template/';
  static const String GRIDFS_UPLOAD_DUAL = "gridfs/dual/";
  static const String GRIDFS_POST = "gridfs/";
  static const String GRIDFS_DOWNLOAD_CIRCLEOBJECT_THUMBNAIL =
      "gridfs/circleobjectthumbnail/";
  static const String GRIDFS_DOWNLOAD_CIRCLEOBJECT_FULL =
      "gridfs/circleobjectfull/";
  static const String METRICS = 'metrics/';
  static const String BACKLOG = 'backlog/';
  static const String BACKLOG_REPLY = 'backlog/reply/';
  static const String TUTORIALS = 'tutorial/topics/';
  static const String TUTORIALS_GENERATE = 'tutorial/generate/';
  static const String RELEASES = 'release/';
  static const String DEVICE_KYBERPUBLICKEY_POST = 'device/kyberpublickey/';
  static const String DEVICE_KYBERPUBLICKEY_PUT = 'device/putkyberpublickey/';
  static const String DEVICE_KYBERCIPHER_POST = 'device/kybercipher/';
  static const String DEVICE_KYBERCIPHER_PUT = 'device/putkybercipher/';

  //static const String CIRCLEVIDEO = 'circlevideo/';
  //static const String PUBLIC_KEYS = 'publickeys/';
  //static const String CIRCLEGIPHY = 'circlegif/giphy/';
  //static const String CIRCLELINK = 'circlelink/';
  //static const String CIRCLEIMAGETHUMBNAIL = "circleimage/thumbnail/";
  //static const String CIRCLEIMAGEFULL = "circleimage/fullimage/";










  ///outside calls, kyber can't be used
  static const String WEB_ICON =
      'https://img1.wsimg.com/isteam/ip/bc5c5a43-2799-4135-8867-fd0235259013/appstore-a4835b3.png/:/cr=t:0%25,l:0%25,w:100%25,h:100%25/rs=w:1240,h:1240,cg:true';
  static const String GIPHYKEY = "kj7GDyvlc0AN1FSUG8HAKV9EekayUlJQ";
  static const String GIPHY_URL = "https://api.giphy.com/";
  static const String GIPHY_TRANSLATE = GIPHY_URL + "v1/gifs/search";

  static const String TENORKEY = "TETS1EDCVHL4";
  static const String TENOR_URL = "https://g.tenor.com/v1/search";
  static const String TENOR_AUTOCOMPLETE =
      "https://g.tenor.com/v1/autocomplete";
  //static const String GIPHY_TRANSLATE = GIPHY_URL + "v1/gifs/search";

  static const String LINKPREVIEWKEY =
      "5ddec11d71826aa9b367b1bad2cef8573a5d92bc2fd3f";
  static const String LINKPREVIEWURL =
      "http://api.linkpreview.net/?key=" + LINKPREVIEWKEY + "&q=";
}

final urls = Urls();
