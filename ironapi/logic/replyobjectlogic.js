/************
* Author: AL
* Purpose: Logic for replyObjects (replying to wall circleObjects)
**************/

const CircleObject = require('../models/circleobject');
const UserCircle = require('../models/usercircle');
const User = require('../models/user');
const CircleObjectRefeshNeeded = require('../models/circleobjectrefreshneeded');
const CircleObjectNewItem = require('../models/circleobjectnewitem');
const RatchetIndex = require('../models/ratchetindex');
const Delivered = require('../models/circleobjectdelivered');
const imageLogic = require('../logic/imagelogic');
var gifLogic = require('../logic/giflogic');
var reviewLogic = require('../logic/reviewlogic');
var voteLogic = require('./votelogicasync');
var invitationLogic = require('../logic/invitationlogic');
const videoLogic = require('./videologic');
const deviceLogic = require('../logic/devicelogic');
var circleListLogic = require('../logic/circlelistlogic');
var circleRecipeLogic = require('../logic/circlerecipelogic');
var circleEventLogic = require('../logic/circleeventlogic');
var usercircleLogic = require('../logic/usercirclelogic');
const logUtil = require('../util/logutil');
const constants = require('../util/constants');
const circleAlbumController = require('../routes/circlealbumcontroller');
const ReplyObject = require('../models/replyobject');
const replyobject = require('../models/replyobject');
const deviceLogicSingle = require('../logic/devicelogicsingle');

// module.exports.findReplyObjectsInArray = async function (userID, array) {
//     var query = ReplyObject.find({});

//     query.where({ type: { $ne: 'deleted' }, _id: { $in: array } });

//     let replyobjects = await queryAndPopulateReplyObjects(userID, query, 500);

//     return replyobjects;
// }

// module.exports.findRefreshNeededObjects = async function (userID, device) {
//     try {

//         let refreshNeeded = await ReplyObjectRefreshNeeded.find({ user: userID, device: device }).populate("replyObject");

//         let arrayFilter = [];

//         for (let i = 0; i < refreshNeeded.length; i++) {
//             arrayFilter.push(refreshNeeded[i].replyObject._id);
//         }

//         return await this.findReplyObjectsInArray(userID, arrayFilter);

//     } catch (err) {
//         let msg = await logUtil.logError(err, true);
//     }
// }

module.exports.hideReplyObject = async function (replyObjectID, userID) {
    try {

        let replyObject = await ReplyObject.findById(replyObjectID);

        for (let i = 0; i < replyObject.ratchetIndexes.length; i++) {
            if (replyObject.ratchetIndexes[i].user == userID) {
                
                await ReplyObject.updateOne(
                    { "_id": replyObjectID, "ratchetIndexes._id": replyObject.ratchetIndexes[i]._id },
                    {
                        "$set": {
                            "ratchetIndexes.$.active": false
                        }
                    }
                );
            }
        }

        return true;
    } catch (err) {
        console.error(err);
    }
    return false;
}

module.exports.tagViolation = async function (circleID, replyObject) {
    try {

        replyObject.type = "systemmessage";
        replyObject.body = "Reply was reported in violation of Terms of Service and has been removed";
        replyObject.creator = undefined;
        replyobject.ratchetIndexes = undefined;
        replyObject.crank = undefined;
        replyObject.signature = undefined;
        replyObject.senderRatchetPublic = undefined;
        replyObject.reactions = undefined;

        replyObject.lastUpdate = Date.now();

        await replyObject.save();

        deviceLogic.sendNotificationToCircle(circleID, null, null, null, "Reply removed by IronCircles");
    } catch (err) {
        console.error(err);
    }
    return false;
}

