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

const Device = require('../models/device');
const User = require('../models/user');
const UserCircle = require('../models/usercircle');
const Circle = require('../models/circle');
const CircleObject = require('../models/circleobject');
const ReminderTracker = require('../models/remindertracker');
const DeviceRemoteWipe = require('../models/deviceremotewipe');
const userCircleLogic = require('../logic/usercirclelogic');
const systemMessageLogic = require('../logic/systemmessagelogic');
const NotificationLog = require('../models/notificationlog');
const ObjectId = require('mongodb').ObjectId;
const gcm = require('node-gcm');
var randomstring = require("randomstring");
const logUtil = require('../util/logutil');
const constants = require('../util/constants');
const device = require('../models/device');
const ReplyObject = require('../models/replyobject');
const firebase = require('firebase-admin');
const serviceAccount = require('../ironfurnace-a10e7-firebase-adminsdk-p35g8-8cae172dc5.json');

firebase.initializeApp({ credential: firebase.credential.cert(serviceAccount) });

module.exports.firebaseAdmin = firebase;

module.exports.wipeDevice = async function (userID, uuid) {

    try {

        let user = await User.findById(userID);

        if (!user || !(user instanceof User))
            throw new Error('Unauthorized');

        //is this user authorized to wipe this device?
        let deviceRemoteWipe = await DeviceRemoteWipe.findOne({ 'users': user._id, uuid: uuid }).populate('deviceOwner');

        if (!deviceRemoteWipe || !(deviceRemoteWipe instanceof DeviceRemoteWipe))
            throw new Error('Unauthorized');

        let device = null;

        for (let i = 0; i < deviceRemoteWipe.deviceOwner.devices.length; i++) {

            if (deviceRemoteWipe.deviceOwner.devices[i].uuid == uuid) {
                device = deviceRemoteWipe.deviceOwner.devices[i];
                break;
            }
        }

        if (device != null) {
            ///delete any UserCircle ratchetKeys using this device id
            await UserCircle.updateMany({ 'user': deviceRemoteWipe.deviceOwner._id }, { $pull: { 'ratchetPublicKeys': { user: deviceRemoteWipe.deviceOwner._id, device: device.uuid } } });
            ///Leave the keys in case the user decides to log into the device again
            //await CircleObject.updateMany({ $pull: { ratchetIndexes: { device: device.uuid } } });

            if (device.platform == 'iOS' || device.platform == 'macos')
                await this.sendiOSSingleDevice('', deviceRemoteWipe.code, '', device, constants.NOTIFICATION_TYPE.DEVICE_WIPE);
            else
                await this.sendAndroidSingleDevice('', deviceRemoteWipe.code, '', device, constants.NOTIFICATION_TYPE.DEVICE_WIPE);

            device.pushToken = null;
            device.activated = false;
            device.wiped = true;

            user.markModified('devices');
            await user.save();

            return device;
        }

    } catch (err) {
        var msg = await logUtil.logError(err, false);
        throw (err);
    }


}

module.exports.deactivateDevice = async function (userID, uuid) {

    try {
        let user = await User.findById(userID);

        if (!user || !(user instanceof User))
            throw new Error('Unauthorized');

        //ensure this device belongs to this user
        var device = null;

        for (let i = 0; i < user.devices.length; i++) {

            if (user.devices[i].uuid == uuid) {
                device = user.devices[i];
                break;
            }
        }

        if (device != null) {

            //find the authorization code
            let deviceRemoteWipe = await DeviceRemoteWipe.findOne({ 'users': user._id, uuid: uuid }).populate('deviceOwner');

            if (!deviceRemoteWipe || !(deviceRemoteWipe instanceof DeviceRemoteWipe))
                throw new Error('Unauthorized');

            ///delete any UserCircle ratchetKeys using this device id
            await UserCircle.updateMany({ 'user': user._id, circle: { $ne: null }, removeFromCache: null }, { $pull: { 'ratchetPublicKeys': { user: user._id, device: device.uuid } } });

            if (device.platform == 'iOS' || device.platform == 'macos')
                await this.sendiOSSingleDevice('Device deactivated', deviceRemoteWipe.code, '', device, constants.NOTIFICATION_TYPE.DEVICE_DEACTIVATED);
            else
                await this.sendAndroidSingleDevice('Device deactivated', deviceRemoteWipe.code, '', device, constants.NOTIFICATION_TYPE.DEVICE_DEACTIVATED);

            device.pushToken = null;
            device.activated = false;
            user.markModified('devices');
            await user.save();

            return device;

        } else {
            throw new Error("Device not found");
        }

    } catch (err) {
        var msg = await logUtil.logError(err, false);
        throw (err);
    }


}

/*
module.exports.deleteDevicesByToken = function (deviceToken) {
 
    //TODO rewrite this using promises
    try {
 
        //remove this device from all users
        User.find({}, function (err, users) {   //this isn't empty, there is a populate below
 
            if (err || !users) {
                console.error(err);
                return;
            }
 
            users.forEach(function (user) {
 
                user.devices.forEach(function (device) {
 
                    user.update({ $pull: { devices: device._id } }, function (err) {
 
                        if (err)
                            console.error(err);
                        else
                            console.log('Device:' + device._id + ' and pushToken:' + deviceToken + ' removed.')
 
                    });
 
 
                });
 
            });
 
 
            //remove any devices from the Devices collection
            Device.deleteMany({ "token": deviceToken }, function (err, devices) {
                if (err || !devices)
                    return;
 
            });
 
 
        }).populate({ path: "devices", match: { pushToken: deviceToken } });
    } catch (err) {
        var msg = await logUtil.logError(err, false);
        return;
    }
 
 
}*/

