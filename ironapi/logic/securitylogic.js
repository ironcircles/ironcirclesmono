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
const logUtil = require('../util/logutil');

module.exports.canUserAccessCircleReturnCircle = function (userID, circleID) {

    return new Promise(function (resolve, reject) {

        UserCircle.findOne({ 'circle': circleID, 'user': userID })
            .then(function (usercircle) {
                if (usercircle)
                    //return Circle.findOne({'id':circleID});
                    return UserCircle.populate(usercircle, { path: "circle" });
                else
                    throw new Error("access denied");
            }).then((usercircle) => {
                resolve(usercircle.circle);
            })
            .catch(function (err) {
                console.error(err);
                //next(err);
                return reject(err);
            });
    });
}

module.exports.canUserAccessCircleAsync = async function (userID, circleID) {

    try {

        if (!circleID || !userID)  throw new Error("Access denied");
        var usercircle = await UserCircle.findOne({ 'circle': circleID, 'user': userID }).populate('user').populate('circle').exec();

        if (usercircle instanceof UserCircle)
            return usercircle;
        else
        throw new Error('Access denied: + user: ' + userID + ' circle: ' + circleID);

    } catch (err) {
        console.error(err);
        throw new Error('Access denied: + user: ' + userID + ' circle: ' + circleID);
    }

}


module.exports.canUserAccessCircleP = function (userID, circleID) {

    return new Promise(function (resolve, reject) {

        UserCircle.findOne({ 'circle': circleID, 'user': userID })
            .then(function (usercircle) {
                if (usercircle)
                    return usercircle.populate('user');
                else
                    throw new Error("access denied");
            }).then((usercircle) => {
                return usercircle.populate('circle');
            })
            .then((usercircle) => {
                resolve(usercircle);
            })
            .catch(function (err) {
                console.error(err);
                //next(err);
                return reject(err);
            });
    });
}


function canUserAccessCircleObject(userID, circleObjectID, callback) {

    try {

        CircleObject.findOne({ '_id': circleObjectID, 'creator': userID }, function (err, valid) {
            if (err || !valid)
                callback(false);
            else
                callback(true);

        });

    } catch (err) {
        console.error(err);
        return callback(false);
    }

}


function canUserAccessAvatar(userID, avatarUserID, circleID, callback) {

    try {

        if (userID == avatarUserID) {
            callback(true);
        } else if (circleID) {
            canUserAccessCircle(userID, circleID, function (circleCheckCallback) {
                if (circleCheckCallback)
                    callback(true);
                else
                    callback(false);
            });

        } else {
            callback(false);
        }

    } catch (err) {
        console.error(err);
        return callback(false);
    }


}

function canUserAccessFullImage(userID, fullImageID, callback) {

    try {

        CircleImage.findOne({ 'fullImage': fullImageID }, function (err, circleImage) {

            if (err || circleImage.circleobject.creator != userID)
                callback(false);
            else
                callback(true);

        }).populate("circleobject");

    } catch (err) {
        console.error(err);
        return callback(false);
    }

}

//***********************************************************
//***********************************************************
//THESE FUNCTIONS ARE BEING DEPRECATED  (I PROMISE)
//***********************************************************
//***********************************************************

function canUserAccessCircleReturnUserCircle(userID, circleID, callback) {

    try {

        UserCircle.findOne({ 'circle': circleID, 'user': userID }, function (err, usercircle) {
            if (err || !usercircle)
                callback(false);
            else
                callback(true, usercircle);

        }).populate("circle");

    } catch (err) {
        console.error(err);
        return callback(false);
    }

}

function canUserAccessCircle(userID, circleID, callback) {

    try {

        UserCircle.findOne({ 'circle': circleID, 'user': userID }, function (err, usercircle) {
            if (err || !usercircle)
                callback(false);
            else {

                if (!usercircle.circle) { //make sure the circle wasn't deleted
                    callback(false);
                } else {
                    callback(true, usercircle);
                }
            }

        }).populate('circle');

    } catch (err) {
        console.error(err);
        return callback(false);
    }

}

function canUserAccessCircleReturnUserCircle(userID, circleID, callback) {

    try {

        UserCircle.findOne({ 'circle': circleID, 'user': userID }, function (err, usercircle) {
            if (err || !usercircle)
                callback(false);
            else {
                if (!usercircle.circle) { //make sure the circle wasn't deleted
                    callback(false);
                } else {
                    callback(true, usercircle);
                }
            }

        }).populate("circle");

    } catch (err) {
        console.error(err);
        return callback(false);
    }

}



module.exports.canUserAccessCircle = canUserAccessCircle;
module.exports.canUserAccessCircleObject = canUserAccessCircleObject;
module.exports.canUserAccessFullImage = canUserAccessFullImage;
module.exports.canUserAccessAvatar = canUserAccessAvatar;
module.exports.canUserAccessCircleReturnUserCircle = canUserAccessCircleReturnUserCircle;

