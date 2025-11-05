const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
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
const CircleObjectWaiting = require('../models/circleobjectwaiting');
const circleobject = require('../models/circleobject');
const kyberLogic = require('../logic/kyberlogic');
const multer = require('multer');
const jsonUtil = require('../util/jsonutil');
const fs = require('fs');
const path = require('path');

// Configure multer for file uploads (storing files in memory)
const upload = multer({ storage: multer.memoryStorage() });

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.json({ limit: '50mb' }));
router.use(bodyParser.urlencoded({ limit: '50mb', extended: true, parameterLimit: 50000 }));

// Returns n most recent circleobjects for a circle POSTKYBER
router.get('/circle/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, req.params.id);

    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });

    await usercircleLogic.flipShowBadgeOff(usercircle);

    let circleobjects = await circleObjectLogic.findCircleObjectsLimit(req.user.id, req.params.id, usercircle.created, 100);

    if (!circleobjects) return res.status(500).json("There was a problem finding the circleobjects.");

    usercircle = await usercircleLogic.updateLastAccessedWithUserCircle(usercircle, 'true');

    if (circleobjects.length == undefined) {
      res.status(200).json({ msg: 'No new objects', usercircle: usercircle });

    } else {
      var usercircles = await UserCircle.find({ 'circle': req.params.id }).populate('user').populate('circle');
      res.status(200).send({ circleobjects: circleobjects, usercircles: usercircles, usercircle: usercircle, circle: usercircle.circle });
    }

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});

router.post('/bycircle/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleID);

    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });

    await usercircleLogic.flipShowBadgeOff(usercircle);

    let circleobjects = await circleObjectLogic.findCircleObjectsLimit(req.user.id, body.circleID, usercircle.created, 100);

    if (!circleobjects) return res.status(500).json("There was a problem finding the circleobjects.");

    usercircle = await usercircleLogic.updateLastAccessedWithUserCircle(usercircle, 'true');

    let payload = {};

    if (circleobjects.length == undefined) {
      payload = { msg: 'No new objects', usercircle: usercircle };

    } else {
      var usercircles = await UserCircle.find({ 'circle': body.circleID }).populate('user').populate('circle');
      payload = { circleobjects: circleobjects, usercircles: usercircles, usercircle: usercircle, circle: usercircle.circle };
    }


    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});


// Returns new posts from a specific date forward.  POSTKYBER
router.get('/circlenew/:id&:date&:updatebadge', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, req.params.id);

    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });

    await usercircleLogic.flipShowBadgeOff(usercircle);

    let circleobjects = await circleObjectLogic.findCircleObjectsNewThan(req.user.id, req.params.id, req.params.date, usercircle.created, 500);
    let refreshNeededObjects = await circleObjectLogic.findRefreshNeededObjects(req.user.id, req.headers.device);


    usercircle = await usercircleLogic.updateLastAccessedWithUserCircle(usercircle, req.params.updatebadge);

    if (!circleobjects) {
      console.error(err);
      return res.status(500).json({ err: "There was a problem finding the circleobjects." });
    }

    if (circleobjects.length == undefined) {
      res.status(200).json({ msg: 'No new objects', usercircle: usercircle });

    } else {

      var usercircles = await UserCircle.find({ 'circle': req.params.id }).populate('user').populate('circle');
      res.status(200).send({ circleobjects: circleobjects, refreshNeededObjects: refreshNeededObjects, usercircles: usercircles, usercircle: usercircle, circle: usercircle.circle });
    }
  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }

});

router.post('/circlenew/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleID);

    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });

    await usercircleLogic.flipShowBadgeOff(usercircle);

    let circleobjects = await circleObjectLogic.findCircleObjectsNewThan(req.user.id, body.circleID, body.lastUpdate, usercircle.created, 500);
    let refreshNeededObjects = await circleObjectLogic.findRefreshNeededObjects(req.user.id, req.headers.device);


    usercircle = await usercircleLogic.updateLastAccessedWithUserCircle(usercircle, body.updatebadge);

    if (!circleobjects) {
      console.error(err);
      return res.status(500).json({ err: "There was a problem finding the circleobjects." });
    }

    let payload = {};

    if (circleobjects.length == undefined) {
      payload = { msg: 'No new objects', usercircle: usercircle };

    } else {

      var usercircles = await UserCircle.find({ 'circle': body.circleID }).populate('user').populate('circle');
      payload = { circleobjects: circleobjects, refreshNeededObjects: refreshNeededObjects, usercircles: usercircles, usercircle: usercircle, circle: usercircle.circle };
    }

    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }

});



