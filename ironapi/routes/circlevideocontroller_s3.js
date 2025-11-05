const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
mongoose.Promise = require('bluebird');
const logUtil = require('../util/logutil');
const CircleVideo = require('../models/circlevideo');
const CircleObject = require('../models/circleobject');
const passport = require('passport');
const securityLogic = require('../logic/securitylogic');
const circleObjectLogic = require('../logic/circleobjectlogic');
const securityLogicAsync = require('../logic/securitylogicasync');
const deviceLogic = require('../logic/devicelogic');
const deviceLogicSingle = require('../logic/devicelogicsingle');
const gridFS = require('../util/gridfsutil');
const ObjectID = require('mongodb').ObjectId;
const constants = require('../util/constants');
const bodyParser = require('body-parser');
const mongodb = require('mongodb');
let conn = mongoose.connection;
let Grid = require('gridfs-stream');
const metricLogic = require('../logic/metriclogic');
Grid.mongo = mongoose.mongo;
const CircleObjectCircle = require('../models/circleobjectcircle');
const CircleObjectWaiting = require('../models/circleobjectwaiting');
const kyberLogic = require('../logic/kyberlogic');


router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleid);
    if (!usercircle)
      return res.status(400).json({ msg: 'Access denied' });

    //make sure the parameters were passed in
    var circleID;
    var userID;

    try {
      circleID = new ObjectID(body.circleid);
      userID = new ObjectID(req.user.id);

    } catch (err) {
      console.error(err);
      return res.status(400).json({ msg: 'Need to send parameters' });
    }

    //see if the object exists
    let existing = await CircleObject.findOne({ 'creator': userID, 'seed': body.seed }).populate('video').populate('creator').populate('circle').populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();;

    if (existing instanceof CircleObject) {
      logUtil.logAlert(req.user.id + ' tried to post an object that already exists. seed: ' + body.seed);
      return res.status(200).json({ circleobject: existing, msg: 'circleobject already exists.' });

    } else {

      let circleObject = await CircleObject.new(body);
      circleObject.creator = req.user.id;
      circleObject = circleObjectLogic.setTimer(circleObject, usercircle.circle);
      if (body.scheduledFor) {
        circleObject.scheduledFor = new Date(body.scheduledFor);
        if (circleObject.scheduledFor < Date.now()) {
          logUtil.logAlert(req.user.id + ' tried to schedule sending a video for a time before now.');
          return res.status(500);
        }
      }

      //create the circleimage object
      var circleVideo = await CircleVideo.new(body.video);
      circleVideo.circle = body.circleid;  //TODO is this necessary?

      await circleVideo.save();

      //save the circleobject
      circleObject.video = circleVideo;
      await circleObject.save();

      //Add the circleobject to the user's newItems list
      circleObjectLogic.saveNewItem(usercircle.circle._id, circleObject, body.device);

      await circleObject.populate(['creator', 'circle', 'video']);

      if (circleObject.scheduledFor != null && circleObject.scheduledFor != undefined) {
        let connection = new CircleObjectCircle({
          circle: body.circle,
          circleObject: circleObject._id,
          taggedUsers: body.taggedUsers
        });
        await connection.save();
        circleObject.circle = undefined;
        await circleObject.save();

        return res.status(200).json({ circleobject: circleObject, circlevideo: circleVideo });

      } else {
        metricLogic.incrementPosts(circleObject.creator);

        var notification = circleObject.creator.username + " sent a new ironclad video";
        var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
        let oldNotification = "New ironclad message";

        //if (body.waitingOn == null) {

          ///process now
          deviceLogicSingle.sendMessageNotificationToCircle(circleObject, body.circleid, req.user.id, body.pushtoken, circleObject.lastUpdate, notification, notificationType, oldNotification);  //async ok

          //Add the circleobject to the user's newItems list
          circleObjectLogic.saveNewItem(usercircle.circle._id, circleObject, body.device);

          ///wait 200 milliseconds
          //await new Promise(resolve => setTimeout(resolve, 3000));

          //process other objects waiting on this one if it's not waiting
          circleObjectLogic.processWaitingObjects(circleObject.seed);

        // } else {

        //   //save meta data for waiting object
        //   let waitingObject = new CircleObjectWaiting({ circleObject: circleObject._id, taggedUsers: body.taggedUsers, pushToken: body.pushtoken, notification: notification, notificationType: notificationType, skipDevice: body.device });
        //   await waitingObject.save();

        //   circleObjectLogic.processWaitingObjects(body.waitingOn);



        // }


        //return res.status(200).json({ circleobject: circleObject, circlevideo: circleVideo });

        let payload = { circleobject: circleObject, circlevideo: circleVideo };
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);
      }
    }

  } catch (err) {

    var msg = await logUtil.logError(err);
    return res.status(500).json({ msg: msg });
  }

});



module.exports = router;