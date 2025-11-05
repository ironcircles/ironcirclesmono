/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates access control functions.  Validates a user can access
 * a circle, image, or avatar.  
 * 
 * TODO: Most callback functions have been replaced with promises.  
 * Remove the rest.  
 * 
 *  
 ***************************************************************************/
const UserCircle = require('../models/usercircle');
const Circle = require('../models/circle');
const CircleObject = require('../models/circleobject');
const CircleImage = require('../models/circleimage');
const CircleListTemplate = require('../models/circlelisttemplate');
const CircleRecipeTemplate = require('../models/circlerecipetemplate');
const ObjectID = require('mongodb').ObjectId;
const logUtil = require('../util/logutil');
const CircleObjectCircle = require('../models/circleobjectcircle');
const ReplyObject = require('../models/replyobject');

module.exports.canUserModifyReplyObject = async function (userID, replyObjectID, circleObjectID) {
    try {

        var replyObject = await ReplyObject.findOne({'_id': replyObjectID, 'creator': userID });

        if (!(replyObject instanceof ReplyObject)) {

            //f it's already deleted, pass back so app can delete from cache
            var deletedObject = await ReplyObject.findOne({ '_id': replyObjectID, 'type': 'deleted' });
            if (deletedObject instanceof ReplyObject) {
                return deletedObject;
            }

            var circleObjectCircle = await CircleObjectCircle.findOne({ 'circleObject': circleObjectID }).populate(['circleObject', 'circle']);
            if (circleObjectCircle instanceof CircleObjectCircle) {
                return circleObjectCircle;
            } else {
                console.log("access denied for userid: " + userID + " circleObjectID: " + circleObjectID);
                throw ("access denied");
            }

        }

        return replyObject;
    } catch (err) {
        let msg = await logUtil.logError(err, true);
        throw err;
    }
}

module.exports.canUserAccessCircle = async function (userID, circleID) {

    try {

        //console.log("canUserAccessCircle: " + userID + " " + circleID); 
        
        //this will toss an error if the params are invalid
        let circleIDObj = new ObjectID(circleID);
        let userIDObj = new ObjectID(userID);

        var usercircle = await UserCircle.findOne({ 'circle': circleIDObj, 'user': userIDObj }).populate('user').populate('circle').exec();

        if (usercircle && usercircle instanceof UserCircle)
            return usercircle;
        else
            throw new Error("Access denied");

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        throw new Error("Access denied");
    }

}

module.exports.canUserAccessUserCircle = async function (userID, userCircleID) {

    try {

        var userCircle = await UserCircle.findOne({ _id: userCircleID, user: userID }).populate('user').populate('circle').exec();
        if (userCircle && userCircle instanceof UserCircle)
            return userCircle;
        else
            throw new Error("Access denied");

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        throw err;
    }
}

module.exports.canUserAccessCircleObject = async function (userID, circleObjectID) {

    try {

        var circleObject = await CircleObject.findOne({ '_id': circleObjectID, });

        if (!(circleObject instanceof CircleObject)) throw new Error("access denied")

        var userCircle = await UserCircle.findOne({ circle: circleObject.circle, user: userID }).populate('user').populate('circle').exec();

        if (userCircle && userCircle instanceof UserCircle)
            return userCircle;
        else
            throw new Error("Access denied");

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        throw err;
    }

}

module.exports.canUserModifyCircleObject = async function (userID, circleObjectID) {

    try {

        var circleObject = await CircleObject.findOne({ '_id': circleObjectID, 'creator': userID }); //.populate('circle');

        if (!(circleObject instanceof CircleObject)) {

            //if it's already deleted, pass back so app can delete from cache
            var deletedObject = await CircleObject.findOne({ '_id': circleObjectID, 'type': 'deleted' }); //.populate('circle');
            if (deletedObject instanceof CircleObject) {
                return deletedObject;
            }

            var circleObjectCircle = await CircleObjectCircle.findOne({ 'circleObject': circleObjectID }).populate(['circleObject', 'circle']);
            if (circleObjectCircle instanceof CircleObjectCircle) {
                return circleObjectCircle;
            } else {
                console.log("access denied for userid: " + userID + " circleObjectID: " + circleObjectID);
                throw ("access denied");
            }
        }

        return circleObject;
    } catch (err) {
        let msg = await logUtil.logError(err, true);
        throw err;
    }

}


module.exports.canUserAccessCircleListTemplate = async function (userID, templateID) {

    try {
        var template = await CircleListTemplate.findOne({ '_id': templateID, 'owner': userID }).populate('owner').exec();

        if (!template)
            throw new Error('access denied');

        return template;

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        throw err;
    }

}

module.exports.canUserAccessCircleRecipeTemplate = async function (userID, templateID) {

    try {
        var template = await CircleRecipeTemplate.findOne({ '_id': templateID, 'owner': userID }).populate('owner').exec();

        if (!(template instanceof CircleRecipeTemplate))
            throw new Error('access denied');

        return template;

    } catch (err) {
        let msg = await logUtil.logError(err, true);
        throw err;
    }

}