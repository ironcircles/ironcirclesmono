/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates logic for usercircles.  
 * 
 * TODO: Replace functions that use callbacks with promises
 * 
 *  
 ***************************************************************************/
const UserCircle = require('../models/usercircle');
const gridFS = require('../util/gridfsutil');
var Invitation = require('../models/invitation');
var invitationLogic = require('../logic/invitationlogic');
var circleObjectLogic = require('../logic/circleobjectlogic');
var voteLogic = require('../logic/votelogicasync');
var systemMessageLogic = require('../logic/systemmessagelogic');
const circleLogic = require('../logic/circlelogic');
const CircleObject = require('../models/circleobject');
const User = require('../models/user');
const UserConnection = require('../models/userconnection');
const MemberCircle = require('../models/membercircle');
var ActionRequired = require('../models/actionrequired');
const logUtil = require('../util/logutil');
const constants = require('../util/constants');
const awsLogic = require('./awslogic');
const { canUserAccessCircleListTemplate } = require('./securitylogicasync');
const { remove } = require('../models/device');
const ObjectId = require('mongodb').ObjectId;


let userFieldsToPopulate = '_id username lowercase avatar accountType role';
let hostedFurnaceFields = '_id name lowercase override discoverable enableWall wallCircleID adultOnly description hostedFurnaceImage';

module.exports.setConnections = async function (userCircle) {

    ///ignore the Beta circle
    if (userCircle.circle._id.equals(ObjectId('621e6fd26673b8001559e701'))) return;

    let user = userCircle.user;

    let userConnection = await UserConnection.findOne({ user: user._id }).populate('connections').exec();

    if (!(userConnection instanceof UserConnection)) {
        ///this should only happen for the new user, and only if it is their first circle or dm
        userConnection = new UserConnection({ user: user._id, connections: [] });
    }


    //grab the usercircles that are not the current user
    let memberUserCircles = await UserCircle.find({ user: { $ne: user._id }, circle: userCircle.circle, removeFromCache: null }).populate('user');

    for (k = 0; k < memberUserCircles.length; k++) {

        let memberUserCircle = memberUserCircles[k];

        let memberConnection = await UserConnection.findOne({ user: memberUserCircle.user._id }).populate('connections').exec();

        if (!(memberConnection instanceof UserConnection)) {
            ///this will happen for the first time the person connects with someone on the network
            memberConnection = new UserConnection({ user: memberUserCircle.user._id, connections: [] });
        }

        let alreadyConnected = false;
        ///are they already connected?
        for (let i = 0; i < memberConnection.connections.length; i++) {
            if (memberConnection.connections[i]._id.equals(user._id)) {
                alreadyConnected = true;
                continue;
            }
        }

        if (!alreadyConnected) {

            memberConnection.connections.push(user._id);
            await memberConnection.save();
        }


        ///create the user connection
        alreadyConnected = false;
        ///are they already connected?
        for (let i = 0; i < userConnection.connections.length; i++) {
            if (userConnection.connections[i]._id.equals(memberUserCircle.user._id)) {
                alreadyConnected = true;
                continue;
            }
        }

        if (!alreadyConnected) {

            userConnection.connections.push(memberUserCircle.user._id);
            await userConnection.save();
        }
    }


}

