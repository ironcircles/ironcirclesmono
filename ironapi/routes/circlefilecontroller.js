const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const CircleFile = require('../models/circlefile');
const CircleObject = require('../models/circleobject');
const passport = require('passport');
const securityLogic = require('../logic/securitylogic');
const securityLogicAsync = require('../logic/securitylogicasync');
const logUtil = require('../util/logutil');
const circleObjectLogic = require('../logic/circleobjectlogic');
const deviceLogicSingle = require('../logic/devicelogicsingle');
const CircleObjectCircle = require('../models/circleobjectcircle');
/*const fileLogic = require('../logic/filelogic');
const logUtil = require('../util/logutil');
const s3Util = require('../util/s3util');
const deviceLogic = require('../logic/devicelogic');
*/
const kyberLogic = require('../logic/kyberlogic');
const constants = require('../util/constants');
const metricLogic = require('../logic/metriclogic');

/*
var multer = require('multer
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

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleid);
    if (!usercircle)
      return res.status(400).json({ msg: 'Access denied' });

    if (usercircle.
      beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    //create the circleobject
    var existingObject = await CircleObject.findOne({ 'creator': req.user.id, 'seed': body.seed, circle: body.circleid }).populate('creator').populate('circle').populate('file').populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();

    if (existingObject instanceof CircleObject) {
      console.log('Seed already exists');

      //The user can see this object because we already validated they are in the Circle above
      return res.status(200).json({ msg: 'Seed already exists', circleobject: existingObject });
    }

    let circleObject = await CircleObject.new(body);
    circleObject.creator = req.user.id;
    circleObject = circleObjectLogic.setTimer(circleObject, usercircle.circle);
    if (body.scheduledFor) {
      circleObject.scheduledFor = new Date(body.scheduledFor);
      if (circleObject.scheduledFor < Date.now()) {
        logUtil.logAlert(req.user.id + ' tried to schedule sending a file for a time before now.');
        return res.status(500);
      }
    }

    //create the circleimage object
    var circleFile = await CircleFile.new(body.file);
    circleFile.circle = body.circleid;  //TODO is this necessary?
    await circleFile.save();

    //console.log(circleImage._id.toString());

    //save the circleobject
    circleObject.file = circleFile;
    await circleObject.save();

    await circleObject.populate(['creator', 'circle', 'file']);

    if (circleObject.scheduledFor != null && circleObject.scheduledFor != undefined) {
      let connection = new CircleObjectCircle({
        circle: body.circle,
        circleObject: circleObject._id,
        taggedUsers: body.taggedUsers
      });
      await connection.save();
      circleObject.circle = undefined;
      await circleObject.save();


      let payload = { circleobject: circleObject };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);

    } else {

      metricLogic.incrementPosts(circleObject.creator);

      //Add the circleobject to the user's newItems list
      circleObjectLogic.saveNewItem(usercircle.circle._id, circleObject, body.device);

      var notification = circleObject.creator.username + " sent a new ironclad file";
      var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
      let oldNotification = "New ironclad message";

      deviceLogicSingle.sendMessageNotificationToCircle(circleObject, body.circleid, req.user.id, body.pushtoken, circleObject.lastUpdate, notification, notificationType, oldNotification);  //async ok

      let payload = { circleobject: circleObject };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json({ circleobject: circleObject });

    }
  } catch (err) {
    let msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
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

    var valid = await securityLogic.canUserAccessCircleAsync(req.user.id, circleID);

    if (!valid)
      return res.status(400).json({ success: false, msg: 'Access denied' });

    let circleobject = await CircleObject.findOne({ "_id": circleObjectID, creator: req.user.id }).populate("circle").populate('creator').populate('file').populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();

    if (!(circleobject instanceof CircleObject)) {
      return res.status(400).json({ success: false, msg: 'circleobject not found' });

    }

    await circleobject.update(body);
    await circleobject.file.update(body.file);

    await circleobject.file.save();

    circleobject.type = 'circlefile';
    circleobject.body = body.body;
    //circleobject.body = results[1];
    circleobject.emojiOnly = req.headers.emojiOnly;
    circleobject.lastUpdate = Date.now();
    await circleobject.save();

    await circleobject.populate([{ path: 'reactions', populate: { path: 'users', select: '_id username' } }, { path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }, 'creator', 'circle', 'file']);

    deviceLogicSingle.sendDataOnlyRefreshToCircle(circleID);
    //return res.status(200).json({ circleobject: circleobject, msg: 'Successfully created new circleobject.' });

    let payload = { circleobject: circleobject, msg: 'Successfully created new circleobject.' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    let msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});


module.exports = router;