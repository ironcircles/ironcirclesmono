const express = require('express');
const router = express.Router();
const passport = require('passport');
const CircleObject = require('../models/circleobject');
const CircleObjectReaction = require('../models/circleobjectreaction');
const RatchetIndex = require('../models/ratchetindex');
const UserCircle = require('../models/usercircle');
const securityLogic = require('../logic/securitylogic');
const metricLogic = require('../logic/metriclogic');
const securityLogicAsync = require('../logic/securitylogicasync');
const circleObjectLogic = require('../logic/circleobjectlogic');
const usercircleLogic = require('../logic/usercirclelogic');
const deviceLogic = require('../logic/devicelogic');
const deviceLogicSingle = require('../logic/devicelogicsingle');
const logUtil = require('../util/logutil');
const constants = require('../util/constants');
const Violation = require('../models/violation');
const CircleObjectCircle = require('../models/circleobjectcircle');
const replyObjectLogic = require('../logic/replyobjectlogic');
const ReplyObject = require('../models/replyobject');
const bodyParser = require('body-parser');
const kyberLogic = require('../logic/kyberlogic');

const { CIRCLEOBJECT_TYPE } = require('../util/constants');
router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

if (process.env.NODE_ENV !== 'production') {
    require('dotenv').load();
}

///post reply
router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

    try {

        let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        ///AUTHORIZATION CHECK
        var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circle);

        if (!(usercircle instanceof UserCircle)) {
            throw new Error('Access denied');
        }

        if (usercircle.beingVotedOut == true) {
            throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
        }

        let circle = usercircle.circle;

        //ReplyObject.updateMany({}, {$unset: {storageID:undefined}}, {multi: true});

        // var replyObjectsAll = await ReplyObject.find({});

        // for (let i = 0; i < replyObjectsAll.length; i++) {
        //     await ReplyObject.deleteOne(replyObjectsAll[i]);
        // }

        //await ReplyObject.delete(ReplyObjectsAll);

        // var count = await ReplyObject.updateMany({},
        //     {
        //         $unset: {
        //             'storageID': "",
        //         }
        //     }, { strict: false}
        // );

        let payload = {};


        ///does the seed from this user already exist?
        var existing = await ReplyObject.findOne({ seed: body.seed, creator: req.user.id, circle: body.circle }).populate('creator').populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).exec();

        if (existing instanceof ReplyObject) {
            logUtil.logAlert(req.user.id + ' tried to post an object that already exists. seed: ' + body.seed);
            payload = { replyobject: existing, msg: "ReplyObject already exists" };

        } else {
            var circleObject = await CircleObject.findById(body.circleObjectID);
            if (!(circleObject instanceof CircleObject))
                throw new Error("CircleObject replying to not found.");

            let replyObject = await ReplyObject.new(body);
            replyObject.creator = req.user.id;
            replyObject.circleObject = circleObject;
            await replyObject.save();
            await replyObject.populate(['creator', 'circleObject']);

            metricLogic.incrementPosts(replyObject.creator);

            let type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEMESSAGE;
            var notification = replyObject.creator.username + " sent a new ironclad reply " + type;
            let oldNotification = "New ironclad message";
            var notificationType = constants.NOTIFICATION_TYPE.REPLY;

            var circleObject = await CircleObject.findById(body.circleObjectID).populate('creator').populate('circle');

            deviceLogicSingle.sendReplyMessageNotificationToWall(circleObject, body.circle, replyObject,
                req.user.id, body.pushtoken, replyObject.lastItemUpdate,
                notification, notificationType, oldNotification, body.taggedUsers
            );

            payload = { replyobject: replyObject, msg: 'Successfully created new ReplyObject' };
        }

        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ msg: msg });
    }
});

