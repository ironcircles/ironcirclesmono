/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates logic to deal with CircleObject models.  
 *  
 * 
 *  
 ***************************************************************************/

const CircleObject = require('../models/circleobject');
const CircleObjectWaiting = require('../models/circleobjectwaiting');
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
const deviceLogicSingle = require('../logic/devicelogicsingle');


let userFieldsToPopulate = '_id username lowercase avatar accountType';


module.exports.processSingleWaitingObject = async function (circleObject, updateLastUpdate) {

    let metaData = await CircleObjectWaiting.findOne({ circleObject: circleObject._id });

    if (metaData instanceof CircleObjectWaiting) {

        let now = Date.now();
        circleObject.waitingOn = undefined;
        circleObject.created = now;

        if (updateLastUpdate == true) {
            circleObject.lastUpdate = now;
        }

        //circleObject = this.setTimer(circleObject, circleObject.circle);

        await circleObject.save();
        await deviceLogicSingle.sendMessageNotificationToCircle(circleObject, circleObject.circle, circleObject.creator, metaData.pushToken, circleObject.lastUpdate, metaData.notification, metaData.notificationType, "New ironclad message", metaData.taggedUsers);
        await this.saveNewItem(circleObject.circle, circleObject, metaData.skipDevice);
        await CircleObjectWaiting.deleteOne({ circleObject: circleObject._id });

        return true;
    }

    return false;
}

module.exports.processWaitingObjects = async function (seed) {


    let waitingOnObject = await CircleObject.findOne({ seed: seed, waitingOn: undefined });

    if (waitingOnObject instanceof CircleObject) {
        let waitingObjects = await CircleObject.find({ waitingOn: seed }).populate('circle').populate('creator');

        if (waitingObjects.length > 1) {

            //console.log('break');
        }

        for (let i = 0; i < waitingObjects.length; i++) {

            let circleObject = waitingObjects[i];

            let success = await this.processSingleWaitingObject(circleObject, false);

            if (success) {
                ///process any waiting on this object
                this.processWaitingObjects(circleObject.seed);
            }

        }
        return waitingObjects.length > 0;

    } else {
        return false;
    }
}

module.exports.tagViolation = async function (circleID, circleObject) {

    try {

        circleObject.type = "systemmessage";
        circleObject.body = "message was reported in violation of Terms of Service and has been removed";
        circleObject.creator = undefined;
        circleObject.ratchetIndexes = undefined;
        circleObject.crank = undefined;
        circleObject.signature = undefined;
        circleObject.senderRatchetPublic = undefined;
        circleObject.url = undefined;
        circleObject.gif = undefined;
        circleObject.link = undefined;
        circleObject.vote = undefined;
        circleObject.review = undefined;
        circleObject.image = undefined;
        circleObject.event = undefined;
        circleObject.blob = undefined;
        circleObject.movie = undefined;
        circleObject.list = undefined;
        circleObject.recipe = undefined;
        circleObject.reactions = undefined;

        circleObject.lastUpdate = Date.now();

        await circleObject.save();

        deviceLogic.sendNotificationToCircle(circleID, null, null, null, 'Message removed by IronCircles');

    } catch (err) {
        console.error(err);
    }

    return false;
}

module.exports.findCircleObjectsLimit = async function (userID, circleID, userCircleCreated, limit) {
    var query = CircleObject.find({});

    query.where({ "circle": circleID, type: { $ne: 'deleted' } });
    query.and({ lastUpdate: { $gt: userCircleCreated } });
    //query.and({ waitingOn: undefined });


    let circleobjects = await queryAndPopulateCircleObjects(userID, query, limit);

    return circleobjects;

}

module.exports.findCircleObjectsNewThan = async function (userID, circleID, newerThan, userCircleCreated, limit) {
    var query = CircleObject.find({});

    query.where({ "circle": circleID });
    query.and([{ lastUpdate: { $gt: newerThan } }, { lastUpdate: { $gt: userCircleCreated } }]);
    //query.and({ waitingOn: undefined });

    let circleobjects = await queryAndPopulateCircleObjects(userID, query, limit);

    return circleobjects;

}

module.exports.findCircleObjectsBetween = async function (userID, circleID, start, stop, userCircleCreated, limit) {
    var query = CircleObject.find({});

    query.where({ "circle": circleID, type: { $ne: 'deleted' } });
    query.and({ lastUpdate: { $gt: userCircleCreated }, created: { $gt: start, $lt: stop } });
    //query.and({ waitingOn: undefined });

    let circleobjects = await queryAndPopulateCircleObjects(userID, query, limit);

    return circleobjects;

}