async function updateLinkedUsers(user, uuid, pushToken, platform, build, model, oldID) {

    let updated = false;

    let linkedUsers = await User.find({ linkedUser: user._id });

    //also update any linked users
    for (let u = 0; u < linkedUsers.length; u++) {
        let linkedUser = linkedUsers[u];
        for (let j = 0; j < linkedUser.devices.length; j++) {

            if (linkedUser.devices[j].uuid == uuid || linkedUser.devices[j].uuid == oldID) {
                linkedUser.devices[j].uuid = uuid;
                linkedUser.devices[j].lastUpdate = Date.now();
                linkedUser.devices[j].activated = true;
                linkedUser.devices[j].wiped = false;
                linkedUser.devices[j].loggedIn = true;
                linkedUser.devices[j].build = build;
                linkedUser.devices[j].platform = platform;
                linkedUser.devices[j].model = model;
                linkedUser.devices[j].pushToken = pushToken;

                await linkedUser.save();
                updated = true;

            }
        }
    }

    return updated;

}

///This should only be called when initializing kyber for an ios user
module.exports.updateDevice = async function (user, pushToken, platform, uuid, build, model, identity, oldID) {
    var deviceUpdated = false;

    try {

        ///if the device is already in the user's list, update it
        for (let i = 0; i < user.devices.length; i++) {

            if (user.devices[i].uuid == uuid || user.devices[i].uuid == oldID) {

                let device = user.devices[i];
                device.uuid = uuid;
                device.pushToken = pushToken;
                device.identity = identity;
                device.model = model;
                device.platform = platform;
                build = build;
                loggedIn = true;

                await user.save();
                deviceUpdated = true;
                break;
            }
        }


        if (deviceUpdated == false) {
            ///not found so add it
            let device = new Device({
                uuid: uuid,
                pushToken: pushToken,
                model: model,
                identity: identity,
                platform: platform,
                build: build,
                loggedIn: true
            });

            user.devices.push(device);
            await user.save();
            deviceUpdated = true;
        }

        if (deviceUpdated == true) {
            await updateLinkedUsers(user, uuid, pushToken, platform, build, model, oldID);
        }


    } catch (err) {
        await logUtil.logError(err, false);
        return false;
    }

    return deviceUpdated;
}


module.exports.registerDevice = async function (owner, pushToken, platform, uuid, build, model, identity) {

    try {

        //if (!pushToken) return;

        //does this device exist?
        var user = await User.findOne({ _id: owner });
        let linkedUsers = await User.find({ linkedUser: user._id });

        if (!(user instanceof User)) throw ("user not found");

        let found = false;
        for (let i = 0; i < user.devices.length; i++) {

            //match the deviceID
            if (user.devices[i].uuid == uuid) {

                //does the pushToken and model match and platform match?
                if (user.devices[i].pushToken != pushToken || user.devices[i].model != model || user.devices[i].platform != platform) {
                    user.devices[i].pushToken = pushToken;
                    user.devices[i].model = model;
                    user.devices[i].activated = true;
                    user.devices[i].wiped = false;
                    user.devices[i].loggedIn = true;
                    user.devices[i].build = build;
                    user.devices[i].platform = platform;
                    await user.save();

                    //also update any linked users
                    for (let u = 0; u < linkedUsers.length; u++) {
                        let linkedUser = linkedUsers[u];

                        for (let j = 0; j < linkedUser.devices.length; j++) {

                            if (linkedUser.devices[j].uuid == user.devices[i].uuid) {
                                linkedUser.devices[j].pushToken = pushToken;
                                linkedUser.devices[j].model = model;
                                linkedUser.devices[j].activated = true;
                                linkedUser.devices[j].wiped = false;
                                linkedUser.devices[j].loggedIn = true;
                                linkedUser.devices[j].build = build;
                                linkedUser.devices[j].platform = platform;

                                await linkedUser.save();

                            }
                        }
                    }


                    console.log('Device pushToken updated ' + uuid + '   ' + pushToken);
                } else {
                    user.devices[i].lastUpdate = Date.now();
                    user.devices[i].activated = true;
                    user.devices[i].wiped = false;
                    user.devices[i].loggedIn = true;
                    user.devices[i].build = build;
                    user.devices[i].platform = platform;
                    user.devices[i].model = model;
                    await user.save();

                    //also update any linked users
                    for (let u = 0; u < linkedUsers.length; u++) {
                        let linkedUser = linkedUsers[u];

                        let linkedFound = false;

                        for (let j = 0; j < linkedUser.devices.length; j++) {

                            if (linkedUser.devices[j].uuid == uuid) {
                                linkedUser.devices[j].lastUpdate = Date.now();
                                linkedUser.devices[j].activated = true;
                                linkedUser.devices[j].wiped = false;
                                linkedUser.devices[j].loggedIn = true;
                                linkedUser.devices[j].build = build;
                                linkedUser.devices[j].platform = platform;
                                linkedUser.devices[j].model = model;

                                await linkedUser.save();

                                linkedFound = true;

                            }
                        }

                        if (!linkedFound) {
                            await logUtil.logAlert('could not find linked device so added one:' + linkedUser._id + " : " + uuid + " : " + pushToken);

                            let device = new Device({
                                uuid: uuid,
                                pushToken: pushToken,
                                model: model,
                                identity: identity,
                                platform: platform,
                                build: build,
                                loggedIn: true
                            });

                            linkedUser.devices.push(device);
                            await linkedUser.save();
                        }
                    }



                }

                found = true;
                break;

            } else if (pushToken != '' && pushToken != null && pushToken != undefined && user.devices[i].pushToken == pushToken) {  //does the pushToken match?

                await logUtil.logAlert('user updated device with a duplicate pushtoken:' + user._id + " old uuid: " + user.devices[i].uuid + " new uuid: " + uuid + " : " + pushToken);
                user.devices[i].uuid = uuid;
                user.devices[i].model = model;
                user.devices[i].activated = true;
                user.devices[i].wiped = false;
                user.devices[i].build = build,
                    user.devices[i].loggedIn = true;
                await user.save();
                //console.log('Device uuid updated ' + uuid + '   ' + pushToken);

                found = true;
                break;


            }

        }

        if (found == false) {

            let device = new Device({
                uuid: uuid,
                pushToken: pushToken,
                model: model,
                identity: identity,
                platform: platform, build: build, loggedIn: true
            });

            user.devices.push(device);

            // save the user
            await user.save();

            await notifyNetworksOfDeviceChange(user, device);


            let deviceRemoteWipe = DeviceRemoteWipe({
                users: [user], deviceOwner: user, uuid: device.uuid, code: randomstring.generate({
                    length: 80,
                    charset: 'alphabetic'
                })
            });

            await deviceRemoteWipe.save();

            console.log('Device added ' + device.uuid);

            //also add the device to linked users
            for (let i = 0; i < linkedUsers.length; i++) {

                let device = new Device({
                    uuid: uuid,
                    pushToken: pushToken,
                    identity: identity,
                    model: model,
                    platform: platform, build: build, loggedIn: true
                });

                linkedUsers[i].devices.push(device);
                await linkedUsers[i].save();

                await notifyNetworksOfDeviceChange(linkedUsers[i], device);
            }



        }


        //sanity check device for linked users
        for (let i = 0; i < user.devices.length; i++) {
            let device = user.devices[i];

            for (let j = 0; j < linkedUsers.length; j++) {

                let linkedUser = linkedUsers[j];

                for (let k = 0; k < linkedUser.devices.length; k++) {

                    if (linkedUser.devices[k].uuid == device.uuid) {
                        found = true;
                    }
                }

                if (!found) {

                    let device = new Device({
                        uuid: uuid,
                        pushToken: pushToken,
                        identity: identity,
                        model: model,
                        platform: platform, build: build, loggedIn: true
                    });

                    linkedUser.devices.push(device);
                    await linkedUser.save();

                    //await notifyNetworksOfDeviceChange(linkedUser, device);
                }

            }
        }


        //return the opposite of found. Calling functions are check for deviceUpdate == true
        return !found;


    } catch (err) {
        await logUtil.logError(err, false);
        return false;
    }

}