/// edit reply
router.put('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

    try {
        let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        let replyObjectID = req.params.id;
        if (replyObjectID == 'undefined') {
            replyObjectID = body.replyObjectID;
        }

        //AUTHORIZATION CHECK
        var userCircle = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleID);
        if (!(userCircle instanceof UserCircle))
            throw new Error('Access denied');

        if (userCircle.beingVotedOut == true) {
            throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
        }

        var userFieldsToPopulate = '_id username avatar';

        var replyObject = await ReplyObject.findOne({ "_id": replyObjectID, creator: req.user.id, circle: body.circleID, circleObject: body.circleObjectID }).populate("creator").populate("circleObject"); //.populate("lastUpdate", userFieldsToPopulate);

        if (replyObject instanceof ReplyObject) {

            //replyObject.lastEdited = req.user.id;
            await replyObject.update(body);
            await replyObject.save();

            await replyObject.populate(['creator', 'lastUpdate', { path: 'reactions', populate: { path: 'users', select: '_id username' } }]);
            //deviceLogicSingle.sendDataOnlyRefreshToCircle(body.circleID);
            deviceLogicSingle.sendDataOnlyReplyMessageNotification(replyObject.circleObject.seed, body.circleID, replyObject, req.user.id, body.pushtoken);

            // return res.status(200).json({ replyObject: replyObject });

            let payload = { replyObject: replyObject };
            payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
            return res.status(200).json(payload);

        } else {
            throw new Error('Access to object denied');
        }

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ msg: msg });
    }
});

//Returns x number of replies from a specific date backwards
router.get('/byolder/:circleObjectID&:circleID&:date', passport.authenticate('jwt', { session: false }), async (req, res) => {
    try {

        ///AUTHORIZATION CHECK
        //var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.params.circleID);
        var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, req.params.circleID);

        var circleObject = await CircleObject.findById(req.params.circleObjectID);

        if (!usercircle)
            return res.status(400).json({ err: 'Access denied' });

        if (!circleObject)
            return res.status(500).json({ err: "replying to nothing" });

        let replyobjects = await replyObjectLogic.findReplyObjectsOlderThan(req.user.id, req.params.circleObjectID, req.params.date, circleObject.created, 150);

        if (replyobjects.length == 0) {
            res.status(200).send({ success: false, msg: 'No older objects' });
        } else {
            res.status(200).send({ success: true, replyobjects: replyobjects });
        }

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ err: msg });
    }
});

//Returns x number of replies from a specific date backwards
router.post('/getbyolder/', passport.authenticate('jwt', { session: false }), async (req, res) => {
    try {

        let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        ///AUTHORIZATION CHECK
        var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, circleID);

        var circleObject = await CircleObject.findById(body.circleObjectID);

        if (!usercircle)
            return res.status(400).json({ err: 'Access denied' });

        if (!circleObject)
            return res.status(500).json({ err: "replying to nothing" });

        let replyobjects = await replyObjectLogic.findReplyObjectsOlderThan(req.user.id, body.circleObjectID, body.olderThan, circleObject.created, 150);

        let payload = {};

        if (replyobjects.length == 0) {
            payload = { success: false, msg: 'No older objects' };
        } else {
            payload = { success: true, replyobjects: replyobjects };
        }

        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ err: msg });
    }
});

/// returns new posts from a specific date forward, POSTKYBER
router.get('/bynewer/:circleObjectID&:circleID&:date', passport.authenticate('jwt', { session: false }), async (req, res) => {
    try {
        ///AUTHORIZATION CHECK
        var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, req.params.circleID);

        var circleObject = await CircleObject.findById(req.params.circleObjectID);

        if (!usercircle)
            return res.status(400).json({ err: 'Access denied' });

        if (!circleObject)
            return res.status(500).json({ err: "replying to nothing" });
        //return res.status(400).json({ err: 'Access denied' });

        //await usercircleLogic.flipShowBadgeOff(usercircle);

        let replyobjects = await replyObjectLogic.findReplyObjectsNewThan(req.user.id, req.params.circleObjectID, req.params.date, circleObject.created, 500);
        //let refreshNeededObjects = await replyObjectLogic.findRefreshNeededObjects(req.user.id, req.headers.device);
        ///REFRSH NEEDED JUST FOR PINNED OBJECTS

        //usercircle = await usercircleLogic.updateLastAccessedWithUserCircle(usercircle, req.params.updatebadge);

        if (!replyobjects) {
            console.error(err);
            return res.status(500).json({ err: "There was a problem finding the replyobjects." });
        }

        if (replyobjects.length == undefined) {
            res.status(200).json({ msg: 'No new objects', usercircle: usercircle });
        } else {

            var usercircles = await UserCircle.find({ 'circle': req.params.circleID }).populate('user').populate('circle');
            res.status(200).send({
                replyobjects: replyobjects, //refreshNeededObjects: refreshNeededObjects, 
                usercircles: usercircles, usercircle: usercircle, circle: usercircle.circle
            });

        }
    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ err: msg });
    }
});