module.exports.getUserCirclesHistory = async function (user) {

    var query = UserCircle.find({});

    query.where({ user: user._id, removeFromCache: undefined, circle: { $ne: null } });

    var usercircles = await query.sort('created')
        .populate({ path: "user", select: userFieldsToPopulate, populate: [{ path: 'hostedFurnace', select: hostedFurnaceFields }] }).populate('dm').populate("circle").exec();

    //populate all members this user is connected to
    //will be used client side to refresh username, avatar, etc
    let members = [];
    let memberCircles = [];
    let circleIDArray = [];


    ///grab the network members
    if (user.hostedFurnace == null) {
        members = await User.find({ hostedFurnace: user.hostedFurnace, keyGen: true, /*lockedOut: { $ne: true }*/ }).select(userFieldsToPopulate).sort({ lowercase: 1 }).populate({ path: 'hostedFurnace', select: hostedFurnaceFields }).exec();

    } else {
        //include locked out users so the client cache refreshes
        members = await User.find({ hostedFurnace: user.hostedFurnace, /*removeFromCache: { $ne: true }, lockedOut: { $ne: true }*/ }).select(userFieldsToPopulate).sort({ lowercase: 1 }).populate({ path: 'hostedFurnace', select: hostedFurnaceFields }).exec();
    }

    ///grab the membercircles
    for (i = 0; i < usercircles.length; i++) {
        if (usercircles[i].circle != null) {
            circleIDArray.push(usercircles[i].circle._id);
        }
    }

    let results = await UserCircle.find({ circle: { $in: circleIDArray }, user: { $ne: ObjectId(user._id) } }).populate({path: 'user', select: userFieldsToPopulate}).populate('circle').populate('dm');

    for (let i = 0; i < results.length; i++) {
        try {
            if (results[i].user == null) {
                console.log('cleanup: ' + results[i]);
                continue;
            }

            if (results[i].circle == null) {
                console.log('cleanup: ' + results[i]);
                continue;
            }

            memberCircles.push(new MemberCircle({ userID: user._id, memberID: results[i].user._id, circleID: results[i].circle._id, dm: results[i].circle.dm, }));
        } catch (err) {
            console.log('cleanup: memberID: ' + results[i]);
            logUtil.logError(err, true);
        }
    }

    //add users who have been invited to DMs but not accepted
    let dmInvites = await Invitation.find({ circle: { $in: circleIDArray }, inviter: ObjectId(user._id) }).populate({path: 'invitee', select: userFieldsToPopulate}).populate('circle');

    for (let i = 0; i < dmInvites.length; i++) {
        try {
            if (dmInvites[i].circle.dm == true) {
                memberCircles.push(new MemberCircle({ userID: user._id, memberID: dmInvites[i].invitee._id, circleID: dmInvites[i].circle._id, dm: dmInvites[i].circle.dm }));
            }
        } catch (err) {
            logUtil.logError(err, true);
        }
    }


    ///grab the users connections
    let connections = [];
    let userConnection = await UserConnection.findOne({ user: user._id }).populate('connections').exec();

    if (userConnection instanceof UserConnection) {
        connections = userConnection.connections;
    }

    //Node.js syntax for removing duplicates
    let uniqueMembers = Array.from(new Set(members));

    let returnArray = [];
    returnArray[0] = usercircles;
    returnArray[1] = uniqueMembers;
    returnArray[2] = memberCircles;
    returnArray[3] = connections;

    return returnArray;

}
module.exports.getUserCircles = async function (user, deviceID, hiddenOpen) {

    try {

        // let userFieldsToPopulate = '_id username lowercase avatar accountType';
        // let hostedFurnaceFields = '_id name lowercase override discoverable enableWall wallCircleID adultOnly description hostedFurnaceImage';

        var query = UserCircle.find({});

        //if the users device build is less than 123, don't return the wall circles
        var build = null;

        for (var i = 0; i < user.devices.length; i++) {
            if (user.devices[i].uuid == deviceID) {
                build = user.devices[i].build;
                break;
            }
        }

        // if (build < 123 || build == null) {
        //     query.where({ user: user._id, wall: false });
        //} else {

        query.where({ user: user._id, });
        //}

        if (hiddenOpen != undefined && hiddenOpen != null && hiddenOpen != '[]') {

            var format = hiddenOpen.replace('[', '');
            format = format.replace(']', '');

            var hiddenParams = format.split(', ');
            query.or([{ hidden: false }, { _id: { $in: hiddenParams } }]);

        } else {
            query.and({ hidden: false });
        }

        var usercircles = await query.sort('created')
            .populate({ path: "user", select: userFieldsToPopulate, populate: [{ path: 'hostedFurnace', select: hostedFurnaceFields }] }).populate('dm').populate("circle").exec();


        let invitations = await invitationLogic.getUserInvitations(user._id);
        let actionRequired = await ActionRequired.find({ user: user._id, alertType: { $ne: 8 } }).populate({path: 'user', select: userFieldsToPopulate}).populate({path: 'resetUser', select: userFieldsToPopulate}).populate({path: 'member', select: userFieldsToPopulate}).populate({ path: 'networkRequest', populate: [{ path: 'hostedFurnace', select: hostedFurnaceFields }, { path: 'user',select: userFieldsToPopulate }] }).exec();



        //populate all members this user is connected to
        //will be used client side to refresh username, avatar, etc
        let members = [];
        let memberCircles = [];
        let circleIDArray = [];


        ///grab the network members
        if (user.hostedFurnace == null) {
            members = await User.find({ hostedFurnace: user.hostedFurnace, keyGen: true, /*lockedOut: { $ne: true }*/ }).select(userFieldsToPopulate).sort({ lowercase: 1 }).populate({ path: 'hostedFurnace', select: hostedFurnaceFields }).exec();

        } else {
            //include locked out users so the client cache refreshes
            members = await User.find({ hostedFurnace: user.hostedFurnace, /*removeFromCache: { $ne: true }, lockedOut: { $ne: true }*/ }).select(userFieldsToPopulate).sort({ lowercase: 1 }).populate({ path: 'hostedFurnace', select: hostedFurnaceFields }).exec();
        }

        ///grab the membercircles
        for (i = 0; i < usercircles.length; i++) {
            if (usercircles[i].circle != null) {
                circleIDArray.push(usercircles[i].circle._id);
            }
        }

        let results = await UserCircle.find({ circle: { $in: circleIDArray }, user: { $ne: ObjectId(user._id) } }).populate({path: 'user', select: userFieldsToPopulate}).populate('circle').populate('dm');

        for (let i = 0; i < results.length; i++) {
            try {
                if (results[i].user == null) {
                    console.log('cleanup: ' + results[i]);
                    continue;
                }

                if (results[i].circle == null) {
                    console.log('cleanup: ' + results[i]);
                    continue;
                }

                memberCircles.push(new MemberCircle({ userID: user._id, memberID: results[i].user._id, circleID: results[i].circle._id, dm: results[i].circle.dm, }));
            } catch (err) {
                console.log('cleanup: memberID: ' + results[i]);
                logUtil.logError(err, true);
            }
        }

        //add users who have been invited to DMs but not accepted
        let dmInvites = await Invitation.find({ circle: { $in: circleIDArray }, inviter: ObjectId(user._id) }).populate({path: 'invitee', select: userFieldsToPopulate}).populate('circle');

        for (let i = 0; i < dmInvites.length; i++) {
            try {
                if (dmInvites[i].circle.dm == true) {
                    memberCircles.push(new MemberCircle({ userID: user._id, memberID: dmInvites[i].invitee._id, circleID: dmInvites[i].circle._id, dm: dmInvites[i].circle.dm }));
                }
            } catch (err) {
                logUtil.logError(err, true);
            }
        }


        ///grab the users connections
        let connections = [];
        let userConnection = await UserConnection.findOne({ user: user._id }).populate('connections').exec();

        if (userConnection instanceof UserConnection) {
            connections = userConnection.connections;
        }

        //Node.js syntax for removing duplicates
        let uniqueMembers = Array.from(new Set(members));

        let circleObjects = [];
        let refreshNeededObjects = [];

        if (deviceID != null) {
            circleObjects = await circleObjectLogic.returnNewItemsForDevice(user._id, deviceID, 500);
            refreshNeededObjects = await circleObjectLogic.findRefreshNeededObjects(user._id, deviceID);
        }

        let returnArray = [];
        returnArray[0] = usercircles;
        returnArray[1] = invitations;
        returnArray[2] = actionRequired;
        returnArray[3] = uniqueMembers;
        returnArray[4] = memberCircles;
        returnArray[5] = circleObjects;
        returnArray[6] = refreshNeededObjects;
        returnArray[7] = connections;

        //console.log(uniqueMembers);
        //console.log(memberCircles);
        //console.log(returnArray);

        return returnArray;

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        throw new Error(msg);
    }

}

