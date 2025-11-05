import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/encryption/encryptblob.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/dialognotice.dart';
import 'package:ironcirclesapp/screens/widgets/dialogpremiumfeature.dart';
import 'package:ironcirclesapp/services/cache/imagecache_service.dart';
import 'package:ironcirclesapp/services/cache/table_usercirclecache.dart';

class PremiumFeatureCheck {
  static Future<bool> canChangeStorage(
      BuildContext context, UserFurnace userFurnace) async {
    bool retValue = false;

    if (globalState.user.accountType == AccountType.PREMIUM) {
      retValue = true;
    } else {
      DialogPremiumFeature.premiumFeature(
          context,
          AppLocalizations.of(context)!.premiumFeatureTitle,
          AppLocalizations.of(context)!.premiumFeatureStorage);
    }

    return retValue;
  }

  static bool canStreamVideo(BuildContext context) {
    return true;

    bool retValue = false;

    if (globalState.user.accountType != AccountType.FREE) {
      retValue = true;
    } else {
      DialogPremiumFeature.premiumFeature(
          context,
          AppLocalizations.of(context)!.premiumFeatureTitle,
          AppLocalizations.of(context)!.premiumFeatureStreaming);
    }

    return retValue;
  }

  static Future<bool> canHideCircle(
      BuildContext context, List<UserFurnace> userFurnaces) async {
    bool retValue = false;

    if (globalState.user.accountType != AccountType.FREE) {
      retValue = true;
    } else {
      int count =
          await TableUserCircleCache.countConnectedHiddenCircles(userFurnaces);

      if (count >= 1) {
        DialogPremiumFeature.premiumFeature(
            context,
            AppLocalizations.of(context)!.premiumFeatureTitle,
            AppLocalizations.of(context)!.premiumFeatureHideLimit);
      } else
        retValue = true;
    }

    return retValue;
  }

  static const int imageSize = 12582912; //12MB
  //static final int imageSize = 104857600; //12MB
  static const int videoSize = 104857600; //100MB
  static const int fileSize = 104857600; //100MB

  static double calcCompressedByteSize(bool hiRes, File file) {
    int uncompressedSize = file.lengthSync();
    int quality =
        ImageCacheService.getFullImageQuality(hiRes, uncompressedSize);

    debugPrint('uncompressedSize: $uncompressedSize');
    debugPrint('quality: $quality');
    debugPrint('compressedSize: ${uncompressedSize * (quality / 100)}');
    debugPrint('maxSize: $imageSize');
    return uncompressedSize * (quality / 100);
  }

  static bool checkFileSizeRestriction(
      BuildContext context, bool hiRes, MediaCollection mediaCollection) {
    bool failed = false;
    int count = 0;

    if (globalState.user.accountType != AccountType.FREE) {
      failed = false;

      for (var media in mediaCollection.media) {
        if ((media.mediaType == MediaType.file ||
                media.mediaType == MediaType.image ||
                media.mediaType == MediaType.gif) &&
            media.file.existsSync() &&
            media.file.lengthSync() >= EncryptBlob.maxForEncrypted) {
          media.tooLarge = true;
          failed = true;
          count++;
        }
      }

      if (failed) {
        DialogNotice.showNoticeOptionalLines(
            context,
            AppLocalizations.of(context)!.fileTooLargeTitle,
            AppLocalizations.of(context)!.fileTooLargeTitle,
            false);
      }

      return !failed;
    } else {
      for (var media in mediaCollection.media) {
        ///don't bother checking images from the interal camera
        if ((media.mediaType == MediaType.image) && media.fromCamera == false) {
          //double compressedSize = calcCompressedByteSize(hiRes, media.file);
          debugPrint('uncompressedSize: ${media.file.lengthSync()}');

          ///images get compressed so double the size
          if (media.file.lengthSync() >= (imageSize * 2)) {
            media.tooLarge = true;
            failed = true;
            count++;
          }
        } else if (media.mediaType == MediaType.video &&
            media.file.lengthSync() >= videoSize) {
          media.tooLarge = true;
          failed = true;
          count++;
        } else if (media.mediaType == MediaType.file &&
            media.file.lengthSync() >= fileSize) {
          media.tooLarge = true;
          failed = true;
          count++;
        }
      }
    }

    if (failed) {
      if (count == 1) {
        DialogPremiumFeature.premiumFeature(
            context,
            AppLocalizations.of(context)!.premiumFeatureMediaTooLargeTitle,
            AppLocalizations.of(context)!.premiumFeatureMediaTooLargeMessage);
      } else {
        DialogPremiumFeature.premiumFeature(
            context,
            AppLocalizations.of(context)!.premiumFeatureMediasTooLargeTitle,
            AppLocalizations.of(context)!.premiumFeatureMediasTooLargeMessage);
      }
    }

    return !failed;
  }

  static bool remoteWipeOn(BuildContext context) {
    bool retValue = false;

    if (globalState.user.accountType != AccountType.FREE) {
      retValue = true;
    } else {
      DialogPremiumFeature.premiumFeature(
          context,
          AppLocalizations.of(context)!.premiumFeatureTitle,
          AppLocalizations.of(context)!.premiumFeatureRemoteWipe);
    }
    return retValue;
  }

  static bool canCreateOwnerCircle(BuildContext context) {
    bool retValue = false;

    if (globalState.user.accountType != AccountType.FREE) {
      retValue = true;
    } else {
      DialogPremiumFeature.premiumFeature(
          context,
          AppLocalizations.of(context)!.premiumFeatureTitle,
          AppLocalizations.of(context)!.premiumFeatureOwnerCircle);
    }
    return retValue;
  }

  static bool canCreateTemporaryCircle(BuildContext context) {
    bool retValue = false;

    if (globalState.user.accountType != AccountType.FREE) {
      retValue = true;
    } else {
      DialogPremiumFeature.premiumFeature(
        context,
        AppLocalizations.of(context)!.premiumFeatureTitle,
        AppLocalizations.of(context)!.premiumFeatureTemporaryCircle);
    }
    return retValue;
  }

  static bool wipeFileOn() {
    bool retValue = false;

    if (globalState.user.accountType != AccountType.FREE) {
      retValue = true;
    }
    return retValue;
  }

  static Future<bool> canAddNetwork(
      BuildContext context, List<UserFurnace> userFurnaces) async {
    bool retValue = false;

    if (globalState.user.accountType != AccountType.FREE) {
      retValue = true;
    } else {
      int count = 0;

      for (UserFurnace userFurnace in userFurnaces) {
        if (!userFurnace.connected!) continue; //don't count
        if (userFurnace.alias!.toLowerCase() == 'ironforge')
          continue; //don't count the IronForge
        if (userFurnace.id != null &&
            userFurnace.id == '648b352b78954857ec1b2da6')
          continue; //don't count IronCircles

        count = count + 1;
      }

      if (count >= 5) {
        DialogPremiumFeature.premiumFeature(
            context,
            AppLocalizations.of(context)!.premiumFeatureTitle,
            AppLocalizations.of(context)!.premiumFeatureNetworkLimit);
      } else
        retValue = true;
    }
    return retValue;
  }
}
