const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
var secret = process.env.secret;
const passport = require('passport');
const User = require('../models/user');
const KeychainBackup = require('../models/keychainbackup');
const KeychainFull = require('../models/keychainfull');
const constants = require('../util/constants');
const logUtil = require('../util/logutil');
const s3Util = require('../util/s3util');
const ActionRequired = require('../models/actionrequired');
const gridFS = require('../util/gridfsutil');
const kyberLogic = require('../logic/kyberlogic');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

require('../config/passport')(passport);

router.use(bodyParser.json({ limit: '50mb' }));
router.use(bodyParser.urlencoded({ limit: '50mb', extended: true, parameterLimit: 50000 }));

//router.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));
//router.use(bodyParser.json());



//backup keychains
router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //just adding records
    let keychainBackup = new KeychainBackup({ device: body.device, keychain: body.keychain, user: req.user._id });
    keychainBackup.location = process.env.blobLocation;

    await keychainBackup.save();



    let payload = { success: true };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

    //res.status(200).json({ success: true });


  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});

//backup keychains
router.post('/fullbackup/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //just adding records
    let keychainFull = new KeychainFull({ device: body.device, keychain: body.keychain, user: req.user._id, keychainBackupSize: body.size });
    keychainFull.location = process.env.blobLocation;

    await keychainFull.save();

    let payload = { success: true };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);


  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});


//get keychains
router.post('/restore/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let allBackups = [];

    let pullExtra = false;

    if (body.pullExtra != undefined && body.pullExtra != null) {

      pullExtra = body.pullExtra;
    }

    let fullBackups = await KeychainFull.find({ user: req.user._id }).sort({ created: -1 }).limit(50);

    if (fullBackups.length == 0) {
      //no full backups, just get the all the incremental backups
      let keychainBackups = await KeychainBackup.find({ user: req.user._id }).sort({ lastUpdate: -1 });

      if (keychainBackups.length > 0) {

        allBackups = allBackups.concat(keychainBackups);
      }
    } else {


      let deviceCounter = 0;

      //loop through the fulls, don't add duplicate devices, and add incremental backups
      for (let i = 0; i < fullBackups.length; i++) {

        let fullBackup = fullBackups[i];

        //did we already add this device?
        if (allBackups.filter(x => x.device == fullBackup.device).length > 0) {

          if (pullExtra) {
            deviceCounter++;
            if (deviceCounter > 2) {
              continue;
            }
          } else {
            continue;
          }

        }

        let start = fullBackup.created;

        //get all the incremental backups for this device
        let keychainBackups = await KeychainBackup.find({ user: req.user._id, created: { $gte: start }, device: fullBackup.device }).sort({ lastUpdate: -1 });

        keychainBackups = keychainBackups.concat(fullBackup);

        if (keychainBackups.length > 0) {

          allBackups = allBackups.concat(keychainBackups);
        }
      }
    }

    //res.status(200).json({ keychainBackups: allBackups });

    let payload = { keychainBackups: allBackups };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});

//get keychains
// router.get('/:userid', passport.authenticate('jwt', { session: false }), async (req, res) => {

//   try {

//     let keychainBackups = await KeychainBackup.find({ user: req.user._id }).sort({ lastUpdate: -1 });

//     let payload = { keychainBackups: keychainBackups };
//     payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

//     res.status(200).json({ keychainBackups: keychainBackups });

//   } catch (err) {

//     var msg = await logUtil.logError(err, true);
//     return res.status(500).json({ err: msg });

//   }

// });

//toggle keychain backup
router.post('/toggle/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //let user = await User.findById(req.user._id);
    let user = req.user;

    user.autoKeychainBackup = body.autoKeychainBackup;
    await user.save();

    let payload = {};

    if (user.autoKeychainBackup == false) {

      let keychains = await KeychainBackup.find({ user: req.user._id });

      for (let i = 0; i < keychains.length; i++) {
        let keychain = keychains[i];

        if (keychain.location == constants.BLOB_LOCATION.S3) {

          s3Util.deleteBlob(constants.BUCKET_TYPE.KEYCHAIN_BACKUP, keychain.keychain);

        } else {
          gridFS.deleteBlob('keychainBlob', keychain.keychain);

        }

      }

      await KeychainBackup.deleteMany({ user: user._id });
      payload = { success: true };
    } else {

      await ActionRequired.deleteOne({ user: user._id, alertType: constants.ACTION_REQUIRED.EXPORT_KEYS });
      var actionRequired = await ActionRequired.find({ user: req.user.id }).populate('user').populate('resetUser').populate('member').populate({ path: 'networkRequest', populate: [{ path: 'hostedFurnace' }, { path: 'user' }] }).exec();

      payload = { success: true, actionrequired: actionRequired };
    }


    //let payload = { user, circle };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});


module.exports = router;