/*

//return top X circleobjects filtered by circletype
router.get('/circlefilter/:id&:filter', passport.authenticate('jwt', { session: false }), function (req, res) {

  //AUTHORIZATION CHECK
  securityLogic.canUserAccessCircle(req.user.id, req.params.id, function (valid) {
    if (!valid)
      return res.json({ success: false, msg: 'Access denied' });

    var filter = req.params.filter;

    if (filter == null) {
      return res.json({ success: true, msg: 'Missing parameter' });
    } else {
      CircleObject.find({ "circle": req.params.id, "type": filter }).sort({ lastUpdate: -1 }).limit(50)
        .populate("creator").populate("circle").populate("vote").populate("image").populate("gif").populate("link").populate("movie").populate("event").populate({ path: 'review', populate: { path: 'master' } })
        .exec(function (err, circleobjects) {

          if (err) return res.status(500).send("There was a problem finding the circleobjects.");

          usercircleLogic.updateLastAccessed(req.params.id, req.user.id, circleobjects, function (valid) {
            if (!valid)
              return res.status(500).send("There was a problem finding the circle users.");

            res.status(200).send({ success: true, circleobjects: circleobjects });

          });


        });
    }
  });
});


//Returns X number of posts before and after a specific post; useful for flipping through an image gallery
router.get('/circleimages/:id&:date', passport.authenticate('jwt', { session: false }), function (req, res) {

  //AUTHORIZATION CHECK
  securityLogic.canUserAccessCircle(req.user.id, req.params.id, function (valid) {
    if (!valid)
      return res.json({ success: false, msg: 'Access denied' });

    //  console.log( req.params.date);


    // CircleObject.find({"circle":req.params.id, lastUpdate: {$gt: req.params.date}}).sort({lastUpdate: -1})

    CircleObject.find({ "circle": req.params.id, type: 'circleimage', lastUpdate: { $lte: req.params.date } }).sort({ lastUpdate: -1, _id: -1 }).limit(100)
      .populate("creator").populate("circle").populate("image")
      .exec(function (err, oldercircleobjects) {


        //console.log(oldercircleobjects);

        if (err) return res.send({ success: false, msg: "There was a problem finding the circleobjects." });

        CircleObject.find({ "circle": req.params.id, type: 'circleimage', lastUpdate: { $gt: req.params.date } }).sort({ lastUpdate: 1 }).limit(100)
          .populate("creator").populate("circle").populate("image")
          .exec(function (err, newercircleobjects) {

            if (err) return res.send({ success: false, msg: "There was a problem finding the circleobjects." });

            res.send({ success: true, oldercircleobjects: oldercircleobjects, newercircleobjects, newercircleobjects });

          });

      });
  });
});

*/


//Returns X number of posts from a specific jump to date and forward POSTKYBER
router.get('/circlejumpdate/:id&:cacheDate&:jumpDate', passport.authenticate('jwt', { session: false }), async (req, res) => {


  try {

    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, req.params.id);

    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });

    let circleobjects = await circleObjectLogic.findCircleObjectsBetween(req.user.id, req.params.id, req.params.jumpDate, req.params.cacheDate, usercircle.created, 10000);

    if (circleobjects.length == 0) {
      res.status(200).send({ success: false, msg: 'No older objects' });
    } else {
      //res.status(200).send({ circleobjects: circleobjects, usercircles: usercircles, usercircle: usercircle,});
      res.status(200).send({ success: true, circleobjects: circleobjects });

    }

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});

router.post('/circlejumpdate/', passport.authenticate('jwt', { session: false }), async (req, res) => {


  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleID);

    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });


    let circleobjects = await circleObjectLogic.findCircleObjectsBetween(req.user.id, body.circleID, body.jumpTo, body.cacheDate, usercircle.created, 10000);

    let payload = {};

    if (circleobjects.length == 0) {
      payload = { success: false, msg: 'No older objects' };
    } else {
      //res.status(200).send({ circleobjects: circleobjects, usercircles: usercircles, usercircle: usercircle,});
      payload = { success: true, circleobjects: circleobjects };

    }

    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});

//Returns X number of posts from a specific date backwards POSTKYBER
router.get('/circleolder/:id&:date', passport.authenticate('jwt', { session: false }), async (req, res) => {


  try {

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.params.id);

    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });

    let circleobjects = await circleObjectLogic.findCircleObjectsOlderThan(req.user.id, req.params.id, req.params.date, usercircle.created, 500);

    if (circleobjects.length == 0) {
      res.status(200).send({ success: false, msg: 'No older objects', circleobjects: circleobjects });
    } else {
      //res.status(200).send({ circleobjects: circleobjects, usercircles: usercircles, usercircle: usercircle,});
      res.status(200).send({ success: true, circleobjects: circleobjects });

    }

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});

router.post('/circleolder/', passport.authenticate('jwt', { session: false }), async (req, res) => {


  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);


    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleID);

    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });

    let circleobjects = await circleObjectLogic.findCircleObjectsOlderThan(req.user.id, body.circleID, body.created, usercircle.created, 500);

    let payload = {};

    if (circleobjects.length == 0) {
      payload = { success: false, msg: 'No older objects', circleobjects: circleobjects };
    } else {
      //res.status(200).send({ circleobjects: circleobjects, usercircles: usercircles, usercircle: usercircle,});
      payload = { success: true, circleobjects: circleobjects };


    }

    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});



