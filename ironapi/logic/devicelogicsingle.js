/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates device management logic.  Store and manage users deviceid
 * for push notifications.
 * 
 * TODO: remove all functions that do not use promises, remove P from other functions
 * (it denotes a promise)
 * 
 *  
 ***************************************************************************/

var Device = require('../models/device');
const User = require('../models/user');
const Circle = require('../models/circle');
const UserCircle = require('../models/usercircle');
const CircleObject = require('../models/circleobject');
const CircleImage = require('../models/circleimage');
const CircleRecipe = require('../models/circlerecipe');
const CircleVideo = require('../models/circlevideo');
const CircleVote = require('../models/circlevote');
const CircleVoteOption = require('../models/circlevoteoption');
const CircleList = require('../models/circlelist');
const ReminderTracker = require('../models/remindertracker');
const NotificationLog = require('../models/notificationlog');
const userCircleLogic = require('./usercirclelogic');
const deviceLogic = require('./devicelogic');
const gcm = require('node-gcm');
var randomstring = require("randomstring");
const logUtil = require('../util/logutil');
const device = require('../models/device');
const constants = require('../util/constants');
const CircleObjectReaction = require('../models/circleobjectreaction');
const ReplyObject = require('../models/replyobject');

// const firebase = require('firebase-admin');
// const serviceAccount = require('../ironfurnace-a10e7-firebase-adminsdk-p35g8-8cae172dc5.json');

// firebase.initializeApp({ credential: firebase.credential.cert(serviceAccount) });

module.exports.sendReplyMessageDeleteNotificationToWall = async function (circleID, skipDeviceToken, replyObjectID) {
    try {
        let userCircles = await UserCircle.find({ circle: circleID }).populate('user').exec();

        if (!userCircles)
            throw ('UserCircles not found');

        for (let u = 0; u < userCircles.length; u++) {
            let userCircle = userCircles[u];

            if (userCircle.user == null) {
                console.group('Could not load user associated to usercircle: UserCircle: ' + userCircle._id);
            } else {

                let tokens = [];

                console.log('data only message for ' + userCircle.user.username + ' in circle ' + circleID); ///gets here fine
                if (userCircle.beingVotedOut == true) return;

                for (let i = 0; i < userCircle.user.devices.length; i++) {
                    let device = userCircle.user.devices[i];

                    if (device.pushToken == null || device.loggedIn == false) continue;

                    var found = false;

                    //make sure the push token hasn't recieved a message already
                    for (let index = 0; index < tokens.length; index++) {
                        if (tokens[index].pushToken == device.pushToken)
                            found = true;
                    }

                    if (found == true) continue; //already send a notification

                    if (skipDeviceToken != undefined && skipDeviceToken != null) {
                        if (device.pushToken == skipDeviceToken) continue;
                    }

                    if (device.build == null || device.build == undefined) continue;

                    //TODO remove this after all iOS users transition to b60 or higher
                    if (device.platform == constants.DEVICE_PLATFORM.iOS) {
                        if (device.build < 60) continue;
                    }

                    tokens.push(device.pushToken);
                }

                deviceLogic.sendReplyDataNotification(replyObjectID, tokens, constants.TAG_TYPE.ICM);
            }
        }
    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }
}

module.exports.sendDataOnlyReplyMessageNotification = async function (circleObjectSeed, circleID, replyObject, skipUserID, skipDeviceToken) {
    try {

        //await userCircleLogic.flipShowBadgesOn(circleID, skipUserID, lastItemUpdate);

        ///send notification to creator of circleObject
        ///based off of sened notification to creator logic

        let userCircles = await UserCircle.find({ circle: circleID }).populate('user').exec();

        if (!userCircles)
            throw ('UserCircles not found');

        for (let u = 0; u < userCircles.length; u++) {
            let userCircle = userCircles[u];

            if (userCircle.user == null) {
                console.log('Could not load user associated to usercircle: UserCircle: ' + userCircle._id);
            } else {
                if (replyObject.creator._id.equals(userCircle.user._id) && userCircle.user._id.equals(skipUserID) == false) {
                    //this.sendReplyNotificationToIndividual(circleObject.seed, replyObject, circleID, userCircle, skipUserID, skipDeviceToken, notification, constants.TAG_TYPE.ICM, notificationType, oldNotification);
                } else {
                    deviceLogic.sendDataOnlyReplyMessage(circleObjectSeed, replyObject, circleID, userCircle, skipDeviceToken, constants.TAG_TYPE.ICM);
                }
            }
        }

        return;

    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }
}


module.exports.sendReplyMessageNotificationToWall = async function (circleObject, circleID, replyObject, skipUserID, skipDeviceToken, lastItemUpdate, notification, notificationType, oldNotification, taggedUsers) {
    try {

        //await userCircleLogic.flipShowBadgesOn(circleID, skipUserID, lastItemUpdate);

        ///send notification to creator of circleObject
        ///based off of sened notification to creator logic

        let userCircles = await UserCircle.find({ circle: circleID }).populate('user').exec();

        if (!userCircles)
            throw ('UserCircles not found');

        for (let u = 0; u < userCircles.length; u++) {
            let userCircle = userCircles[u];

            let taggedNotification = "";

            //if (userCircle.showBadge == true) {
            if (taggedUsers != undefined && taggedUsers != null) {
                for (let m = 0; m < taggedUsers.length; m++) {
                    if (userCircle.user._id.equals(taggedUsers[m]._id)) {
                        taggedNotification = replyObject.creator.username + ' tagged you in an ironclad reply';
                    }
                }
            }
            //}

            let notiText = notification;
            if (taggedNotification != "") {
                notiText = taggedNotification;
            }

            if (userCircle.user == null) {
                console.log('Could not load user associated to usercircle: UserCircle: ' + userCircle._id);
            } else {
                if (circleObject.creator._id.equals(userCircle.user._id) && userCircle.user._id.equals(skipUserID) == false) {
                    ///to circle object's owner
                    this.sendReplyNotificationToIndividual(circleObject.seed, replyObject, circleID, userCircle, skipUserID, skipDeviceToken, notiText, constants.TAG_TYPE.ICM, notificationType, oldNotification);
                } else if (taggedNotification != "") {
                    ///to tagged user(s)
                    this.sendReplyNotificationToIndividual(circleObject.seed, replyObject, circleID, userCircle, skipUserID, skipDeviceToken, notiText, constants.TAG_TYPE.ICM, notificationType, oldNotification);
                } else {
                    deviceLogic.sendDataOnlyReplyMessage(circleObject.seed, replyObject, circleID, userCircle, skipDeviceToken, constants.TAG_TYPE.ICM);
                }
            }
        }

        return;

    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }
}

