/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates logic to deal with Circle models.  
 *  
 * TODO: update logic to use promises instead of callbacks.
 * 
 *  
 ***************************************************************************/
const constants = require('../util/constants');
const Circle = require('../models/circle');
const UserCircle = require('../models/usercircle');
const CircleSettingsObject = require('../models/circlesettingsobject');
const CircleObject = require('../models/circleobject');
var CircleVote = require('../models/circlevote');
var CircleVoteOption = require('../models/circlevoteoption');
var voteLogic = require('./votelogicasync');
const user = require('../models/user');
const logUtil = require('../util/logutil');
var randomstring = require("randomstring");


module.exports.votedNeeded = async function (circle) {

    var voteNeeded = true;

    if (circle.ownershipModel == constants.CIRCLE_OWNERSHIP.OWNER)
        voteNeeded = false;
    else {
        var count = await UserCircle.countDocuments({ "circle": circle._id });

        if (circle.privacyVotingModel == constants.VOTE_MODEL.MAJORITY) {
            ///if it is a simple majority vote, the user's vote would default to yes and the vote would close automatically anyway
            if (count < 3) {
                voteNeeded = false;
            }
        }
        else if (count == 1) {
            voteNeeded = false;
        }
    }

    return voteNeeded;
}

module.exports.setSettings = async function (circle, proposedCircle) {

    try {

        if (proposedCircle.privacyShareImage != undefined) circle.privacyShareImage = proposedCircle.privacyShareImage;
        if (proposedCircle.privacyShareURL != undefined) circle.privacyShareURL = proposedCircle.privacyShareURL;
        if (proposedCircle.privacyShareGif != undefined) circle.privacyShareGif = proposedCircle.privacyShareGif;
        if (proposedCircle.privacyCopyText != undefined) circle.privacyCopyText = proposedCircle.privacyCopyText;
        if (proposedCircle.privacyDisappearingTimer != undefined) {
            circle.privacyDisappearingTimer = proposedCircle.privacyDisappearingTimer;
            circle.privacyDisappearingTimerSeconds = proposedCircle.privacyDisappearingTimer * 60 * 60;
        }

        if (proposedCircle.securityMinPassword != undefined) circle.securityMinPassword = proposedCircle.securityMinPassword;
        //if (proposedCircle.security2FA != undefined) circle.security2FA = proposedCircle.security2FA;
        if (proposedCircle.securityDaysPasswordValid != undefined) circle.securityDaysPasswordValid = proposedCircle.securityDaysPasswordValid;
        if (proposedCircle.securityTokenExpirationDays != undefined) circle.securityTokenExpirationDays = proposedCircle.securityTokenExpirationDays;
        if (proposedCircle.securityLoginAttempts != undefined) circle.securityLoginAttempts = proposedCircle.securityLoginAttempts;

        if (proposedCircle.toggleEntryVote != undefined) circle.toggleEntryVote = proposedCircle.toggleEntryVote;
        if (proposedCircle.toggleMemberPosting != undefined) circle.toggleMemberPosting = proposedCircle.toggleMemberPosting;
        if (proposedCircle.toggleMemberReacting != undefined) circle.toggleMemberReacting = proposedCircle.toggleMemberReacting;



        circle.lastUpdate = Date.now();
        await circle.save();

        return circle;


    } catch (err) {
        console.error(err);
        throw (err);
    }

    return null;

}

module.exports.getSettings = function (circle, settings) {

    try {

        let somethingChanged = false;

        let proposedChanges = new CircleSettingsObject({ circle: circle, proposedCircle: circle });

        for (let i = 0; i < settings.length; i++) {

            let setting = settings[i].setting;


            if (setting == constants.CIRCLE_SETTING.PRIVACY_DISAPPEARING_TIMER) {

                let settingValue = settings[i].numericSetting;

                let changed = settingChanged(circle, setting, settingValue);

                if (changed) {
                    proposedChanges.proposedCircle.set({ [setting]: settingValue });
                    somethingChanged = true;
                }


            } else {

                let settingValue = settings[i].boolSetting;

                if (!settingValid(setting, settingValue)) throw new Error("Invalid setting");

                let changed = settingChanged(circle, setting, settingValue);

                if (changed) {
                    proposedChanges.proposedCircle.set({ [setting]: settingValue });
                    somethingChanged = true;
                }
            }
        }

        if (!somethingChanged)
            throw new Error("Nothing changed");

        return proposedChanges;


    } catch (err) {
        console.error(err);
        throw (err);
    }

}