module.exports.getUserCirclesParam = async function (userID, circleID, hiddenOpen, notDeleted) {

    try {
        var query = UserCircle.find({});

        query.where({ user: userID });

        if (circleID != undefined && circleID != null) {
            query.and({ circle: circleID });
        }

        if (hiddenOpen != null && hiddenOpen != '[]') {

            var format = hiddenOpen.replace('[', '');
            format = format.replace(']', '');

            var guardedParams = format.split(', ');
            query.or([{ hidden: false }, { _id: { $in: guardedParams } }]);

        } else {
            query.and({ hidden: false });
        }

        if (notDeleted)
            query.and({ circle: { $ne: null } });

        var usercircles = await query.sort('created')
            .populate({ path: "user", select: userFieldsToPopulate, populate: [{ path: 'hostedFurnace', select: hostedFurnaceFields}] }).populate("circle").populate('dm').exec();

        var invitationCount = await invitationLogic.getUserInvitationCount(userID);
        var actionRequired = await ActionRequired.find({ user: userID }).populate({ path: "user", select: userFieldsToPopulate}).populate({ path: "resetUser", select: userFieldsToPopulate}).populate({ path: "member", select: userFieldsToPopulate}).populate({ path: 'networkRequest', populate: [{ path: 'hostedFurnace', select: hostedFurnaceFields }, { path: 'user', select: userFieldsToPopulate }] }).exec();
        //var actionRequiredNonPriority = await CircleObject.countDocuments({});

        //return the activity for the circle since the user last visited
        /*for (i = 0; i < usercircles.length; i++) {
            var usercircle = usercircles[i];

            //the code below can eventually be removed.  Need to provide backwards compatibilty support
            //for usercircles in use before lastItemUpdate was stored in the usercircle
            if (usercircle.lastItemUpdate == undefined) {

                //console.log('usercircle.lastItemUpdate == undefined');
                var lastCircleObject = await CircleObject.findOne({ "circle": usercircle.circle, type: { $ne: 'deleted' } }).sort({ lastUpdate: -1 }).limit(1);

                usercircle.lastItemUpdate = "2018-01-01T00:00:00.000Z";

                if (lastCircleObject) {
                    usercircle.lastItemUpdate = lastCircleObject.lastUpdate;
                }
                usercircle.save();   //save this so we don't need to load it next time.
            }
        }*/

        let returnArray = [];
        returnArray[0] = usercircles;
        returnArray[1] = invitationCount;
        returnArray[2] = actionRequired;

        return returnArray;

    } catch (err) {
        console.error(err);
        return null;
    }

}