notifyNetworksOfDeviceChange = async function (user, device) {


    try {
        let userCircles = await UserCircle.find({ user: user._id, removeFromCache: null });

        let includedCircles = [];

        for (let i = 0; i < userCircles.length; i++) {

            let otherCount = await UserCircle.countDocuments({ circle: userCircles[i].circle, removeFromCache: null, user: { $ne: user._id } });

            if (otherCount > 0) {

                if (!includedCircles.includes(userCircles[i].circle)) {
                    includedCircles.push(userCircles[i].circle);
                    logUtil.logAlert(user.username + ' added a new device (' + device.model + ')');
                    //TODO uncomment below after testing
                    //systemMessageLogic.sendMessage(userCircles[i].circle, user.username + ' added a new device (' + device.model + ')');
                }
            }

        }
    }
    catch (err) {
        await logUtil.logError(err, false);
    }

}

module.exports.sendNotification = async function (userID, notification, notificationType) {

    try {

        let devices = await loadUserDevices(userID, null);

        if (!devices) throw ('Could not load devices for user ' + userID);

        // console.log(userID);
        // console.log(devices[0].length);
        // console.log(notification);

        if (devices[0].length > 0) {
            sendNotification(notification, userID, '', devices[0], 'IronCircles', notificationType);

        }

        if (devices[1].length > 0) {
            sendNotification(notification, userID, '', devices[1], 'IronCircles', notificationType);
        }

    } catch (err) {
        await logUtil.logError(err, false);
        return;
    }

}

module.exports.sendInvitation = async function (userID, notification, invitation) {

    try {

        let tempObject = JSON.parse(JSON.stringify(invitation));
        tempObject.invitee = removeUserFields(tempObject.invitee);
        tempObject.inviter = removeUserFields(tempObject.inviter);
        tempObject.circle = removeCircleFields(tempObject.circle);

        let oldNotification = 'New invitation in IronCircles';

        if (!notification)
            notification = oldNotification;

        let notificationType = constants.NOTIFICATION_TYPE.INVITATION;

        let devices = await loadUserDevices(userID, null);

        if (!devices) throw ('Could not load devices for user ' + userID);

        // console.log(userID);
        // console.log(devices[0].length);
        // console.log(notification);

        if (devices[0].length > 0) {

            let splitDevices = splitDevicesByBuild(devices[0], 65);

            if (splitDevices[0].length > 0)
                sendNotification(oldNotification, userID, tempObject, splitDevices[0], 'invitation', notificationType);

            if (splitDevices[1].length > 0)
                sendNotification(notification, userID, tempObject, splitDevices[1], 'invitation', notificationType);

        }

        if (devices[1].length > 0) {
            let splitDevices = splitDevicesByBuild(devices[1], 65);

            if (splitDevices[0].length > 0)
                sendNotification(oldNotification, userID, tempObject, splitDevices[0], 'invitation', notificationType);

            if (splitDevices[1].length > 0)
                sendNotification(notification, userID, tempObject, splitDevices[1], 'invitation', notificationType);
        }

    } catch (err) {
        await logUtil.logError(err, false);
        return;
    }

}

module.exports.sendActionNeededNotification = async function (userID, notification) {

    try {

        let notificationType = constants.NOTIFICATION_TYPE.ACTION_NEEDED;

        let oldNotification = 'Action needed in IronCircles';

        if (!notification)
            notification = oldNotification;


        let devices = await loadUserDevices(userID, null);

        if (!devices) throw ('Could not load devices for user ' + userID);



        if (devices[0].length > 0) {

            let splitDevices = splitDevicesByBuild(devices[0], 65);

            if (splitDevices[0].length > 0)
                sendNotification(oldNotification, userID, '', splitDevices[0], 'action needed', notificationType);

            if (splitDevices[1].length > 0)
                sendNotification(notification, userID, '', splitDevices[1], 'action needed', notificationType);

        }

        if (devices[1].length > 0) {
            let splitDevices = splitDevicesByBuild(devices[1], 65);

            if (splitDevices[0].length > 0)
                sendNotification('Action needed in IronCircles', userID, '', splitDevices[0], notificationType);

            if (splitDevices[1].length > 0)
                sendNotification('Action needed in IronCircles', userID, '', splitDevices[1], notificationType);
        }



    } catch (err) {
        var msg = await logUtil.logError(err, false);
        return;
    }

}