module.exports.sendReplyReactionNotification = async function (circleObject, circleID, replyObject, skipUserID, skipDeviceToken, notification, notificationType, oldNotification, newEmoji, circleObjectReaction) {
    try {

        //await userCircleLogic.setLastItemUpdateNoBadge(circleID, lastItemUpdate);

        let userCircles = await UserCircle.find({ circle: circleID }).populate('user').exec();

        if (!userCircles)
            throw ("UserCircles not found");

        for (let u = 0; u < userCircles.length; u++) {
            let userCircle = userCircles[u];

            if (userCircle.user == null) {
                console.log('Could not load user associated to usercircle: UserCircle: ' + userCircle._id);
            } else {

                if (replyObject.creator._id.equals(userCircle.user._id) && userCircle.user._id.equals(skipUserID) == false) {
                    this.sendReplyNotificationToIndividual(circleObject.seed, replyObject, circleID, userCircle, skipUserID, skipDeviceToken, notification, constants.TAG_TYPE.REPLY_REACTION, notificationType, oldNotification, newEmoji, circleObjectReaction);
                } else {
                    deviceLogic.sendDataOnlyReplyMessage(circleObject.seed, replyObject, circleID, userCircle, skipDeviceToken, constants.TAG_TYPE.REPLY_REACTION);
                }

            }
        }

        return;
    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }
}

module.exports.sendMessageNotificationToCircle = async function (circleObject, circleID, skipUserID, skipDeviceToken, lastItemUpdate, notification, notificationType, oldNotification, taggedUsers) {
    try {



        if (circleObject == null || circleObject == undefined) {
            throw ('cannot send notification. circleObject is null');
        } else if (circleID == null || circleID == undefined) {
            throw ('cannot send notification. circleID is null');
        }


        if (notification == null || notification == undefined) notification = 'New ironclad message';
        await userCircleLogic.flipShowBadgesOn(circleID, skipUserID, lastItemUpdate);

        await findDevicesAndSend(circleObject, circleID, skipUserID, skipDeviceToken, notification, notificationType, oldNotification, taggedUsers);

        return;


    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }

}

module.exports.sendNotificationToIndividual = async function (circleObject, circleID, userCircle, skipUserID, skipDeviceToken, lastItemUpdate, notification, tag, flipBadge, notificationType, oldNotification, newEmoji, circleObjectReaction) {
    try {

        if (flipBadge == undefined || flipBadge == null || flipBadge == true)
            await userCircleLogic.flipShowBadgesOn(circleID, skipUserID, lastItemUpdate);

        if (userCircle.muted == true) return;
        if (userCircle.beingVotedOut == true) return;

        for (let i = 0; i < userCircle.user.devices.length; i++) {
            let muteNotification = true;
            let device = userCircle.user.devices[i];

            if (device.pushToken == null) continue;
            if (device.pushToken == "") continue;
            if (device.pushToken == skipDeviceToken) continue;
            if (device.loggedIn == false) continue;


            if ((userCircle.hidden == false || (userCircle.hiddenOpen != undefined && userCircle.hiddenOpen != null && userCircle.hiddenOpen.length != 0))) {

                muteNotification = false;

                if (userCircle.hiddenOpen != undefined && userCircle.hiddenOpen != null) {

                    if (userCircle.hiddenOpen.length > 0) {

                        for (let index = 0; index < userCircle.hiddenOpen.length; index++) {
                            if (userCircle.hiddenOpen[index] == device.uuid) {
                                muteNotification = false;
                                break;
                            }
                        }
                    }
                }
            }

            if (device.build == null || device.build == undefined) continue;

            //TODO remove this after all iOS users transition to b60 or higher
            if (device.platform == constants.DEVICE_PLATFORM.iOS) {
                if (device.build < 60) continue;
            }



            if (muteNotification == true) {
                deviceLogic.sendDataOnlyMessage(circleID, userCircle, '', tag);


            } else {

                let notiText = notification;

                if (device.build < 65)
                    notiText = oldNotification;


                let tempObject = stripFields(circleObject, userCircle, device);

                if (newEmoji == true) {

                    if (device < 129) {
                        notification = "You recieved a reaction your app version can't support. Please update.";
                        tempObject.reactionsPlus = [];
                    } else {
                        tempObject.reactions = [];
                    }
                }

                if (device.platform == constants.DEVICE_PLATFORM.ANDROID) {

                    sendNotification(notiText, tempObject, device, circleID, notificationType, userCircle.user._id, circleObject.creator._id, circleObjectReaction);

                } else if (device.platform == constants.DEVICE_PLATFORM.iOS) {

                    await deviceLogic.sendSingleDeviceDataNotification(circleID, device, 'tag');

                    setTimeout(async function () {
                        sendNotification(notiText, tempObject, device, circleID, notificationType, userCircle.user._id, circleObject.creator._id, circleObjectReaction);
                    }, 3000);

                    //deviceLogic.sendNotificationToCircle(circleID, skipUserID, skipDeviceToken, lastItemUpdate);
                } else if (device.platform == constants.DEVICE_PLATFORM.MACOS) {
                    sendNotification(notiText, tempObject, device, circleID, notificationType, userCircle.user._id, circleObject.creator._id, circleObjectReaction);

                }

            }
        }


        return;


    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }

}

module.exports.sendReplyNotificationToIndividual = async function (circleObjectSeed, replyObject, circleID, userCircle, skipUserID, skipDeviceToken, notification, tag, notificationType, oldNotification, newEmoji, circleObjectReaction) {
    try {

        // if (flipBadge == undefined || flipBadge == null || flipBadge == true)
        //     await userCircleLogic.flipShowBadgesOn(circleID, skipUserID, lastItemUpdate);

        if (userCircle.muted == true) return;
        if (userCircle.beingVotedOut == true) return;

        for (let i = 0; i < userCircle.user.devices.length; i++) {
            let muteNotification = true;
            let device = userCircle.user.devices[i];

            if (device.pushToken == null) continue;
            if (device.pushToken == "") continue;
            if (device.pushToken == skipDeviceToken) continue;
            if (device.loggedIn == false) continue;


            if ((userCircle.hidden == false || (userCircle.hiddenOpen != undefined && userCircle.hiddenOpen != null && userCircle.hiddenOpen.length != 0))) {

                muteNotification = false;

                if (userCircle.hiddenOpen != undefined && userCircle.hiddenOpen != null) {

                    if (userCircle.hiddenOpen.length > 0) {

                        for (let index = 0; index < userCircle.hiddenOpen.length; index++) {
                            if (userCircle.hiddenOpen[index] == device.uuid) {
                                muteNotification = false;
                                break;
                            }
                        }
                    }
                }
            }

            if (device.build == null || device.build == undefined) continue;

            //TODO remove this after all iOS users transition to b60 or higher
            if (device.platform == constants.DEVICE_PLATFORM.iOS) {
                if (device.build < 60) continue;
            }



            if (muteNotification == true) {
                //deviceLogic.sendDataOnlyMessage(circleID, userCircle, '', tag);


            } else {

                let notiText = notification;

                if (device.build < 65)
                    notiText = oldNotification;

                //let tempObject = replyObject.ID;
                let tempObject = await stripReplyFields(replyObject, circleObjectSeed);

                //let tempObject = stripFields(circleObject, userCircle, device);

                if (newEmoji == true) {

                    if (device < 129) {
                        notification = "You recieved a reaction your app version can't support. Please update.";
                        tempObject.reactions = [];
                    } else {
                        tempObject.reactions = [];
                    }
                }

                if (device.platform == constants.DEVICE_PLATFORM.ANDROID) {

                    sendNotification(notiText, tempObject, device, circleID, notificationType, userCircle.user._id, skipUserID, circleObjectReaction);

                } else if (device.platform == constants.DEVICE_PLATFORM.iOS) {

                    await deviceLogic.sendSingleDeviceDataNotification(circleID, device, 'tag');

                    setTimeout(async function () {
                        sendNotification(notiText, tempObject, device, circleID, notificationType, userCircle.user._id, replyObject.creator._id, circleObjectReaction);
                    }, 3000);

                    //deviceLogic.sendNotificationToCircle(circleID, skipUserID, skipDeviceToken, lastItemUpdate);
                } else if (device.platform == constants.DEVICE_PLATFORM.MACOS) {
                    sendNotification(notiText, tempObject, device, circleID, notificationType, userCircle.user._id, replyObject.creator._id, circleObjectReaction);

                }

            }
        }


        return;

    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }
}

