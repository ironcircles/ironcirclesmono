const CircleListTask = require('../models/circlelisttask');
const CircleEvent = require('../models/circleevent');
const Invitations = require('../models/invitation');
const CircleVote = require('../models/circlevote');
const RatchetIndex = require('../models/ratchetindex');
const Invitation = require('../models/invitation');
const HostedInvitation = require('../models/hostedinvitation');
const MagicNetworkLink = require('../models/magicnetworklink');
const deviceLogic = require('../logic/devicelogic');
const voteLogic = require('../logic/votelogicasync');
const deviceLogicSingle = require('../logic/devicelogicsingle');
const constants = require('../util/constants');
const logUtil = require('../util/logutil');
const User = require('../models/user');
const Metric = require('../models/metric');
const UserCircle = require('../models/usercircle');
const CircleObject = require('../models/circleobject');
const Log = require('../models/log');
const circleObjectLogic = require('../logic/circleobjectlogic');
const Circle = require('../models/circle');
const { json } = require('body-parser');
const { deactivateUserCircle } = require('../logic/usercirclelogic');
const CircleObjectCircle = require('../models/circleobjectcircle');
const metricLogic = require('../logic/metriclogic');
const IronCurrency = require('../models/ironcurrency');
const IronCoinWallet = require('../models/ironcoinwallet');
const HostedFurnace = require('../models/hostedfurnace');
const AgoraCall = require('../models/circleagoracall');
const ObjectId = require('mongodb').ObjectId;

const second = 1000;
const minute = second * 60;
const hour = minute * 60;
const day = hour * 24;


///poll the server to see if any active calls have ended
module.exports.checkActiveCalls = async function () {

    // let activeCalls = await AgoraCall.find({ active: true }).exec();

    // for (let i = 0; i < activeCalls.length; i++) {


    //     const userStates = await agoraSDK.getChannelUsers({
    //         appId: 'your-app-id',
    //         channelName: call.circleId
    //     });

    //     // Check if users are still in the call
    //     const expectedUsers = call.participants;
    //     const actualUsers = userStates.map(u => u.uid);

    //     const leftUsers = expectedUsers.filter(uid => !actualUsers.includes(uid));

    //     if (leftUsers.length > 0) {
    //         // Users left - update billing
    //         await handleUsersLeft(call.circleId, leftUsers);
    //     }


    //     let call = activeCalls[i];
    //     if (call.endTime && call.endTime < new Date()) {
    //         //call has ended, update the call record
    //         call.active = false;
    //         await call.save();

    //         //log the call minutes
    //         let agoraCallMinutes = new AgoraCallMinutes({
    //             agoraCall: call._id,
    //             duration: Math.floor((call.endTime - call.startTime) / 1000),
    //             startTime: call.startTime,
    //             endTime: call.endTime,
    //             user: call.participants //assuming participants is an array of user IDs
    //         });
    //         await agoraCallMinutes.save();
    //     }
    // }



};



///Was used when metrics first came online to back populate existing users
/*module.exports.metrics = async function () {
    let users = await User.find({ keyGen: true });

    for (let i = 0; i < users.length; i++) {

        saveMetric(users[i]);
    }
}

async function saveMetric(user) {
    try {
        let userCircle = await UserCircle.findOne({ user: user._id }).sort({ lastAccessed: -1 }).limit(1);
        let count = await CircleObject.countDocuments({ creator: user._id });

        let metric = await Metric.findOne({ user: userCircle.user._id });

        if (metric instanceof Metric) {
            metric.recentMessageCount = count;
            metric.lastAccessed = userCircle.lastAccessed;


        } else {
            metric = new Metric({ user: user, lastAccessed: userCircle.lastAccessed, recentMessageCount: count });

        }

        await metric.save();
    } catch (err) {

        console.log(err);

    }

}*/



module.exports.timeoutMagicLinks = async function () {

    try {
        let seven = day * 7;
        let expire = new Date(Date.now() - seven);

        var result = await MagicNetworkLink.updateMany({ created: { $lte: expire }, active: { $ne: false } }, { active: false });

        console.log(result);

    } catch (err) {
        logUtil.logError(err, true);
    }

}

module.exports.cleanLogs = async function () {

    try {
        let duration = day * 30;
        let expire = new Date(Date.now() - duration);

        var result = await Log.deleteMany({ created: { $lte: expire } });

        console.log(result);

    } catch (err) {
        logUtil.logError(err, true);
    }

}


