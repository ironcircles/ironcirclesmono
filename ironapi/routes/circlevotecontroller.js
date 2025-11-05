const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const ObjectID = require('mongodb').ObjectId;
const passport = require('passport');
var CircleVote = require('../models/circlevote');
var UserCircle = require('../models/usercircle');
const CircleObject = require('../models/circleobject');
var voteLogic = require('../logic/votelogicasync');
const securityLogic = require('../logic/securitylogicasync');
const circleObjectLogic = require('../logic/circleobjectlogic');
const deviceLogic = require('../logic/devicelogic');
const deviceLogicSingle = require('../logic/devicelogicsingle');
const circle = require('../models/circle');
const logUtil = require('../util/logutil');
const constants = require('../util/constants');
const metricLogic = require('../logic/metriclogic');
const CircleObjectCircle = require('../models/circleobjectcircle');
const Circle = require('../models/circle');
const kyberLogic = require('../logic/kyberlogic');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.json({ limit: '10mb' }));
router.use(bodyParser.urlencoded({ limit: '10mb', extended: true, parameterLimit: 50000 }));


router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var userCircle = await securityLogic.canUserAccessCircle(req.user.id, body.circleid);
    if (!(userCircle instanceof UserCircle)) return res.status(400).json({ msg: 'Access denied' });


    if (userCircle.
      beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }


    var circleID;

    //make sure the parameters were passed in
    try {
      circleID = new ObjectID(body.circleid);
    } catch (err) {
      return res.status(400).json({ msg: "Need to send valid parameters" });
    }

    //does the seed from this user already exist?
    var existing = await CircleObject.findOne({ seed: body.seed, creator: req.user.id, circle: body.circle }).populate('creator').populate('circle').populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).populate({
      path: 'vote',
      populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, {
        path: 'options',
        populate: { path: 'usersVotedFor' }
      }]
    }).exec();

    let payload = {};

    if (existing instanceof CircleObject) {
      logUtil.logAlert(req.user.id + ' tried to post an object that already exists. seed: ' + body.seed);
      //return res.status(200).json({ circleobject: existing, msg: 'circleobject already exists.' });
      payload ={ circleobject: existing, msg: 'circleobject already exists.' };

    } else {

      var circleObject = await voteLogic.createCircleVote(circleID, req.user.id, body.question, null, body.model, null, body.options, body.seed);

      circleObject.device = body.device;
      if (body.scheduledFor != null) {
        circleObject.scheduledFor = new Date(body.scheduledFor);
        if (circleObject.scheduledFor < Date.now()) {
          logUtil.logAlert(req.user.id + ' tried to schedule sending a vote for a time before now.');
          return res.status(500);
        }
      }



      if (circleObject.scheduledFor != null && circleObject.scheduledFor != undefined) {
        let connection = new CircleObjectCircle({
          circle: body.circleid,
          circleObject: circleObject._id,
          taggedUsers: body.taggedUsers
        });
        await connection.save();
        circleObject.circle = undefined;
        await circleObject.save();
        await circleObject.populate('creator');
        //return res.status(200).json({ circleobject: circleObject });
        payload = { circleobject: circleObject };

      } else {

        //Add the circleobject to the user's newItems list
        circleObjectLogic.saveNewItem(userCircle.circle._id, circleObject, body.device);

        var notification = circleObject.creator.username + " created an new vote";
        var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
        let oldNotification = "New ironclad message";

        metricLogic.incrementPosts(circleObject.creator);

        //send a notification to the circle and return
        deviceLogicSingle.sendMessageNotificationToCircle(circleObject, circleID, req.user.id, body.pushtoken, circleObject.lastUpdate, notification, notificationType, oldNotification);  //async ok

        //deviceLogicSingle.sendMessageNotificationToCircle(circleObject, circleID, req.user.id, body.pushtoken, circleObject.lastUpdate);  //async ok

        await circleObject.populate('creator');
        payload = { circleobject: circleObject };

      }


    }

    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    
    return res.status(200).json(payload);


  } catch (err) {
    let msg = await logUtil.logError(err, true, null, req.user.id);
    return res.status(500).json({ msg: msg });
  }


});


module.exports.deleteByVoteID = async function (voteID) {
  try {

    //Delete the CircleVote
    await CircleVote.findByIdAndRemove({ _id: voteID });

    return;

  } catch (err) {
    console.error(err);
    throw (err);
  }

}

router.put('/uservoted/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  //make sure the parameters were passed in
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var userCircle = await securityLogic.canUserAccessCircle(req.user.id, body.circleid);
    if (!userCircle) return res.status(400).json({ msg: 'Access denied' });


    let id = req.params.id;
    if (id == 'undefined') {

      id = body.circleObjectID;
    }

    var circleObjectID;

    //make sure the parameters were passed in
    try {
      circleObjectID = new ObjectID(id);
    } catch (err) {
      return res.status(400).json({ msg: "Need to send valid parameters" });
    }

    var circleObject = await voteLogic.setUserVote(circleObjectID, req.user.id, body.option);

    if (!circleObject instanceof CircleObject) throw (circleObject);

    await circleObject.populate([{
      path: 'vote',
      populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, {
        path: 'options',
        populate: { path: 'usersVotedFor' }
      }]
    }, { path: 'reactions', populate: { path: 'users', select: '_id username' } },{ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }, 'circle', "creator"]);

    var notification = userCircle.user.username + " voted";
    var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
    let oldNotification = "New ironclad message";

    await deviceLogicSingle.sendNotificationToCreator(notification, circleObject, userCircle.circle._id, req.user.id, body.pushtoken, circleObject.lastUpdate, notificationType, oldNotification);
    deviceLogic.sendDataOnlyMessage(userCircle.circle._id, userCircle, body.pushtoken, constants.TAG_TYPE.EDIT, circleObject.lastUpdate);
    //deviceLogicSingle.sendMessageNotificationToCircle(circleObject, userCircle.circle._id, req.user.id, req.body.pushtoken, circleObject.lastUpdate, notification, notificationType, oldNotification);  //async ok


    //return res.json({ msg: 'Successfully saved vote', circleobject: circleObject, circle: circleObject.circle });

    let payload = { msg: 'Successfully saved vote', circleobject: circleObject, circle: circleObject.circle };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }

});



module.exports = router;