module.exports.sendDataOnlyRefreshToCircle = async function (circleID) {
    try {

        let userCircles = await UserCircle.find({ circle: circleID, beingVotedOut: { $ne: true } }).populate('user').exec();

        if (!userCircles)
            throw ("UserCircles not found");

        for (let u = 0; u < userCircles.length; u++) {

            let userCircle = userCircles[u];

            if (userCircle.user == null) {
                console.log('Could not load user associated to usercircle: UserCircle: ' + userCircle._id);
            } else {

                deviceLogic.sendDataOnlyMessage(circleID, userCircle, '', '');

            }
        }

        return;

    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }

}


module.exports.sendReactionRemovalNotificationToCircle = async function (circleID, skipUserID, skipDeviceToken, lastItemUpdate) {
    try {

        //await userCircleLogic.flipShowBadgesOn(circleID, skipUserID, lastItemUpdate);
        await userCircleLogic.setLastItemUpdateNoBadge(circleID, lastItemUpdate);

        let userCircles = await UserCircle.find({ circle: circleID, beingVotedOut: { $ne: true } }).populate('user').exec();

        if (!userCircles)
            throw ("UserCircles not found");

        for (let u = 0; u < userCircles.length; u++) {

            let userCircle = userCircles[u];

            if (userCircle.user == null) {
                console.log('Could not load user associated to usercircle: UserCircle: ' + userCircle._id);
            } else {

                deviceLogic.sendDataOnlyMessage(circleID, userCircle, skipDeviceToken, constants.TAG_TYPE.REACTION);  //no one needs a notification for a reaction removal

            }
        }

        return;

    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }

}

//Creator gets a heads up notification, all other Circle members get data only
module.exports.sendNotificationToCreator = async function (notification, circleObject, circleID, skipUserID, skipDeviceToken, lastItemUpdate, notificationType, oldNotification) {
    try {

        await userCircleLogic.flipShowBadgesOn(circleID, skipUserID, lastItemUpdate);

        let userCircles = await UserCircle.find({ circle: circleID }).populate('user').exec();

        if (!userCircles)
            throw ("UserCircles not found");

        for (let u = 0; u < userCircles.length; u++) {

            let userCircle = userCircles[u];

            if (userCircle.user == null) {
                console.log('Could not load user associated to usercircle: UserCircle: ' + userCircle._id);
            } else {

                if (circleObject.creator._id.equals(userCircle.user._id) && userCircle.user._id.equals(skipUserID) == false) {  //only the user gets a notification

                    this.sendNotificationToIndividual(circleObject, circleID, userCircle, skipUserID, skipDeviceToken, lastItemUpdate, notification, constants.TAG_TYPE.ICM, false, notificationType, oldNotification);

                } else {
                    deviceLogic.sendDataOnlyMessage(circleID, userCircle, skipDeviceToken, constants.TAG_TYPE.ICM);
                }

            }
        }

        return;

    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }

}

module.exports.sendReactionNotificationToCircle = async function (circleObject, circleObjectReaction, circleID, skipUserID, skipDeviceToken, lastItemUpdate, notification, notificationType, oldNotification, newEmoji) {
    try {

        await userCircleLogic.setLastItemUpdateNoBadge(circleID, lastItemUpdate);

        let userCircles = await UserCircle.find({ circle: circleID, beingVotedOut: { $ne: true } }).populate({ path: 'user', populate: { path: "devices" } }).exec();

        if (!userCircles)
            throw ("UserCircles not found");

        for (let u = 0; u < userCircles.length; u++) {

            let userCircle = userCircles[u];

            if (userCircle.user == null) {
                console.log('Could not load user associated to usercircle: UserCircle: ' + userCircle._id);
            } else {

                ///don't send if the user is newer than the original message
                // if (circleObject.created < userCircle.created){
                //     continue;
                // }

                if (circleObject.creator._id.equals(userCircle.user._id) && (userCircle.user._id.equals(skipUserID) == false)) {  //only the user gets a notification

                    // if (newEmoji == true) {
                    //     for (let i = 0; i < userCircle.user.devices.length; i++) {
                    //         if (userCircle.user.devices[i].build < 129) {
                    //             notification = "You recieved a reaction your app version can't support. Please update.";
                    //         }
                    //     }
                    // }

                    this.sendNotificationToIndividual(circleObject, circleID, userCircle, skipUserID, skipDeviceToken, lastItemUpdate, notification, constants.TAG_TYPE.REACTION, false, notificationType, oldNotification, newEmoji, circleObjectReaction);

                } else {
                    deviceLogic.sendDataOnlyMessage(circleID, userCircle, skipDeviceToken, constants.TAG_TYPE.REACTION, null);
                }

            }
        }

        return;

    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }

}