/// returns new posts from a specific date forward
router.post('/getbynewer/', passport.authenticate('jwt', { session: false }), async (req, res) => {
    try {

        let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        ///AUTHORIZATION CHECK
        var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleID);

        var circleObject = await CircleObject.findById(body.circleObjectID);

        if (!usercircle)
            return res.status(400).json({ err: 'Access denied' });

        if (!circleObject)
            return res.status(500).json({ err: "replying to nothing" });
        //return res.status(400).json({ err: 'Access denied' });

        //await usercircleLogic.flipShowBadgeOff(usercircle);

        let replyobjects = await replyObjectLogic.findReplyObjectsNewThan(req.user.id, body.circleObjectID, body.date, circleObject.created, 500);
        //let refreshNeededObjects = await replyObjectLogic.findRefreshNeededObjects(req.user.id, req.headers.device);
        ///REFRSH NEEDED JUST FOR PINNED OBJECTS

        //usercircle = await usercircleLogic.updateLastAccessedWithUserCircle(usercircle, body.updatebadge);

        if (!replyobjects) {
            console.error(err);
            return res.status(500).json({ err: "There was a problem finding the replyobjects." });
        }

        let payload = {};

        if (replyobjects.length == undefined) {
            payload = { msg: 'No new objects', usercircle: usercircle };
        } else {

            var usercircles = await UserCircle.find({ 'circle': req.params.circleID }).populate('user').populate('circle');
            payload = {
                replyobjects: replyobjects, //refreshNeededObjects: refreshNeededObjects, 
                usercircles: usercircles, usercircle: usercircle, circle: usercircle.circle
            };

        }

        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);
    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ err: msg });
    }
});

router.post('/getsingle', passport.authenticate('jwt', { session: false }), async (req, res) => {
    try {
        let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        ///AUTHORIZATION CHECK
        var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleID);

        let replyObject = await replyObjectLogic.findReplyObjectsByID(req.user.id, //req.body.circleID, 
            body.replyObjectID);

        if (!(replyObject instanceof ReplyObject))
            throw new Error('Object not found');

        // return res.status(200).send({
        //     replyObject: replyObject,
        // });

        let payload = { replyObject: replyObject, };
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ msg: msg });
    }
});

///returns n most recent replyobjects for a circle
router.get('/byobject/:circleObjectID&:circleID', passport.authenticate('jwt', { session: false }), async (req, res) => {
    try {
        ///AUTHORIZATION CHECK
        var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, req.params.circleID);

        if (!usercircle)
            return res.status(400).json({ err: 'Access denied' });

        //await usercircleLogic.flipShowBadgeOff(usercircle);

        let replyobjects = await replyObjectLogic.findReplyObjectsLimit(req.user.id, req.params.circleObjectID, usercircle.created, 100);

        if (!replyobjects) return res.status(500).json("There was a problem finding the replyobjects.");

        usercircle = await usercircleLogic.updateLastAccessedWithUserCircle(usercircle, 'true');

        if (replyobjects.length == undefined) {
            res.status(200).json({
                msg: 'No new objects', usercircle: usercircle
            });
        } else {
            var usercircles = await UserCircle.find({ 'circle': req.params.circleID }).populate('user').populate('circle');
            res.status(200).send({
                replyobjects: replyobjects,
                usercircles: usercircles,
                //usercircle: usercircle, 
                //circle: usercircle.circle 
            });
        }

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ msg: msg });
    }
});

///returns n most recent replyobjects for a circle
router.post('/getbyobject/', passport.authenticate('jwt', { session: false }), async (req, res) => {
    try {

        let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        ///AUTHORIZATION CHECK
        var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleID);

        if (!usercircle)
            return res.status(400).json({ err: 'Access denied' });

        //await usercircleLogic.flipShowBadgeOff(usercircle);

        let replyobjects = await replyObjectLogic.findReplyObjectsLimit(req.user.id, body.circleObjectID, usercircle.created, 100);

        if (!replyobjects) return res.status(500).json("There was a problem finding the replyobjects.");

        usercircle = await usercircleLogic.updateLastAccessedWithUserCircle(usercircle, 'true');

        let payload = {};

        if (replyobjects.length == undefined) {
            payload ={
                msg: 'No new objects', usercircle: usercircle
            };
        } else {
            var usercircles = await UserCircle.find({ 'circle': body.circleID }).populate('user').populate('circle');
            payload ={
                replyobjects: replyobjects,
                usercircles: usercircles,
                //usercircle: usercircle, 
                //circle: usercircle.circle 
            };
        }

        
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ msg: msg });
    }
});