module.exports.sendReminderToUser = async function (userID, objectID, reminderNotice, reminderType) {

    try {

        //has this already been sent for this user?

        let reminderTracker = await ReminderTracker.findOne({ objectID: objectID, 'user': userID, 'reminderType': reminderType });

        if (!reminderTracker) {
            let devices = await loadUserDevices(userID, null);

            if (!devices) return;//throw ('Could not load devices for user ' + userID);

            if (devices[0].length > 0)
                sendNotification(reminderNotice, userID, '', devices[0], 'reminder');

            if (devices[1].length > 0)
                sendNotification(reminderNotice, userID, '', devices[1], 'reminder');

            //console.log('reminder sent');

            reminderTracker = new ReminderTracker({ user: userID, objectID: objectID, 'reminderType': reminderType });
            await reminderTracker.save();

        }

    } catch (err) {
        var msg = await logUtil.logError(err, false);
        return;
    }

}


function splitDevicesByBuild(devices, build) {


    let oldDevices = [];
    let newDevices = [];

    for (let i = 0; i < devices.length; i++) {

        if (!devices[i].build || devices[i].build < build)
            oldDevices.push(devices[i]);
        else
            newDevices.push(devices[i]);

    }


    return [oldDevices, newDevices];
}

module.exports.sendDeleteNotification = async function (circleObjectID, circleID, skipUserID, skipDeviceToken, notification, notificationType) {

    try {

        ///TODO cleanup this mess (oldNotification) after everyone is on v65+

        let devices = await loadDeviceList(circleID, skipUserID, skipDeviceToken);

        if (!devices) return; //throw ('Could not load devices in sendDeleteNotifcation ' + circleID);

        if (devices[0].length > 0) {

            let splitDevices = splitDevicesByBuild(devices[0], 65);

            if (splitDevices[1].length > 0)
                sendNotification(notification, circleObjectID, circleID, splitDevices[1], 'IronCircles', notificationType);

            if (splitDevices[0].length > 0)
                sendNotification('Member deleted ironclad message', circleObjectID, circleID, splitDevices[0], 'IronCircles', notificationType);

        }

        if (devices[1].length > 0) {
            let splitDevices = splitDevicesByBuild(devices[1], 65);

            if (splitDevices[1].length > 0)
                sendNotification(notification, circleObjectID, circleID, splitDevices[1], 'IronCircles', notificationType);

            if (splitDevices[0].length > 0)
                sendNotification('Member deleted ironclad message', circleObjectID, circleID, splitDevices[0], 'IronCircles', notificationType);
        }

    } catch (err) {
        var msg = await logUtil.logError(err, false);
        return;
    }

}


module.exports.sendNotificationToCircle = async function (circleID, skipUserID, skipDeviceToken, lastItemUpdate, notification) {
    try {

        if (lastItemUpdate != null && lastItemUpdate != undefined)
            await userCircleLogic.flipShowBadgesOn(circleID, skipUserID, lastItemUpdate);

        let devices = await loadDeviceList(circleID, skipUserID, skipDeviceToken);

        if (!devices) {
            //console.log('Failed to loadDeviceList in sendNotificationToCircle');
            return;
        }

        if (devices[0].length > 0)
            sendNotification(notification, '', circleID, devices[0], 'IronCircles');

        if (devices[1].length > 0)
            sendNotification(notification, '', circleID, devices[1], 'IronCircles');


        return;


    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }



}




async function loadUserDevices(userID, skipDeviceToken) {
    try {
        let user = await User.findOne({ "_id": userID });
        if (!user)
            throw new Error("User not found");

        let devices = [];
        let androidDevices = [];
        let iOSDevices = [];

        for (let i = 0; i < user.devices.length; i++) {

            let device = user.devices[i];

            if (device.pushToken == null) continue;
            if (device.pushToken == "") continue;

            if (device.pushToken != skipDeviceToken) {

                var found = false;

                for (let index = 0; index < androidDevices.length; index++) {
                    if (androidDevices[index].pushToken == device.pushToken)
                        found = true;
                }

                for (let index = 0; index < iOSDevices.length; index++) {
                    if (iOSDevices[index].pushToken == device.pushToken)
                        found = true;
                }


                if (!found) {
                    if (device.loggedIn == true) {

                        if (device.platform == 'android') {
                            androidDevices.push(device);
                        } else if (device.platform == 'iOS' || device.platform == 'macos') {
                            iOSDevices.push(device);
                        }
                    }

                }
            }

        }

        devices.push(androidDevices);
        devices.push(iOSDevices);
        return devices;

    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }

    return;
}

async function loadDeviceList(circleID, skipUserID, skipDeviceToken) {
    try {

        if (circleID == null || circleID == undefined) {
            throw ('cannot send notification. circleID is null');
        }

        let userCircles = await UserCircle.find({ beingVotedOut: { $ne: true }, circle: circleID }).populate('user').exec();

        if (!userCircles)
            throw ("UserCircles not found");

        let devices = [];
        let androidDevices = [];
        let iOSDevices = [];

        for (let u = 0; u < userCircles.length; u++) {

            //console.log(u);
            let userCircle = userCircles[u];
            //console.log(userCircle.user.username);

            if (userCircle.user == null) {

                console.log('Could not load user associated to usercircle: UserCircle: ' + userCircle._id);

            } else {

                if (userCircle.muted == true) {

                    sendDataOnlyMessage(circleID, userCircle, skipDeviceToken);
                    continue;
                }

                //usercircle is for the sender
                if (userCircle.user._id == skipUserID) {

                    //send data only messages
                    for (let i = 0; i < userCircle.user.devices.length; i++) {
                        let device = userCircle.user.devices[i];

                        if (device.pushToken == null) continue;
                        if (device.pushToken == "") continue;

                        if (device.pushToken != skipDeviceToken) {
                            sendDataOnlyMessage(circleID, userCircle, skipDeviceToken);

                            break; //the function above takes care of all devices
                        }
                    }

                }

                //skip the user that generated the message
                else if (userCircle.user._id != skipUserID) { // && (userCircle.hidden == false || (userCircle.hiddenOpen != undefined && userCircle.hiddenOpen != null && userCircle.hiddenOpen.length != 0))) {

                    for (let i = 0; i < userCircle.user.devices.length; i++) {
                        //userCircle.user.devices.forEach(function (device) {
                        let device = userCircle.user.devices[i];

                        if (device.pushToken == null) continue;
                        if (device.pushToken == "") continue;

                        if (device.pushToken != skipDeviceToken) {

                            if (device.loggedIn != undefined) {
                                if (device.loggedIn == false) continue;
                            }

                            var found = false;

                            for (let index = 0; index < androidDevices.length; index++) {
                                if (androidDevices[index].pushToken == device.pushToken)
                                    found = true;
                            }

                            for (let index = 0; index < iOSDevices.length; index++) {
                                if (iOSDevices[index].pushToken == device.pushToken)
                                    found = true;
                            }


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

                            // console.log('skip = ' + skip);

                            if (!found && !skip) {

                                if (device.platform == 'android') {
                                    androidDevices.push(device);
                                } else if (device.platform == 'iOS' || device.platform == 'macos') {
                                    iOSDevices.push(device);
                                }

                            }
                        }


                    }
                }

            }

        }

        devices.push(androidDevices);
        devices.push(iOSDevices);
        return devices;


    } catch (err) {
        var msg = await logUtil.logError(err, false);
        return;
    }
}

