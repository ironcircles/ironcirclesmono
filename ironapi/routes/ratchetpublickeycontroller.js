const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
var secret = process.env.secret;
const passport = require('passport');
const User = require('../models/user');
const RatchetPublicKey = require('../models/ratchetpublickey');
const Circle = require('../models/circle');
const UserCircle = require('../models/usercircle');
const CircleObject = require('../models/circleobject');
const Delivered = require('../models/circleobjectdelivered');
const ActionRequired = require('../models/actionrequired');
const deviceLogic = require('../logic/devicelogic');
const userCircleLogic = require('../logic/usercirclelogic');
const circleObjectLogic = require('../logic/circleobjectlogic');
const constants = require('../util/constants');
var crypto = require("crypto");
const logUtil = require('../util/logutil');
const securityLogicAsync = require('../logic/securitylogicasync');
const ratchetKeyLogic = require('../logic/ratchetkeylogic');
const RatchetPublicKeyHistory = require('../models/ratchetpublickeyhistory');
const kyberLogic = require('../logic/kyberlogic');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

require('../config/passport')(passport);
var jwt = require('jsonwebtoken');

//router.use(bodyParser.urlencoded({ extended: true }));
//router.use(bodyParser.json());

router.use(bodyParser.json({ limit: '100mb' }));
router.use(bodyParser.urlencoded({ limit: '100mb', extended: true, parameterLimit: 50000 }));

///Get the public keys for a circle, deprecated, POSTKYBER
router.get('/:circleid', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    // //Authorization Check
    // var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.params.circleid);
    // if (!userCircle instanceof UserCircle) {
    //   console.log("RatchetController access denied userid: " + req.user.id + " circleid: " + req.params.circleid);

    //   throw Error("access denied");
    // }

    // if (userCircle.beingVotedOut == true) {
    //   throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    // }


    // //include the current members; will need to create ratchet for self in case of reinstall or clearing cache
    // let memberCircles = await UserCircle.find({ circle: userCircle.circle, removeFromCache: undefined, ratchetPublicKeys: { $ne: null }, beingVotedOut: { $ne: true } });


    // let ratchetPublicKeys = [];

    // for (let i = 0; i < memberCircles.length; i++) {

    //   //console.log(memberCircles[i]._id.toString());

    //   for (let j = 0; j < memberCircles[i].ratchetPublicKeys.length; j++) {
    //     ratchetPublicKeys.push(memberCircles[i].ratchetPublicKeys[j]);
    //   }
    // }

    let ratchetPublicKeys = await ratchetKeyLogic.getPublicKeys(req.user.id, req.params.circleid);

    res.status(200).json({ ratchetPublicKeys: ratchetPublicKeys });
  } catch (err) {
    let msg = await logUtil.logError(err, true);
    res.status(500).json({ msg: msg });
  }


});

router.post('/getpublic/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    // //Authorization Check
    // var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleID);
    // if (!userCircle instanceof UserCircle) {
    //   console.log("RatchetController access denied userid: " + req.user.id + " circleid: " + body.circleID);

    //   throw Error("access denied");
    // }

    // if (userCircle.beingVotedOut == true) {
    //   throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    // }


    // //include the current members; will need to create ratchet for self in case of reinstall or clearing cache
    // let memberCircles = await UserCircle.find({ circle: userCircle.circle, removeFromCache: undefined, ratchetPublicKeys: { $ne: null }, beingVotedOut: { $ne: true } });


    // let ratchetPublicKeys = [];

    // for (let i = 0; i < memberCircles.length; i++) {

    //   //console.log(memberCircles[i]._id.toString());

    //   for (let j = 0; j < memberCircles[i].ratchetPublicKeys.length; j++) {
    //     ratchetPublicKeys.push(memberCircles[i].ratchetPublicKeys[j]);
    //   }
    // }

    //res.status(200).json({ ratchetPublicKeys: ratchetPublicKeys });

    let ratchetPublicKeys = await ratchetKeyLogic.getPublicKeys(req.user.id, body.circleID);

    let payload = { ratchetPublicKeys: ratchetPublicKeys };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);
  } catch (err) {
    let msg = await logUtil.logError(err, true);
    res.status(500).json({ msg: msg });
  }


});

