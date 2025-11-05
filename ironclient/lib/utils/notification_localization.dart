import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';

class NotificationLocalization {
  ///This function should only be used for API calls
  static getLocalizedString(String key, BuildContext context) {
    if (key.toLowerCase() == "access denied")
      return AppLocalizations.of(context)!.errorAccessDenied;
    else if (key.toLowerCase() == "invalid credentials for this network")
      return AppLocalizations.of(context)!
          .errorInvalidCredentialsForThisNetwork;
    else if (key.toLowerCase() == "invalid username or password")
      return AppLocalizations.of(context)!.errorInvalidUsernameOrPassword;
    else if (key.toLowerCase() == "choose the leave option instead")
      return AppLocalizations.of(context)!.errorChooseLeaveOption;
    else if (key.toLowerCase() == "minors cannot be voted out")
      return AppLocalizations.of(context)!.errorMinorsCannotBeVotedOut;
    else if (key.toLowerCase() ==
        "only the owner of this circle can remove members")
      return AppLocalizations.of(context)!.errorOnlyOwnerCanRemoveMembers;
    else if (key.toLowerCase() == "you cannot remove yourself")
      return AppLocalizations.of(context)!.errorCannotRemoveYourself;
    else if (key.toLowerCase() ==
        "cannot remove 1 of 2 members. Consider leaving instead.")
      return AppLocalizations.of(context)!.errorCannotRemoveOneOfTwoMembers;
    else if (key.toLowerCase() == "could not find any members")
      return AppLocalizations.of(context)!.errorCouldNotFindAnyMembers;
    else if (key.toLowerCase() == "could not usercircle")
      return AppLocalizations.of(context)!.errorCouldNotFindAnyCircles;
    else if (key.toLowerCase() == "could not create vote")
      return AppLocalizations.of(context)!.errorCouldNotCreateVote;
    else if (key.toLowerCase() == "vote to remove user created")
      return AppLocalizations.of(context)!.noticeVoteToRemoveUserCreated;
    else if (key.toLowerCase() == "could not load circle")
      return AppLocalizations.of(context)!.errorCouldNotLoadCircle;
    else if (key.toLowerCase() == "could not find circle")
      return AppLocalizations.of(context)!.errorCouldNotFindCircle;
    else if (key.toLowerCase() == "only the owner can delete this circle")
      return AppLocalizations.of(context)!.errorOnlyOwnerCanDeleteCircle;
    else if (key.toLowerCase() == "failed to create vote")
      return AppLocalizations.of(context)!.errorFailedToCreateVote;
    else if (key.toLowerCase() == "could not find CircleObject by vote")
      return AppLocalizations.of(context)!.errorCouldNotFindCircleObjectByVote;
    else if (key.toLowerCase() == "could not find recipe")
      return AppLocalizations.of(context)!.errorCouldNotFindRecipe;
    else if (key.toLowerCase() == "invalid setting")
      return AppLocalizations.of(context)!.errorInvalidSetting;
    else if (key.toLowerCase() == "nothing changed")
      return AppLocalizations.of(context)!.errorNothingChanged;
    else if (key.toLowerCase() == "invalid parameter")
      return AppLocalizations.of(context)!.errorInvalidParameter;
    else if (key.toLowerCase() ==
        "change Circle security settings voting model?")
      return AppLocalizations.of(context)!
          .errorChangeCircleSecuritySettingsVotingModel;
    else if (key.toLowerCase() ==
        "change Circle privacy settings voting model?")
      return AppLocalizations.of(context)!
          .noticeChangeCirclePrivacySettingsVotingModel;
    else if (key.toLowerCase() ==
        "a vote to change settings already exists. that vote must be deleted or closed.")
      return AppLocalizations.of(context)!
          .errorVoteToChangeSettingsAlreadyExists;
    else if (key.toLowerCase() ==
        "a vote to change the voting model for these settings already exists.  that vote must be deleted or closed.")
      return AppLocalizations.of(context)!
          .errorVoteToChangeVotingModelForSettingsAlreadyExists;
    else if (key.toLowerCase() == "allow circle settings changes?")
      return AppLocalizations.of(context)!.noticeAllowCircleSettingsChanges;
    else if (key.toLowerCase() == "minimum password length is 4 characters")
      return AppLocalizations.of(context)!.errorMinimumPasswordLength;
    else if (key.toLowerCase() ==
        "Maximum password length is 30 characters".toLowerCase())
      return AppLocalizations.of(context)!.errorMaximumPasswordLength;
    else if (key.toLowerCase() ==
        "Minimum days for password change is 1".toLowerCase())
      return AppLocalizations.of(context)!.errorMinimumDaysForPasswordChange;
    else if (key.toLowerCase() ==
        "Minimum stay logged in days is 1".toLowerCase())
      return AppLocalizations.of(context)!.errorMinimumStayLoggedInDays;
    else if (key.toLowerCase() ==
        "Minimum login attempts before lock is 3".toLowerCase())
      return AppLocalizations.of(context)!.errorMinimumLoginAttemptsBeforeLock;
    else if (key.toLowerCase() == "Unauthorized".toLowerCase())
      return AppLocalizations.of(context)!.errorUnauthorized;
    else if (key.toLowerCase() == "Device not found".toLowerCase())
      return AppLocalizations.of(context)!.errorDeviceNotFound;
    else if (key.toLowerCase() == "Device deactivated".toLowerCase())
      return AppLocalizations.of(context)!.noticeDeviceDeactivated;
    else if (key.toLowerCase() == "User not found".toLowerCase())
      return AppLocalizations.of(context)!.errorUserNotFound;
    else if (key.toLowerCase() == "UserCircles not found".toLowerCase())
      return AppLocalizations.of(context)!.errorUserCirclesNotFound;
    else if (key.toLowerCase() == "Could not find image".toLowerCase())
      return AppLocalizations.of(context)!.errorCouldNotFindImage;
    else if (key.toLowerCase() == "Could not load invitation".toLowerCase())
      return AppLocalizations.of(context)!.errorCouldNotLoadInvitation;
    else if (key.toLowerCase() == "Invitation deleted".toLowerCase())
      return AppLocalizations.of(context)!.errorInvitationDeleted;
    else if (key.toLowerCase() == "Failed to save vote".toLowerCase())
      return AppLocalizations.of(context)!.errorFailedToSaveVote;
    else if (key.toLowerCase() == "Access denied".toLowerCase())
      return AppLocalizations.of(context)!.errorAccessDenied;
    else if (key.toLowerCase() == "Creator cannot modify vote".toLowerCase())
      return AppLocalizations.of(context)!.errorCreatorCannotModifyVote;
    else if (key.toLowerCase() == "Could not find album".toLowerCase())
      return AppLocalizations.of(context)!.errorCouldNotFindAlbum;
    else if (key.toLowerCase() == "Could not create DM".toLowerCase())
      return AppLocalizations.of(context)!.errorCouldNotCreateDM;
    else if (key.toLowerCase() == "DM already exists".toLowerCase())
      return AppLocalizations.of(context)!.errorDMAlreadyExists;
    else if (key.toLowerCase() ==
        "You are already invited to this DM".toLowerCase())
      return AppLocalizations.of(context)!.errorYouAreAlreadyInvitedToThisDM;
    else if (key.toLowerCase() ==
        "No need to change voting model for owners".toLowerCase())
      return AppLocalizations.of(context)!
          .errorNoNeedToChangeVotingModelForOwners;
    else if (key.toLowerCase() ==
        "Only owners can change settings for owned circles".toLowerCase())
      return AppLocalizations.of(context)!
          .errorOnlyOwnersCanChangeSettingsForOwnedCircles;
    else if (key.toLowerCase() == "Settings changed".toLowerCase())
      return AppLocalizations.of(context)!.noticeSettingsChanged;
    else if (key.toLowerCase() == "Object not found".toLowerCase())
      return AppLocalizations.of(context)!.errorObjectNotFound;
    else if (key.toLowerCase() == "CircleObject already exists".toLowerCase())
      return AppLocalizations.of(context)!.errorCircleObjectAlreadyExists;
    else if (key.toLowerCase() ==
        "Only the owner of a network can transfer ownership".toLowerCase())
      return AppLocalizations.of(context)!
          .errorOnlyOwnerOfNetworkCanTransferOwnership;
    else if (key.toLowerCase() ==
        "Network name is already in use".toLowerCase())
      return AppLocalizations.of(context)!.errorNetworkNameIsAlreadyInUse;
    else if (key.toLowerCase() ==
        "The owner of a network cannot be locked out".toLowerCase())
      return AppLocalizations.of(context)!.errorOwnerOfNetworkCannotBeLockedOut;
    else if (key.toLowerCase() == "Could not connect".toLowerCase())
      return AppLocalizations.of(context)!.errorCouldNotConnect;
    else if (key.toLowerCase() == "Could not connect to storage".toLowerCase())
      return AppLocalizations.of(context)!.errorCouldNotConnectToStorage;
    else if (key.toLowerCase() == "User not found".toLowerCase())
      return AppLocalizations.of(context)!.errorUserNotFound;
    else if (key.toLowerCase() == "User was already invited".toLowerCase())
      return AppLocalizations.of(context)!.errorUserWasAlreadyInvited;
    else if (key.toLowerCase() == "Failed to send invitation".toLowerCase())
      return AppLocalizations.of(context)!.errorFailedToSendInvitation;
    else if (key.toLowerCase() ==
        "Successfully created vote for invite".toLowerCase())
      return AppLocalizations.of(context)!
          .noticeSuccessfullyCreatedVoteForInvite;
    else if (key.toLowerCase() ==
        "Successfully created invitation".toLowerCase())
      return AppLocalizations.of(context)!.errorSuccessfullyCreatedInvitation;
    else if (key.toLowerCase() ==
        "There was a problem finding the invitation".toLowerCase())
      return AppLocalizations.of(context)!
          .errorThereWasAProblemFindingTheInvitation;
    else if (key.toLowerCase() ==
        "Terms of Service not agreed to".toLowerCase())
      return AppLocalizations.of(context)!.errorTermsOfServiceNotAgreedTo;
    else if (key.toLowerCase() ==
        "Could not find a name for network".toLowerCase())
      return AppLocalizations.of(context)!.errorCouldNotFindANameForNetwork;
    else if (key.toLowerCase() == "reset: could not find user".toLowerCase())
      return AppLocalizations.of(context)!.errorResetCouldNotFindUser;
    else if (key.toLowerCase() == "Reset code expired".toLowerCase())
      return AppLocalizations.of(context)!.errorResetCodeExpired;
    else if (key.toLowerCase() == "Invalid username or password".toLowerCase())
      return AppLocalizations.of(context)!.errorInvalidUsernameOrPassword;
    else if (key.toLowerCase() ==
        "Upgrade required before proceeding".toLowerCase())
      return AppLocalizations.of(context)!.errorUpgradeRequiredBeforeProceeding;
    else if (key.toLowerCase() ==
        "Username cannot be longer than 25 chars".toLowerCase())
      return AppLocalizations.of(context)!
          .errorUsernameCannotBeLongerThan25Chars;
    else if (key.toLowerCase() == "Profile updates complete".toLowerCase())
      return AppLocalizations.of(context)!.noticeProfileUpdatesComplete;
    else if (key.toLowerCase() ==
        "Network must be transferred before deletion".toLowerCase())
      return AppLocalizations.of(context)!
          .errorNetworkMustBeTransferedBeforeDeletion;
    else if (key.toLowerCase() ==
        "Transferee is not on the network".toLowerCase())
      return AppLocalizations.of(context)!.errorTransfereeIsNotOnTheNetwork;
    else if (key.toLowerCase() == "Changes saved".toLowerCase())
      return AppLocalizations.of(context)!.changesSaved;
    else if (key.toLowerCase() == "Username updated".toLowerCase())
      return AppLocalizations.of(context)!.usernameUpdated;
    else if (key.toLowerCase() == "Username is already taken".toLowerCase())
      return AppLocalizations.of(context)!.usernameAlreadyTaken;
    else if (key.toLowerCase() == "Username did not change".toLowerCase())
      return AppLocalizations.of(context)!.usernameNotChanged;
    else if (key.toLowerCase() ==
        "username reservation preference set".toLowerCase())
      return AppLocalizations.of(context)!.usernameReserved;
    else if (key.toLowerCase() == "invalid login attempt # 1".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidLoginAttempt} 1";
    else if (key.toLowerCase() == "invalid login attempt # 2".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidLoginAttempt} 2";
    else if (key.toLowerCase() == "invalid login attempt # 3".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidLoginAttempt} 3";
    else if (key.toLowerCase() == "invalid login attempt # 4".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidLoginAttempt} 4";
    else if (key.toLowerCase() == "invalid login attempt # 5".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidLoginAttempt} 5";
    else if (key.toLowerCase() == "invalid login attempt # 6".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidLoginAttempt} 6";
    else if (key.toLowerCase() == "invalid login attempt # 7".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidLoginAttempt} 7";
    else if (key.toLowerCase() == "invalid login attempt # 8".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidLoginAttempt} 8";
    else if (key.toLowerCase() == "invalid login attempt # 9".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidLoginAttempt} 9";
    else if (key.toLowerCase() == "invalid login attempt # 10".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidLoginAttempt} 10";
    else if (key.toLowerCase().contains("invalid login attempt"))
      return AppLocalizations.of(context)!.invalidLoginAttempt;
    else if (key.toLowerCase() ==
        "invalid reset code attempt # 1".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidResetCodeAttempt} 1";
    else if (key.toLowerCase() ==
        "invalid reset code attempt # 2".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidResetCodeAttempt} 2";
    else if (key.toLowerCase() ==
        "invalid reset code attempt # 3".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidResetCodeAttempt} 3";
    else if (key.toLowerCase() ==
        "invalid reset code attempt # 4".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidResetCodeAttempt} 4";
    else if (key.toLowerCase() ==
        "invalid reset code attempt # 5".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidResetCodeAttempt} 5";
    else if (key.toLowerCase() ==
        "invalid reset code attempt # 6".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidResetCodeAttempt} 6";
    else if (key.toLowerCase() ==
        "invalid reset code attempt # 7".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidResetCodeAttempt} 7";
    else if (key.toLowerCase() ==
        "invalid reset code attempt # 8".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidResetCodeAttempt} 8";
    else if (key.toLowerCase() ==
        "invalid reset code attempt # 9".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidResetCodeAttempt} 9";
    else if (key.toLowerCase() ==
        "invalid reset code attempt # 10".toLowerCase())
      return "${AppLocalizations.of(context)!.invalidResetCodeAttempt} 10";
    else if (key
        .toLowerCase()
        .contains('seconds before trying again'.toLowerCase())) {
      String removeText = key
          .toLowerCase()
          .replaceAll(' seconds before trying again'.toLowerCase(), '');
      removeText =
          removeText.toLowerCase().replaceAll('need to wait'.toLowerCase(), '');
      int seconds = int.parse(removeText);
      return '${AppLocalizations.of(context)!.needToWaitSeconds1} $seconds ${AppLocalizations.of(context)!.needToWaitSeconds2}';
    } else if (key.toLowerCase().contains(
        'Cannot set to discoverable. Network name or image contains inappropriate content.'
            .toLowerCase()))
      return AppLocalizations.of(context)!.overrideDiscoverable;
    else if (key.toLowerCase().contains(
        'This is a linked account, please login with your primary account'
            .toLowerCase()))
      return AppLocalizations.of(context)!.canNotLoginWithLinkedAccount;
    else if (key
        .toLowerCase()
        .contains('invalid network name or credentials'.toLowerCase()))
      return AppLocalizations.of(context)!.invalidNetworkNameOrCredentials;
    else if (key.toLowerCase().contains('no match'.toLowerCase()))
      return AppLocalizations.of(context)!.noMatch;
    else if (key.toLowerCase().contains('Vote already exists'.toLowerCase()))
      return AppLocalizations.of(context)!.voteAlreadyExists;
    else if (key
        .toLowerCase()
        .contains('your account on this network has been locked'.toLowerCase()))
      return AppLocalizations.of(context)!.accountLocked;
    else if (key
        .toLowerCase()
        .contains('user is already a member'.toLowerCase()))
      return AppLocalizations.of(context)!.userIsAlreadyAMember;
    else if (key.toLowerCase().contains('connection timed out'.toLowerCase()))
      return AppLocalizations.of(context)!.connectionTimedOut;
    else if (key.toLowerCase().contains('circle deleted'.toLowerCase()))
      return AppLocalizations.of(context)!.circleDeleted;
    else if (key.toLowerCase().contains('invitation not found'.toLowerCase()))
      return AppLocalizations.of(context)!.invitationNotFound;
    else if (key.toLowerCase().contains('dm deleted'.toLowerCase()))
      return AppLocalizations.of(context)!.dmDeleted;
    else if (key
        .toLowerCase()
        .contains('your account has been locked'.toLowerCase()))
      return AppLocalizations.of(context)!.accountLocked;
    else if (key.toLowerCase().contains('Not enough IronCoin'.toLowerCase()))
      return AppLocalizations.of(context)!.notEnoughIronCoin;
    else if (key
        .toLowerCase()
        .contains('prompt contains inappropriate language'.toLowerCase()))
      return AppLocalizations.of(context)!.promptContainsInappropriateLanguage;
    else if (key
        .toLowerCase()
        .contains('transfer must be 1 coin or more'.toLowerCase()))
      return AppLocalizations.of(context)!.positiveTransferAmount;
    else if (key
        .toLowerCase()
        .contains('cote to delete circle created'.toLowerCase()))
      return AppLocalizations.of(context)!.voteToDeleteCreated;
    else if (key.toLowerCase().contains('pin required'.toLowerCase()))
      return AppLocalizations.of(context)!.pinRequired;
    else if (key
        .toLowerCase()
        .contains('votes cannot have duplicate values'.toLowerCase()))
      return AppLocalizations.of(context)!.votesCannotHaveDuplicates;
    else if (key.toLowerCase().contains(
        'Could not connect to network. Please check settings'.toLowerCase()))
      return AppLocalizations.of(context)!.cannotConnectToNetwork;
    else if (key.toLowerCase().contains(
        'Could not find an account matching network and username'
            .toLowerCase()))
      return AppLocalizations.of(context)!.couldNotFindAccount;

    LogBloc.postLog("Could not find localized error message for key: $key",
        'getLocalizedString');

    return AppLocalizations.of(context)!.errorGenericTitle;
  }

  static getLocalizedTitle(String key, BuildContext context) {
    if (key.toLowerCase() == "Code Fragments Sent".toLowerCase())
      return AppLocalizations.of(context)!.codeFragmentsSentTitle;
    else if (key.toLowerCase() == "Could not reset".toLowerCase())
      return AppLocalizations.of(context)!.couldNotResetTitle;
    else if (key.toLowerCase() == "Notice".toLowerCase())
      return AppLocalizations.of(context)!.noticeTitle;

    LogBloc.postLog("Could not find localized error message for key: $key",
        'getLocalizedString');
    return AppLocalizations.of(context)!.errorGenericTitle;
  }
}