///TODO need a field stored at the object level
router.put('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let circleObjectID = req.params.id;
    if (circleObjectID == 'undefined') {
      circleObjectID = body.circleObjectID;
    }

    //AUTHORIZATION CHECK
    var userCircle = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleID);
    if (!(userCircle instanceof UserCircle))
      throw new Error('Access denied');

    if (userCircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    var userFieldsToPopulate = '_id username avatar';

    var circleObject;
    if (body.type == constants.CIRCLEOBJECT_TYPE.CIRCLECREDENTIAL) {


      circleObject = await CircleObject.findOne({ "_id": circleObjectID, circle: body.circleID }).populate("circle").populate('creator').populate("lastEdited", userFieldsToPopulate);
    } else {
      circleObject = await CircleObject.findOne({ "_id": circleObjectID, circle: body.circleID, creator: req.user.id }).populate("circle").populate('creator').populate("lastEdited", userFieldsToPopulate);;
    }


    let payload = {};

    if (!(circleObject instanceof CircleObject)) {
      ///TODO temporary code to fix link issue
      circleObject = await CircleObject.findOne({ "_id": circleObjectID, circle: body.circleID });
      await circleObject.populate(['creator', 'circle', 'image', 'video', { path: 'album', populate: { path: 'media', populate: { path: 'encryptedLineItem' } } }, { path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }, { path: 'reactions', populate: { path: 'users', select: '_id username' } }]).populate({ path: 'reactionsPlus', populate: { path: 'users', select: userFieldsToPopulate } });
      //throw new Error('Access to object denied: id:' + req.params.id + " circle:" + body.circleID + " user:"+ req.user.id);
      console.log('Access to object denied: id:' + circleObjectID + " circle:" + body.circleID + " user:" + req.user.id);
      payload = { circleobject: circleObject };
    } else {

      circleObject.lastEdited = req.user.id;

      await circleObject.update(body);
      await circleObject.save();

      //TODO reduce lastEdited fields
      await circleObject.populate(['creator', 'lastEdited', 'circle', 'image', 'video', { path: 'album', populate: { path: 'media', populate: { path: 'encryptedLineItem' } } }, { path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }, { path: 'reactions', populate: { path: 'users', select: '_id username' } }, { path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }]);
      deviceLogicSingle.sendDataOnlyRefreshToCircle(body.circleID);
      payload = { circleobject: circleObject };

    }

    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});

//Mark a CircleObject as received
router.post('/markreceived/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {


    //circleObjectLogic.markReceived(req.user.id, req.body.device, req.body.circleObjects);

    res.status(200).send({});
  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});

router.post('/markdelivered', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    circleObjectLogic.markDelivered(req.user.id, body.circleObjects, body.device);


    // return res.status(200).send({
    //   msg: 'success'
    // });

    let payload = { msg: 'success' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);



  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});


router.post('/notdelivered', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    metricLogic.setLastAccessed(req.user);

    var circleObjects = await circleObjectLogic.returnNotDeliveredForDevice(req.user.id, req.user.device);

    let refreshNeededObjects = await circleObjectLogic.findRefreshNeededObjects(req.user.id, req.body.device);

    return res.status(200).send({

      circleobjects: circleObjects, refreshNeededObjects: refreshNeededObjects,
      //latestBuild: releases[0].build
    });


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});

router.post('/usercircles', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    metricLogic.setLastAccessed(req.user);

    //AUTHORIZATION CHECK (only checks circles for token validated user)
    var circleObjects = await circleObjectLogic.returnNewObjectsForAllUserCircles(req.user.id, body.openguarded, body.circlelastupdates);

    let refreshNeededObjects = await circleObjectLogic.findRefreshNeededObjects(req.user.id, body.device);

    // return res.status(200).send({

    //   circleobjects: circleObjects, refreshNeededObjects: refreshNeededObjects,
    //   //latestBuild: releases[0].build
    // });

    let payload = { circleobjects: circleObjects, refreshNeededObjects: refreshNeededObjects, };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);



  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});

router.post('/getsingle', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleID);

    let circleObject = await circleObjectLogic.findCircleObjectsByID(req.user.id, body.circleID, body.circleObjectID);


    if (!(circleObject instanceof CircleObject))
      throw new Error('Object not found');

    // return res.status(200).send({

    //   circleObject: circleObject,
    // });

    let payload = { circleObject: circleObject };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);



  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});