/*
function sendAndroidNotification(title, body, androidDevices) {
    try {
        let message = new gcm.Message({
            collapseKey: title,
            priority: 'high',
            data: {
                title: title,
                body: body,
            },
            notification: {
                title: title,
                sound: 'default',
                tag: "icnotification",
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                //body: "This is a notification that will be displayed if your app is in the background."
            }
        });
        //TODO - Store this APU key somewhere safe
        let sender = new gcm.Sender('AAAA1Y8v-1U:APA91bHzw73PS0OtvK6cUHJdLZ9YjUH50bh8TUxNWgs9tT6AUwIAdVzYeDxGo3v0y3v7ZPCXPGG9iuxA-2Eh1JW04KPHM4uPI05kBCThLhzIpqtf2fWjIPcPq1_520TY7wjrbfRhMA8p');
        //let sender = new gcm.Sender('AAAAcRvIRXw:APA91bHn3TunFugAU-vFFnOT4Ko1vS0WxHH32RLRt23bCxDKCVfa7tGG1JHrRcdjOcJdjKUkkFIVrhTtl9ynPyP3Ip7nx9tX3pA4Rw0u_pq8CjmYdUM_NPluJ4nbKp23OC4_SvzHboR8');
        console.log(sender);
        sender.send(message, {
            registrationTokens: androidDevices
        }, function (err, response) {
            if (err) {
                console.error(err);
            } else {
                console.log(response);
                //TODO - remove invalid registrations that come back.  
            }
        });
    } catch (err) {
        console.error(err);
        return;
    }
}
*/

module.exports.removeFailedTokens = async function (failedTokens) {

    try {

        //TODO this was removing the device for a user, I think.  

        console.log('tokens not registered: ' + failedTokens);

        let users = await User.find({ "devices.pushToken": { $in: failedTokens } });
        //var memberCircles = await UserCircle.find({ 'circle': { $in: circles } }).populate('user').exec();

        //TODO have to match the token to a device, then delete from UserCircles for that user and device


        for (let u = 0; u < users.length; u++) {

            let user = users[u];

            for (let i = 0; i < user.devices.length; i++) {

                let device = user.devices[i];

                //if the tokens match
                for (let i = 0; i < failedTokens.length; i++) {

                    if (device.pushToken == failedTokens[i]) {
                        logUtil.logAlert('device: ' + device.uuid + ' user: ' + user._id);

                        device.expiredToken = device.pushToken;
                        //device.tokenExpired = Date.now();
                        device.pushToken = null;
                        device.activated = false;


                        await user.save();

                        //TODO remove the ratchetKeys


                    }
                }

            }


        }
        return;

    } catch (err) {
        var msg = await logUtil.logError(err, false);

    }

}



async function removeDevice(pushToken) {

    try {
        await User.updateMany({ $pull: { devices: { pushToken: pushToken } } });

    } catch (err) {
        console.error(err);
        //return res.status(500).json({ msg: err });
    }

}




module.exports.sendAndroidSingleDevice = async function (notification, object1, object2, device, notificationType) {

    sendNotification(notification, object1, object2, [device], 'IronCircles', notificationType);
}

module.exports.sendiOSSingleDevice = async function (notification, object1, object2, device, notificationType) {

    sendNotification(notification, object1, object2, [device], 'IronCircles', notificationType);
}


module.exports.sendAndroidSingleDeviceRefreshNeeded = async function (notification, circleObjectID, circleID, devices, object, notificationType) {

    sendNotification(notification, circleObjectID, circleID, devices, 'IronCircles', notificationType, object);
}

module.exports.sendiOSSingleDeviceRefreshNeeded = async function (notification, circleObjectID, circleID, devices, object, notificationType) {

    sendNotification(notification, circleObjectID, circleID, devices, 'IronCircles', notificationType, object);
}


function stringValue(obj) {
    try {
        //console.log("obj: " + obj + " type: " + typeof obj);

        // let retValue = false;

        // console.log(typeof obj);

        if (ObjectId.isValid(obj)) {
            let stringID = ObjectId(obj).toString();
            return stringID;

        } else if (typeof obj === "string") {
            return obj;
        } else if (typeof obj === "object") {
            //console.log("returning: " + JSON.stringify(obj));
            return JSON.stringify(obj);
        }

        return obj;

    } catch (e) {

        logUtil.logError(e, false);
        return obj;
    }
};