async function findDevicesAndSend(circleObject, circleID, skipUserID, skipDeviceToken, notification, notificationType, oldNotification, taggedUsers) {
    try {

        if (circleID == null || circleID == undefined) {
            throw ('cannot send notification. circleID is null');
        }
        
        let userCircles = await UserCircle.find({ circle: circleID, beingVotedOut: { $ne: true } }).populate('user').exec();

        if (!userCircles)
            throw ("UserCircles not found");

        //let devices = [];
        let androidDevices = [];
        let iOSDevices = [];

        for (let u = 0; u < userCircles.length; u++) {

            //console.log(u);
            let userCircle = userCircles[u];
            //console.log(userCircle.user.username);
            let taggedNotification = "";



            if (userCircle.user == null) {

                console.log('Could not load user associated to usercircle: UserCircle: ' + userCircle._id);

            } else {

                if (userCircle.muted == true) {

                    deviceLogic.sendDataOnlyMessage(circleID, userCircle, skipDeviceToken);
                    continue;
                }

                //usercircle is for the sender
                if (userCircle.user._id == skipUserID) {

                    ///don't send if new user of circle
                    if (!notification.includes(" has joined!")) {
                        //send data only messages
                        for (let i = 0; i < userCircle.user.devices.length; i++) {
                            let device = userCircle.user.devices[i];

                            if (device.pushToken != skipDeviceToken) {

                                if (device.build == null || device.build == undefined) continue;

                                // //TODO remove this after all iOS users transition to b60 or higher
                                // if (device.platform == constants.DEVICE_PLATFORM.iOS) {
                                //     if (device.build < 60) continue;
                                // }


                                deviceLogic.sendDataOnlyMessage(circleID, userCircle, skipDeviceToken);

                                break; //the function above takes care of all devices
                            }
                        }
                    } else {
                        return;
                    }

                } else if ((userCircle.hidden == false || (userCircle.hiddenOpen != undefined && userCircle.hiddenOpen != null && userCircle.hiddenOpen.length != 0))) {

                    if (circleObject.type != constants.CIRCLEOBJECT_TYPE.CIRCLEVOTE) {
                        if (userCircle.user.blockedList.length > 0) {
                            for (let j = 0; j < userCircle.user.blockedList.length; j++) {
                                let blockedUser = userCircle.user.blockedList[j];
                                if (circleObject.creator._id.equals(blockedUser._id)) {
                                    userCircle.showBadge = false;
                                    await UserCircle.updateOne({ 'circle': circleID, 'user': userCircle.user }, { $set: { showBadge: false } });
                                }
                            }
                        }
                    }

                    if (userCircle.showBadge == true) {

                        if (taggedUsers != undefined && taggedUsers != null) {
                            for (let m = 0; m < taggedUsers.length; m++) {

                                if (userCircle.user._id.equals(taggedUsers[m]._id)) {

                                    let type = 'message';

                                    if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEEVENT) {
                                        type = 'event';
                                    } else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLELIST) {
                                        type = 'list';

                                    } else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLERECIPE) {
                                        type = 'recipe';

                                    } else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEVIDEO) {
                                        type = 'video';

                                    } else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEIMAGE) {
                                        type = 'video';

                                    }
                                    taggedNotification = circleObject.creator.username + ' tagged you in an ironclad ' + type;
                                }

                            }
                        }


                        for (let i = 0; i < userCircle.user.devices.length; i++) {
                            let device = userCircle.user.devices[i];

                            if (device.pushToken == null) continue;
                            if (device.pushToken == "") continue;
                            if (device.pushToken == skipDeviceToken) continue;
                            if (device.activated == false) continue;
                            if (device.tokenExpired != null) continue;

                            //console.log(device.loggedIn);

                            if (device.loggedIn != undefined) {
                                if (device.loggedIn == false) continue;
                            }

                            var found = false;


                            //make sure the push token hasn't recieved a message already
                            for (let index = 0; index < androidDevices.length; index++) {
                                if (androidDevices[index].pushToken == device.pushToken)
                                    found = true;
                            }

                            for (let index = 0; index < iOSDevices.length; index++) {
                                if (iOSDevices[index].pushToken == device.pushToken)
                                    found = true;
                            }

                            if (found) continue;  //already send a notification

                            var skip = false;

                            if (userCircle.hidden == true) {
                                skip = true;

                                if (userCircle.hiddenOpen != undefined && userCircle.hiddenOpen != null) {

                                    if (userCircle.hiddenOpen.length > 0) {

                                        for (let index = 0; index < userCircle.hiddenOpen.length; index++) {
                                            if (userCircle.hiddenOpen[index] == device.uuid) {
                                                skip = false;
                                                break;
                                            }

                                        }
                                    }

                                }
                            }

                            if (skip) continue;  //hidden circle is closed; consider sending a data only message;

                            if (device.build == null || device.build == undefined) continue;

                            // //TODO remove this after all iOS users transition to b60 or higher
                            // if (device.platform == constants.DEVICE_PLATFORM.iOS) {
                            //     if (device.build < 60) continue;
                            // }


                            let tempObject = JSON.parse(JSON.stringify(circleObject));
                            let ratchetsForUser = [];

                            //for all ratchets in this circleobject
                            for (let ri = 0; ri < tempObject.ratchetIndexes.length; ri++) {

                                //find the ones that match this user && device
                                if (tempObject.ratchetIndexes[ri].user == userCircle.user._id && tempObject.ratchetIndexes[ri].device == device.uuid) {
                                    ratchetsForUser.push(tempObject.ratchetIndexes[ri]);

                                }
                            }

                            ///The user might have a device mismatch
                            if (ratchetsForUser.length == 0) {
                                logUtil.logAlert('Could not find ratchets for user: ' + userCircle.user._id + ' device: ' + device.uuid + ' circleObject: ' + circleObject._id, null, userCircle.user._id);
                                for (let ri = 0; ri < tempObject.ratchetIndexes.length; ri++) {

                                    //find the ones that match this user only
                                    if (tempObject.ratchetIndexes[ri].user == userCircle.user._id) {
                                        ratchetsForUser.push(tempObject.ratchetIndexes[ri]);

                                    }
                                }
                            }


                            tempObject.ratchetIndexes = ratchetsForUser;
                            if (tempObject.type != constants.CIRCLEOBJECT_TYPE.SYSTEMMESSAGE) {
                                tempObject.creator = removeUserFields(tempObject.creator, true);
                            }
                            tempObject.circle = removeCircleFields(tempObject.circle);

                            if (tempObject.lastEdited != undefined && tempObject.lastEdited != null) {
                                tempObject.lastEdited = removeUserFields(tempObject.lastEdited, false);
                            }

                            if (tempObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLELIST) {

                                if (tempObject.list.lastEdited != undefined)
                                    tempObject.list.lastEdited = removeUserFields(tempObject.list.lastEdited, false);
                            } else if (tempObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEEVENT) {
                                if (tempObject.event.lastEdited != undefined)
                                    tempObject.event.lastEdited = removeUserFields(tempObject.event.lastEdited, false);

                            }

                            ///remove reactions unnecessary user info
                            if (tempObject.reactions) {
                                for (let i = 0; i < tempObject.reactions.length; i++) {

                                    for (let u = 0; u < tempObject.reactions[i].users.length; u++) {

                                        tempObject.reactions[i].users[u] = removeUserFields(tempObject.reactions[i].users[u], true);

                                    }

                                }
                            }

                            if (tempObject.reactionsPlus) {
                                for (let i = 0; i < tempObject.reactionsPlus.length; i++) {

                                    for (let u = 0; u < tempObject.reactionsPlus[i].users.length; u++) {

                                        tempObject.reactionsPlus[i].users[u] = removeUserFields(tempObject.reactionsPlus[i].users[u], true);

                                    }

                                }
                            }

                            let notiText = notification;

                            if (taggedNotification != "") {
                                notiText = taggedNotification;
                            }

                            // if (!device.build) {
                            //     notiText = 'New activity in IronCircles';
                            // } else if (device.build < 65)
                            //     notiText = oldNotification;

                            if (device.platform == 'android') {

                                //console.log('android:' + device);

                                androidDevices.push(device);
                                if (tempObject.type == constants.CIRCLEOBJECT_TYPE.SYSTEMMESSAGE) {
                                    sendNotification(notiText, tempObject, device, circleID, notificationType, null, null);
                                } else {
                                    sendNotification(notiText, tempObject, device, circleID, notificationType, userCircle.user._id, circleObject.creator._id);
                                }



                            } else if (device.platform == 'iOS' || device.platform == 'macos') {
                                iOSDevices.push(device);

                                //console.log('iOS:' + device);

                                if (device.platform == 'macos') {
                                    if (tempObject.type == constants.CIRCLEOBJECT_TYPE.SYSTEMMESSAGE) {
                                        sendNotification(notiText, tempObject, device, circleID, notificationType, null, null);
                                    } else {
                                        sendNotification(notiText, tempObject, device, circleID, notificationType, userCircles[u].user._id, circleObject.creator._id);
                                    }

                                } else {

                                    //deviceLogic.sendDataOnlyMessage(circleID, userCircles[u], skipDeviceToken, 'tag', null);
                                    await deviceLogic.sendSingleDeviceDataNotification(circleID, device, 'tag');

                                    setTimeout(async function () {
                                        if (tempObject.type == constants.CIRCLEOBJECT_TYPE.SYSTEMMESSAGE) {
                                            sendNotification(notiText, tempObject, device, circleID, notificationType, null, null);
                                        } else {
                                            sendNotification(notiText, tempObject, device, circleID, notificationType, userCircles[u].user._id, circleObject.creator._id);
                                        }
                                    }, 3000);
                                    //deviceLogic.sendNotificationToCircle(circleID, skipUserID, skipDeviceToken, lastItemUpdate);
                                }
                            }

                        }

                    }



                }

            }

        }

        return;


    } catch (err) {
        var msg = await logUtil.logError(err, false);
        return;
    }
}

