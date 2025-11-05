const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
var secret = process.env.secret;
const passport = require('passport');
const User = require('../models/user');
const Circle = require('../models/circle');
const deviceLogic = require('../logic/devicelogic');
const kyberLogic = require('../logic/kyberlogic');
var crypto = require("crypto");
const logUtil = require('../util/logutil');
const ObjectId = require('mongodb').ObjectId;

const LAPSEDSECOND = 20;
const SLOWLOGINAFTER = 3;
const HOURS_48 = 60 * 60 * 1000 * 48;

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

require('../config/passport')(passport);
var jwt = require('jsonwebtoken');
const user = require('../models/user');
const deviceremotewipe = require('../models/deviceremotewipe');


router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

router.post('/kybertest/', async (req, res) => {
  try {


    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //let decryptedBody = await kyberLogic.decryptBody(req.body.uuid, req.body.iv, req.body.mac, req.body.enc);

    console.log(body);

    ///pull some random data for testing
    let user = await User.findOne({ 'devices.uuid': req.body.uuid });
    let circle = await Circle.findOne({}).limit(1);

    let payload = { user, circle };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);







    // if (req.body.enc == null || req.body.enc == undefined) {
    //   throw new Error('unauthorized');
    // }

    // if (req.body.iv == null || req.body.iv == undefined) {
    //   throw new Error('unauthorized');
    // }

    // if (req.body.mac == null || req.body.mac == undefined) {
    //   throw new Error('unauthorized');
    // }


    // let deviceKyber = await DeviceKyber.findOne({ uuid: req.body.uuid, pk: { $ne: null }, sk: { $ne: null } });

    // const iv = Buffer.from(req.body.iv, 'utf8');
    // const mac = Buffer.from(req.body.mac, 'utf8');
    // const data = Buffer.from(req.body.enc, 'utf8');

    // //const aesCipher = AESGCM.aes256gcm(device);
    // const decrypted = aesCipher.decrypt(deviceKyber.ss, data, iv, mac);

    // res.status(200).json({ result: decrypted });

  } catch (err) {

    //var msg = await logUtil.logError(err, true);
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ err: msg });

  }

});

router.post('/kyberpublickey/', async (req, res) => {
  try {

    if (req.body.uuid == null || req.body.uuid == undefined) {
      throw new Error('unauthorized');
    }

    let pk = await kyberLogic.postPublicKey(req.body.uuid);

    res.status(200).json({ pk: pk });

  } catch (err) {

    //var msg = await logUtil.logError(err, true);
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ err: msg });

  }

});

router.post('/putkyberpublickey/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    if (req.body.uuid == null || req.body.uuid == undefined) {
      throw new Error('unauthorized');
    }

    let pk = await kyberLogic.putPublicKey(req.user._id, req.body.uuid);

    res.status(200).json({ pk: pk });

  } catch (err) {

    //var msg = await logUtil.logError(err, true);
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ err: msg });

  }

});

// router.post('/kyberpublickey/', passport.authenticate('jwt', { session: false }), async (req, res) => {
//   try {

//     ///make sure the device id matches one of the user's devices
//     let user = await User.findOne({ _id: req.user.id, 'devices.uuid': req.body.uuid });

//     if (!(user instanceof User)) {
//       throw new Error('unauthorized');
//     }

//     const recipient = new Kyber768(); // Kyber512 and Kyber1024 are also available.
//     const [pk, skR] = await recipient.generateKeyPair();

//     res.status(200).json({ pk: pk });

//   } catch (err) {

//     var msg = await logUtil.logError(err, true);
//     return res.status(500).json({ err: msg });

//   }

// });


router.post('/kybercipher/', async (req, res) => {
  try {

    if (req.body.uuid == null || req.body.uuid == undefined) {
      throw new Error('unauthorized');
    }


    await kyberLogic.postSharedSecret(req.body.uuid, req.body.ct);

    res.status(200).json({ msg: "success" });

  } catch (err) {

    //var msg = await logUtil.logError(err, true);
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ err: msg });

  }

});

///only authenticated users can update the shared secret
router.post('/putkybercipher/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    if (req.body.uuid == null || req.body.uuid == undefined || req.body.ct == null || req.body.ct == undefined) {
      throw new Error('unauthorized');
    }
    await kyberLogic.putSharedSecret(req.user._id, req.body.uuid, req.body.ct);

    res.status(200).json({ msg: "success" });

  } catch (err) {

    //var msg = await logUtil.logError(err, true);
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ err: msg });

  }

});


router.post('/fetch/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let user = await User.findOne({ _id: req.user.id, 'devices.activated': true });

    //res.status(200).json({ devices: user.devices });


    let payload = { devices: user.devices };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {

    //var msg = await logUtil.logError(err, true);
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ err: msg });

  }

});

router.post('/remotewipe/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let device = await deviceLogic.wipeDevice(req.user.id, body.uuid);

    //res.status(200).json({ wipeDevice: device });


    let payload = { wipeDevice: device };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});


router.post('/deactivate/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let device = await deviceLogic.deactivateDevice(req.user.id, body.uuid);

    //res.status(200).json({ deactivateDevice: device });

    let payload = { deactivateDevice: device };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});



module.exports = router;