async function sendNotification(notification, object1, object2, devices, collapseKey, notificationType, strippedObject) {

    try {

        let tokens = [];

        for (let index = 0; index < devices.length; index++) {

            let device = devices[index];

            //console.log(androidDevices[index]);
            if (device.pushToken != null)
                tokens.push(device.pushToken);
        }


        let notificationLog = await saveNotification(notification, strippedObject, object1, object2, devices, notificationType);

        if (tokens.length == 0) {
            failNotificationLog(notificationLog, 'No tokens');
            return;
        }


        var nType;

        if (notificationType == undefined || notificationType == null)
            nType = getNotificationType(notification);
        else
            nType = notificationType;


        let object = '';
        if (strippedObject != undefined && strippedObject != null)
            object = strippedObject;

        // console.log(notification);
        // console.log(notificationType);

        for (let index = 0; index < tokens.length; index++) {
            let token = tokens[index];
            if (token == "") continue;

            try {

                let message = {
                    data: {
                        notificationType: nType.toString(),
                        //object: JSON.stringify(object),
                        strippedObject: JSON.stringify(object),
                        object1: stringValue(object1),
                        object2: stringValue(object2),
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
                                category: "FLUTTER_NOTIFICATION_CLICK"
                            }
                        },
                        headers: {
                            "apns-priority": "10",
                        },
                    },
                    notification: {
                        title: "IronCircles",
                        body: notification,
                    },
                    token: token
                };

                //console.log(message);

                let result = await firebase.messaging().send(message);

            } catch (err) {
                var msg = await logUtil.logError(err, false);

                if (err.message == "Requested entity was not found." || err.message == "The registration token is not a valid FCM registration token") {
                    module.exports.removeFailedTokens([token]);
                }

                //throw (err);
            }

        }

        // let message = new gcm.Message({
        //     collapseKey: collapseKey,
        //     //'collapse_key': collapseKey,
        //     priority: 'high',
        //     //senderID: "485797414268",   
        //     //contentAvailable: true,
        //     data: {
        //         notificationType: nType,
        //         strippedObject: object,
        //         object1: object1,
        //         object2: object2,
        //         id: randomstring.generate({
        //             length: 40,
        //             charset: 'alphabetic'
        //         })
        //     },
        //     notification: {
        //         collapseKey: collapseKey,
        //         //contentAvailable: true,

        //         priority: 'high',
        //         title: "IronCircles",
        //         body: notification,
        //         sound: 'default',
        //         tag: collapseKey,
        //         click_action: 'FLUTTER_NOTIFICATION_CLICK',
        //     }
        // });

        // sender.send(message, { registrationTokens: tokens }, function (err, response) {

        //     if (err)
        //         console.error(err);
        //     else {
        //         console.log(response);

        //         var failed_tokens = tokens.filter((token, i) => response.results[i].error == "MessageTooBig");
        //         if (failed_tokens.length > 0) {
        //             console.log('These fireTokens are no longer ok:', failed_tokens);
        //             //module.exports.removeFailedTokens(notRegisteredTokens);
        //         }

        //         var notRegisteredTokens = tokens.filter((token, i) => response.results[i].error == "NotRegistered");
        //         //var failed_tokens = tokens.filter((token, i) => response.results[i].error != null);
        //         if (notRegisteredTokens.length > 0) {
        //             //console.log('These fireTokens are no longer ok:', failed_tokens);
        //             module.exports.removeFailedTokens(notRegisteredTokens);
        //         }
        //     }
        // });


    } catch (err) {
        var msg = await logUtil.logError(err, false);
    }

    return;
}

async function saveNotification(notification, object, object1, object2, devices, notificationType) {

    try {
        let notificationLog = new NotificationLog({ notification: notification, type: notificationType, });


        if (devices != null && devices != undefined) {

            for (let index = 0; index < devices.length; index++) {
                let device = devices[index];

                notificationLog.devices = [];
                notificationLog.devices.push(device._id);
            }
        }
        if (object != null) {

            notificationLog.object = JSON.stringify(object);
            //let tempObject = JSON.parse(object);
            notificationLog.circleObject = object;
        }

        if (object1 != null) {

            notificationLog.object1 = object1;
        }

        if (object2 != null) {
            notificationLog.object2 = object2;
        }
        await notificationLog.save();

        return notificationLog;
    } catch (err) {
        var msg = await logUtil.logError(err, false);

    }
}

async function failNotificationLog(notificationLog, reason) {
    notificationLog.success = false;
    notificationLog.error = reason;
    await notificationLog.save();
}

// async function sendiOSNotification(notification, object1, object2, devices, collapseKey, notificationType, strippedObject) {

//     try {

//         //TODO - Store this APU key somewhere safe
//         //let sender = new gcm.Sender('AAAAcRvIRXw:APA91bHn3TunFugAU-vFFnOT4Ko1vS0WxHH32RLRt23bCxDKCVfa7tGG1JHrRcdjOcJdjKUkkFIVrhTtl9ynPyP3Ip7nx9tX3pA4Rw0u_pq8CjmYdUM_NPluJ4nbKp23OC4_SvzHboR8');
//         let sender = new gcm.Sender('AAAAcRvIRXw:APA91bGDGN9y5P2aSZgH37M3XZuDg9s-FhyxkAmcFft4xbZkQR99sjYH-1LSNEDkte3AZRb2dlX3jEGENXhQcSEMtg3KJraTkdIYmZAzASebVpXsYC89JuWvCyOR_P37bgJIx3dOhFDO');

//         let tokens = [];

//         for (let index = 0; index < devices.length; index++) {  //intentionally send one device at a time
//             let device = devices[index];

//             if (device.build == null || device.build == undefined) continue;

//             //TODO remove this after all iOS users transition to b60 or higher
//             if (device.platform == constants.DEVICE_PLATFORM.iOS) {
//                 if (device.build < 60) continue;
//             }

//             if (device.pushToken != null)
//                 tokens.push(device.pushToken);
//         }

//         let notificationLog = await saveNotification(notification, strippedObject, object1, object2, devices, notificationType);


//         if (tokens.length == 0) {
//             failNotificationLog(notificationLog, 'No tokens');
//             return;
//         }
//         //else console.log(tokens);

//         var nType;

//         if (notificationType == undefined || notificationType == null)
//             nType = getNotificationType(notification);
//         else
//             nType = notificationType;

//         let object = '';
//         if (strippedObject != undefined && strippedObject != null)
//             object = strippedObject;

//         console.log(notification);
//         console.log(nType);

//         let message = new gcm.Message({
//             //collapseKey: collapseKey,
//             priority: 'high',
//             contentAvailable: true,
//             data: {
//                 title: "IronCircles",
//                 notificationType: nType,
//                 click_action: 'FLUTTER_NOTIFICATION_CLICK',
//                 strippedObject: object,
//                 object1: object1,
//                 object2: object2,
//                 id: randomstring.generate({
//                     length: 40,
//                     charset: 'alphabetic'
//                 })