module.exports.getNumberofUsersP = function (circleID) {

    return new Promise(function (resolve, reject) {

        UserCircle.find({ 'circle': circleID })
            .then((usercircles) => {

                return resolve(usercircles.length);
            })
            .catch((err) => {

                return reject(err);

            });
    });

}


module.exports.getNumberofUsers = async function getNumberofUsers(circleID) {

    try {

        ///don't include users who are being voted out
        var usercircles = await UserCircle.find({ beingVotedOut: { $ne: true }, 'circle': circleID });

        if (usercircles) {
            return usercircles.length;
        } else {
            return 0;
        }

    } catch (err) {
        console.error(err);
        throw (err);
    }

}


module.exports.updateLastAccessedWithUserCircle = async function (usercircle, updateBadge) {

    // var usercircle;

    try {
        // usercircle = await UserCircle.findOne({ "circle": circleID, "user": userID }).populate("user").populate("circle");;

        //console.log('inside updateLastAccessedWithUserCircle');
        // console.log('inside updateLastAccessedWithUserCircle updateBadge: ' + updateBadge);

        if (usercircle != null) {

            //console.log(usercircle.lastAccessed);


            usercircle.lastAccessed = Date.now();

            //console.log(usercircle.lastAccessed);
            //console.log(usercircle.showBadge);
            //console.log(updateBadge);

            if (updateBadge == 'true') {
                usercircle.showBadge = false;
                //console.log('inside updateLastAccessedWithUserCircle: ' + usercircle.showBadge);
            }

            //console.log(usercircle.showBadge);

            var result = await usercircle.save();



        }

    } catch (err) {
        console.error(err);
    }

    return usercircle;

}