module.exports.processWaitingObjects = async function () {

    try {

        //console.log('processWaitingObjects worker fired off at ' + new Date().toString());

        //process anything waiting for more than 15 minutes.
        let expireMinutes = minute * 15;
        let expireDate = new Date(Date.now() - expireMinutes);

        let circleObjects = await CircleObject.find({ waitingOn: { $ne: undefined }, created: { $lte: expireDate } }).populate(['creator', 'circle']).sort({ created: 1 });

        for (let i = 0; i < circleObjects.length; i++) {

            let circleObject = circleObjects[i];

            await circleObjectLogic.processSingleWaitingObject(circleObject, true);

        }

        //console.log('processWaitingObjects worker finished at ' +  new Date().toString());


    } catch (err) {
        logUtil.logError(err, true);
    }

}


module.exports.disappear = async function () {

    try {

        //console.log('disappear fired off');

        let circles = await Circle.find({ $and: [{ privacyDisappearingTimerSeconds: { $ne: 0 } }, { privacyDisappearingTimerSeconds: { $ne: undefined } }] });


        for (let j = 0; j < circles.length; j++) {

            let circle = circles[j];
            //console.log(circle.privacyDisappearingTimerSeconds);
            //safety check 
            if (circle.privacyDisappearingTimerSeconds == 0) continue;


            let timerExpires = new Date(Date.now() - circles[j].privacyDisappearingTimerSeconds * 1000);

            //console.log(Date.now());
            //console.log(expires);

            //console.log(timerExpires);

            let circleObjects = await CircleObject.find({ circle: circles[j]._id, type: { $ne: 'deleted' }, created: { $lte: timerExpires } });

            if (!circleObjects || circleObjects.length == 0) continue;

            for (let i = 0; i < circleObjects.length; i++) {

                //console.log(Date.now());
                console.log('message disappeared');
                circleObjectLogic.deleteCircleObject(circleObjects[i], null);
            }

            deviceLogicSingle.sendDataOnlyRefreshToCircle(circles[j]._id);

        }

        let circleObjects = await CircleObject.find({ timerExpires: { $lte: new Date() } });

        if (!circleObjects || circleObjects.length == 0) return;

        for (let i = 0; i < circleObjects.length; i++) {

            try {
                circleObjectLogic.deleteCircleObject(circleObjects[i], null, true);
                //deviceLogic.sendDeleteNotification(circleObjects[i], circleObjects[i].circle);
                deviceLogicSingle.sendDataOnlyRefreshToCircle(circleObjects[i].circle);
                console.log('user message disappeared');

            } catch (err) {
                logUtil.logError(err, true);
            }

        }

    } catch (err) {
        logUtil.logError(err, true);
    }

}