//             },
//             notification: {
//                 priority: 'high',
//                 title: "IronCircles",
//                 body: notification,
//                 sound: 'default',
//                 click_action: 'FLUTTER_NOTIFICATION_CLICK',
//             }
//         });

//         sender.send(message, { registrationTokens: tokens }, function (err, response) {

//             if (err)
//                 console.error(err);
//             else {
//                 console.log(response);

//                 var notRegisteredTokens = tokens.filter((token, i) => response.results[i].error == "NotRegistered");
//                 //var failed_tokens = tokens.filter((token, i) => response.results[i].error != null);
//                 if (notRegisteredTokens.length > 0) {
//                     module.exports.removeFailedTokens(notRegisteredTokens);
//                 }
//             }
//         });




//     } catch (err) {
//         var msg = await logUtil.logError(err, false);
//         throw (err);
//     }

//     return;
// }



async function sendDataOnlyMessage(circleID, userCircle, skipDeviceToken, tag, lastItemUpdate) {

    let tokens = [];

    //console.log('data only message for ' + userCircle.user.username + ' in circle ' + circleID);

    if (userCircle.beingVotedOut == true) return;

    if (lastItemUpdate != null && lastItemUpdate != undefined)
        await userCircleLogic.flipShowBadgesOn(circleID, userCircle.user._id, lastItemUpdate);

    for (let i = 0; i < userCircle.user.devices.length; i++) {
        let device = userCircle.user.devices[i];

        if (device.pushToken == null || device.loggedIn == false) continue;

        var found = false;

        //make sure the push token hasn't recieved a message already
        for (let index = 0; index < tokens.length; index++) {
            if (tokens[index].pushToken == device.pushToken)
                found = true;
        }

        if (found == true) continue;  //already send a notification

        if (skipDeviceToken != undefined && skipDeviceToken != null) {
            if (device.pushToken == skipDeviceToken) continue;
        }

        if (device.build == null || device.build == undefined) continue;

        //TODO remove this after all iOS users transition to b60 or higher
        if (device.platform == constants.DEVICE_PLATFORM.iOS) {
            if (device.build < 60) continue;
        }


        tokens.push(device.pushToken);

        //sendAndroidDataNotification('New activity in IronCircles', tempObject, device, 'IronCircles', circleID, skipUserID, skipDeviceToken, lastItemUpdate);

    }

    sendDataNotification(circleID, tokens, tag);
}
exports.sendDataOnlyMessage = sendDataOnlyMessage;

module.exports.sendDataOnlyReplyMessage = async function (circleObjectSeed, replyObject, circleID, userCircle, skipDeviceToken, tag, lastItemUpdate) {
    let tokens = [];

    console.log('data only message for ' + userCircle.user.username + ' in circle ' + circleID);

    if (userCircle.beingVotedOut == true) return;

    if (lastItemUpdate != null && lastItemUpdate != undefined)
        await userCircleLogic.flipShowBadgesOn(circleID, userCircle.user._id, lastItemUpdate);

    for (let i = 0; i < userCircle.user.devices.length; i++) {
        let device = userCircle.user.devices[i];

        if (device.pushToken == null || device.loggedIn == false) continue;

        var found = false;

        //make sure the push token hasn't recieved a message already
        for (let index = 0; index < tokens.length; index++) {
            if (tokens[index].pushToken == device.pushToken)
                found = true;
        }

        if (found == true) continue;  //already send a notification

        if (skipDeviceToken != undefined && skipDeviceToken != null) {
            if (device.pushToken == skipDeviceToken) continue;
        }

        if (device.build == null || device.build == undefined) continue;

        //TODO remove this after all iOS users transition to b60 or higher
        if (device.platform == constants.DEVICE_PLATFORM.iOS) {
            if (device.build < 60) continue;
        }


        tokens.push(device.pushToken);

        //sendAndroidDataNotification('New activity in IronCircles', tempObject, device, 'IronCircles', circleID, skipUserID, skipDeviceToken, lastItemUpdate);

    }

    //sendDataNotification(circleID, tokens, tag);
    this.sendRefreshReplyDataNotification(circleObjectSeed, replyObject, tokens, tag);
}


module.exports.sendSingleDeviceDataNotification = async function (circleID, device, tag) {

    await sendDataNotification(circleID, [device.pushToken], tag);
}

async function sendDataNotification(circleID, tokens, tag) {

    try {

        //console.log('sending data only message to ' + tokens.length + ' devices');

        //TODO - Store this APU key somewhere safe
        //let sender = new gcm.Sender('AAAAcRvIRXw:APA91bHn3TunFugAU-vFFnOT4Ko1vS0WxHH32RLRt23bCxDKCVfa7tGG1JHrRcdjOcJdjKUkkFIVrhTtl9ynPyP3Ip7nx9tX3pA4Rw0u_pq8CjmYdUM_NPluJ4nbKp23OC4_SvzHboR8');
        //let sender = new gcm.Sender('AAAAcRvIRXw:APA91bGDGN9y5P2aSZgH37M3XZuDg9s-FhyxkAmcFft4xbZkQR99sjYH-1LSNEDkte3AZRb2dlX3jEGENXhQcSEMtg3KJraTkdIYmZAzASebVpXsYC89JuWvCyOR_P37bgJIx3dOhFDO');


        //let tokens = [];
        // tokens.push(token);


        // if (tokens.length == 0) {
        //     console.log('data only message, tokens are empty');
        //     return;
        // } else if (tokens.length == 1) {
        //     console.log('sending data only message to ' + tokens[0] + ' device');
        // }
        // else {
        //     console.log('sending data only message to ' + tokens.length + ' devices');
        // }


        let sendTag = constants.TAG_TYPE.ICM;
        if (tag)
            sendTag = tag;

        let id = circleID;

        // console.log(circleID);

        if (circleID instanceof Circle) {
            id = circleID._id.toString();
        } else {

            try {

                id = circleID.toString();
            } catch (err) {

            }
        }

        for (let index = 0; index < tokens.length; index++) {
            let token = tokens[index];

            if (token == "") continue;

            try {
                let message = {
                    data: {
                        object2: id,
                        tag: sendTag.toString(),
                        id: randomstring.generate({
                            length: 40,
                            charset: 'alphabetic'
                        })
                    },
                    android: {
                        priority: 'high',
                    },
                    apns: {
                        payload: {
                            aps: {
                                contentAvailable: true,
                            },
                        },
                        headers: {
                            "apns-push-type": "background",
                            "apns-priority": "5", // Must be `5` when `contentAvailable` is set to true.
                        },
                    },
                    token: token
                };

                //console.log(message);

                let result = await firebase.messaging().send(message);

            } catch (err) {
                var msg = await logUtil.logError(err, false);

                if (err.message == "Requested entity was not found." || err.message == "The registration token is not a valid FCM registration token") {
                    module.exports.removeFailedTokens([token]);
                }
            }

        }

    } catch (err) {
        var msg = await logUtil.logError(err, false);
        //throw (err);
    }

    return;
}