module.exports.findCircleObjectsOlderThan = async function (userID, circleID, olderThan, userCircleCreated, limit) {
    var query = CircleObject.find({});

    query.where({ "circle": circleID, type: { $ne: 'deleted' } });
    query.and({ lastUpdate: { $gt: userCircleCreated }, created: { $lt: olderThan } });
    //query.and({ waitingOn: undefined });

    let circleobjects = await queryAndPopulateCircleObjects(userID, query, limit);

    return circleobjects;

}

module.exports.findCircleObjectsLatest = async function (userID, circleID) {
    var query = CircleObject.findOne({});

    query.where({ "circle": circleID, type: { $ne: 'deleted' } });
    //query.and({ waitingOn: undefined });

    let circleobject = await queryAndPopulateCircleObjects(userID, query, 1);

    return circleobject;

}

module.exports.findCircleObjectsInArray = async function (userID, array) {
    var query = CircleObject.find({});

    query.where({ type: { $ne: 'deleted' }, _id: { $in: array } });
    //query.and({ waitingOn: undefined });

    let circleobjects = await queryAndPopulateCircleObjects(userID, query, 500);

    return circleobjects;

}

module.exports.findCircleObjectsByID = async function (userID, circleID, circleObjectID) {
    var query = CircleObject.findOne({ "_id": circleObjectID, circle: circleID });
    //query.and({ waitingOn: undefined });

    let circleobject = await queryAndPopulateCircleObjects(userID, query, 1);

    return circleobject;

}

module.exports.markDelivered = async function (userID, circleObjectIDs, device) {

    try {

        //console.log('marking delivered:' + circleObjectIDs.length + ' for user: ' + userID + ' device: ' + device);

        if (Array.isArray(circleObjectIDs)) {
            if (circleObjectIDs.length > 0) {
                await CircleObjectNewItem.deleteMany({ user: userID, circleObject: { $in: circleObjectIDs }, device: device });
            }
        }

        return;

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        //throw new Error(msg);
    }

}


module.exports.saveNewItem = async function (circleID, circleObject, skipDevice) {

    try {
        //let user = await User.findOne({ _id: userID });
        let userCircles = await UserCircle.find({ circle: circleID, removeFromCache: null }).populate({ path: "user", populate: [{ path: 'blockedList', }] });

        for (let u = 0; u < userCircles.length; u++) {

            let user = userCircles[u].user;

            for (let i = 0; i < user.devices.length; i++) {

                if (skipDevice == user.devices[i].uuid) continue;

                ///skip this check if in debugging mode as the token will expire for iOS
                if (process.env.NODE_ENV == 'production') {

                    if (user.devices[i].pushToken == null || user.devices[i].expiredToken != null) continue;
                }

                if (user.devices[i].build < 117) continue;

                let exists = await CircleObjectNewItem.findOne({ user: user._id, circleObject: circleObject._id, device: user.devices[i].uuid });

                if (exists && exists instanceof CircleObject)
                    return;

                if (circleObject.type != constants.CIRCLEOBJECT_TYPE.CIRCLEVOTE) {
                    for (let c = 0; c < user.blockedList.length; c++) {
                        let blockedUser = user.blockedList[c];
                        if (circleObject.creator._id.equals(blockedUser._id)) {
                            return;
                        }
                    }
                }

                let notDelivered = new CircleObjectNewItem({ user: user._id, circleObject: circleObject._id, device: user.devices[i].uuid });
                await notDelivered.save();
            }
        }

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        //throw new Error(msg);
    }

}