///used to set password helpers
///TODO reduce the return results to just the users actually selected, could be a problem on large networks, POSTKYBER
router.post('/publicmemberkeys/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var user = await User.findOne({ "_id": req.user.id });
    let members = await userCircleLogic.listOfConnectedUsers(user);

    let userPublicKeys = [];

    for (let i = 0; i < members.length; i++) {

      for (let j = 0; j < req.body.passwordHelpers.length; j++) {

        if (members[i]._id.equals(req.body.passwordHelpers[j]._id)) {
          userPublicKeys.push(members[i].ratchetPublicKey);
          break;

        }
      }
    }

    res.status(200).json({ ratchetPublicKeys: userPublicKeys });
  } catch (err) {
    let msg = await logUtil.logError(err, true);
    res.status(500).json({ msg: msg });
  }


});

///used to set password helpers
///TODO reduce the return results to just the users actually selected, could be a problem on large networks
router.post('/getpublicmemberkeys/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await User.findOne({ "_id": req.user.id });
    let members = await userCircleLogic.listOfConnectedUsers(user);

    let userPublicKeys = [];

    for (let i = 0; i < members.length; i++) {

      for (let j = 0; j < body.passwordHelpers.length; j++) {

        if (members[i]._id.equals(body.passwordHelpers[j]._id)) {
          userPublicKeys.push(members[i].ratchetPublicKey);
          break;

        }
      }
    }

    //res.status(200).json({ ratchetPublicKeys: userPublicKeys });

    let payload = { ratchetPublicKeys: userPublicKeys };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    let msg = await logUtil.logError(err, true);
    res.status(500).json({ msg: msg });
  }


});

///deprecated, POSTKYBER
router.get('/publicmemberkey/:userid', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let user = await User.findOne(req.params.userid);
    var requester = await User.findOne({ "_id": req.user.id });
    let members = await userCircleLogic.listOfConnectedUsers(requester);

    let allowed = false;

    for (let i = 0; i < members; i++) {
      if (requester._id.equals(members[i]._id)) {
        allowed = true;
        break;
      }
    }

    if (allowed)
      res.status(200).json({ publicKey: user.publicKey });
    else
      throw ('unauthorized');
  } catch (err) {
    let msg = await logUtil.logError(err, true);
    res.status(500).json({ msg: msg });
  }


});

router.post('/getpublicmemberkey/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let user = await User.findOne(body.userID);
    var requester = await User.findOne({ "_id": req.user.id });
    let members = await userCircleLogic.listOfConnectedUsers(requester);

    let allowed = false;

    for (let i = 0; i < members; i++) {
      if (requester._id.equals(members[i]._id)) {
        allowed = true;
        break;
      }
    }

    if (allowed) {
      //res.status(200).json({ publicKey: user.publicKey });
      let payload = { publicKey: user.publicKey };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);
    }
    else
      throw new Error('unauthorized');
  } catch (err) {
    let msg = await logUtil.logError(err, true);
    res.status(500).json({ msg: msg });
  }


});




/*


async function ratchetKeysForward(userID, ratchetPublicKeys) {

  for (let i = 0; i < ratchetPublicKeys.length; i++) {
    let remoteRatchet = ratchetPublicKeys[i];

    if (remoteRatchet.device == undefined || remoteRatchet.device == null || remoteRatchet.device == "")
      throw ("device is blank (new device or circle)");


    //Authorization Check
    var userCircle = await securityLogicAsync.canUserAccessUserCircle(userID, remoteRatchet.userCircle);
    if (!userCircle instanceof UserCircle) throw Error("access denied");

    let ratchetPublicKey = RatchetPublicKey({ user: userID, circle: userCircle.circle, device: remoteRatchet.device, public: remoteRatchet.public, keyIndex: remoteRatchet.keyIndex });

    //in case there is already one for this device

    await UserCircle.updateOne({ '_id': userCircle._id }, { $push: { 'ratchetPublicKeys': ratchetPublicKey } }); //,'keyIndex': {$ne: ratchetPublicKey.keyIndex} } });
    await UserCircle.updateOne({ '_id': userCircle._id }, { $pull: { 'ratchetPublicKeys': { user: userID, device: ratchetPublicKey.device, 'keyIndex': { $ne: ratchetPublicKey.keyIndex } } } });

    //await UserCircle.updateOne({ '_id': userCircle._id }, { $pull: { 'ratchetPublicKeys': { device: ratchetPublicKey.device, user: req.user._id } } });
    //await UserCircle.updateOne({ '_id': userCircle._id }, { $push: { 'ratchetPublicKeys': ratchetPublicKey } });

    //userCircle.ratchetPublicKeys.push(ratchetPublicKey);
    //await userCircle.save();


  }

  await User.updateOne({ "_id": userID }, { $set: { keyGen: true } });


}

//User has logged into new device or joined a new circle
router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    logUtil.logAlert(req.user.id + ' has ratcheted multiple keys forward');

    //async call so it doesn't timeout
    ratchetKeysForward(req.user.id, req.body.ratchetPublicKeys);


    res.status(200).json({ msg: "keys added", });
  } catch (err) {
    let msg = await logUtil.logError(err, true);
    res.status(500).json({ msg: msg });
  }

*/