module.exports.sendRefreshReplyDataNotification = async function (circleObjectSeed, replyObject, tokens, tag) {
    try {

        // let sender = new gcm.Sender('AAAAcRvIRXw:APA91bGDGN9y5P2aSZgH37M3XZuDg9s-FhyxkAmcFft4xbZkQR99sjYH-1LSNEDkte3AZRb2dlX3jEGENXhQcSEMtg3KJraTkdIYmZAzASebVpXsYC89JuWvCyOR_P37bgJIx3dOhFDO');

        //console.log("sending refresh reply notification"); ///means theres been an edit, or its new reply notification to a member

        if (tokens.length == 0) {
            console.log('data only message, tokens are empty');
            return;
        } else if (tokens.length == 1) {
            console.log('sending data only message to ' + tokens[0] + ' device');
        } else {
            console.log('sending data only message to ' + tokens.length + ' devices');
        }

        console.log("replyobjectid in notificaton: " + replyObject.id);

        let sendTag = constants.TAG_TYPE.ICM;
        if (tag) sendTag = tag;

        let tempObject = await ReplyObject.baseNew(replyObject);
        tempObject.seed = circleObjectSeed;

        for (let index = 0; index < tokens.length; index++) {
            let token = tokens[index];

            if (token == "") continue;

            try {
                let message = {
                    data: {
                        replyUpdate: JSON.stringify(tempObject),
                        tag: sendTag,
                        id: randomstring.generate({
                            length: 40,
                            charset: 'alphabetic'
                        })
                    },
                    android: {
                        priority: 'high',
                    },
                    apns: {
                        payload: {
                            aps: {
                                contentAvailable: true,
                            },
                        },
                        headers: {
                            "apns-push-type": "background",
                            "apns-priority": "5", // Must be `5` when `contentAvailable` is set to true.
                        },
                    },
                    token: token
                };

                //console.log(message);

                let result = await firebase.messaging().send(message);

            } catch (err) {
                var msg = await logUtil.logError(err, false);

                if (err.message == "Requested entity was not found." || err.message == "The registration token is not a valid FCM registration token") {
                    module.exports.removeFailedTokens([token]);
                }

                //throw (err);
            }
        }

    } catch (err) {
        var msg = await logUtil.logError(err, false);
        throw (err);
    }
    return;
}


module.exports.sendReplyDataNotification = async function (replyObjectID, tokens, tag) {
    try {

        //let sender = new gcm.Sender('AAAAcRvIRXw:APA91bGDGN9y5P2aSZgH37M3XZuDg9s-FhyxkAmcFft4xbZkQR99sjYH-1LSNEDkte3AZRb2dlX3jEGENXhQcSEMtg3KJraTkdIYmZAzASebVpXsYC89JuWvCyOR_P37bgJIx3dOhFDO');

        //console.log("sending delete notification");

        if (tokens.length == 0) {
            console.log('data only message, tokens are empty');
            return;
        } else if (tokens.length == 1) {
            console.log('sending data only message to ' + tokens[0] + ' device');
        } else {
            console.log('sending data only message to ' + tokens.length + ' devices');
        }

        console.log("replyobjectid in notificaton: " + replyObjectID);

        let sendTag = constants.TAG_TYPE.ICM;
        if (tag) sendTag = tag;


        for (let index = 0; index < tokens.length; index++) {
            let token = tokens[index];
            if (token == "") continue;
            try {

                let message = {
                    data: {
                        reply: replyObjectID,
                        tag: sendTag,
                        id: randomstring.generate({
                            length: 40,
                            charset: 'alphabetic'
                        })
                    },
                    android: {
                        priority: 'high',
                    },
                    apns: {
                        payload: {
                            aps: {
                                contentAvailable: true,
                            },
                        },
                        headers: {
                            "apns-push-type": "background",
                            "apns-priority": "5", // Must be `5` when `contentAvailable` is set to true.
                        },
                    },
                    token: token
                };

                //console.log(message);

                let result = await firebase.messaging().send(message);

            } catch (err) {
                var msg = await logUtil.logError(err, false);

                if (err.message == "Requested entity was not found." || err.message == "The registration token is not a valid FCM registration token") {
                    module.exports.removeFailedTokens([token]);
                }

                //throw (err);
            }
        }
    } catch (err) {
        var msg = await logUtil.logError(err, false);
        throw (err);
    }
    return;
}

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



module.exports.countAvailableMessages = async function (userID) {

    let count = 0;

    try {
        let userCircles = await UserCircle.find({ user: userID, hidden: false, showBadge: true, circle: { $ne: null }, removeFromCache: null, }).populate('circle').populate('user');

        //let array = [];

        for (let i = 0; i < userCircles.length; i++) {

            let add = await CircleObject.countDocuments({ circle: userCircles[i].circle._id, created: { $gt: userCircles[i].lastAccessed }, creator: { $ne: userID } });

            count = count + add;
        }

        /* var query = CircleObject.countDocuments({});
 
         query.where({ circle: { $in: array } });
 
         count = await query.exec();
         */


        //console.log(userID + ' has ' + count + ' unread messages');

    } catch (err) {
        var msg = await logUtil.logError(err, true);
    }
    return count;


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
    delete accountRecovery;
    delete joinBeta;



    return user;
}