function stripFields(circleObject, userCircle, device) {

    // return circleObject; 

    let tempObject = JSON.parse(JSON.stringify(circleObject));
    let ratchetsForUser = [];

    //for all ratchets in this circleobject
    for (let ri = 0; ri < tempObject.ratchetIndexes.length; ri++) {

        //find the ones that match this user
        if (userCircle.user._id.equals(tempObject.ratchetIndexes[ri].user)) { //} == userCircle.user._id) {

            if (tempObject.ratchetIndexes[ri].device == device.uuid)
                ratchetsForUser.push(tempObject.ratchetIndexes[ri]);

        }
    }

    //remove other pinned users
    let pinnedUsers = [];
    for (let pu = 0; pu < tempObject.pinnedUsers.length; pu++) {

        //find the ones that match this user
        if (userCircle.user._id.equals(tempObject.pinnedUsers[pu])) { //} == userCircle.user._id) {

            pinnedUsers.push(tempObject.pinnedUsers[pu]);

        }
    }


    ///remove reactions unnecessary user info
    if (tempObject.reactions) {
        for (let i = 0; i < tempObject.reactions.length; i++) {

            for (let u = 0; u < tempObject.reactions[i].users.length; u++) {

                tempObject.reactions[i].users[u] = removeUserFields(tempObject.reactions[i].users[u], true);

            }

        }
    }

    if (tempObject.reactionsPlus) {
        for (let i = 0; i < tempObject.reactionsPlus.length; i++) {

            if (tempObject.reactionsPlus[i].users != null && tempObject.reactionsPlus[i].users != undefined) {
                for (let u = 0; u < tempObject.reactionsPlus[i].users.length; u++) {

                    tempObject.reactionsPlus[i].users[u] = removeUserFields(tempObject.reactionsPlus[i].users[u], true);

                }
            }

        }
    }

    tempObject.ratchetIndexes = ratchetsForUser;
    tempObject.pinnedUsers = pinnedUsers;
    tempObject.creator = removeUserFields(tempObject.creator, true);
    tempObject.circle = removeCircleFields(tempObject.circle);

    if (tempObject.lastEdited != undefined && tempObject.lastEdited != null) {
        tempObject.lastEdited = removeUserFields(tempObject.lastEdited, false);
    }

    if (tempObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLELIST) {

        if (tempObject.list.lastEdited != undefined)
            tempObject.list.lastEdited = removeUserFields(tempObject.list.lastEdited, false);


    } else if (tempObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEEVENT) {
        if (tempObject.event.lastEdited != undefined)
            tempObject.event.lastEdited = removeUserFields(tempObject.event.lastEdited, false);
    }

    return tempObject;

}

async function stripReplyFields(replyObject, circleObjectSeed) {

    let tempObject = await ReplyObject.baseNew(replyObject);

    ///just for sending notification
    tempObject.seed = circleObjectSeed;

    return tempObject;
}

function removeCircleFields(circle) {

    delete circle.type;
    delete circle.ownershipModel;
    delete circle.privacyVotingModel;
    delete circle.privacyShareImage;
    delete circle.privacyShareURL;
    delete circle.privacyShareGif;
    delete circle.privacyCopyText;
    delete circle.securityVotingModel;
    delete circle.securityMinPassword;
    delete circle.security2FA;
    delete circle.securityDaysPasswordValid;

    delete circle.securityTokenExpirationDays;
    delete circle.securityLoginAttempts;
    delete circle.owner;
    delete circle.created;
    delete circle.lastUpdate;

    delete circle.retention;
    delete circle.privacyDisappearingTimer;
    delete circle.privacyDisappearingTimerSeconds;


    return circle;
}

function removeUserFields(user, keepAvatar) {
    user.devices = [];
    user.passwordHelpers = [];
    user.blockedList = [];
    user.allowedList = [];

    delete user.passwordExpired;
    delete user.loginAttempts;
    delete user.loginAttemptsExceeded;
    delete user.autoKeychainBackup;
    delete user.tokenExpired;
    delete user.lockedOut;
    delete user.securityMinPassword;
    delete user.securityDaysPasswordValid;
    delete user.securityTokenExpirationDays;
    delete user.securityLoginAttempts;
    delete user.keyGen;
    delete user.blockedEnabled;
    delete user.password;
    delete user.resetCodeAttemptsExceeded;
    delete user.avatar;
    delete user.allowClosed;
    delete user.security2FA;
    delete user.passwordChangedOn;
    delete user.coinLedger;
    delete user.ironCoin;
    //delete user.over18;
    //delete user.accountType;
    delete user.tos;
    delete user.lastKeyBackup;
    delete user.created;
    delete user.lastUpdate;
    delete user.ratchetPublicKey;
    delete user.lowercase;
    delete user.accountType;
    delete user.guaranteedUnique;
    delete user.hostedFurnace;
    delete user.submitLogs;
    delete user.passwordBeforeChange;
    delete user.passwordResetRequired;
    delete user.loginAttemptsLastFailed;
    delete user.reservedUsername;
    delete user.role;
    delete user.minor;
    delete user.accountRecovery;
    delete user.joinBeta;



    return user;
}