module.exports.updateLastAccessed = async function (circleID, userID, updateLastAccessed) {

    var usercircle;

    try {
        usercircle = await UserCircle.findOne({ "circle": circleID, "user": userID }).populate("user").populate("circle").populate('dm');

        if (updateLastAccessed && usercircle != null) {
            usercircle.lastAccessed = Date.now();
            usercircle.showBadge = false;

            await usercircle.save();

        }

    } catch (err) {
        console.error(err);
        return callback(false);
    }

    return usercircle;

}

/*
function updateLastAccessed(circleID, userID, circleobjects, callback) {

    try {

        // console.log('hit updateLastAccessed');

        //Fire and forget; log any errors.
        UserCircle.findOne({ "circle": circleID, "user": userID }, function (err, usercircle) {
            if (err || !usercircle)
                callback(false);

            usercircle.lastAccessed = Date.now();

            // console.log('updateLastAccessed: saving this shit ');

            usercircle.save(function (err) {
                if (err)
                    callback(false);
                else
                    callback(true, usercircle.lastAccessed);
            });

        });


    } catch (err) {
        console.error(err);
        return callback(false);
    }

}
*/

module.exports.getCirclesFromPassphrase = async function getCirclesFromPassphrase(userid, passphrase) {

    try {

        var hiddenCircles = [];

        // var test = await UserCircle.findOne({ "user": userid, hidden: true, removeFromCache: null }).exec();

        //load all the hidden circles for this user
        let usercircles = await UserCircle.find({ "user": userid, hidden: true, removeFromCache: null }).populate({path:'user', select: userFieldsToPopulate}).populate('circle').exec();

        /*
                async function asyncForEach(array, callback) {
                    for (let index = 0; index < array.length; index++) {
                        await callback(array[index], index, array);
                    }
                }
        
                */

        for (let index = 0; index < usercircles.length; index++) {
            // check if password matches
            let isMatch = await usercircles[index].comparePassphrase(passphrase);

            if (isMatch) {
                //retValue = true;
                //found = usercircle;
                hiddenCircles.push(usercircles[index]);
            }

        }

        return hiddenCircles;

    } catch (err) {
        console.error(err);
        return null;
    }
};


module.exports.deactivateUserCircle = async function (usercircle, message) {
    try {

        if (usercircle.circle == null && usercircle.removeFromCache == undefined) {
            ///the user already left the circle
            return;
        }

        usercircle.removeFromCache = usercircle.circle._id;
        //clear the circleID; this will prevent the user from authenticating to the circle in the future
        //we don't just delete the usercircle because the Application needs to know to remove the usercircle from the clientside cache

        if (usercircle.background) {

            if (usercircle.backgroundLocation == constants.BLOB_LOCATION.GRIDFS) {
                gridFS.deleteBlob("circlebackgrounds", usercircle.background);
            } else {
                awsLogic.deleteObject(process.env.s3_backgrounds_bucket, usercircle.background);
            }

        }

        var userCircles = await UserCircle.find({ "circle": usercircle.circle._id, _id: { $ne: usercircle._id } });

        var moreFolks = true;

        if (userCircles) {
            if (userCircles.length == 0) {
                moreFolks = false;

            }
        } else moreFolks = false;

        if (moreFolks) {
            if (message)
                await systemMessageLogic.sendMessage(usercircle.circle, usercircle.user.username + message);
            else
                await systemMessageLogic.sendMessage(usercircle.circle, usercircle.user.username + ' has left the ' + usercircle.circle.chatType());

            voteLogic.userLeftAdjustVotes(usercircle.circle, usercircle.user);

        }
        else {
            circleLogic.deleteCircle(usercircle.user._id, usercircle.circle);  //async
            invitationLogic.deleteAllCircleInvitations(usercircle.circle);
        }

        //usercircle.dm = null;
        usercircle.dmConnected = false;
        usercircle.circle = null;
        usercircle.ratchetPublicKeys = null;
        usercircle.ratchetIndex = null;
        usercircle.hiddenOpen = null;
        usercircle.hidden = null;
        usercircle.guarded = null;
        usercircle.guardedPin = null;
        await usercircle.save();

        return true;

    } catch (err) {
        console.error(err);

    }

    return false;

}