///This is a new post. It's called file because the background processor needed
///to use a file instead of json in case memory was dumped client side before the message sent
router.post('/file/', passport.authenticate('jwt', { session: false }), upload.single('file'), async (req, res) => {
  try {

    let body = await jsonUtil.safeParse(req);

    let pushToken = body.pushtoken;
    if (pushToken == null || pushToken == undefined) {

      ///find the device
      for (let i = 0; i < req.user.devices.length; i++) {
        if (req.user.devices[i].deviceID == req.body.device) {
          pushToken = req.user.devices[i].pushToken;
          break;
        }
      }
    }

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circle);

    if (!(usercircle instanceof UserCircle)) {
      throw new Error('Access denied');
    }

    if (usercircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    let circle = usercircle.circle;

    //does the seed from this user already exist?
    //var existing = await CircleObject.findOne({ seed: body.seed, creator: req.user.id, circle: body.circle }).populate('creator').populate('circle').populate({ path: 'reactionsPlus', populate: { path: 'users' } }).populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();

    let count = await CircleObject.countDocuments({ seed: body.seed, creator: req.user.id, circle: body.circle });

    if (count > 0) {
      logUtil.logAlert(req.user.id + ' tried to post an object that already exists. seed: ' + body.seed);

      ///load the object
      var existing = await CircleObject.findOne({ seed: body.seed, creator: req.user.id, circle: body.circle }).populate('creator').populate('circle').populate({ path: 'reactionsPlus', populate: { path: 'users' } }).populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();

      payload = { _id: existing._id, seed: existing.seed, created: existing.created, lastUpdate: existing.lastUpdate };
      payload = await kyberLogic.encryptPayload(body.enc, body.uuid, payload);
      return res.status(200).json(payload);
      //return res.status(200).json({ circleobject: existing, msg: 'CircleObject already exists' });

    } else {
      let circleObject = await CircleObject.new(body);
      ///don't use the userid passed in through the body, can be manipulated
      circleObject.creator = req.user.id;
      circleObject = circleObjectLogic.setTimer(circleObject, usercircle.circle);
      if (body.scheduledFor) {
        circleObject.scheduledFor = new Date(body.scheduledFor);
        if (circleObject.scheduledFor < Date.now()) {
          logUtil.logAlert(req.user.id + ' tried to schedule sending an object for a time before now.');
          return res.status(500);
        }
      }

      await circleObject.save();
      await circleObject.populate([{ path: 'creator', select: '_id username' }, 'circle']);


      let payload = {};

      if (circleObject.scheduledFor != null && circleObject.scheduledFor != undefined) {
        let connection = new CircleObjectCircle({
          circle: body.circle,
          circleObject: circleObject._id,
          taggedUsers: body.taggedUsers
        });
        await connection.save();
        circleObject.circle = undefined;
        await circleObject.save();

        if (body.build != null && body.build != undefined && body.build > 155) {
          payload = { id: circleObject._id, created: circleObject.created, lastUpdate: circleObject.lastUpdate };
        } else {
          payload = { circleobject: circleObject };
        }

      } else {

        metricLogic.incrementPosts(circleObject.creator);



        let type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEMESSAGE;
        if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEGIF)
          type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEGIF;

        var notification = circleObject.creator.username + " sent a new ironclad " + type;
        var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
        let oldNotification = "New ironclad message";


        //if (body.waitingOn == null) {

          ///process now
          deviceLogicSingle.sendMessageNotificationToCircle(circleObject, circle, req.user.id, pushToken, circleObject.lastUpdate, notification, notificationType, oldNotification, body.taggedUsers);  //async ok

          //Add the circleobject to the user's newItems list
          circleObjectLogic.saveNewItem(circle._id, circleObject, body.device);

          ///wait 200 milliseconds
          //await new Promise(resolve => setTimeout(resolve, 3000));

          //process other objects waiting on this one if it's not waiting
          circleObjectLogic.processWaitingObjects(circleObject.seed);

        // } else {

        //   //save meta data for waiting object
        //   let waitingObject = new CircleObjectWaiting({ circleObject: circleObject._id, taggedUsers: body.taggedUsers, pushToken: pushToken, notification: notification, notificationType: notificationType, skipDevice: body.device });
        //   await waitingObject.save();

        //   circleObjectLogic.processWaitingObjects(body.waitingOn);

        // }

        payload = { _id: circleObject._id, seed: circleObject.seed, created: circleObject.created, lastUpdate: circleObject.lastUpdate, ratchetIndexes: circleObject.ratchetIndexes, senderRatchetPublic: circleObject.senderRatchetPublic };

      }

      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);
    }

  } catch (error) {
    res.status(500).json({ error: 'Internal server error', details: error.message });
  }
});