module.exports.returnNewItemsForDevice = async function (userID,  /*notDeleted*/ deviceID, limit) {

    try {

        var userFieldsToPopulate = '_id username avatar';

        let notDelivered = await CircleObjectNewItem.find({ user: userID, device: deviceID }).sort({ lastUpdate: -1 }).limit(limit)
            .populate({
                path: "circleObject", populate:
                    [
                        { path: "circle" },
                        { path: "creator", userFieldsToPopulate },
                        { path: 'lastEdited', userFieldsToPopulate },
                        { path: "vote", populate: [{ path: 'winner', populate: { path: 'usersVotedFor', select: userFieldsToPopulate } }, { path: 'options', populate: { path: 'usersVotedFor', select: userFieldsToPopulate } }], },
                        { path: 'album', populate: { path: 'media', populate: { path: 'encryptedLineItem' } } },
                        { path: "image" },
                        { path: "recipe" },
                        { path: "video" },
                        { path: "file" },
                        { path: "list", populate: [{ path: 'lastEdited', select: userFieldsToPopulate }, { path: 'tasks', populate: [{ path: 'completedBy', select: userFieldsToPopulate }, { path: 'assignee', select: userFieldsToPopulate }], }] },
                        { path: "reactions", populate: { path: 'users', select: userFieldsToPopulate } },
                        { path: "reactionsPlus", populate: { path: 'users', select: userFieldsToPopulate } },
                        { path: "event", populate: [{ path: 'lastEdited' }, { path: 'encryptedLineItems' }] },
                        { path: "review", populate: { path: 'master' } },
                        { path: "ratchetIndexes", match: { user: userID } },
                    ]
                /*
                populate: { path: 'lastEdited', userFieldsToPopulate },
                populate: { path: "vote", populate: [{ path: 'winner', populate: { path: 'usersVotedFor', select: userFieldsToPopulate } }, { path: 'options', populate: { path: 'usersVotedFor', select: userFieldsToPopulate } }], },
                populate: { path: "image", populate: { path: 'album', populate: [{ path: 'objects', populate: [{ path: 'creator', select: userFieldsToPopulate }, { path: 'image' }, { path: 'video' }] }] } },
                populate: { path: "recipe" },
                populate: { path: "video" },
                populate: { path: "file" },
                populate: { path: "list", populate: [{ path: 'lastEdited', select: userFieldsToPopulate }, { path: 'tasks', populate: [{ path: 'completedBy', select: userFieldsToPopulate }, { path: 'assignee', select: userFieldsToPopulate }], }] },
                populate: { path: "reactions", populate: { path: 'users', select: userFieldsToPopulate } },
                populate: { path: "event", populate: [{ path: 'lastEdited' }, { path: 'encryptedLineItems' }] },
                populate: { path: "review", populate: { path: 'master' } },
            populate: { path: "ratchetIndexes", match: { user: userID } },*/
            });


        let circleObjects = [];

        let user = await User.findById(userID).populate('blockedList');
        for (j = 0; j < user.blockedList.length; j++) {
            let blockedUser = user.blockedList[j];
            circleObjects = circleObjects.filter(obj => obj.creator == null || obj.creator._id.equals(blockedUser._id == false) || obj.type == constants.CIRCLEOBJECT_TYPE.CIRCLEVOTE);
        }
        for (let i = 0; i < notDelivered.length; i++) {
            circleObjects.push(notDelivered[i].circleObject);
        }


        //console.log('new items: ' + circleObjects.length + ' for user: ' + userID + ' device: ' + deviceID);
        return circleObjects;

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        throw new Error(msg);
    }

}