module.exports.scheduledMessage = async function () {

    try {

        let sendAt = new Date(Date.now());
        let circleObjects = await CircleObject.find({ type: { $ne: 'deleted' }, circle: undefined, scheduledFor: { $lte: sendAt } }).sort({ scheduledFor: 1 }).populate(['creator']);
        if (!circleObjects || circleObjects.length == 0) return;

        for (let i = 0; i < circleObjects.length; i++) {

            let obj = circleObjects[i];
            let connection = await CircleObjectCircle.findOne({ circleObject: obj._id }).populate(['circle', 'taggedUsers']);
            metricLogic.incrementPosts(obj.creator);

            if (connection == null) {
                // await CircleObject.deleteOne(obj);
            } else {
                obj.lastUpdate = obj.scheduledFor;
                obj.created = obj.scheduledFor;
                obj.circle = connection.circle._id;
                obj.save();

                let type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEMESSAGE;
                var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
                let oldNotification = "New ironclad message";
                if (obj.type == constants.CIRCLEOBJECT_TYPE.CIRCLEGIF) {
                    type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEGIF;
                } else if (obj.type == constants.CIRCLEOBJECT_TYPE.CIRCLEEVENT) {
                    await obj.populate({ path: 'event', populate: [{ path: 'encryptedLineItems', populate: [{ path: 'ratchetIndex' }] }] });
                    type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEEVENT;
                    notificationType = constants.NOTIFICATION_TYPE.EVENT;
                    oldNotification = "New ironclad event";
                } else if (obj.type == constants.CIRCLEOBJECT_TYPE.CIRCLERECIPE) {
                    await obj.populate('recipe');
                    type = constants.CIRCLEOBJECT_ENGLISH.CIRCLERECIPE;
                    //notificationType = constants.NOTIFICATION_TYPE.RECIPE;
                    oldNotification = "New ironclad recipe";
                } else if (obj.type == constants.CIRCLEOBJECT_TYPE.CIRCLELIST) {
                    await obj.populate({ path: 'list', populate: [{ path: 'tasks', populate: { path: 'assignee' } }, /*{ path: 'lastEdited}' }*/] });
                    type = constants.CIRCLEOBJECT_ENGLISH.CIRCLELIST;
                } else if (obj.type == constants.CIRCLEOBJECT_TYPE.CIRCLEIMAGE) {
                    await obj.populate('image');
                    type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEIMAGE;
                } else if (obj.type == constants.CIRCLEOBJECT_TYPE.CIRCLEVIDEO) {
                    await obj.populate('video');
                    type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEVIDEO;
                } else if (obj.type == constants.CIRCLEOBJECT_TYPE.CIRCLEFILE) {
                    await obj.populate('file');
                    type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEFILE;
                } else if (obj.type == constants.CIRCLEOBJECT_TYPE.CIRCLEVOTE) {
                    await obj.populate({ path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] });
                    type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEVOTE;
                }
                var notification = obj.creator.username + " sent a new ironclad " + type;
                await obj.populate(['circle', 'creator']);

                deviceLogicSingle.sendMessageNotificationToCircle(obj, connection.circle._id, obj.creator._id, obj.device.pushToken, obj.lastUpdate, notification, notificationType, oldNotification, connection.taggedUsers);
                //should skip saving to creator's device
                circleObjectLogic.saveNewItem(connection.circle._id, obj, obj.device);

                await CircleObjectCircle.deleteOne(connection);

                console.log('message sent');
            }
        }
    } catch (err) {
        logUtil.logError(err, true);
    }
}

module.exports.sendReminders = async function () {

    try {

        sendTaskReminders();
        sendEventReminders();
        sendInviteReminders();
    } catch (err) {
        logUtil.logError(err, true);
    }

}

module.exports.deleteExpiredPublicKeys = async function () {

    try {
        let days = day * 90;
        let keyExpirationDate = new Date(Date.now() - days);

        let counter = 0;


        ///FIRST CHECK
        ///Remove any devices that have been deactivated
        //let users = await User.find({'devices.keysRemoved': {$ne: true}, $or: [{ 'devices.expiredToken': { $ne: null }}, {'devices.activated': false }]});
        let users = await User.find({ 'devices.keysRemoved': { $exists: false }, 'devices.activated': false });
        for (let i = 0; i < users.length; i++) {
            let user = users[i];

            let devices = user.devices;

            for (let d = 0; d < devices.length; d++) {

                let device = devices[d];

                //sanity check
                if (device.activated == false || device.expiredToken != null) {

                    try {

                        counter = counter + 1;
                        await UserCircle.updateMany({ 'ratchetPublicKeys': { $ne: null } }, { $pull: { 'ratchetPublicKeys': { user: user._id, device: device.uuid, } } });

                        device.keysRemoved = true;
                        await user.save();

                    } catch (err) {

                        logUtil.logError(err, true);
                    }
                }

            }

        }



        // console.log('COUNTER FIRST: ' + counter);

        //SECOND check
        //Remove any keys that are old than 180 days

        let updateManyResult = await UserCircle.updateMany({ removeFromCache: { $exists: false }, ratchetPublicKeys: { $ne: null } }, { $pull: { 'ratchetPublicKeys': { 'created': { $lte: keyExpirationDate } } } });
        //console.log('COUNTER SECOND: ' + updateManyResult);

    } catch (err) {
        logUtil.logError(err, true);
    }
}

async function sendTaskReminders() {

    try {

        let start = new Date(Date.now());
        let end = new Date(start.getTime() + hour);

        //console.log(start);
        let circleListTask = await CircleListTask.find({
            'due': {
                $gt: start,
                $lt: end
            }
        }).populate('assignee').exec();

        sendTaskRemindersForArray(circleListTask, 'Task in IronCircles is due within the hour', constants.REMINDER_TYPE.DUE_IN_HOUR);

        start = new Date(Date.now() + hour);
        //console.log(start);
        end = new Date(Date.now() + 1000 + day);

        circleListTask = await CircleListTask.find({
            'due': {
                $gt: start,
                $lt: end
            }
        }).populate('assignee').exec();

        sendTaskRemindersForArray(circleListTask, 'Task in IronCircles is due within 24 hours', constants.REMINDER_TYPE.DUE_IN_DAY);

    } catch (err) {

        console.error(err);
    }
}