function stripObject(object) {
    //used when sending a push notification failed because the object was too large
    delete object.list;
    delete object.recipe;
    delete object.event;
    delete object.vote;
    delete object.body;
    delete object.ratchetIndexes;
    delete object.senderRatchetPublic;
    delete object.crank;
    delete object.signature;

    return object;
}


// async function sendAndroidNotification(notification, object, device, circleID, notificationType, userID, creatorID, circleObjectReaction) {

//     try {

//         //TODO - Store this APU key somewhere safe
//         //let sender = new gcm.Sender('AAAAcRvIRXw:APA91bHn3TunFugAU-vFFnOT4Ko1vS0WxHH32RLRt23bCxDKCVfa7tGG1JHrRcdjOcJdjKUkkFIVrhTtl9ynPyP3Ip7nx9tX3pA4Rw0u_pq8CjmYdUM_NPluJ4nbKp23OC4_SvzHboR8');
//         let sender = new gcm.Sender('AAAAcRvIRXw:APA91bGDGN9y5P2aSZgH37M3XZuDg9s-FhyxkAmcFft4xbZkQR99sjYH-1LSNEDkte3AZRb2dlX3jEGENXhQcSEMtg3KJraTkdIYmZAzASebVpXsYC89JuWvCyOR_P37bgJIx3dOhFDO');

//         let notificationLog;
//         if (notificationType == constants.NOTIFICATION_TYPE.REPLY) {
//             notificationLog = await saveNotification(notification, null, device, circleID, notificationType, userID, creatorID);
//         } else {
//             notificationLog = await saveNotification(notification, object, device, circleID, notificationType, userID, creatorID);
//         }


//         let tokens = [device.pushToken];

//         if (tokens.length == 0) {
//             console.log('token not found');
//             failNotificationLog(notificationLog, 'token not found');
//             return;
//         }

//         //remove this once everyone is higher than v21
//         if (!device.build) {
//             if (notification == "Member deleted ironclad message")
//                 notification = "User deleted item in Circle";
//             if (notification == "New ironclad message" || notification == "Member updated ironclad message")
//                 notification = "New activity in IronCircles";
//         }

//         var nType;

//         if (notificationType == undefined)
//             nType = getNotificationType(notification);
//         else
//             nType = notificationType;


//         console.log(notification);
//         console.log(nType);

//         let message;

//         if (nType == constants.NOTIFICATION_TYPE.REPLY_REACTION) {
//             //object and reaction
//             message = new gcm.Message({
//                 priority: 'high',
//                 contentAvailable: true,
//                 delayWhileIdle: false,
//                 data: {
//                     notificationType: nType,
//                     object: object,
//                     reaction: circleObjectReaction,
//                     id: randomstring.generate({
//                         length: 40,
//                         charset: 'alphabetic'
//                     })
//                 }, 
//                 notification: {
//                     priority: 'high',
//                     title: "IronCircles",
//                     body: notification,
//                     sound: 'default',
//                     click_action: 'FLUTTER_NOTIFICATION_CLICK',
//                 }
//             });

//         } else if (circleObjectReaction != null &&
//             circleObjectReaction != undefined && device.build >= 136) {
//             let reactor = await User.findById(creatorID);
//             let reaction = new CircleObjectReaction({
//                 users: [new User({ _id: creatorID, username: reactor.username })],
//                 index: circleObjectReaction.index,
//                 emoji: circleObjectReaction.emoji,
//             });
//             //await reaction.populate("users");
//             message = new gcm.Message({
//                 //collapseKey: collapseKey,
//                 //'collapse_key': collapseKey,
//                 priority: 'high',
//                 //senderID: "485797414268",   
//                 //contentAvailable: true,
//                 contentAvailable: true,
//                 delayWhileIdle: false,
//                 data: {
//                     //body: body,
//                     notificationType: nType,
//                     reaction: reaction,
//                     objectID: object._id,
//                     id: randomstring.generate({
//                         length: 40,
//                         charset: 'alphabetic'
//                     })
//                 },
//                 notification: {
//                     //collapseKey: collapseKey,
//                     //contentAvailable: true,
//                     priority: 'high',
//                     title: "IronCircles",
//                     body: notification,
//                     sound: 'default',
//                     //tag: collapseKey,
//                     click_action: 'FLUTTER_NOTIFICATION_CLICK',
//                 }
//             });

//         } else {
//             message = new gcm.Message({
//                 //collapseKey: collapseKey,
//                 //'collapse_key': collapseKey,
//                 priority: 'high',
//                 //senderID: "485797414268",   
//                 //contentAvailable: true,
//                 contentAvailable: true,
//                 delayWhileIdle: false,
//                 data: {
//                     //body: body,
//                     notificationType: nType,
//                     object: object,
//                     id: randomstring.generate({
//                         length: 40,
//                         charset: 'alphabetic'
//                     })
//                 },
//                 notification: {
//                     //collapseKey: collapseKey,
//                     //contentAvailable: true,
//                     priority: 'high',
//                     title: "IronCircles",
//                     body: notification,
//                     sound: 'default',
//                     //tag: collapseKey,
//                     click_action: 'FLUTTER_NOTIFICATION_CLICK',
//                 }
//             });
//         }

//         //console.log(message.size());

//         sender.send(message, { registrationTokens: tokens }, function (err, response) {

//             if (err)
//                 console.error(err);
//             else {
//                 console.log(response);

//                 var tooLargeTokens = tokens.filter((token, i) => response.results[i].error == "MessageTooBig");
//                 //var failed_tokens = tokens.filter((token, i) => response.results[i].error != null);
//                 if (tooLargeTokens.length > 0) {
//                     console.log('content too large');
//                     failNotificationLog(notificationLog, 'content too large');
//                     //send old school style
//                     deviceLogic.sendAndroidSingleDeviceRefreshNeeded(notification, object._id, circleID, [device], stripObject(object), notificationType);
//                 }

//                 var notRegisteredTokens = tokens.filter((token, i) => response.results[i].error == "NotRegistered");
//                 //var failed_tokens = tokens.filter((token, i) => response.results[i].error != null);
//                 if (notRegisteredTokens.length > 0) {
//                     console.log('not registered');
//                     failNotificationLog(notificationLog, 'not registered');
//                     //send old school style
//                     deviceLogic.removeFailedTokens(notRegisteredTokens);
//                 }


//             }
//         });

//     } catch (err) {
//         var msg = await logUtil.logError(err, false);
//         throw (err);
//     }

//     return;
// }