module.exports.createModelVote = async function (circle, modelChange, userID, settingChangeType, description) {

    try {

        //make sure there isn't a conflicting vote model change
        let checkVoteType;
        let voteType;
        let votingModel;
        let question;

        //check the setting
        if (modelChange != constants.VOTE_MODEL.UNANIMOUS && modelChange != constants.VOTE_MODEL.MAJORITY)
            throw new Error("Invalid parameter");

        if (settingChangeType == constants.CIRCLE_SETTING_CHANGE_TYPE.SECURITY) {
            checkVoteType = constants.VOTE_TYPE.SECURITY_SETTING;
            voteType = constants.VOTE_TYPE.SECURITY_SETTING_MODEL;
            votingModel = circle.securityVotingModel;
            question = "Change Circle security settings voting model?"
        } else if (settingChangeType == constants.CIRCLE_SETTING_CHANGE_TYPE.PRIVACY) {
            checkVoteType = constants.VOTE_TYPE.PRIVACY_SETTING;
            voteType = constants.VOTE_TYPE.PRIVACY_SETTING_MODEL;
            votingModel = circle.privacyVotingModel;
            question = "Change Circle privacy settings voting model?"
        } else {
            throw new Error("Invalid parameter");
        }

        let voteExists = await voteLogic.voteExists(circle._id, checkVoteType);

        if (voteExists) throw new Error("A vote to change settings already exists. That vote must be deleted or closed.");


        let seed = randomstring.generate({
            length: 10,
            charset: 'alphabetic'
        })

        //createCircleVote validates the vote does not exist already.
        var circleObject = await voteLogic.createCircleVote(circle._id, userID,
            question,
            voteType, votingModel, modelChange, [{ option: "Yes" }, { option: "No" }], seed, description);  //TODO add the seed

        return circleObject;


    } catch (err) {
        //msg = await logUtil.logError(err, true);
        console.error(err);
        throw (err);
    }
}

module.exports.createVote = async function (circle, proposedChanges, userID, settingChangeType, description) {

    try {

        //make sure there isn't a conflicting vote model change
        let type;
        let voteType;
        let votingModel;

        if (settingChangeType == constants.CIRCLE_SETTING_CHANGE_TYPE.SECURITY) {
            type = constants.VOTE_TYPE.SECURITY_SETTING_MODEL;
            voteType = constants.VOTE_TYPE.SECURITY_SETTING;
            votingModel = circle.securityVotingModel;
        } else {
            type = constants.VOTE_TYPE.PRIVACY_SETTING_MODEL;
            voteType = constants.VOTE_TYPE.PRIVACY_SETTING;
            votingModel = circle.privacyVotingModel;
        }

        let voteExists = await voteLogic.voteExists(circle._id, type);

        if (voteExists) throw new Error("A vote to change the voting model for these settings already exists.  That vote must be deleted or closed.");

        let seed = randomstring.generate({
            length: 10,
            charset: 'alphabetic'
        })

        //createCircleVote validates the vote does not exist already.
        var circleObject = await voteLogic.createCircleVote(circle._id, userID,
            "Allow Circle Settings Changes?",
            voteType, votingModel, proposedChanges._id, [{ option: "Yes" }, { option: "No" }], seed, description);  //TODO add the seed

        return circleObject;


    } catch (err) {
        //msg = await logUtil.logError(err, true);
        console.error(err);
        throw (err);
    }
}





module.exports.votingModelValid = async function (setting, settingValue) {
    try {

        //check the settings voting model
        if (setting == constants.CIRCLE_SETTING.SECURITY_VOTING_MODEL ||
            setting == constants.CIRCLE_SETTING.PRIVACY_VOTING_MODEL) {

            if (settingValue == constants.VOTE_MODEL.UNANIMOUS ||
                settingValue == constants.VOTE_MODEL.MAJORITY) {
                return true;
            }
        }

    } catch (err) {
        console.error(err);
    }
    return false;

}