///POSTKYBER
router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let pushToken = body.pushtoken;
    if (pushToken == null || pushToken == undefined) {

      ///find the device
      for (let i = 0; i < req.user.devices.length; i++) {
        if (req.user.devices[i].deviceID == req.body.device) {
          pushToken = req.user.devices[i].pushToken;
          break;
        }
      }
    }

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circle);

    if (!(usercircle instanceof UserCircle)) {
      throw new Error('Access denied');
    }

    if (usercircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    let circle = usercircle.circle;

    //does the seed from this user already exist?
    //var existing = await CircleObject.findOne({ seed: body.seed, creator: req.user.id, circle: body.circle }).populate('creator').populate('circle').populate({ path: 'reactionsPlus', populate: { path: 'users' } }).populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();

    let count = await CircleObject.countDocuments({ seed: body.seed, creator: req.user.id, circle: body.circle });

    if (count > 0) {
      logUtil.logAlert(req.user.id + ' tried to post an object that already exists. seed: ' + body.seed);

      ///load the object
      var existing = await CircleObject.findOne({ seed: body.seed, creator: req.user.id, circle: body.circle }).populate('creator').populate('circle').populate({ path: 'reactionsPlus', populate: { path: 'users' } }).populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();

      return res.status(200).json({ circleobject: existing, msg: 'CircleObject already exists' });

    } else {
      let circleObject = await CircleObject.new(body);
      ///don't use the userid passed in through the body, can be manipulated
      circleObject.creator = req.user.id;
      circleObject = circleObjectLogic.setTimer(circleObject, usercircle.circle);
      if (body.scheduledFor) {
        circleObject.scheduledFor = new Date(body.scheduledFor);
        if (circleObject.scheduledFor < Date.now()) {
          logUtil.logAlert(req.user.id + ' tried to schedule sending an object for a time before now.');
          return res.status(500);
        }
      }



      ///not need as it is accounted for in the .new() method
      // if (body.waitingOn != null) {
      //   circleObject.waitingOn = body.waitingOn;
      // }

      await circleObject.save();
      await circleObject.populate([{ path: 'creator', select: '_id username' }, 'circle']);


      let payload = {};

      if (circleObject.scheduledFor != null && circleObject.scheduledFor != undefined) {
        let connection = new CircleObjectCircle({
          circle: body.circle,
          circleObject: circleObject._id,
          taggedUsers: body.taggedUsers
        });
        await connection.save();
        circleObject.circle = undefined;
        await circleObject.save();

        if (body.build != null && body.build != undefined && body.build > 155) {
          payload = { id: circleObject._id, created: circleObject.created, lastUpdate: circleObject.lastUpdate };
        } else {
          payload = { circleobject: circleObject };
        }

      } else {

        metricLogic.incrementPosts(circleObject.creator);



        let type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEMESSAGE;
        if (circleObject.type == constants.CIRCLEOBJECT_TYPE.CIRCLEGIF)
          type = constants.CIRCLEOBJECT_ENGLISH.CIRCLEGIF;

        var notification = circleObject.creator.username + " sent a new ironclad " + type;
        var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
        let oldNotification = "New ironclad message";


        //if (body.waitingOn == null) {

          ///process now
          deviceLogicSingle.sendMessageNotificationToCircle(circleObject, circle, req.user.id, pushToken, circleObject.lastUpdate, notification, notificationType, oldNotification, body.taggedUsers);  //async ok

          //Add the circleobject to the user's newItems list
          circleObjectLogic.saveNewItem(circle._id, circleObject, body.device);

          ///wait 200 milliseconds
          //await new Promise(resolve => setTimeout(resolve, 3000));

          //process other objects waiting on this one if it's not waiting
          circleObjectLogic.processWaitingObjects(circleObject.seed);

        // } else {

        //   //save meta data for waiting object
        //   let waitingObject = new CircleObjectWaiting({ circleObject: circleObject._id, taggedUsers: body.taggedUsers, pushToken: pushToken, notification: notification, notificationType: notificationType, skipDevice: body.device });
        //   await waitingObject.save();

        //   circleObjectLogic.processWaitingObjects(body.waitingOn);

        // }

        if (body.build != null && body.build != undefined && body.build > 155) {
          payload = { _id: circleObject._id, seed: circleObject.seed, created: circleObject.created, lastUpdate: circleObject.lastUpdate };
        } else {
          payload = { circleobject: circleObject };
        }
      }
      //payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);

    }

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});


router.put('/hide/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleid);

    if (!(usercircle instanceof UserCircle)) {
      throw new Error('Access denied');
    }

    let circleObjectID = req.params.id;

    if (circleObjectID == 'undefined') {
      circleObjectID = body.circleObjectID;
    }

    var success = await circleObjectLogic.hideCircleObject(circleObjectID, body.circleid, req.user.id);

    let lastCircleObject = await usercircleLogic.updateLastItemUpdate(body.circleid, req.user.id);

    if (success) {
      //res.status(200).json({ msg: 'Successfully hide post', lastCircleObject: lastCircleObject });

      let payload = { msg: 'Successfully hide post', lastCircleObject: lastCircleObject };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);


    }
    else
      throw new Error('Post not found');

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });

  }
});