async function sendNotification(notification, object, device, circleID, notificationType, userID, creatorID, circleObjectReaction) {

    try {


        let notificationLog;
        if (notificationType == constants.NOTIFICATION_TYPE.REPLY) {
            notificationLog = await saveNotification(notification, null, device, circleID, notificationType, userID, creatorID);
        } else {
            notificationLog = await saveNotification(notification, object, device, circleID, notificationType, userID, creatorID);
        }

        if (device.pushToken == null) {
            console.log('token not found');
            failNotificationLog(notificationLog, 'token not found');
            return;
        }

        //remove this once everyone is higher than v21
        if (!device.build) {
            if (notification == "Member deleted ironclad message")
                notification = "User deleted item in Circle";
            if (notification == "New ironclad message" || notification == "Member updated ironclad message")
                notification = "New activity in IronCircles";
        }

        let messageCount = 0;

        if (device.platform == 'iOS' || device.platform == 'macos') {

            messageCount = await deviceLogic.countAvailableMessages(userID);
        }

        var nType;

        if (notificationType == undefined)
            nType = getNotificationType(notification);
        else
            nType = notificationType;


        // console.log(notification);
        // console.log(nType);

        let message;

        if (nType == constants.NOTIFICATION_TYPE.REPLY_REACTION) {
            //object and reaction

            message = {
                data: {
                    notificationType: nType.toString(),
                    object: JSON.stringify(object),
                    reaction: JSON.stringify(circleObjectReaction),
                    id: randomstring.generate({
                        length: 40,
                        charset: 'alphabetic'
                    })
                },
                android: {
                    priority: 'high',
                    notification: {
                        clickAction: 'FLUTTER_NOTIFICATION_CLICK'
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            category: "FLUTTER_NOTIFICATION_CLICK"
                        }
                    },
                    headers: {
                        "apns-priority": "10", // Must be `5` when `contentAvailable` is set to true.
                    },
                },
                notification: {
                    title: "IronCircles",
                    body: notification,
                },
                token: device.pushToken
            };
        } else if (circleObjectReaction != null &&
            circleObjectReaction != undefined && device.build >= 136) {
            let reactor = await User.findById(creatorID);
            let reaction = new CircleObjectReaction({
                users: [new User({ _id: creatorID, username: reactor.username })],
                index: circleObjectReaction.index,
                emoji: circleObjectReaction.emoji,
            });

            message = {
                data: {
                    notificationType: nType.toString(),
                    //object: JSON.stringify(object),
                    reaction: JSON.stringify(reaction),
                    objectID: object._id,
                    id: randomstring.generate({
                        length: 40,
                        charset: 'alphabetic'
                    })
                },
                android: {
                    priority: 'high',
                    notification: {
                        clickAction: 'FLUTTER_NOTIFICATION_CLICK'
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            category: "FLUTTER_NOTIFICATION_CLICK"
                        }
                    },
                    headers: {
                        "apns-priority": "10", // Must be `5` when `contentAvailable` is set to true.
                    },
                },
                notification: {
                    title: "IronCircles",
                    body: notification,
                },
                token: device.pushToken
            };

        } else {
            message = {
                data: {
                    notificationType: nType.toString(),
                    object: JSON.stringify(object),
                    id: randomstring.generate({
                        length: 40,
                        charset: 'alphabetic'
                    })
                },
                android: {
                    priority: 'high',
                    notification: {
                        clickAction: 'FLUTTER_NOTIFICATION_CLICK'
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            contentAvailable: true,
                            badge: messageCount,
                            //sound: "default",
                            category: "FLUTTER_NOTIFICATION_CLICK"
                        }
                    },
                    headers: {
                        "apns-priority": "10", // Must be `5` when `contentAvailable` is set to true.
                    },
                },
                notification: {
                    title: "IronCircles",
                    body: notification,
                },
                token: device.pushToken
            };
        }

        //console.log(message.size());
        //console.log(message);

        let result = await deviceLogic.firebaseAdmin.messaging().send(message);

        //console.log('Successfully sent message:', result);



        // deviceLogic.firebaseAdmin.messaging().send(message)
        //     .then((response) => {
        //         // Response is a message ID string.
        //         console.log('Successfully sent message:', response);
        //     })
        //     .catch((error) => {
        //         logUtil.logError(error, false);
        //         //console.log('Error sending message:', error);
        //         if (error == "Requested entity was not found."){
        //             //console.log('Token not found: ' + token);
        //             module.exports.removeFailedTokens([token]);
        //         }
        //     });


        // sender.send(message, { registrationTokens: tokens }, function (err, response) {

        //     if (err)
        //         console.error(err);
        //     else {
        //         console.log(response);

        //         var tooLargeTokens = tokens.filter((token, i) => response.results[i].error == "MessageTooBig");
        //         //var failed_tokens = tokens.filter((token, i) => response.results[i].error != null);
        //         if (tooLargeTokens.length > 0) {
        //             console.log('content too large');
        //             failNotificationLog(notificationLog, 'content too large');
        //             //send old school style
        //             deviceLogic.sendAndroidSingleDeviceRefreshNeeded(notification, object._id, circleID, [device], stripObject(object), notificationType);
        //         }

        //         var notRegisteredTokens = tokens.filter((token, i) => response.results[i].error == "NotRegistered");
        //         //var failed_tokens = tokens.filter((token, i) => response.results[i].error != null);
        //         if (notRegisteredTokens.length > 0) {
        //             console.log('not registered');
        //             failNotificationLog(notificationLog, 'not registered');
        //             //send old school style
        //             deviceLogic.removeFailedTokens(notRegisteredTokens);
        //         }


        //     }
        // });

    } catch (err) {


        if (err.message == "Requested entity was not found." || err.message == "The registration token is not a valid FCM registration token") {
            deviceLogic.removeFailedTokens([device.pushToken]);

            //} else if (err.message == "Android message is too big" || err.message == "iOS message is too big") {
        } else if (err.message.includes("message is too big")) {
            deviceLogic.sendAndroidSingleDeviceRefreshNeeded(notification, object._id, circleID, [device], stripObject(object), notificationType);


        } else {

            var msg = await logUtil.logError(err, false);
        }
    }

    return;
}

async function saveNotification(notification, object, device, circleID, notificationType, userID, creatorID) {

    try {
        let notificaitonLog = new NotificationLog({ user: userID, sender: creatorID, notification: notification, type: notificationType, device: device.uuid, pushToken: device.pushToken });

        if (circleID != null) {
            notificaitonLog.circle = circleID;
        }

        if (object != null) {

            notificaitonLog.object = JSON.stringify(object);
            //let tempObject = JSON.parse(object);
            notificaitonLog.circleObject = object;
        }
        await notificaitonLog.save();

        return notificaitonLog;
    } catch (err) {
        var msg = await logUtil.logError(err, false);

    }
}

async function failNotificationLog(notificationLog, reason) {
    notificationLog.success = false;
    notificationLog.error = reason;
    await notificationLog.save();
}

// async function sendiOSNotification(notification, object, device, circleID, notificationType, userID, creatorID, circleObjectReaction) {

//     try {

