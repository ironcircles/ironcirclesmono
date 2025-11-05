const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const passport = require('passport');
const securityLogicAsync = require('../logic/securitylogicasync');
const eventLogic = require('../logic/eventlogic');
var CircleEvent = require('../models/circleevent');
var CircleObject = require('../models/circleobject');
const circleObjectLogic = require('../logic/circleobjectlogic');
const deviceLogic = require('../logic/devicelogic');
const deviceLogicSingle = require('../logic/devicelogicsingle');
const logUtil = require('../util/logutil');
const constants = require('../util/constants');
const metricLogic = require('../logic/metriclogic');
const ObjectId = require('mongodb').ObjectId;
const CircleObjectCircle = require('../models/circleobjectcircle');
const kyberLogic = require('../logic/kyberlogic');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}


// router.use(bodyParser.urlencoded({ extended: true }));
// router.use(bodyParser.json());

router.use(bodyParser.json({ limit: '10mb' }));
router.use(bodyParser.urlencoded({ limit: '10mb', extended: true, parameterLimit: 50000 }));

router.put('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let circleObjectID = req.params.id;

    if (circleObjectID == 'undefined'){
      circleObjectID = body.circleObjectID;
    }


    //AUTHORIZATION CHECK
    let userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circle);
    if (!userCircle) return res.status(400).json({ msg: 'Access denied' });

    //make sure the parameters were passed in
    try {
      circleObjectID = new ObjectId(circleObjectID);
    } catch (err) {
      return res.status(400).json({ msg: "Need to send valid parameters" });
    }

    var circleObject = await CircleObject.findById(circleObjectID).populate('creator').populate('circle').populate({ path: 'event', populate: [{ path: 'encryptedLineItems', populate: [{ path: 'ratchetIndex', populate: { path: 'user' } }] }] });

    if (!circleObject instanceof CircleObject) throw new Error('unathorized');

    let event = circleObject.event;

    //Only update the event if this is from the creator
    if (req.user.id == circleObject.creator._id)
      await event.update(body.event, req.user.id);


    let encryptedReply = await event.updateReply(body.event.encryptedLineItems[0], req.user.id);
    await encryptedReply.save();

    event.lastEdited = req.user;

    if (encryptedReply.version == 1) { //it's a new event so add it to the collection
      event.encryptedLineItems.push(encryptedReply);
      //save the collection
      //await event.save();
    }// else if (req.user.id == circleObject.creator._id)
    await event.save();

    //need to save any creator changes
    if (req.user.id == circleObject.creator._id) {
      await circleObject.update(body);

    }


    let lastUpdate = Date.now();
    circleObject.lastUpdate = lastUpdate;
    circleObject.lastUpdateNotReaction = lastUpdate;
    await circleObject.save();

    //Need to pickup any other RSPVs that occured during the save process
    var circleObject = await CircleObject.findById(circleObjectID).populate('creator').populate('circle').populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users',  select: '_id username' } }).populate({ path: 'event', populate: [{ path: 'lastEdited', select: '_id username' }, { path: 'encryptedLineItems', populate: [{ path: 'ratchetIndex', /*populate: { path: 'user' }*/ }] }] });
    //await circleObject.populate('creator').populate('circle').populate({ path: 'event', populate: [{ path: 'encryptedLineItems', populate: [{ path: 'ratchetindex', populate: { path: 'user' } }] }] }).execPopulate();


    var notificationType = constants.NOTIFICATION_TYPE.EVENT;
    let oldNotification = "Member updated ironclad event";

    if (req.user.id == circleObject.creator.id) {
      var notification = circleObject.creator.username + " updated an ironclad event";
      deviceLogicSingle.sendMessageNotificationToCircle(circleObject, userCircle.circle._id, req.user.id, body.pushtoken, circleObject.lastUpdate, notification, notificationType, oldNotification);  //async ok

    } else {
      var notification = req.user.username + " responded to your ironclad event";
      await deviceLogicSingle.sendNotificationToCreator(notification, circleObject, body.circle, req.user.id, body.pushtoken, circleObject.lastUpdate, notificationType, oldNotification);
    }

    //return res.json({ msg: 'updated event', circleobject: circleObject, circle: circleObject.circle });

    let payload = { msg: 'updated event', circleobject: circleObject, circle: circleObject.circle };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }

});


