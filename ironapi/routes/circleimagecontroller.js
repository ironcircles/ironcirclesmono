const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const CircleImage = require('../models/circleimage');
const CircleObject = require('../models/circleobject');
const passport = require('passport');
const securityLogic = require('../logic/securitylogic');
const securityLogicAsync = require('../logic/securitylogicasync');
const deviceLogic = require('../logic/devicelogic');
const circleObjectLogic = require('../logic/circleobjectlogic');
const deviceLogicSingle = require('../logic/devicelogicsingle');
const imageLogic = require('../logic/imagelogic');
const logUtil = require('../util/logutil');
const s3Util = require('../util/s3util');
const CircleObjectCircle = require('../models/circleobjectcircle');
const constants = require('../util/constants');
const metricLogic = require('../logic/metriclogic');
const CircleObjectWaiting = require('../models/circleobjectwaiting');
const kyberLogic = require('../logic/kyberlogic');
/*
var multer = require('multer');
const gridFS = require('../util/gridfsutil');
let Grid = require('gridfs-stream');
Grid.mongo = mongoose.mongo;
*/

const bodyParser = require('body-parser');
router.use(bodyParser.json({ limit: '10mb' }));
router.use(bodyParser.urlencoded({ limit: '10mb', extended: true, parameterLimit: 50000 }));

const ObjectID = require('mongodb').ObjectID;

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.post('/objectonly', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);
    let payload = {};

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleid);
    if (!usercircle)
      return res.status(400).json({ msg: 'Access denied' });

    if (usercircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }


    //create the circleobject
    var existingObject = await CircleObject.findOne({ 'creator': req.user.id, 'seed': body.seed, circle: body.circleid }).populate('creator').populate('circle').populate('image').populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();

    if (existingObject instanceof CircleObject) {
      console.log('Seed already exists');

      //The user can see this object because we already validated they are in the Circle above
      return res.status(200).json({ msg: 'Seed already exists', circleobject: existingObject });
    }

    let circleObject = await CircleObject.new(body);
    circleObject.creator = req.user.id;
    circleObject = circleObjectLogic.setTimer(circleObject, usercircle.circle._id);
    if (body.scheduledFor) {
      circleObject.scheduledFor = new Date(body.scheduledFor);
      if (circleObject.scheduledFor < Date.now()) {
        logUtil.logAlert(req.user.id + ' tried to schedule sending an image for a time before now.');
        return res.status(500);
      }
    }

    //create the circleimage object
    var circleImage = await CircleImage.new(body.image);
    circleImage.circle = usercircle.circle;  //TODO is this necessary?
    await circleImage.save();

    //console.log(circleImage._id.toString());

    //save the circleobject
    circleObject.image = circleImage;
    await circleObject.save();

    await circleObject.populate(['creator', 'circle', 'image']);

    if (circleObject.scheduledFor != null && circleObject.scheduledFor != undefined) {
      let connection = new CircleObjectCircle({
        circle: usercircle.circle,
        circleObject: circleObject._id,
        taggedUsers: body.taggedUsers
      });
      await connection.save();
      circleObject.circle = undefined;
      await circleObject.save();

      payload = { circleobject: circleObject };

    } else {

      metricLogic.incrementPosts(circleObject.creator);

      //Add the circleobject to the user's newItems list
      circleObjectLogic.saveNewItem(usercircle.circle._id, circleObject, body.device);

      var notification = circleObject.creator.username + " sent a new ironclad image";
      var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
      let oldNotification = "New ironclad message";

      //TURN OFF WAITING ON FOR NOW
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

      payload = { circleobject: circleObject };

    }

    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }
});


router.put('/objectonly/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var circleID = body.circleid;
    let circleObjectID = req.params.id;
    if (circleObjectID == 'undefined') {
      circleObjectID = body.circleObjectID;
    }

    //AUTHORIZATION CHECK

    var userCircle = await securityLogic.canUserAccessCircleAsync(req.user.id, circleID);

    if (!userCircle)
      return res.status(400).json({ success: false, msg: 'Access denied' });

    if (userCircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    let circleobject = await CircleObject.findOne({ "_id": circleObjectID, creator: req.user.id }).populate("circle").populate('creator').populate('image').populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();

    if (!(circleobject instanceof CircleObject)) {
      return res.status(400).json({ success: false, msg: 'c' });

    }

    await circleobject.update(body);
    await circleobject.image.update(body.image);

    await circleobject.image.save();

    circleobject.type = 'circleimage';
    circleobject.body = body.body;
    //circleobject.body = results[1];
    circleobject.emojiOnly = req.headers.emojiOnly;
    circleobject.lastUpdate = Date.now();
    await circleobject.save();

    await circleobject.populate([{ path: 'reactions', populate: { path: 'users', select: '_id username' } }, { path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }, 'creator', 'circle', 'image']);

    deviceLogicSingle.sendDataOnlyRefreshToCircle(circleID);
    //return res.status(200).json({ circleobject: circleobject, msg: 'Successfully created new circleobject.' });

    let payload = { circleobject: circleobject, msg: 'Successfully created new circleobject.' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err.message });
  }

});