///POSTKYBER
router.delete('/:id&:circleObjectID&:circleID', passport.authenticate('jwt', { session: false }), async (req, res) => {
    try {
        ///AUTHORIZATION CHECK
        var replyObject = await securityLogicAsync.canUserModifyReplyObject(req.user.id, req.params.id, req.params.circleObjectID);

        if (!(replyObject instanceof ReplyObject)) {
            throw new Error('Access denied');
        }

        var success;
        //let lastReplyObject;
        success = await replyObjectLogic.deleteReplyObject(replyObject, req);
        //lastCircleObject = await usercircleLogic.updateLastItemUpdate(circleObject.circle._id, req.user.id);

        if (success)
            res.status(200).json({ msg: 'Successfully deleted replyobject.' });
    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ msg: msg });
    }
});

router.post('/delete/', passport.authenticate('jwt', { session: false }), async (req, res) => {
    try {
        let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        ///AUTHORIZATION CHECK
        var replyObject = await securityLogicAsync.canUserModifyReplyObject(req.user.id, body.id, body.circleObjectID);

        if (!(replyObject instanceof ReplyObject)) {
            throw new Error('Access denied');
        }

        var success;
        //let lastReplyObject;
        success = await replyObjectLogic.deleteReplyObject(replyObject, req);
        //lastCircleObject = await usercircleLogic.updateLastItemUpdate(circleObject.circle._id, req.user.id);

        if (success) {
            //res.status(200).json({ msg: 'Successfully deleted replyobject.' });

            let payload = { msg: 'Successfully deleted replyobject.' };
            payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
            return res.status(200).json(payload);
        } else {
            throw new Error('delete failed');
        }
    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ msg: msg });
    }
});

router.post('/violation/', passport.authenticate('jwt', { session: false }), async (req, res) => {
    try {

        let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        //AUTHORIZATION CHECK
        var userCircle = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleID);

        if (!(userCircle instanceof UserCircle)) {
            return res.status(400).json({ success: false, msg: 'Access denied' });
        }

        let replyObject = await ReplyObject.findById(body.violation.replyObject).populate("creator");

        if (replyObject.creator.equals(body.violation.violator) == false)
            return res.status(400).json({ msg: 'Access denied' });

        let violation = await Violation.new(body.violation);
        violation.reporter = req.user.id;

        violation.replyObjectID = replyObject._id;
        violation.circleObjectType = replyObject.type;

        await violation.save();

        ///don't let a user report and delete a post to remove them
        if (userCircle.beingVotedOut != true) {
            await replyObjectLogic.tagViolation(body.circleID, replyObject);
        }

        //return res.status(200).json({ msg: 'violation reported' });

        let payload = { msg: 'violation reported' };
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);


    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ msg: msg });
    }
})

router.put('/hide/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {
    try {


        let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        let replyObjectID = req.params.id;
        if (replyObjectID == 'undefined') {
            replyObjectID = body.replyObjectID;
        }

        ///AUTHORIZATION CHECK
        var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleid);

        if (!(usercircle instanceof UserCircle)) {
            throw new Error('Access denied');
        }

        var success = await replyObjectLogic.hideReplyObject(replyObjectID, req.user.id);

        if (success) {
            //res.status(200).json({ msg: 'Successfully hid reply' });

            let payload = { msg: 'Successfully hid reply' };
            payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
            return res.status(200).json(payload);

        } else {
            throw new Error('an error occured');
        }

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ msg: msg });
    }
})