router.delete('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //AUTHORIZATION CHECK
    var circleObject = await securityLogicAsync.canUserModifyCircleObject(req.user.id, req.params.id);
    var circleObjectCircle;

    if (!(circleObject instanceof CircleObject)) {
      if (!(circleObject instanceof CircleObjectCircle)) {
        throw new Error('Access denied');
      } else {
        circleObjectCircle = circleObject;
      }
    }

    var success;
    let lastCircleObject;
    if (circleObjectCircle instanceof CircleObjectCircle) {
      success = await circleObjectLogic.deleteCircleObject(circleObjectCircle.circleObject, req);
      lastCircleObject = await usercircleLogic.updateLastItemUpdate(circleObjectCircle.circle._id, req.user.id);
    } else if (circleObject.scheduledFor != undefined) {
      circleObjectCircle = await CircleObjectCircle.findOne({ 'circleObject': req.params.id }).populate(['circleObject', 'circle']);
      success = await circleObjectLogic.deleteCircleObject(circleObjectCircle.circleObject, req);
      lastCircleObject = await usercircleLogic.updateLastItemUpdate(circleObjectCircle.circle._id, req.user.id);
    } else {
      success = await circleObjectLogic.deleteCircleObject(circleObject, req);
      lastCircleObject = await usercircleLogic.updateLastItemUpdate(circleObject.circle._id, req.user.id);
    }

    if (circleObjectCircle) {
      await CircleObjectCircle.deleteOne(circleObjectCircle);
    }

    ///TODO don't pass back the entire object
    if (success)
      res.status(200).json({ msg: 'Successfully deleted circleobject.', lastCircleObject: lastCircleObject });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });

  }

});


//updates the usercircle to remove 
async function updateShowBadge(newItems, usercircle) {


  try {

    usercircle.newItems = newItems;
    await usercircle.save();

    return usercircle;

  } catch (err) {

    console.error(err);
    return usercircle;
  }




}

async function defaultReactionSavePlus(circleObject,
  index,
  user,
  circleobjectid,
  circleID) {

  //compare index to find reaction
  //push reaction to circleObject.reactionsPlus

  let changed = false;
  let reactionFound = false;

  if (circleObject.reactionsPlus != undefined) {
    for (let i = 0; i < circleObject.reactionsPlus.length; i++) {
      if (changed == true) break;

      let reaction = circleObject.reactionsPlus[i];

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
          await CircleObjectReaction.updateOne({ '_id': reaction._id, }, { $push: { 'users': user } });

          let now = Date.now();
          await CircleObject.updateOne({ "_id": circleobjectid, circle: circleID }, { $set: { lastUpdate: now, lastReactedDate: now } });

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
    await CircleObject.updateOne({ '_id': circleObject._id }, { $push: { 'reactionsPlus': reaction } });
    let now = Date.now();
    await CircleObject.updateOne({ "_id": circleobjectid, circle: circleID }, { $set: { lastUpdate: now, lastReactedDate: now } });
    changed = true;
  }

  return changed;

}

async function defaultReactionSave(circleObject,
  index,
  user,
  circleobjectid,
  circleID) {

  //compare index to find reaction
  //push reaction to circleObject.reactions

  let changed = false;
  let reactionFound = false;

  if (circleObject.reactions != undefined) {
    for (let i = 0; i < circleObject.reactions.length; i++) {
      if (changed == true) break;

      let reaction = circleObject.reactions[i];

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
          await CircleObjectReaction.updateOne({ '_id': reaction._id, }, { $push: { 'users': user } });

          let now = Date.now();
          await CircleObject.updateOne({ "_id": circleobjectid, circle: circleID }, { $set: { lastUpdate: now, lastReactedDate: now } });

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
    await CircleObject.updateOne({ '_id': circleObject._id }, { $push: { 'reactions': reaction } });
    let now = Date.now();
    await CircleObject.updateOne({ "_id": circleobjectid, circle: circleID }, { $set: { lastUpdate: now, lastReactedDate: now } });
    changed = true;
  }

  return changed;

}

async function reactionsPlusSave(circleObject,
  emoji,
  user,
  circleobjectid,
  circleID) {

  //compare emoji to find reaction
  //push reaction to circleObject.reactionsPlus

  let changed = false;
  let reactionFound = false;

  if (circleObject.reactionsPlus != undefined) {
    for (let i = 0; i < circleObject.reactionsPlus.length; i++) {
      if (changed == true) break;

      let reaction = circleObject.reactionsPlus[i];

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
          await CircleObjectReaction.updateOne({ '_id': reaction._id, }, { $push: { 'users': user } });

          let now = Date.now();
          await CircleObject.updateOne({ "_id": circleobjectid, circle: circleID }, { $set: { lastUpdate: now, lastReactedDate: now } });

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
    await CircleObject.updateOne({ '_id': circleObject._id }, { $push: { 'reactionsPlus': reaction } });
    let now = Date.now();
    await CircleObject.updateOne({ "_id": circleobjectid, circle: circleID }, { $set: { lastUpdate: now, lastReactedDate: now } });
    changed = true;
  }

  return changed;

}

router.post('/reaction/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var userCircle = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleID);

    if (!userCircle)
      return res.status(400).json({ success: false, msg: 'Access denied' });

    var circleObject = await CircleObject.findOne({ "_id": body.circleobjectid, circle: body.circleID }).populate("circle")
      .populate({ path: 'creator', select: '_id username blockedList' }).populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } });

    if (!circleObject || circleObject == null)
      throw new Error('Access denied');

    let skip = false;
    if (circleObject.creator.blockedList.length > 0) {
      for (let i = 0; i < circleObject.creator.blockedList.length; i++) {
        let blockedUser = circleObject.creator.blockedList[i];
        if (blockedUser._id.equals(req.user._id)) {
          skip = true;
          return;
        }
      }
    }


    userCircle.showBadge = false;
    await userCircle.save();

    let emoji = body.emoji;
    let index = body.index;
    let changed = false;

    let newEmoji = false;

    if (index != null) {
      ///save to reactionsPlus
      changed = await defaultReactionSavePlus(circleObject, index, req.user, body.circleobjectid, body.circleID);
      ///save to reactions
      changed = await defaultReactionSave(circleObject, index, req.user, body.circleobjectid, body.circleID);
    } else if (emoji != null) {
      ///save to reactionsPlus
      changed = await reactionsPlusSave(circleObject, emoji, req.user, body.circleobjectid, body.circleID);
      newEmoji = true;
    }

    circleObject = await circleObjectLogic.findCircleObjectsByID(req.user.id, body.circleID, body.circleobjectid);
    if (changed == true && skip == false) {

      var notification = req.user.username + " reacted to your ironclad message";
      var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
      let oldNotification = "Member reacted to your ironclad message";

      let reaction;
      if (index != null) {
        reaction = CircleObjectReaction({ user: req.user.id, index: index });
      } else {
        reaction = CircleObjectReaction({ user: req.user.id, emoji: emoji });
      }

      deviceLogicSingle.sendReactionNotificationToCircle(circleObject, reaction, body.circleID, req.user.id, body.pushtoken, circleObject.lastUpdate, notification, notificationType, oldNotification, newEmoji);  //async ok
    }
    //console.log("Time after reaction complete");

    // return res.status(200).json({ circleobject: circleObject });

    let payload = { circleobject: circleObject };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});