function settingValid(setting, settingValue) {
    try {
        //check the circle settings
        if (setting == constants.CIRCLE_SETTING.PRIVACY_SHAREIMAGE ||
            setting == constants.CIRCLE_SETTING.PRIVACY_SHAREURL ||
            setting == constants.CIRCLE_SETTING.PRIVACY_SHAREGIF ||
            setting == constants.CIRCLE_SETTING.PRIVACY_COPYTEXT ||
            setting == constants.CIRCLE_SETTING.TOGGLE_ENTRY_VOTE ||
            setting == constants.CIRCLE_SETTING.TOGGLE_MEMBER_POSTING ||
            setting == constants.CIRCLE_SETTING.TOGGLE_MEMBER_REACTING) {

            if (Boolean(settingValue) == true || Boolean(settingValue) == false)
                return true;

        } else if (setting == constants.CIRCLE_SETTING.SECURITY_MINPASSWORD) {
            //let maybe = Number.isInteger(settingValue);

            let num = Number(settingValue);
            let maybe = Number.isInteger(num);

            if (maybe) {
                if (num < 4)
                    throw new Error("Minimum password length is 4 characters");
                else if (num > 30)
                    throw new Error("Maximum password length is 30 characters");
            }

            return maybe;

        } else if (setting == constants.CIRCLE_SETTING.SECURITY_DAYSPASSWORDVALID) {

            let num = Number(settingValue);
            let maybe = Number.isInteger(num);

            if (maybe) {
                if (num < 1)
                    throw new Error("Minimum days for password change is 1");
                //else if (num > 30)
                //throw new Error("maximum password length is 30 characters");
            }

            return maybe;

        } else if (setting == constants.CIRCLE_SETTING.SECURITY_TOKENEXPIRATIONDAYS) {

            let num = Number(settingValue);
            let maybe = Number.isInteger(num);

            if (maybe) {
                if (num < 1)
                    throw new Error("Minimum stay logged in days is 1");
                //else if (num > 30)
                //throw new Error("maximum password length is 30 characters");
            }

            return maybe;

        } else if (setting == constants.CIRCLE_SETTING.SECURITY_LOGINATTEMPTS) {

            let num = Number(settingValue);
            let maybe = Number.isInteger(num);

            if (maybe) {
                if (num < 3)
                    throw new Error("Minimum login attempts before lock is 3");
                //else if (num > 30)
                //throw new Error("maximum password length is 30 characters");
            }

            return maybe;

        } else if (setting == constants.CIRCLE_SETTING.PRIVACY_DISAPPEARING_TIMER) {

            maybe = true;

            return maybe;

        }

    } catch (err) {
        logUtil.logError(err, true);
        throw (err);
    }

    return false;

}





module.exports.votingModelChanged = function (circle, setting, settingValue) {

    try {

        if (setting == constants.CIRCLE_SETTING.PRIVACY_VOTING_MODEL)
            return circle.privacyVotingModel != settingValue;

        if (setting == constants.CIRCLE_SETTING.SECURITY_VOTING_MODEL)
            return circle.securityVotingModel != settingValue;

    } catch (err) {
        console.error(err);
    }

    return false;

}


// function getTimerInSeconds(timerString) {

//     var timer;

//     if (timerString == constants.DISAPPEARING_TIMER_STRING.OFF)
//         timer = constants.DISAPPEARING_TIMER.OFF;
//     else if (timerString == constants.DISAPPEARING_TIMER_STRING.FOUR_HOURS)
//         timer = constants.DISAPPEARING_TIMER.FOUR_HOURS;
//     else if (timerString == constants.DISAPPEARING_TIMER_STRING.EIGHT_HOURS)
//         timer = constants.DISAPPEARING_TIMER.EIGHT_HOURS;
//     else if (timerString == constants.DISAPPEARING_TIMER_STRING.ONE_DAY)
//         timer = constants.DISAPPEARING_TIMER.ONE_DAY;
//     else if (timerString == constants.DISAPPEARING_TIMER_STRING.ONE_WEEK)
//         timer = constants.DISAPPEARING_TIMER.ONE_WEEK;
//     else if (timerString == constants.DISAPPEARING_TIMER_STRING.THIRTY_DAYS)
//         timer = constants.DISAPPEARING_TIMER.THIRTY_DAYS;
//     else if (timerString == constants.DISAPPEARING_TIMER_STRING.NINETY_DAYS)
//         timer = constants.DISAPPEARING_TIMER.NINETY_DAYS;
//     else if (timerString == constants.DISAPPEARING_TIMER_STRING.SIX_MONTHS)
//         timer = constants.DISAPPEARING_TIMER.SIX_MONTHS;
//     else if (timerString == constants.DISAPPEARING_TIMER_STRING.ONE_YEAR)
//         timer = constants.DISAPPEARING_TIMER.ONE_YEAR;