router.delete('/reaction/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {
    try {

        let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        let circleObjectReactionID = req.params.id;
        if (circleObjectReactionID == 'undefined') {
            circleObjectReactionID = body.circleObjectReactionID;
        }

        ///AUTHORIZATION CHECK
        var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circle);

        if (!usercircle)
            return res.status(400).json({ success: false, msg: 'Access denied' });

        ///find object
        var replyObject = await ReplyObject.findOne({ "_id": body.replyObjectID, circleObject: body.circleObjectID }).populate("creator").populate("circleObject").populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } });

        if (!replyObject || replyObject == null) {
            throw new Error('Access denied');
        }

        let index = body.index;
        let emoji = body.emoji;

        let reaction = await CircleObjectReaction.findById(circleObjectReactionID);

        let verifiedIndex = reaction.index;
        let verifiedEmoji = reaction.emoji;

        if (verifiedIndex != null) {
            ///compare index to find reaction
            ///delete from reactions
            for (let i = 0; i < replyObject.reactions.length; i++) {
                if (replyObject.reactions[i].index == verifiedIndex) {

                    ///remove user from reaction
                    await CircleObjectReaction.updateOne({ '_id': replyObject.reactions[i]._id }, { $pull: { 'users': req.user.id } });
                    if (replyObject.reactions[i].users.length == 1) {

                        //TODO need to insert transaction here
                        var reCheck = await CircleObjectReaction.findById(replyObject.reactions[i]._id);

                        if (reCheck.users.length == 0)
                            await ReplyObject.updateOne({ '_id': body.replyObjectID }, { $pull: { 'reactions': replyObject.reactions[i]._id } });
                        break;
                    }
                }
            }

        } else if (verifiedEmoji != null) {
            ///compare emoji to find reaction
            ///delete from reactions
            for (let i = 0; i < replyObject.reactions.length; i++) {
                if (replyObject.reactions[i].emoji == verifiedEmoji) {

                    ///remove user from reaction
                    await CircleObjectReaction.updateOne({ '_id': replyObject.reactions[i]._id }, { $pull: { 'users': req.user.id } });

                    if (replyObject.reactions[i].users.length == 1) {

                        ///TODO need to insert transaction here
                        var reCheck = await CircleObjectReaction.findById(replyObject.reactions[i]._id);

                        if (reCheck.users.length == 0) {
                            await ReplyObject.updateOne({ '_id': body.replyObjectID }, { $pull: { 'reactions': replyObject.reactions[i]._id } });
                        }
                        break;
                    }
                }
            }
        }

        await ReplyObject.updateOne({ "_id": body.replyObjectID, circleObject: body.circleObjectID }, { $set: { lastUpdate: Date.now() } });

        replyObject = await replyObjectLogic.findReplyObjectsByID(req.user.id, body.replyObjectID);

        deviceLogicSingle.sendDataOnlyReplyMessageNotification(replyObject.circleObject.seed, body.circle, replyObject, req.user.id, body.pushtoken);
        //deviceLogicSingle.sendReplyReactionRemovalNotification(body.circle, req.user.id, body.pushtoken);
        //deviceLogicSingle.sendReactionRemovalNotificationToCircle(body.circleID, req.user.id, body.pushtoken, circleObject.lastUpdate);  //async ok

        //return res.status(200).json({ replyobject: replyObject });

        let payload = { replyobject: replyObject };
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);


    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ msg: msg });
    }
})