async function sendTaskRemindersForArray(circleListTasks, reminder, reminderType) {
    try {
        if (circleListTasks.length > 0) {

            for (let i = 0; i < circleListTasks.length; i++) {
                let circleListTask = circleListTasks[i];

                if (circleListTask.assignee != null) {
                    //console.log(reminder + circleListTask.due.toString());
                    deviceLogic.sendReminderToUser(circleListTask.assignee, circleListTask._id, reminder, reminderType);
                }
            }


        }
    } catch (err) {

        console.error(err);
    }

}


async function sendEventReminders() {

    try {

        let start = new Date(Date.now());
        let end = new Date(start.getTime() + (hour * 4));

        let circleEvents = await
            CircleEvent.find({
                'startDate': {
                    $gt: start,
                    $lt: end
                }
            }).populate([{ path: 'lastEdited', select: '_id username' }, { path: 'encryptedLineItems' }]).exec();

        sendEventRemindersForArray(circleEvents, 'Reminder: an event occurs in 4 hours', constants.REMINDER_TYPE.DUE_IN_HOUR);


        start = new Date(Date.now() + (hour * 4));
        end = new Date(Date.now() + 1000 + day);

        circleEvents = await
            CircleEvent.find({
                'startDate': {
                    $gt: start,
                    $lt: end
                }
            }).populate([{ path: 'lastEdited', select: '_id username' }, { path: 'encryptedLineItems' }]).exec();


        sendEventRemindersForArray(circleEvents, 'Reminder: an event occurs in 24 hours', constants.REMINDER_TYPE.DUE_IN_DAY);

    } catch (err) {

        console.error(err);
    }
}


async function sendInviteReminders() {

    try {

        let start = new Date(Date.now());
        let olderThan = new Date(start.getTime() - (hour * 24));

        let invitations = await
            Invitation.find({
                status: 'pending', $or: [{
                    lastReminderSent: {
                        //$gt: start,
                        $lt: olderThan
                    }
                }, { lastReminderSent: null }]
            }
            ).populate('invitee').populate('inviter').populate('circle').exec();


        for (let i = 0; i < invitations.length; i++) {

            try {

                //console.log(invitations[i]._id);

                let trailer = ' a Circle';
                if (invitations[i].dm)
                    trailer = ' a DM';

                if (invitations[i].inviter == null || invitations[i].invitee == null) {
                    console.log('cleanup: ' + invitations[i]);
                    continue;
                }

                if (invitations[i].status == constants.INVITATION_STATUS.PENDING)
                    await deviceLogic.sendInvitation(invitations[i].invitee._id, invitations[i].inviter.username + ' has invited you to' + trailer, invitations[i]);

                invitations[i].lastReminderSent = Date.now();
                await invitations[i].save();

            } catch (err) {

                logUtil.logError(err, true);
            }
        }

    } catch (err) {

        logUtil.logError(err, true);
    }
}

async function sendEventRemindersForArray(circleEvents, reminder, reminderType) {
    try {
        if (circleEvents.length > 0) {

            for (let i = 0; i < circleEvents.length; i++) {
                let circleEvent = circleEvents[i];

                if (circleEvent.circle) {

                    //grab a list of everyone in the circle
                    let userCircles = await UserCircle.find({ circle: circleEvent.circle }); //no need to populate

                    //obsfucated logic
                    for (let u = 0; u < userCircles.length; u++) {

                        //for (let j = 0; j < circleEvent.ratchetIndex; j++) {
                        deviceLogic.sendReminderToUser(userCircles[u].user, circleEvent._id, reminder, reminderType);
                        //}
                    }
                }

            }
        }
    } catch (err) {
        logUtil.logError(err, true);
    }

}