ratchetKeysForward = async function (userID, ratchetPublicKeys) {

  try {

    for (let i = 0; i < ratchetPublicKeys.length; i++) {
      let remoteRatchet = ratchetPublicKeys[i];

      if (remoteRatchet.device == undefined || remoteRatchet.device == null || remoteRatchet.device == "")
        throw ("device is blank (new device or circle)");

      //Authorization Check
      var userCircle = await securityLogicAsync.canUserAccessUserCircle(userID, remoteRatchet.userCircle);
      if (!userCircle instanceof UserCircle) throw Error("access denied");

      let ratchetPublicKey = RatchetPublicKey({ user: userID, circle: userCircle.circle, device: remoteRatchet.device, public: remoteRatchet.public, keyIndex: remoteRatchet.keyIndex });

      //in case there is already one for this device
      await UserCircle.updateOne({ '_id': userCircle._id }, { $push: { 'ratchetPublicKeys': ratchetPublicKey } }); //,'keyIndex': {$ne: ratchetPublicKey.keyIndex} } });
      await UserCircle.updateOne({ '_id': userCircle._id }, { $pull: { 'ratchetPublicKeys': { user: userID, device: ratchetPublicKey.device, 'keyIndex': { $ne: ratchetPublicKey.keyIndex } } } });

    }

    await User.updateOne({ "_id": userID }, { $set: { keyGen: true } });

    //console.log('RATCHETED PUBLIC KEYS DONE AT ' + Date.now().toString());
  } catch (err) {
    let msg = await logUtil.logError(err, true, null, userID);
    res.status(500).json({ msg: msg });
  }
}

//User has logged into new device or joined a new circle
router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    logUtil.logAlert(req.user.id + ' has ratcheted multiple keys forward', null, req.user.id);

    ///async call so it doesn't timeout
    ratchetKeysForward(req.user.id, body.ratchetPublicKeys);

    //console.log('200 DONE AT ' + Date.now().toString());

    //return early so the client doesn't timeout
    //res.status(200).json({ msg: "keys added", });

    let payload = { msg: "keys added", };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    let msg = await logUtil.logError(err, true);
    res.status(500).json({ msg: msg });
  }

  //await user.updateOne({ $pull: { nextKeys: {keyIndex: oldIndex} }});

});

/*
//User has logged into new device or joined a new circle
router.post('/userpublickey/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    await User.updateOne({ "_id": req.user._id }, { $set: { public: req.body.public } });

    res.status(200).json({ msg: "key added", });
  } catch (err) {
    let msg = await logUtil.logError(err, true);
    res.status(500).json({ msg: msg });
  }

  //await user.updateOne({ $pull: { nextKeys: {keyIndex: oldIndex} }});

});
*/


