const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
var CircleLink = require('../models/circlelink');
const CircleObject = require('../models/circleobject');
const passport = require('passport');
const securityLogic = require('../logic/securitylogicasync');
const deviceLogic = require('../logic/devicelogic');
const bodyParser =  require('body-parser');
const logUtil = require('../util/logutil');
const kyberLogic = require('../logic/kyberlogic');
//const bodyParser =  require('body-parser');
const ObjectID = require('mongodb').ObjectID;

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

/*
router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircle(req.user.id, req.body.circleID);

    if (!usercircle)
      return res.status(400).json({ msg: 'Access denied' });

    //make sure the parameters were passed in
    try {
      var circleID = new ObjectID(req.body.circleID);
      var userID = new ObjectID(req.user.id);

    } catch (err) {
      console.error(err);
      return res.status(400).json({ msg: 'Need to send parameters' });
    }


    //create the circlelink object
    var circlelink = new CircleLink();

    //create the circleobject
    var circleobject = new CircleObject({
      circle: circleID,
      creator: userID,
      body: req.body.body,
      type: "circlelink",
      seed: req.body.seed,
    });

    circlelink.circle = circleID;
    circlelink.title = req.body.title;
    circlelink.description = req.body.description;
    circlelink.url = req.body.url;
    circlelink.image = req.body.image;
    //circlegif.imageType = req.headers.imagetype;
    await circlelink.save();

    circleobject.link = circlelink;
    circleobject.lastUpdate = Date.now();

    await circleobject.save();
    await circleobject.populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate('creator').populate('circle').populate('link').execPopulate();

    //send a notification to the circle and return
    await deviceLogic.sendNotificationToCircle(circleID, req.user.id, req.body.pushtoken);

    return res.status(200).json({ circleobject: circleobject, circlelink: circlelink });
  } catch (err) {
    console.error(err);
    //next(err);
    return res.status(500).json({ msg: "Failed to upload link" });
  }

});


router.put('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircle(req.user.id, req.body.circleID);

    if (!usercircle)
      return res.status(400).json({ msg: 'Access denied' });

    var circleObject = await CircleObject.findOne({ "_id": req.params.id }).populate('link').populate('circle').populate('creator');

    if (!circleObject.link)
      circleObject.link = CircleLink();

    circleObject.type = 'circlelink';
    circleObject.link.title = req.body.title;
    circleObject.link.description = req.body.description;
    circleObject.link.url = req.body.url;
    circleObject.link.image = req.body.image;
    await circleObject.link.save();

    circleObject.body = req.body.body;
    circleObject.lastUpdate = Date.now();
    await circleObject.save();

    deviceLogic.sendNotificationToCircle(req.body.circleID, req.user.id, req.body.pushtoken);  //async ok
    return res.status(200).json({ circleobject: circleObject, msg: 'Successfully updated CircleLink.' });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: "Failed to upload link" });
  }

});
*/
module.exports = router;