/*
router.post('/thumbnail', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    //AUTHORIZATION CHECK
    var circle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.headers.circleid);
    if (!circle)
      return res.status(400).json({ msg: 'Access denied' });

    //make sure the parameters were passed in
    var circleID;
    var userID;

    try {
      circleID = new ObjectID(req.headers.circleid);
      userID = new ObjectID(req.user.id);

    } catch (err) {
      console.error(err);
      return res.status(400).json({ msg: 'Need to send parameters' });
    }

    //create the circleimage object
    var circleimage = new CircleImage();

    //create the circleobject
    var circleobject = await CircleObject.findOne({ 'creator': userID, 'seed': req.headers.seed });

    if (circleobject) {
      console.log('Seed already exists');
      return res.status(400).json({ msg: 'Seed already exists' });
    }


    circleobject = new CircleObject({
      circle: circleID,
      creator: userID,
      type: "circleimage",
    });

    var results;
    var body;

    //backwards compatible
    if (req.headers.bothimages != undefined)
      results = await gridFS.saveThumbAndFullReturnArray(req, res, req.headers.circleid);
    else
      results = await gridFS.saveBlobReturnArray(req, res, "image", "thumbnails", req.headers.circleid);


    //save the circleimage
    circleimage.circle = circleID;

    if (req.headers.bothimages != undefined) {
      circleimage.thumbnail = results.thumbnail;
      circleimage.fullImage = results.fullimage;
      circleimage.thumbnailSize = results.thumbnailSize;
      circleimage.fullImageSize = results.fullimageSize;

      body = results.body;

    } else {
      //this is deprecated
      circleimage.fullImage = results[1];
      body = results[0];
    }

    circleimage.imageType = req.headers.imagetype;
    await circleimage.save();


    console.log('posted thumbnail: ' + circleimage._id);

    //save the circleobject
    circleobject.created = Date.now();
    circleobject.image = circleimage;
    circleobject.seed = req.headers.seed;
    circleobject.lastUpdate = Date.now();

    if (body != null) {
      if (body != '') circleobject.body = body;
    }

    await circleobject.save();

    await CircleObject.populate(circleobject, { path: "circle" });
    await CircleObject.populate(circleobject, { path: "creator" });

    //send a notification to the circle
    if (req.headers.bothimages != undefined)
      await deviceLogic.sendNotificationToCircle(req.headers.circleid, req.user.id, req.headers.devicetoken, circleobject.lastUpdate, 'Member posted ironclad image');

    return res.status(200).json({ circleobject: circleobject, circleimage: circleimage });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }
});


router.post('/fullimage', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //AUTHORIZATION CHECK
    var circle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.headers.circleid);
    if (!circle)
      return res.status(400).json({ msg: 'Access denied' });

    var circleobject = await CircleObject.findById(req.headers.circleobjectid);

    var results = await gridFS.saveBlob(req, res, "image", "fullimages", req.headers.circleid);

    console.log('posted fullimage: ' + circleobject.image._id);

    circleobject.image.fullImage = results[0];
    circleobject.lastUpdate = Date.now();
    await circleobject.image.save();

    //send a notification to the circle
    deviceLogic.sendNotificationToCircle(req.headers.circleid, req.user.id, req.headers.devicetoken, circleobject.lastUpdate, 'Member posted ironclad image');

    return res.status(200).json({ fullImage: circleobject.image.fullImage, circleobject: circleobject });

  }
  catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }

});



router.get('/thumbnail/:id', passport.authenticate('jwt', { session: false }), function (req, res) {

  //AUTHORIZATION CHECK
  securityLogic.canUserAccessCircleReturnUserCircle(req.user.id, req.headers.circleid, function (valid) {
    if (!valid)
      return res.status(400).json({ msg: 'Access denied' });

    try {

      // console.log('Thumbnail fullImageID: ' + req.params.id);

      gridFS.loadBlob(res, "thumbnails", req.params.id)
        .catch(function (err) {
          console.error(err);
          //next(err);
          return res.status(200).json({ msg: "Failed to load thumbnail" });
        });

    } catch (err) {
      return res.status(500).json({ message: "Invalid id" });
    }
  });
});


router.get('/fullimage/:id', passport.authenticate('jwt', { session: false }), function (req, res) {

  //AUTHORIZATION CHECK
  securityLogic.canUserAccessCircleReturnUserCircle(req.user.id, req.headers.circleid, function (valid) {
    if (!valid) {
      console.log('Access denied');
      return res.status(400).json({ msg: 'Access denied' });
    }

    gridFS.loadBlob(res, "fullimages", req.params.id)
      .catch(function (err) {
        console.error(err);
        return res.status(500).json({ msg: "Failed to load image" });
      });

  });
});
*/



module.exports = router;