module.exports.timeoutInvitations = async function () {

    try {
        let now = new Date(Date.now());

        //let olderThan = new Date(now.getTime() - (day * 2)); //48 hours

        //console.log(olderThan);

        let invitationVotes = await CircleVote.find({
            type: constants.VOTE_TYPE.ADD_MEMBER, open: true,
            /*'created': {
                $lt: olderThan
            }*/
        }).populate('circle');

        for (let i = 0; i < invitationVotes.length; i++) {


            //grab the Circle
            let circle = invitationVotes[i].circle;
            let vote = invitationVotes[i];

            //quite a few circles have the old invitationTimeout field instead of the new privacyInvitationTimeout.
            //This logic still works because Mongoose gives privacyInvitationTimeout a default value of 48 if the field doesn't exist
            let expire = new Date(now.getTime() - (circle.privacyInvitationTimeout * hour));

            if (vote.created < expire) {
                voteLogic.forceCloseVote(vote, true); //async
            }

        }

        //console.log(invitationVotes.length);


    } catch (err) {
        logUtil.logError(err, true);
    }

}


module.exports.timeoutVotes = async function () {

    try {
        let now = new Date(Date.now());

        let invitationVotes = await CircleVote.find({
            circle: '618b0b0bff07430015e599ad',
            type: constants.VOTE_TYPE.STANDARD, open: true,
        }).populate('circle');

        console.log(invitationVotes.length);

        for (let i = 0; i < invitationVotes.length; i++) {
            let vote = invitationVotes[i];

            //let expire = new Date(now.getTime());
            let expire = new Date(now.getTime() - (day * 7));

            if (vote.created < expire) {
                voteLogic.forceCloseVote(vote, false); //async
            }

        }


    } catch (err) {
        logUtil.logError(err, true);
    }

}

module.exports.deliverMonthlySubscriberCoin = async function () {

    try {
        let now = new Date(Date.now());
        let day = now.getDate();
        console.log(day);

        let currency = new IronCurrency();
        let coins = currency.subscriberCoins;
        let subscribers = await User.find({ accountType: constants.ACCOUNT_TYPE.PREMIUM, linkedAccount: null, "subscribedOn": day });
        for (let i = 0; i < subscribers.length; i++) {
            let subscriber = subscribers[i];
            subscriber.ironCoin += coins;
            await subscriber.save();
        }
    } catch (err) {
        logUtil.logError(err, true);
    }
}

module.exports.publicNetworkActivityChecker = async function () {
    try {

        var then = new Date(new Date().setDate(new Date().getDate() - 60)); //60 days ago
        let networks = await HostedFurnace.find({ discoverable: true });

        for (let i = 0; i < networks.length; i++) {
            let network = networks[i];
            let users = await User.find({ hostedFurnace: network._id }).sort({ lastUpdate: -1 }).limit(1);
            if (users.length > 0) {
                if (users[0].lastUpdate <= then) {
                    network.discoverable = false;
                    network.approved = false;
                    network.override = false;
                    await network.save();
                }
            }
        }

    } catch (err) {
        logUtil.logError(err, true);
    }
}

module.exports.deleteExpiredCircles = async function () {
    try {
        ///delete temporary circles if their expiration date has passed

        let now = new Date(Date.now());

        let temporaryCircles = await Circle.find({
            type: constants.CIRCLE_TYPE.TEMPORARY,
        });

        for (let i = 0; i < temporaryCircles.length; i++) {
            let circle = temporaryCircles[i];
            if (circle.expiration <= now) {
                if (circle.background) {
                    if (circle.backgroundLocation == constants.BLOB_LOCATION.GRIDFS) {
                        gridFS.deleteBlob("circlebackgrounds", circle.background);
                    } else {
                        awsLogic.deleteObject(process.env.s3_backgrounds_bucket, circle.background);
                    }
                }
                await Circle.deleteOne({ "_id": circle._id });
                console.log("done deleting circle");
            }
        }

    } catch (err) {
        logUtil.logError(err, true);
    }
}

module.exports.createWallets = async function () {

    let ninety = day * 90;
    let getCoins = new Date(Date.now() - ninety);

    let users = await User.find({ removeFromCache: null });

    //loop through users
    for (let i = 0; i < users.length; i++) {
        let user = users[i];

        let wallet = await IronCoinWallet.findOne({ user: user.id });
        if (wallet == null || wallet == undefined) {
            wallet = new IronCoinWallet({ user: user, transactions: [] });
        }

        if (user.lastUpdate > getCoins) {
            wallet.balance = 2500;

        } else {
            wallet.balance = 0;
        }

        await wallet.save();
    }


}
