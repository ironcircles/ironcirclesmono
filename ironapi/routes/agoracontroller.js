const RtcTokenBuilder = require("agora-token");
//const RtcRole = require("../src/RtcTokenBuilder2").Role;
//const RtcTokenBuilder = require("../src/RtcTokenBuilder2").RtcTokenBuilder;
const kyberLogic = require('../logic/kyberlogic');
const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const passport = require('passport');
var randomstring = require("randomstring");
const AgoraCall = require('../models/circleagoracall');
const AgoraUser = require('../models/agorauser');
const AgoraCallMinutes = require('../models/circleagoracallminutes');
const logUtil = require('../util/logutil');
const securityLogic = require('../logic/securitylogic');
const gen = require('../util/gen');
const deviceLogicSingle = require('../logic/devicelogicsingle');


// Get the value of the environment variable AGORA_APP_ID. Make sure you set this variable to the App ID you obtained from Agora console.
const appId = process.env.AGORA_APP_ID;
// Get the value of the environment variable AGORA_APP_CERTIFICATE. Make sure you set this variable to the App certificate you obtained from Agora console
const appCertificate = process.env.AGORA_APP_CERTIFICATE;

// Set streaming permissions
//const role = RtcRole.PUBLISHER;
// Token validity time in seconds
const tokenExpirationInSecond = 3600;
// The validity time of all permissions in seconds
const privilegeExpirationInSecond = 86400;

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

//get a token for video calls
router.post('/startcall/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleID);

    //generate a 30 char unique channel name
    let channelName = randomstring.generate({
      length: 40,
      charset: 'alphabetic'
    })

    var agoraUserID;


    // Check if the user already has an Agora user ID
    let agoraUser = await AgoraUser.findOne({ user: req.user._id });
    if (!(agoraUser instanceof AgoraUser)) {
     // Generate a random unsigned 32-bit integer for the Agora user ID
      agoraUserID = gen.randomUInt32();
 
      agoraUser = new AgoraUser({

        agoraID: agoraUserID, // Generate a random unsigned 32-bit integer
        user: req.user._id
      });
      await agoraUser.save();
    } else {
      agoraUserID = agoraUser.agoraID;
    }



    // Generate Token
    const tokenWithUid = RtcTokenBuilder.RtcTokenBuilder.buildTokenWithUid(appId, appCertificate, channelName, agoraUserID, RtcTokenBuilder.RtcRole.PUBLISHER, tokenExpirationInSecond, privilegeExpirationInSecond);

    ///add the call record
    let agoraCall = new AgoraCall({
      circle: usercircle._circle,
      channel: channelName,
      active: true,
      participants: [req.user._id],
      callType: 'video',
      startTime: Date.now()
    });

    await agoraCall.save();

    //notify the circle that a call has started
    await deviceLogicSingle.sendMessageNotificationToCircle();

    let payload = { token: tokenWithUid, 
      agoraUserID: agoraUserID,
      channelName: channelName
    };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});


//get a token for video calls
router.post('/joincall/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, req.params.id);

    let agoraCall = await AgoraCall.findOne({ circle: usercircle._circle, active: true }.sort({ created: -1 }).limit(1));

    // Generate Token
    const tokenWithUid = RtcTokenBuilder.buildTokenWithUid(appId, appCertificate, agoraCall.channelName, req.user._id, RtcTokenBuilder.RtcRole.PUBLISHER, tokenExpirationInSecond, privilegeExpirationInSecond);

    //add the user to the call record if the user isn't already a participant
    if (!agoraCall.participants.includes(req.user._id)) {
      agoraCall.participants.push(req.user._id);
      await agoraCall.save();
    }

    let payload = { token: tokenWithUid };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});

//leave an angora call
router.post('/leavecall/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var userCircle = await securityLogic.canUserAccessCircleAsync(req.user.id, req.params.id);

    await AgoraCall.updateMany({ 'user': req.user._id }, { $pull: { 'activeParticipants': { user: req.user._id, circleID: userCircle.circle } } });

    let payload = { token: tokenWithUid };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});

module.exports = router;