async function removeConnection(userCircle) {


}


module.exports.deleteAllForUser = async function deleteAllForUser(user) {
    try {

        let usercircles = await UserCircle.find({ user: user._id });

        for (let i = 0; i < usercircles.length; i++) {



            let usercircle = usercircles[i];

            if (usercircle.dm != null) {

                let dm = await UserCircle.findOne({ user: usercircle.dm, circle: usercircle.circle, dm: user._id });

                if (dm instanceof UserCircle) {

                    dm.removeFromCache = usercircle.circle;
                    dm.ratchetPublicKeys = null;
                    dm.ratchetIndex = null;
                    dm.hiddenOpen = null;
                    dm.hidden = null;
                    dm.guarded = null;
                    dm.guardedPin = null;
                    dm.circle = null;

                    await dm.save();
                }

            }

            if (usercircle.background) {

                if (usercircle.backgroundLocation == constants.BLOB_LOCATION.GRIDFS) {
                    gridFS.deleteBlob("circlebackgrounds", usercircle.background);
                } else {
                    awsLogic.deleteObject(process.env.s3_backgrounds_bucket, usercircle.background);
                }

            }

            await usercircle.delete();

        }

    } catch (err) {
        logUtil.logError(err, true);
    }
}

module.exports.deleteAllCircleUserCircles = async function deleteAllCircleUserCircles(circle) {
    try {

        let usercircles = await UserCircle.find({ "circle": circle._id });

        for (let i = 0; i < usercircles.length; i++) {

            let usercircle = usercircles[i];

            usercircle.removeFromCache = circle._id;
            usercircle.ratchetPublicKeys = null;
            usercircle.ratchetIndex = null;
            usercircle.hiddenOpen = null;
            usercircle.hidden = null;
            usercircle.guarded = null;
            usercircle.guardedPin = null;
            usercircle.circle = null;

            await usercircle.save();

            if (usercircle.background) {

                if (usercircle.backgroundLocation == constants.BLOB_LOCATION.GRIDFS) {
                    gridFS.deleteBlob("circlebackgrounds", usercircle.background);
                } else {
                    awsLogic.deleteObject(process.env.s3_backgrounds_bucket, usercircle.background);
                }

            }
        }

        return;

    } catch (err) {
        logUtil.logError(err, true);
    }
}


module.exports.flipShowBadgeOff = async function (userCircle) {

    userCircle.showBadge = false;
    await userCircle.save();
}


async function closeHiddenforUser(userID, deviceID) {

    let userCircles = await UserCircle.find({ user: userID });

    for (let index = 0; index < userCircles.length; index++) {
        let userCircle = userCircles[index];

        if (userCircle.hiddenOpen != undefined || userCircle.hiddenOpen != null) {

            for (let j = 0; j < userCircle.hiddenOpen.length; j++) {

                if (userCircle.hiddenOpen[j] == deviceID) {

                    await UserCircle.updateMany({ '_id': userCircle._id }, { $pull: { 'hiddenOpen': deviceID } });
                }

            }
        }
    }
}
module.exports.closeOpenHiddenPerDevice = async function (userID, deviceID) {
    try {

        if (deviceID == undefined || deviceID == null) return;
        closeHiddenforUser(userID, deviceID);

        ///also close open hidden for linked users
        let linkedUsers = await User.find({ linkedUser: userID });

        for (let i = 0; i < linkedUsers.length; i++) {
            closeHiddenforUser(linkedUsers[i]._id, deviceID);
        }

        return;

    } catch (err) {

        logUtil.logError(err, true);
        //return usercircles;
        return;
    }
}

module.exports.closeOpenHidden = async function (userID) {
    try {
        //only close open hidden for the authenticated use
        //await UserCircle.updateMany({ user: userID }, { hiddenOpen: undefined });

        await UserCircle.updateMany({ user: userID }, { $set: { hiddenOpen: undefined } });

    } catch (err) {

        logUtil.logError(err, true);
        //return usercircles;
    }
}