//         //TODO - Store this APU key somewhere safe
//         //let sender = new gcm.Sender('AAAAcRvIRXw:APA91bHn3TunFugAU-vFFnOT4Ko1vS0WxHH32RLRt23bCxDKCVfa7tGG1JHrRcdjOcJdjKUkkFIVrhTtl9ynPyP3Ip7nx9tX3pA4Rw0u_pq8CjmYdUM_NPluJ4nbKp23OC4_SvzHboR8');
//         let sender = new gcm.Sender('AAAAcRvIRXw:APA91bGDGN9y5P2aSZgH37M3XZuDg9s-FhyxkAmcFft4xbZkQR99sjYH-1LSNEDkte3AZRb2dlX3jEGENXhQcSEMtg3KJraTkdIYmZAzASebVpXsYC89JuWvCyOR_P37bgJIx3dOhFDO');

//         let tokens = [device.pushToken];

//         let notificationLog = await saveNotification(notification, object, device, circleID, notificationType, userID, creatorID);


//         if (tokens.length == 0) {
//             console.log('token not found');
//             failNotificationLog(notificationLog, 'token not found');
//             return;
//         }



//         /*if (userID == '63190d18fcb3d200150697b6' || userID.equals('63190d18fcb3d200150697b6')) {
//             console.log('send message to flybacon');
//             console.log('notifcation' + notification + ", device:" + device);
//             console.log(object);
//         }
//         */

//         //remove this once everyone is higher than v21
//         if (!device.build) {
//             if (notification == "Member deleted ironclad message")
//                 notification = "User deleted item in Circle";
//             if (notification == "New ironclad message" || notification == "Member updated ironclad message")
//                 notification = "New activity in IronCircles";
//         }

//         var nType;

//         if (notificationType == undefined)
//             nType = getNotificationType(notification);
//         else
//             nType = notificationType;


//         let messageCount = 0;

//         if (device.build > 80)
//             messageCount = await deviceLogic.countAvailableMessages(userID);


//         console.log(notification);
//         console.log(nType);

//         let message;

//         if (nType == constants.TAG_TYPE.REPLY_REACTION) {
//             //object and reaction
//             message = new gcm.Message({
//                 priority: 'high',
//                 contentAvailable: true,
//                 delayWhileIdle: false,
//                 title: "IronCircles",
//                 'content-available': true,
//                 'content_available': true,
//                 data: {
//                     title: "IronCircles",
//                     notificationType: nType,
//                     object: object,
//                     reaction: circleObjectReaction,
//                     id: randomstring.generate({
//                         length: 40,
//                         charset: 'alphabetic'
//                     })
//                 },
//                 notification: {
//                     'content-available': true,
//                     'content_available': true,
//                     badge: messageCount,
//                     priority: 'high',
//                     title: "IronCircles",
//                     body: notification,
//                     sound: 'default',
//                     click_action: 'FLUTTER_NOTIFICATION_CLICK',
//                 }
//             });

//         } else if (circleObjectReaction != null &&
//             circleObjectReaction != undefined && device.build >= 136) {

//             let reactor = await User.findById(creatorID);
//             let reaction = new CircleObjectReaction({
//                 users: [new User({ _id: creatorID, username: reactor.username })],
//                 index: circleObjectReaction.index,
//                 emoji: circleObjectReaction.emoji,
//             });
//             //await reaction.populate("users");

//             message = new gcm.Message({
//                 //collapseKey: collapseKey,
//                 contentAvailable: true,
//                 delayWhileIdle: false,
//                 priority: 'high',
//                 title: "IronCircles",

//                 //contentAvailable: true,
//                 'content-available': true,
//                 'content_available': true,
//                 data: {
//                     title: "IronCircles",
//                     //body: body,
//                     notificationType: nType,
//                     //click_action: 'FLUTTER_NOTIFICATION_CLICK',
//                     reaction: reaction,
//                     objectID: object._id,
//                     id: randomstring.generate({
//                         length: 40,
//                         charset: 'alphabetic'
//                     })
//                 },

//                 notification: {
//                     priority: 'high',
//                     //contentAvailable: true,
//                     'content-available': true,
//                     'content_available': true,
//                     title: "IronCircles",
//                     body: notification,
//                     badge: messageCount,
//                     sound: 'default',
//                     click_action: 'FLUTTER_NOTIFICATION_CLICK',
//                 }

//             });

//         } else {
//             message = new gcm.Message({
//                 //collapseKey: collapseKey,
//                 contentAvailable: true,
//                 delayWhileIdle: false,
//                 priority: 'high',
//                 title: "IronCircles",

//                 //contentAvailable: true,
//                 'content-available': true,
//                 'content_available': true,
//                 data: {
//                     title: "IronCircles",
//                     //body: body,
//                     notificationType: nType,
//                     //click_action: 'FLUTTER_NOTIFICATION_CLICK',
//                     object: object,
//                     id: randomstring.generate({
//                         length: 40,
//                         charset: 'alphabetic'
//                     })
//                 },

//                 notification: {
//                     priority: 'high',
//                     //contentAvailable: true,
//                     'content-available': true,
//                     'content_available': true,
//                     title: "IronCircles",
//                     body: notification,
//                     badge: messageCount,
//                     sound: 'default',
//                     click_action: 'FLUTTER_NOTIFICATION_CLICK',
//                 }

//             });
//         }

//         sender.send(message, { registrationTokens: tokens }, function (err, response) {

//             if (err)
//                 console.error(err);
//             else {
//                 console.log(response);
//                 var failed_tokens = tokens.filter((token, i) => response.results[i].error == "MessageTooBig");
//                 if (failed_tokens.length > 0) {
//                     failNotificationLog(notificationLog, 'content too large');
//                     console.log('content too large');
//                     //send old school style
//                     deviceLogic.sendiOSSingleDeviceRefreshNeeded(notification, object._id, circleID, [device], stripObject(object), notificationType);

//                 }

//                 var notRegisteredTokens = tokens.filter((token, i) => response.results[i].error == "NotRegistered");
//                 if (notRegisteredTokens.length > 0) {
//                     console.log('not registered');
//                     failNotificationLog(notificationLog, 'not registered');
//                     //send old school style
//                     deviceLogic.removeFailedTokens(notRegisteredTokens);
//                 }
//             }
//         });

//     } catch (err) {
//         var msg = await logUtil.logError(err, false);
//         throw (err);
//     }

//     return;
// }

function getNotificationType(notification) {

    //TODO This can go away once everyone is on v62
    if (notification == 'New activity in IronCircles'
        || notification == 'New ironclad message'
        || notification == 'Member reacted to your ironclad message'
        || notification == 'Member updated ironclad message'
        || notification == 'Message removed by IronCircles'
    )
        return constants.NOTIFICATION_TYPE.MESSAGE;


    if (notification == 'New ironclad event'
        || notification == 'Member updated ironclad event'
    )
        return constants.NOTIFICATION_TYPE.EVENT;

    if (notification == 'User deleted item in Circle'
        || notification == 'Member deleted ironclad message'
    )
        return constants.NOTIFICATION_TYPE.DELETE;

    if (notification == 'New invitation in IronCircles')
        return constants.NOTIFICATION_TYPE.INVITATION;

    if (notification == 'Action needed in IronCircles')
        return constants.NOTIFICATION_TYPE.ACTION_NEEDED;

}