router.delete('/reaction/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var valid = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleID);
    if (!valid)
      return res.status(400).json({ success: false, msg: 'Access denied' });

    var circleObject = await CircleObject.findOne({ "_id": body.circleobjectid, circle: body.circleID }).populate("circle")
      .populate('creator').populate({ path: 'reactions', populate: { path: 'users', select: '_id username', } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username', } });

    if (!circleObject || circleObject == null)
      throw new Error('access denied');

    let index = body.index;
    let emoji = body.emoji;

    let reaction = await CircleObjectReaction.findById(req.params.id);

    let verifiedIndex = reaction.index;
    let verifiedEmoji = reaction.emoji;

    if (verifiedIndex != null) {
      ///compare index to find reaction
      ///delete from reactions
      for (let i = 0; i < circleObject.reactions.length; i++) {

        if (circleObject.reactions[i].index == verifiedIndex) {

          ///remove user from reaction
          await CircleObjectReaction.updateOne({ '_id': circleObject.reactions[i]._id }, { $pull: { 'users': req.user.id } });

          if (circleObject.reactions[i].users.length == 1) {

            //TODO need to insert transaction here
            var reCheck = await CircleObjectReaction.findById(circleObject.reactions[i]._id);

            if (reCheck.users.length == 0)
              await CircleObject.updateOne({ '_id': body.circleobjectid }, { $pull: { 'reactions': circleObject.reactions[i]._id } });
            break;
          }
        }
      }

      ///compare index to find reaction
      ///delete from reactionsPlus
      for (let j = 0; j < circleObject.reactionsPlus.length; j++) {

        if (circleObject.reactionsPlus[j].index == verifiedIndex) {

          ///remove user from reaction
          await CircleObjectReaction.updateOne({ '_id': circleObject.reactionsPlus[j]._id }, { $pull: { 'users': req.user.id } });

          if (circleObject.reactionsPlus[j].users.length == 1) {

            //TODO need to insert transaction here
            var reCheck = await CircleObjectReaction.findById(circleObject.reactionsPlus[j]._id);

            if (reCheck.users.length == 0)
              await CircleObject.updateOne({ '_id': body.circleobjectid }, { $pull: { 'reactionsPlus': circleObject.reactionsPlus[j]._id } });
            break;
          }
        }
      }
    } else if (verifiedEmoji != null) {
      ///compare emoji to find reaction
      ///delete from reactionsPlus
      for (let i = 0; i < circleObject.reactionsPlus.length; i++) {

        if (circleObject.reactionsPlus[i].emoji == verifiedEmoji) {

          ///remove user from reaction
          await CircleObjectReaction.updateOne({ '_id': circleObject.reactionsPlus[i]._id }, { $pull: { 'users': req.user.id } });

          if (circleObject.reactionsPlus[i].users.length == 1) {

            //TODO need to insert transaction here
            var reCheck = await CircleObjectReaction.findById(circleObject.reactionsPlus[i]._id);

            if (reCheck.users.length == 0)
              await CircleObject.updateOne({ '_id': body.circleobjectid }, { $pull: { 'reactionsPlus': circleObject.reactionsPlus[i]._id } });
            break;
          }
        }
      }
    }

    let now = Date.now();

    await CircleObject.updateOne({ "_id": body.circleobjectid, circle: body.circleID }, { $set: { lastUpdate: now, lastReactedDate: now } });

    circleObject = await circleObjectLogic.findCircleObjectsByID(req.user.id, body.circleID, body.circleobjectid);

    deviceLogicSingle.sendReactionRemovalNotificationToCircle(body.circleID, req.user.id, body.pushtoken, circleObject.lastUpdate);  //async ok

    // return res.status(200).json({ circleobject: circleObject });

    let payload = { circleobject: circleObject };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


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
    if (!(userCircle instanceof UserCircle))
      return res.status(400).json({ success: false, msg: 'Access denied' });

    if (body.violation.reporter != req.user.id)
      return res.status(400).json({ msg: 'Access denied' });



    let circleObject = await CircleObject.findById(body.violation.circleObject).populate("creator");

    if (circleObject.creator.equals(body.violation.violator) == false)
      return res.status(400).json({ msg: 'Access denied' });

    let violation = await Violation.new(body.violation);
    violation.reporter = req.user.id;

    violation.circleObjectID = circleObject._id;
    violation.circleObjectType = circleObject.type;

    await violation.save();

    ///don't let a user report and delete a post to remove them
    if (userCircle.beingVotedOut != true) {
      await circleObjectLogic.tagViolation(body.circleID, circleObject);
    }



    //return res.status(200).json({ msg: 'violation reported' });
    let payload = { msg: 'violation reported' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});



//One time view
router.post('/onetimeview/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {


  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var circleObject = await CircleObject.findById(body.circleObjectID);

    if (!(circleObject instanceof CircleObject)) throw new Error(("CircleObject not found"));

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, circleObject.circle);

    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });

    let allowed = false;

    for (let i = 0; i < circleObject.ratchetIndexes.length; i++) {
      let ratchetIndex = circleObject.ratchetIndexes[i];

      if (ratchetIndex.user == req.user.id) {

        allowed = true;

        //remove the ratchets for the user
        await CircleObject.updateOne({ '_id': circleObject._id }, { $pull: { 'ratchetIndexes': { user: req.user._id } } });

        break;
      }

    }

    // res.status(200).send({ allowed: allowed });
    let payload = { allowed: allowed };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});