router.post('/reaction/', passport.authenticate('jwt', { session: false }), async (req, res) => {
    try {

        let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        //AUTHORIZATION CHECK
        var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circle);

        if (!usercircle)
            return res.status(400).json({ success: false, msg: 'Access denied' });

        ///find object
        var replyObject = await ReplyObject.findOne({ "_id": body.id, circleObject: body.circleObjectID }).populate("creator").populate("circleObject").populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } });

        if (!replyObject || replyObject == null)
            throw new Error('Access denied');

        let skip = false;
        if (replyObject.creator.blockedList.length > 0) {
            for (let i = 0; i < replyObject.creator.blockedList.length; i++) {
                let blockedUser = replyObject.creator.blockedList[i];
                if (blockedUser._id.equals(req.user._id)) {
                    skip = true;
                    return;
                }
            }
        }

        usercircle.showBadge = false;
        await usercircle.save();

        let emoji = body.emoji;
        let index = body.index;
        let changed = false;

        let newEmoji = false;

        if (index != null) {
            changed = await reactionSaveIndex(replyObject, index, req.user, body.circleObjectID);
        } else if (emoji != null) {
            changed = await reactionSaveEmoji(replyObject, emoji, req.user, body.circleObjectID);
            newEmoji = true;
        }

        replyObject = await replyObjectLogic.findReplyObjectsByID(req.user.id, body.id);
        if (changed == true && skip == false) {

            var notification = req.user.username + " reacted to your ironclad reply";
            var notificationType = constants.NOTIFICATION_TYPE.REPLY_REACTION;
            let oldNotification = "Member reacted to your ironclad reply"

            let reaction;
            if (index != null) {
                reaction = CircleObjectReaction({ index: index });
            } else {
                reaction = CircleObjectReaction({ emoji: emoji });
            }
            reaction.users.push(req.user);
            //await reaction.save();

            deviceLogicSingle.sendReplyReactionNotification(replyObject.circleObject, body.circle, replyObject, req.user.id, body.pushtoken,
                notification, notificationType, oldNotification, newEmoji, reaction);
        }
        //console.log("Time after reaction complete");

        //return res.status(200).json({ replyobject: replyObject });

        let payload = { replyobject: replyObject };
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload); v

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        return res.status(500).json({ msg: msg });
    }
})

async function reactionSaveIndex(replyObject, index, user, circleObjectID) {
    let changed = false;
    let reactionFound = false;

    if (replyObject.reactions != undefined) {
        for (let i = 0; i < replyObject.reactions.length; i++) {
            if (changed == true) break;

            let reaction = replyObject.reactions[i];

            if (index != null && index == reaction.index) {
                reactionFound = true;

                let alreadyPosted = false;
                //did this user already post?
                for (let j = 0; j < reaction.users.length; j++) {
                    if (user.id == reaction.users[j]._id) {
                        alreadyPosted = true;
                        break;
                    }
                }

                //not already posted, so add it
                if (!alreadyPosted) {
                    await CircleObjectReaction.updateOne({ '_id': reaction._id }, { $push: { 'users': user } });

                    let now = Date.now();
                    await ReplyObject.updateOne({ "_id": replyObject._id, circleObject: circleObjectID, }, { $set: { lastUpdate: now, lastReactedDate: now } });

                    changed = true;
                    break;
                }
            }
        }
    }

    if (reactionFound == false) {
        let reaction = CircleObjectReaction({ index: index });
        reaction.users.push(user);
        await reaction.save();
        await ReplyObject.updateOne({ '_id': replyObject._id }, { $push: { 'reactions': reaction } });
        let now = Date.now();
        await ReplyObject.updateOne({ "_id": replyObject._id, circleObject: circleObjectID }, { $set: { lastUpdate: now, lastReactedDate: now } });
        changed = true;
    }

    return changed;
}

async function reactionSaveEmoji(replyObject, emoji, user, circleObjectID) {
    let changed = false;
    let reactionFound = false;

    if (replyObject.reactions != undefined) {
        for (let i = 0; i < replyObject.reactions.length; i++) {
            if (changed == true) break;

            let reaction = replyObject.reactions[i];

            if (emoji != null && emoji == reaction.emoji) {
                reactionFound = true;

                let alreadyPosted = false;
                //did this user already post?
                for (let j = 0; j < reaction.users.length; j++) {
                    if (user.id == reaction.users[j]._id) {
                        alreadyPosted = true;
                        break;
                    }
                }

                //not already posted, so add it
                if (!alreadyPosted) {
                    await CircleObjectReaction.updateOne({ '_id': reaction._id }, { $push: { 'users': user } });
                    let now = Date.now();
                    await ReplyObject.updateOne({ "_id": replyObject._id, circleObject: circleObjectID }, { $set: { lastUpdate: now, lastReactedDate: now } });
                    changed = true;
                    break;
                }
            }
        }
    }

    if (reactionFound == false) {
        let reaction = CircleObjectReaction({ emoji: emoji });
        reaction.users.push(user);
        await reaction.save();
        await ReplyObject.updateOne({ '_id': replyObject._id }, { $push: { 'reactions': reaction } });
        let now = Date.now();
        await ReplyObject.updateOne({ "_id": replyObject._id, circleObject: circleObjectID }, { $set: { lastUpdate: now, lastReactedDate: now } });
        changed = true;
    }

    return changed;
}

module.exports = router;