router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    let usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circle);
    if (!usercircle)
      return res.status(400).json({ msg: 'Access denied' });

    if (usercircle.
      beingVotedOut == true) {
        throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    //see if it exists
    var existingObject = await CircleObject.findOne({ 'creator': req.user.id, 'seed': body.seed, circle: body.circleid }).populate('creator').populate('circle').populate({ path: 'event', populate: [{ path: 'lastEdited', select: '_id username' }, { path: 'encryptedLineItems', populate: [{ path: 'ratchetIndex', /*populate: { path: 'user' }*/ }] }] }).populate({ path: 'reactions', populate: { path: 'users',  select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users',  select: '_id username' } }).exec();

    if (existingObject instanceof CircleObject) {
      console.log('Seed already exists');

      //The user can see this object because we already validated they are in the Circle above
      return res.status(200).json({ msg: 'Seed already exists', circleobject: existingObject });
    }


    let circleEvent = await CircleEvent.new(body.event, req.user.id);
    circleEvent.circle = body.circle;

    for (let i = 0; i < circleEvent.encryptedLineItems.length; i++) {

      await circleEvent.encryptedLineItems[i].save();
    }

    await circleEvent.save();

    let circleObject = await CircleObject.new(body);
    circleObject.creator = req.user.id;
    circleObject = circleObjectLogic.setTimer(circleObject, usercircle.circle);
    circleObject.event = circleEvent;
    if (body.scheduledFor) {
      circleObject.scheduledFor = new Date(body.scheduledFor);
      if (circleObject.scheduledFor < Date.now()) {
        logUtil.logAlert(req.user.id + ' tried to schedule sending an event for a time before now.');
        return res.status(500);
      }
    }
    circleObject.lastUpdateNotReaction = circleObject.lastUpdate;
    await circleObject.save();

    //await circleObject.populate('creator').populate('circle').populate({ path: 'event', populate: [{ path: 'encryptedLineItems', populate: [{ path: 'ratchetindex', populate: { path: 'user' } }] }] }).execPopulate();
    await circleObject.populate(['creator', 'circle', { path: 'event', populate: [{ path: 'encryptedLineItems', populate: [{ path: 'ratchetIndex' }] }] }]); //, { path: 'event', populate: [{ path: 'encryptedLineItems', populate: [{ path: 'ratchetIndex', populate: { path: 'user' } }] }] }]);
    //await circleObject.event.populate({ path: 'encryptedLineItems', populate: [{ path: 'ratchetIndex' }] });

    if (circleObject.scheduledFor != null && circleObject.scheduledFor != undefined) {
      let connection = new CircleObjectCircle({
        circle: body.circle,
        circleObject: circleObject._id,
        taggedUsers: body.taggedUsers
      });
      await connection.save();
      circleObject.circle = undefined;
      await circleObject.save();

      return res.json({ success: true, msg: 'Successfully saved new event', circleObject: circleObject, });

    } else {

      metricLogic.incrementPosts(circleObject.creator);

      var notification = circleObject.creator.username + " sent a new ironclad event";
      var notificationType = constants.NOTIFICATION_TYPE.EVENT;
      let oldNotification = "New ironclad event";

      deviceLogicSingle.sendMessageNotificationToCircle(circleObject, body.circle, req.user.id, body.pushtoken, circleObject.lastUpdate, notification, notificationType, oldNotification);  //async ok

      //return res.json({ success: true, msg: 'Successfully saved new event', circleObject: circleObject });

      let payload = { success: true, msg: 'Successfully saved new event', circleObject: circleObject };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);

    }
  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });

  }

});


module.exports = router;