queryAndPopulateCircleObjects = async function (userID, query, limit) {


    var userFieldsWithAvatar = '_id username avatar';
    var userFieldsToPopulate = '_id username';

    try {
        //Don't populate pinnedUsers, a string array is expected on the client
        let circleobjects = await query.sort({ lastUpdate: -1 }).limit(limit)
            .populate("lastEdited", userFieldsToPopulate).populate("creator", userFieldsToPopulate).populate("circle").populate({ path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor', select: userFieldsToPopulate } }, { path: 'options', populate: { path: 'usersVotedFor', select: userFieldsToPopulate } }] })
            .populate({ path: 'album', populate: { path: 'media', populate: { path: 'encryptedLineItem' } } })
            .populate("image").populate("recipe").populate("video").populate("file")
            .populate({ path: 'list', populate: [{ path: 'lastEdited', select: userFieldsToPopulate }, { path: 'tasks', populate: [{ path: 'completedBy', select: userFieldsToPopulate }, { path: 'assignee', select: userFieldsToPopulate }], }] })
            .populate({ path: 'reactions', populate: { path: 'users', select: userFieldsToPopulate } })
            .populate({ path: 'reactionsPlus', populate: { path: 'users', select: userFieldsToPopulate } })
            .populate({ path: 'event', populate: [{ path: 'lastEdited' }, { path: 'encryptedLineItems' }] })
            .populate({ path: 'review', populate: { path: 'master' } })
            .populate({
                path: 'ratchetIndexes', match: { user: userID },
            });

        let copyobjects = circleobjects;
        if (circleobjects != null && circleobjects.length > 0) {
            //console.log('break');

            let user = await User.findById(userID).populate('blockedList');
            for (i = 0; i < user.blockedList.length; i++) {
                let blockedUser = user.blockedList[i];
                copyobjects = circleobjects.filter(obj => obj.creator == null || obj.creator._id.equals(blockedUser._id) == false || obj.type == constants.CIRCLEOBJECT_TYPE.CIRCLEVOTE);
            }

        }

        return copyobjects;

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        throw new Error(msg);
    }

}


module.exports.returnNewObjectsForAllUserCircles = async function (userID, hiddenOpen, /*notDeleted*/ circleLastUpdates) {

    try {
        var query = UserCircle.find({});

        query.where({ user: userID, circle: { $ne: null }, removeFromCache: null });

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
            .populate({ path: "user", select: userFieldsToPopulate }).populate("circle").exec();


        let circleObjects = [];

        for (let i = 0; i < usercircles.length; i++) {

            //if (usercircles[i].circle == null || ) continue;

            var partialResults;

            if (circleLastUpdates != undefined) {
                //find the corresponding lastItemDate
                for (let j = 0; j < circleLastUpdates.length; j++) {

                    if (usercircles[i].circle._id.equals(circleLastUpdates[j].circleID) == true) {
                        //console.log(usercircles[i].lastItemUpdate.valueOf());
                        //console.log(circleLastUpdates[j].lastFetched);
                        if (usercircles[i].lastItemUpdate > circleLastUpdates[j].lastFetched) {
                            partialResults = await this.findCircleObjectsNewThan(userID, circleLastUpdates[j].circleID, circleLastUpdates[j].lastFetched, usercircles[i].created, 100);
                        }

                    }
                }

            } else {
                partialResults = await this.findCircleObjectsLimit(userID, usercircles[i].circle._id, usercircles[i].created, 100);

            }

            if (partialResults) {
                circleObjects.push(partialResults);
            }
        }


        return circleObjects;

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        throw new Error(msg);
    }

}


/*
module.exports.returnMostRecentObjects = async function (userID, circleID, created) {
 
    try {
        let circleobjects = await CircleObject.find({ "circle": circleID, lastUpdate: { $gt: created }, type: { $ne: 'deleted' } }).sort({ lastUpdate: -1 }).limit(100)
            .populate("creator").populate("circle").populate({ path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] })
            .populate("image").populate("gif").populate("recipe").populate("link").populate("video")
            .populate({ path: 'list', populate: [{ path: 'lastEdited' }, { path: 'tasks', populate: [{ path: 'completedBy' }, { path: 'assignee' }], }] })
            .populate({ path: 'reactions', populate: { path: 'users' } })
            .populate({ path: 'event', populate: [{ path: 'encryptedLineItems', populate: [{ path: 'ratchetindex', populate: { path: 'user' } }] }] })
            .populate({ path: 'review', populate: { path: 'master' } }).populate({
                path: 'ratchetIndexes', match: { user: userID },
            });
 
        //await usercircleLogic.updateLastAccessed(circleID, userID, true);
 
        return circleobjects;
 
    } catch (err) {
        let msg = await logUtil.logError(err, true);
        return null;
    }
 
 
}*/
/*
module.exports.returnNewObjects = async function (userID, circleID, circleLastUpdate) {
 
    try {
        let circleobjects = await CircleObject.find({ "circle": circleID, lastUpdate: { $gt: circleLastUpdate } }).sort({ lastUpdate: -1 })
            .populate("creator").populate("circle").populate({ path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] })
            .populate("image").populate("gif").populate("recipe").populate("link").populate("video")
            .populate({ path: 'list', populate: [{ path: 'lastEdited' }, { path: 'tasks', populate: [{ path: 'completedBy' }, { path: 'assignee' },], },] })
            .populate({ path: 'event', populate: [{ path: 'encryptedLineItems', populate: [{ path: 'ratchetindex', populate: { path: 'user' } }] }] })
            .populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } })
            .populate({
                path: 'ratchetIndexes', match: { user: userID },
            });
 
        //await usercircleLogic.updateLastAccessed(circleID, userID, true);
 
        return circleobjects;
 
    } catch (err) {
        let msg = await logUtil.logError(err, true);
        return null;
    }
 
 
}
*/





/***************************************************************************
 * Deletes all objects within a circle.
 * Should only be called when a circle is being deleted.
 * 
 * TODO: validate the parameters
 ***************************************************************************/
module.exports.deleteAllCircleCircleObjects = function deleteAllCircleCircleObjects(circle) {
    return new Promise(function (resolve, reject) {

        CircleObject.deleteMany({ "circle": circle._id })
            .then(function (object) {
                return resolve();
            })
            .catch(function (err) {
                console.error(err);
                return reject(err);
            });

    });
}

module.exports.deleteByVoteID = async function (voteID, req) {

    try {
        var circleObject = await CircleObject.findOne({ 'vote': voteID });

        if (!(circleObject instanceof CircleObject)) throw new Error(("Could not find CircleObject by vote"));

        return await this.deleteCircleObject(circleObject, req);
    } catch (err) {
        console.error(err);
    }

    return false;
}

module.exports.setTimer = function (circleObject, circle) {
    if (circleObject.timer) {

        if (circleObject.timer == 1) {
            circleObject.oneTimeView = true;
        } else {
            let timerExpires = new Date(Date.now() + (circleObject.timer * 1000));
            circleObject.timerExpires = timerExpires;
        }
        //circleObject.timerUser = true;

    } /*else {
         if (circle.privacyDisappearingTimer) {
 
             let seconds = circle.privacyDisappearingTimer * 1000 * 60 * 60;
 
             //this is in hours
             let timerExpires = new Date(Date.now() + seconds);
             circleObject.timerExpires = timerExpires;
             circleObject.timer = seconds;
         }
 
     }*/

    return circleObject;

}

module.exports.hideCircleObject = async function (circleObjectID, circleID, userID) {

    try {


        let circleObject = await CircleObject.findById(circleObjectID);

        for (let i = 0; i < circleObject.ratchetIndexes.length; i++) {

            if (circleObject.ratchetIndexes[i].user == userID) {

                await CircleObject.updateOne(
                    { "_id": circleObjectID, "ratchetIndexes._id": circleObject.ratchetIndexes[i]._id },
                    {
                        "$set": {
                            "ratchetIndexes.$.active": false
                        }
                    }

                );
            }


        }

        //await CircleObject.updateOne({ '_id': circleObjectID }, { $pull: { 'ratchetIndexes': { user: userID, } } });

        //if (req) deviceLogic.sendDeleteNotification(circleObject._id, circleObject.circle, req.user.id, req.headers.devicetoken);
        //if (updateLastItemUpdate) usercircleLogic.updateLastItemUpdateOnly(circleID);

        return true;
    } catch (err) {
        console.error(err);
    }

    return false;

}

module.exports.deleteAllForUser = async function (user) {

    try {
        let circleObjects = await CircleObject.find({ creator: user._id, removeFromCache: null });

        console.log('deleting circleObjects.length posts');

        for (let i = 0; i < circleObjects.length; i++) {

            this.deleteCircleObject(circleObjects[i], null);

        }


    } catch (err) {
        console.error(err);
    }
}

module.exports.deleteCircleObject = async function (circleObject, req, updateLastItemUpdate, customNotification) {

    try {
        //get the creatorID. It is not known whether it has been populated
        var creatorID = null;

        if (circleObject.creator != null && circleObject.creator != undefined) {
            creatorID = circleObject.creator._id;
            if (creatorID == null || creatorID == undefined) {//not populated
                creatorID = circleObject.creator;
            }
        }

        ///needs another try because if something goes wrong, we still want the CircleObject to be deleted
        try {
            if (circleObject.type == 'circlevideo') {

                await videoLogic.deleteCircleVideo(creatorID, circleObject.video);

            } else if (circleObject.type == 'circleimage') {
                circleObject.removeFromCache = circleObject.image;
                imageLogic.deleteCircleImage(creatorID, circleObject.image)

            } else if (circleObject.type == 'circlevote') {

                await circleObject.populate('vote');

                if (circleObject.vote.type == constants.VOTE_TYPE.REMOVE_MEMBER) {
                    try {
                        ///find the UserCircle and set beingVotedOut to false
                        let userCircle = await UserCircle.findOne({ user: circleObject.vote.object, circle: circleObject.circle });
                        if (userCircle instanceof UserCircle) {
                            userCircle.beingVotedOut = false;
                            await userCircle.save();
                        }

                    } catch (err) {
                        logUtil.logError(err, true);
                    }
                }

                invitationLogic.deleteByVoteID(circleObject.vote._id, circleObject.circle);
                voteLogic.deleteByVote(circleObject.vote);

            } else if (circleObject.type == 'circlelist') {

                circleObject.removeFromCache = circleObject.list;
                circleListLogic.deleteCircleList(circleObject.list);

            } else if (circleObject.type == 'circlerecipe') {

                circleObject.removeFromCache = circleObject.recipe;
                circleRecipeLogic.deleteCircleRecipe(circleObject.recipe);
            } else if (circleObject.type == 'circleevent') {

                circleObject.removeFromCache = circleObject.event;
                circleEventLogic.deleteCircleEvent(circleObject.event);
            }
        } catch (err) {
            console.error(err);
        }


        let type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEMESSAGE;

        if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEEVENT)
            type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEEVENT;
        else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEIMAGE)
            type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEIMAGE;
        else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEALBUM)
            type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEALBUM;
        else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEVIDEO)
            type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEVIDEO;
        else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEGIF)
            type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEGIF;
        else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLERECIPE)
            type = constants.CIRCLEOBJECT_ENGLISH.CIRCLERECIPE;
        else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEVOTE)
            type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEVOTE;
        else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLELIST)
            type = constants.CIRCLEOBJECT_ENGLISH.CIRCLELIST;
        else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLELINK)
            type = constants.CIRCLEOBJECT_ENGLISH.CIRCLELINK;
        else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEREVIEW)
            type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEREVIEW;
        else if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEEVENT)
            type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEEVENT;

        circleObject.ratchetIndexes = undefined;
        circleObject.pinnedUsers = undefined;
        circleObject.body = "";
        circleObject.url = undefined;
        circleObject.type = "deleted";
        circleObject.creator = undefined;
        circleObject.link = undefined;
        circleObject.vote = undefined;
        circleObject.review = undefined;
        circleObject.image = undefined;
        circleObject.event = undefined;
        circleObject.blob = undefined;
        circleObject.movie = undefined;
        circleObject.list = undefined;
        circleObject.recipe = undefined;
        circleObject.reactions = undefined;
        circleObject.reactionsPlus = undefined;
        circleObject.timer = undefined;
        circleObject.timerExpires = undefined;

        circleObject.lastUpdate = Date.now();

        await circleObject.save();


        if (req != null) {


            var notification = req.user.username + " deleted an ironclad " + type;
            if (customNotification != undefined && customNotification != null)
                notification = customNotification;

            var notificationType = constants.NOTIFICATION_TYPE.DELETE;
            let oldNotification = "Member deleted ironclad message";

            deviceLogic.sendDeleteNotification(circleObject._id, circleObject.circle, req.user.id, req.headers.devicetoken, notification, notificationType, oldNotification);

            if (updateLastItemUpdate) usercircleLogic.updateLastItemUpdateOnly(req.user.id, circleObject.circle._id);
        }



        return true;
    } catch (err) {
        logUtil.logError(err, true);
    }

    return false;

}