//updates the usercircle to turn on the badge
module.exports.updateLastItemUpdateOnly = async function (userID, circleID) {
    try {
        let lastCircleObject = await circleObjectLogic.findCircleObjectsLatest(userID, circleID);

        await UserCircle.updateMany({ 'circle': circleID, }, { $set: { /*showBadge: false,*/ lastItemUpdate: lastCircleObject.lastUpdate } });

        let userCircles = await UserCircle.find({ 'circle': circleID, }); //.populate('user');

        if (userCircles) {

            for (let i = 0; i < userCircles.length; i++) {

                let userCircle = userCircles[i];

                //console.log(userCircle._id.toString());
                //console.log(userCircle.user.username);
                if (userCircle.lastItemUpdate < userCircle.lastAccessed) {

                    if (userCircle.showBadge != false) {
                        userCircle.showBadge = false;
                        await userCircle.save();
                    }
                }
            }
        }

        return;

    } catch (err) {

        logUtil.logError(err, true);
        return;
    }
}

//updates the usercircle to turn on the badge
module.exports.updateLastItemUpdate = async function (circleID, userID) {
    /*var lastCircleObject = await CircleObject.findOne({ "circle": circleID, type: { $ne: 'deleted' } }).sort({ lastUpdate: -1 }).limit(1);
    //await lastCircleObject.populate('creator').populate('circle').execPopulate();
    await lastCircleObject.populate("creator").populate("circle").populate({ path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] })
        .populate("image").populate("gif").populate("recipe").populate("link").populate("video")
        .populate({ path: 'list', populate: [{ path: 'lastEdited' }, { path: 'tasks', populate: [{ path: 'completedBy' }, { path: 'assignee' },], },] })
        .populate({ path: 'reactions', populate: { path: 'users' } })
        .populate({ path: 'event', populate: [{ path: 'encryptedLineItems', populate:  [{ path: 'ratchetindex', populate: { path: 'user' } }] }] })
        .populate({ path: 'review', populate: { path: 'master' } })
        .populate({
            path: 'ratchetIndexes', match: { user: userID },
        }).execPopulate();
        */

    let lastCircleObject = await circleObjectLogic.findCircleObjectsLatest(userID, circleID);

    if (lastCircleObject != null)
        await UserCircle.updateMany({ 'circle': circleID, }, { $set: { /*showBadge: false,*/ lastItemUpdate: lastCircleObject.lastUpdate } });

    let userCircles = await UserCircle.find({ 'circle': circleID, }).populate('user');

    if (userCircles) {

        for (let i = 0; i < userCircles.length; i++) {

            let userCircle = userCircles[i];

            //console.log(userCircle._id.toString());
            //console.log(userCircle.user.username);
            if (userCircle.lastItemUpdate < userCircle.lastAccessed) {

                if (userCircle.showBadge != false) {
                    userCircle.showBadge = false;
                    await userCircle.save();
                }
            }
        }
    }

    return lastCircleObject;
}


//updates the usercircle to turn on the badge
module.exports.flipShowBadgesOn = async function (circleID, skipUserID, lastItemUpdate) {

    try {

        if (lastItemUpdate == null)
            lastItemUpdate = Date.now();

        var result = await UserCircle.updateMany({ beingVotedOut: { $ne: true }, 'circle': circleID, 'user': { $ne: skipUserID } }, { $set: { showBadge: true, lastItemUpdate: lastItemUpdate } });
        if (skipUserID != null) result = await UserCircle.updateOne({ 'circle': circleID, 'user': skipUserID }, { $set: { lastItemUpdate: lastItemUpdate } });

    } catch (err) {

        console.error(err);

    }

}

//updates the usercircle to set new order
module.exports.setLastItemUpdateNoBadge = async function (circleID, lastItemUpdate) {

    try {

        if (lastItemUpdate == null)
            lastItemUpdate = Date.now();

        var result = await UserCircle.updateMany({ 'circle': circleID, }, { $set: { lastItemUpdate: lastItemUpdate } });


    } catch (err) {

        console.error(err);

    }

}