//Public key has been ratcheted forward clientside
router.put('/:circleid', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let circleID = req.params.circleid;
    if (circleID == 'undefined') {
      circleID = body.circleID;
    }

    //Authorization Check
    var userCircle = await securityLogicAsync.canUserAccessCircle(req.user._id, circleID);
    if (!userCircle instanceof UserCircle) throw Error("access denied");

    if (body.ratchetPublicKey.device == undefined || body.ratchetPublicKey.device == null || body.ratchetPublicKey.device == "")
      throw ("device is blank");


    let ratchetPublicKey = RatchetPublicKey({ user: req.user._id, circle: userCircle.circle, device: body.ratchetPublicKey.device, public: body.ratchetPublicKey.public, keyIndex: body.ratchetPublicKey.keyIndex });


    //add first, then remove others for device
    await UserCircle.updateOne({ '_id': userCircle._id }, { $push: { 'ratchetPublicKeys': ratchetPublicKey } }); //,'keyIndex': {$ne: ratchetPublicKey.keyIndex} } });

    sleepToAvoidMongoReplicaIssue(req.user.id, userCircle, ratchetPublicKey);
    /*
    for (let i = 0; i < userCircle.ratchetPublicKeys.length; i++) {
      let ratchetKey = userCircle.ratchetPublicKeys[i];

      if (ratchetKey.device == ratchetPublicKey.device && ratchetKey.keyIndex != ratchetPublicKey.keyIndex) {
        //remove the old key
        await UserCircle.updateOne({ '_id': userCircle._id }, { $pull: { 'ratchetPublicKeys': { user: req.user._id, device: ratchetPublicKey.device, 'keyIndex': ratchetKey.keyIndex } } });
      }

    }*/

    //The below caused issues when mass posting to a circle
    //await UserCircle.updateOne({ '_id': userCircle._id }, { $pull: { 'ratchetPublicKeys': { user: req.user._id, device: ratchetPublicKey.device, 'keyIndex': { $ne: ratchetPublicKey.keyIndex } } } });

    //console.log('RATCHETED PUBLIC KEY');

    if (body.circleobjects != null && body.circleobjects != undefined) {

      let ids = [];
      for (let j = 0; j < body.circleobjects.length; j++) {

        ids.push(body.circleobjects[j]._id);

      }
      circleObjectLogic.markDelivered(req.user.id, ids, body.device);

    }

    //res.status(200).json({ msg: "keys added", });

    let payload = { msg: "keys added", };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    let msg = await logUtil.logError(err, true);
    res.status(500).json({ msg: msg });
  }

  //await user.updateOne({ $pull: { nextKeys: {keyIndex: oldIndex} }});            

});


async function sleepToAvoidMongoReplicaIssue(userID, userCircle, ratchetPublicKey) {

  try {

    ///this function is neccessary because there was a timing issue with push and pull and the replica set
    ///not actually slepping anymore, looping through one by one instead.

    let ratchetPublicKeyHistory = new RatchetPublicKeyHistory({ circle: userCircle.circle, user: userID, userCircle: userCircle._id, ratchetPublicKeys: userCircle.ratchetPublicKeys, newPublicKey: ratchetPublicKey });


    let removedOne = false;
    //setTimeout(async function() {
    for (let i = 0; i < userCircle.ratchetPublicKeys.length; i++) {
      let ratchetKey = userCircle.ratchetPublicKeys[i];

      if (ratchetKey.device == ratchetPublicKey.device && ratchetKey.keyIndex != ratchetPublicKey.keyIndex) {

        ratchetPublicKeyHistory.removedPublicKeys.push(ratchetKey);
        removedOne = true;
        //remove the old key
        await UserCircle.updateOne({ '_id': userCircle._id }, { $pull: { 'ratchetPublicKeys': { user: userID, device: ratchetPublicKey.device, 'keyIndex': ratchetKey.keyIndex } } });
      }

      if (removedOne) {
        await ratchetPublicKeyHistory.save();
      }



    }
    //}, 3000);
  } catch (err) {
    logUtil.logError(err, true);
  }

}


/*
//User has logged into new device. Fetch the 
router.get('/:usercircleid', passport.authenticate('jwt', { session: false }), function (req, res) {

  try {
    //Authorization Check
    var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.body.circleid);
    if (!userCircle) throw Error("access denied");

    //load next set of public keys for this circle
    let ratchetPublicKeys = await RatchetPublicKey.load({ circle: userCircle.circle });

    res.status(200).json({ ratchetPublicKeys: ratchetPublicKeys});
  } catch (err) {
    let msg = await logUtil.logError(err, true);
    res.status(500).json({ msg: msg });
  }

});
*/

module.exports = router;