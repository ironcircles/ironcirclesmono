
/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates logic to send a system message.  
 * System messages are IronCircle initiated.
 * 
 * This includes welcome messages, voting results, users has left/joined a circle, etc.
 * 
 *  
 ***************************************************************************/
const CircleObject = require('../models/circleobject');
const UserCircle = require('../models/usercircle');
const constants = require('../util/constants');
const logUtil = require('../util/logutil');
const userCircleLogic = require('./usercirclelogic');
const deviceLogicSingle = require('../logic/devicelogicsingle');
var randomstring = require("randomstring");

module.exports.sendMessage = async function (circle, message, invitee) {

    try {

        var circleObject = new CircleObject({
            //creator : user.id,
            circle: circle,
            type: 'systemmessage',
            body: message,
            lastUpdate: Date.now(),
            seed: randomstring.generate({
                length: 40,
                charset: 'alphabetic',

            }),
            created: Date.now(),
        });

        // save the circleobject
        await circleObject.save();

        var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
        var oldNotification = "New circle notification";

        if (invitee) {
            await deviceLogicSingle.sendMessageNotificationToCircle(
                circleObject, 
                circle,
                invitee, 
                null, 
                circleObject.created,
                message,
                notificationType,
                oldNotification,
                null
            );
        } else {
            await deviceLogicSingle.sendMessageNotificationToCircle(
                circleObject, 
                circle,
                null, 
                null, 
                circleObject.created,
                message,
                notificationType,
                oldNotification,
                null
            );
        }

        //await userCircleLogic.flipShowBadgesOn(circle, null, circleObject.created);

        return circleObject;


    } catch (err) {
        console.error(err);

    }

}

module.exports.sendMessageAllCircles = async function (userID, message) {

    try {

        let userCircles = await UserCircle.find({ user: userID });

        for (let i = 0; i < userCircles.length; i++) {

            var circleObject = new CircleObject({
                //creator : user.id,
                circle: userCircles[i].circle,
                type: 'systemmessage',
                body: message,
                lastUpdate: Date.now(),
                seed: randomstring.generate({
                    length: 40,
                    charset: 'alphabetic'
                }),
                created: Date.now(),
            });

            // save the circleobject
            await circleObject.save();
        }


    } catch (err) {
        console.error(err);

    }

}