module.exports.listOfConnectedUsers = async function (user) {
    try {

        //var user = await User.findOne({ "_id": userID }).populate('passwordHelpers');

        var response = await this.getUserCirclesParam(user._id, null, null, true);
        var userCircles = response[0];

        var circles = [];
        for (var i = 0; i < userCircles.length; i++) {
            if (userCircles[i].circle != null) {
                //console.log(userCircles[i]._id.toString());
                circles.push(userCircles[i].circle._id);
            }
        }

        var memberCircles = await UserCircle.find({ 'circle': { $in: circles } }).populate('user').exec();

        var members = [];
        //only return the members, not their UserCircle details
        for (var i = 0; i < memberCircles.length; i++) {
            var member = memberCircles[i].user;

            if (member._id.equals(user._id)) continue; //make user isn't in list already
            if (members.includes(member)) continue; //don't add duplicates

            members.push(member);
        }


        return members;
    } catch (err) {
        var msg = await logUtil.logError(err, true);
        throw (err);
    }
}



//Depricated
module.exports.getUserCirclesAndObjects_deprecated = async function (userID, hiddenOpen, /*notDeleted*/ circleLastUpdates) {

    try {
        var query = UserCircle.find({});

        query.where({ user: userID });

        if (hiddenOpen != undefined && hiddenOpen != null && hiddenOpen != '[]') {

            var format = hiddenOpen.replace('[', '');
            format = format.replace(']', '');

            var hiddenParams = format.split(', ');
            query.or([{ hidden: false }, { _id: { $in: hiddenParams } }]);

        } else {
            query.and({ hidden: false });
        }

        //if (notDeleted)
        // query.and({ circle: { $ne: null } });

        var usercircles = await query.sort('created')
            .populate("user").populate("circle").exec();

        /*if (usercircles.length == 0) {
            throw ('User has no circles');
        }*/

        var invitationCount = await invitationLogic.getUserInvitationCount(userID);
        var actionRequired = await ActionRequired.find({ user: userID }).populate('user').populate('resetUser').populate('member').populate({ path: 'networkRequest', populate: [{ path: 'hostedFurnace' }, { path: 'user' }] }).exec();
        //var actionRequiredNonPriority = await CircleObject.countDocuments({});

        //return the activity for the circle since the user last visited
        for (i = 0; i < usercircles.length; i++) {
            var usercircle = usercircles[i];

            //the code below can eventually be removed.  Need to provide backwards compatibilty support
            //for usercircles in use before lastItemUpdate was stored in the usercircle
            if (usercircle.lastItemUpdate == undefined) {

                //console.log('usercircle.lastItemUpdate == undefined');
                var lastCircleObject = await CircleObject.findOne({ "circle": usercircle.circle, type: { $ne: 'deleted' } }).sort({ lastUpdate: -1 }).limit(1);

                usercircle.lastItemUpdate = "2018-01-01T00:00:00.000Z";

                if (lastCircleObject) {
                    usercircle.lastItemUpdate = lastCircleObject.lastUpdate;
                }
                usercircle.save();   //save this so we don't need to load it next time.
            }
        }


        let circleObjects = [];

        if (circleLastUpdates != undefined) {
            for (let i = 0; i < usercircles.length; i++) {

                if (usercircles[i].circle == null) continue;

                //if (usercircles[i].showBadge==true) {

                //find the corresponding lastItemDate
                for (let j = 0; j < circleLastUpdates.length; j++) {

                    if (usercircles[i].circle._id.equals(circleLastUpdates[j].circleID) == true) {
                        let partialResults = await circleObjectLogic.returnNewObjects(userID, circleLastUpdates[j].circleID, circleLastUpdates[j].lastFetched);

                        if (partialResults) {
                            circleObjects.push(partialResults);
                        }

                    }
                }
                //}
            }
        }


        let returnArray = [];
        returnArray[0] = usercircles;
        returnArray[1] = invitationCount;
        returnArray[2] = actionRequired;
        returnArray[3] = circleObjects;

        return returnArray;

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        throw new Error(msg);
    }

}