//     return timer;


// }

function settingChanged(circle, setting, settingValue) {
    try {

        if (setting == constants.CIRCLE_SETTING.PRIVACY_SHAREIMAGE)
            return circle.settingShareImage != settingValue;

        if (setting == constants.CIRCLE_SETTING.PRIVACY_SHAREURL)
            return circle.settingShareURL != settingValue;

        if (setting == constants.CIRCLE_SETTING.PRIVACY_SHAREGIF)
            return circle.settingShareGif != settingValue;

        if (setting == constants.CIRCLE_SETTING.PRIVACY_COPYTEXT)
            return circle.settingCopyText != settingValue;

        if (setting == constants.CIRCLE_SETTING.SECURITY_MINPASSWORD)
            return circle.securityMinPassword != Number(settingValue);

        if (setting == constants.CIRCLE_SETTING.SECURITY_DAYSPASSWORDVALID)
            return circle.securityDaysPasswordValid != Number(settingValue);

        //if (setting == constants.CIRCLE_SETTING.SECURITY_2FA)
        //return circle.security2FA != Boolean(settingValue);

        if (setting == constants.CIRCLE_SETTING.SECURITY_TOKENEXPIRATIONDAYS)
            return circle.securityTokenExpirationDays != Number(settingValue);

        if (setting == constants.CIRCLE_SETTING.SECURITY_LOGINATTEMPTS)
            return circle.securityLoginAttempts != Number(settingValue);

        if (setting == constants.CIRCLE_SETTING.PRIVACY_DISAPPEARING_TIMER)
            return circle.privacyDisappearingTimer != settingValue;

        if (setting == constants.CIRCLE_SETTING.TOGGLE_ENTRY_VOTE)
            return circle.toggleEntryVote != settingValue;

        if (setting == constants.CIRCLE_SETTING.TOGGLE_MEMBER_POSTING)
            return circle.toggleMemberPosting != settingValue;

        if (setting == constants.CIRCLE_SETTING.TOGGLE_MEMBER_REACTING)
            return circle.toggleMemberReacting != settingValue;

    } catch (err) {
        console.error(err);
    }

    return false;

}
/*
module.exports.settingToEnglish = function (setting) {

    try {

        if (setting == constants.CIRCLE_SETTING.PRIVACY_SHAREIMAGE)
            return constants.CIRCLE_SETTING_ENGLISH.PRIVACY_SHAREIMAGE;

        if (setting == constants.CIRCLE_SETTING.PRIVACY_SHAREURL)
            return constants.CIRCLE_SETTING_ENGLISH.PRIVACY_SHAREURL;

        if (setting == constants.CIRCLE_SETTING.PRIVACY_SHAREGIF)
            return constants.CIRCLE_SETTING_ENGLISH.PRIVACY_SHAREGIF;

        if (setting == constants.CIRCLE_SETTING.PRIVACY_COPYTEXT)
            return constants.CIRCLE_SETTING_ENGLISH.PRIVACY_COPYTEXT;

        if (setting == constants.CIRCLE_SETTING.SECURITY_MINPASSWORD)
            return constants.CIRCLE_SETTING_ENGLISH.SECURITY_MINPASSWORD;

        if (setting == constants.CIRCLE_SETTING.SECURITY_DAYSPASSWORDVALID)
            return constants.CIRCLE_SETTING_ENGLISH.SECURITY_DAYSPASSWORDVALID;

        if (setting == constants.CIRCLE_SETTING.PRIVACY_VOTING_MODEL)
            return constants.CIRCLE_SETTING_ENGLISH.PRIVACY_VOTING_MODEL;

        if (setting == constants.CIRCLE_SETTING.SECURITY_VOTING_MODEL)
            return constants.CIRCLE_SETTING_ENGLISH.SECURITY_VOTING_MODEL;

    } catch (err) {
        console.error(err);
    }

    return false;

}*/