module.exports.refreshNeeded = async function (userID, circleObjectID, skipDevice) {

    try {
        let user = await User.findOne({ _id: userID });

        for (let i = 0; i < user.devices.length; i++) {

            if (skipDevice == user.devices[i].uuid) continue;

            let exists = await CircleObjectRefeshNeeded.findOne({ user: userID, circleObject: circleObjectID, device: user.devices[i].uuid });

            if (exists && exists instanceof CircleObject)
                return;

            let refreshNeeded = CircleObjectRefeshNeeded({ user: userID, circleObject: circleObjectID, device: user.devices[i].uuid });
            await refreshNeeded.save();
        }

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        //throw new Error(msg);
    }

}



module.exports.findRefreshNeededObjects = async function (userID, device) {

    try {

        let refreshNeeded = await CircleObjectRefeshNeeded.find({ user: userID, device: device }).populate("circleObject");

        let arrayFilter = [];

        for (let i = 0; i < refreshNeeded.length; i++) {

            arrayFilter.push(refreshNeeded[i].circleObject._id);
        }

        return await this.findCircleObjectsInArray(userID, arrayFilter);

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        //throw new Error(msg);
    }

}


module.exports.markReceived = async function (userID, device, circleObjects) {

    try {

        let arrayFilter = [];

        for (let i = 0; i < circleObjects.length; i++) {

            arrayFilter.push(circleObjects[i]._id);  //
        }

        await CircleObjectRefeshNeeded.deleteMany({ user: userID, device: device, circleObject: { $in: arrayFilter } })

    } catch (err) {
        let msg = await logUtil.logError(err, true);
    }

    return;

}