//Pin a CircleObject
router.post('/pinobject/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {


    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var circleObject = await CircleObject.findById(req.params.id);

    if (!(circleObject instanceof CircleObject)) throw new Error(('Access denied'));

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, circleObject.circle);

    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });

    if (body.circleWide == true) {
      //pin for the entire circle
      let userCircles = await UserCircle.find({ circle: circleObject.circle });

      for (let i = 0; i < userCircles.length; i++) {


        let found = false;

        for (let j = 0; j < circleObject.pinnedUsers.length; j++) {
          if (circleObject.pinnedUsers[j]._id.equals(userCircles[i].user._id)) found = true;
        }

        if (found == false) {
          circleObject.pinnedUsers.push(userCircles[i].user);
          circleObjectLogic.refreshNeeded(userCircles[i].user._id, circleObject._id, body.device);
        }

        await circleObject.save();
      }

    } else {

      let found = false;

      for (let j = 0; j < circleObject.pinnedUsers.length; j++) {
        if (circleObject.pinnedUsers[j]._id == req.user.id)
          found = true;

      }

      if (found == false) {
        circleObject.pinnedUsers.push(req.user.id);
        circleObjectLogic.refreshNeeded(req.user.id, circleObject._id, body.device);
        await CircleObject.updateOne({ '_id': circleObject._id }, { $push: { 'pinnedUsers': { _id: req.user.id } } });
      }

    }
    deviceLogicSingle.sendDataOnlyRefreshToCircle(circleObject.circle);

    //use the consolidated populate function
    circleObject = await circleObjectLogic.findCircleObjectsByID(req.user.id, circleObject.circle, circleObject._id);

    //res.status(200).send({ circleObject: circleObject });

    let payload = { circleObject: circleObject };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});

//unpin a CircleObject
router.delete('/pinobject/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var circleObject = await CircleObject.findById(req.params.id);

    if (!(circleObject instanceof CircleObject)) throw new Error(('Access denied'));

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, circleObject.circle);
    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });

    await CircleObject.updateOne({ '_id': circleObject._id }, { $pull: { 'pinnedUsers': req.user.id } });
    circleObjectLogic.refreshNeeded(req.user.id, circleObject._id, req.body.device);
    deviceLogicSingle.sendDataOnlyRefreshToCircle(circleObject.circle);

    res.status(200).send({ circleObject: circleObject });
  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});

//unpin a CircleObject
router.post('/unpinobject', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var circleObject = await CircleObject.findById(body.circleObjectID);

    if (!(circleObject instanceof CircleObject)) throw new Error(('Access denied'));

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, circleObject.circle);
    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });

    await CircleObject.updateOne({ '_id': circleObject._id }, { $pull: { 'pinnedUsers': req.user.id } });
    circleObjectLogic.refreshNeeded(req.user.id, circleObject._id, body.device);
    deviceLogicSingle.sendDataOnlyRefreshToCircle(circleObject.circle);

    //res.status(200).send({ circleObject: circleObject });

    let payload = { circleObject: circleObject };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});



module.exports = router;