module.exports.deleteReplyObject = async function (replyObject, req) {
    try {
        var creatorID = null;

        if (replyObject.creator != null && replyObject.creator != undefined) {
            creatorID = replyObject.creator._id;
            if (creatorID == null || creatorID == undefined) {
                creatorID = replyObject.creator;
            }
        }

        let type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEMESSAGE;

        //replyObject.circleObject = undefined;
        replyObject.creator = undefined;
        replyObject.reactions  = undefined;
        replyObject.ratchetIndexes = undefined;
        //replyObject.senderRatchetPublic = undefined;
        //replyObject.crank = undefined;
        //replyObject.signature = undefined;
        //replyobject.verification = undefined;
        //replyObject.device = undefined;
        //replyObject.removeFromCache = undefined;
        replyObject.body = "";
        replyObject.type = "deleted";
        //replyObject.seed = undefined;
        //replyObject.lastUpdate = undefined;
        //replyObject.lastUpdateNotReaction = undefined;
        //replyObject.created = undefined;

        replyObject.lastUpdate = Date.now();

        await replyObject.save();

        if (req != null) {
            // var notification = req.user.username + " deleted an ironclad " + type;
            // var notificationType = constants.NOTIFICATION_TYPE.DELETE;
            // let oldNotification = "Member deleted ironclad message";

            //deviceLogic.sendDeleteNotification(circleObject._id, )

            deviceLogicSingle.sendReplyMessageDeleteNotificationToWall(req.params.circleID, req.headers.devicetoken, replyObject.id);

            //if (updateLastItemUpdate) usercircleLogic.updateLastItemUpdateOnly(req.user.id, circleObject.circle._id);
        }
        
        return true;
    } catch (err) {
        logUtil.logError(err, true);
    }
    return false;
}

module.exports.findReplyObjectsByID = async function (userID, replyObjectID) {
    var query = ReplyObject.findOne({ "_id": replyObjectID });

    let replyobject = await queryAndPopulateReplyObjects(userID, query, 1);

    return replyobject;
}

module.exports.findReplyObjectsLimit = async function (userID, circleObjectID, userCircleCreated, limit) {
    var query = ReplyObject.find({});

    query.where({"circleObject": circleObjectID, type: { $ne: 'deleted' } });
    query.and({ lastUpdate: { $gt: userCircleCreated } });

    let replyobjects = await queryAndPopulateReplyObjects(userID, query, limit);

    return replyobjects;
}

module.exports.findReplyObjectsNewThan = async function (userID, circleObjectID, newerThan, circleObjectCreated, limit) {
    var query = ReplyObject.find({});

    query.where({"circleObject": circleObjectID, type: { $ne: 'deleted' } });
    query.and([{ lastUpdate: { $gt: newerThan } }, { lastUpdate: { $gt: circleObjectCreated } }]);

    let replyobjects = await queryAndPopulateReplyObjects(userID, query, limit);

    return replyobjects;
}

module.exports.findReplyObjectsOlderThan = async function (userID, circleObjectID, olderThan, circleObjectCreated, limit) {
    var query = ReplyObject.find({});

    query.where({ "circleObject": circleObjectID, type: { $ne: 'deleted' } });
    query.and({ lastUpdate: { $gt: circleObjectCreated }, created: { $lt: olderThan } });
    
    let replyobjects = await queryAndPopulateReplyObjects(userID, query, limit);

    return replyobjects;
}

queryAndPopulateReplyObjects = async function (userID, query, limit) {
    var userFieldsToPopulate = '_id username avatar';

    try {
        let replyobjects = await query.sort({ lastUpdate: -1}).limit(limit)
            //.populate("lastEdited", userFieldsToPopulate).
            .populate("creator", userFieldsToPopulate)
            .populate({ path: "circleObject", populate: [{ path: "creator", select: userFieldsToPopulate }] })
            .populate({ path: 'reactions', populate: { path: 'users', select: userFieldsToPopulate, } });

        let copyobjects = replyobjects;
        if (replyobjects != null && replyobjects.length > 0) {
            //console.log('break');

            let user = await User.findById(userID).populate('blockedList');
            for (i = 0; i < user.blockedList.length; i++) {
                let blockedUser = user.blockedList[i];
                copyobjects = replyobjects.filer(obj => obj.creator == null || obj.creator._id.equals(blockedUser._id) == false);
            }
        }

        return copyobjects;
    } catch (err) {
        let msg = await logUtil.logError(err, true);
        throw new Error(msg);
    }
}

