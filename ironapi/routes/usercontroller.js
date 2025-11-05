const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
var secret = process.env.secret;
const passport = require('passport');
const User = require('../models/user');
const Device = require('../models/device');
const Metric = require('../models/metric');
const HostedFurnace = require('../models/hostedfurnace');
const DeviceBlock = require('../models/deviceblock');
const RatchetPublicKey = require('../models/ratchetpublickey');
const Circle = require('../models/circle');
const UserCircle = require('../models/usercircle');
const UserConnection = require('../models/userconnection');
const NetworkRequest = require('../models/networkrequest');
const UserHelper = require('../models/userhelper');
const MagicNetworkLink = require('../models/magicnetworklink');
const IronCoinWallet = require('../models/ironcoinwallet');
const metricLogic = require('../logic/metriclogic');
const keychainBackupLogic = require('../logic/keychainbackuplogic');
const UserKeyBackup = require('../models/userkeybackup');
const UserRecoveryIndex = require('../models/userrecoveryindex');
const RatchetIndex = require('../models/ratchetindex');
const ActionRequired = require('../models/actionrequired');
const deviceLogic = require('../logic/devicelogic');
const userCircleLogic = require('../logic/usercirclelogic');
const invitationLogic = require('../logic/invitationlogic');
const circleObjectLogic = require('../logic/circleobjectlogic');
const systemMessageLogic = require('../logic/systemmessagelogic');
const OfficialNotification = require('../models/officialnotification');
const NotificationUser = require('../models/notificationuser');
const constants = require('../util/constants');
var crypto = require("crypto");
const logUtil = require('../util/logutil');
const Release = require('../models/release');
const ObjectID = require('mongodb').ObjectId;
const Subscription = require('../models/subscription');
const s3Util = require('../util/s3util');
const DeviceNetworkAttempts = require('../models/devicenetworkattempts');
const HostedFurnaceController = require('../routes/hostedfurnacecontroller');
const IronCurrency = require('../models/ironcurrency');
const kyberLogic = require('../logic/kyberlogic');
const LAPSEDSECOND = 20;
const SLOWLOGINAFTER = 3;
const HOURS_48 = 60 * 60 * 1000 * 48;

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

require('../config/passport')(passport);
var jwt = require('jsonwebtoken');
const { findById } = require('../models/circleobject');
const userkeybackup = require('../models/userkeybackup');
const avatar = require('../models/avatar');
//const { TemporaryCredentials } = require('aws-sdk');


router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

let userFieldsToPopulate = '_id username lowercase avatar accountType';

router.post('/logout', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //set open to closed
    userCircleLogic.closeOpenHiddenPerDevice(req.user.id, body.uuid);

    //logout user
    await setLoggedIn(false, req.user.id, body.uuid);

    //return res.status(200).json({ msg: 'success' });

    let payload = { msg: 'success' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ err: msg });

  }
});
async function updatePublicKey(userID, ratchetPublicKey) {

  try {

    let user = await User.findById(userID);

    var save = false;

    if (!user.ratchetPublicKey)
      save = true;
    else if (user.ratchetPublicKey.public != ratchetPublicKey.public)
      save = true;

    if (save) {

      if (ratchetPublicKey.device == null) ratchetPublicKey.device = '';

      user.ratchetPublicKey = RatchetPublicKey.new(ratchetPublicKey);
      await user.save();
    }

  } catch (err) {

    await logUtil.logError(err, true);

  }


}

//
router.post('/setremotepublic/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {


    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    if (body.ratchetPublicKey != null && body.ratchetPublicKey != undefined)
      updatePublicKey(req.user.id, body.ratchetPublicKey);


    //res.status(200).json({ msg: "success" });
    let payload = { msg: "success" };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {

    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ err: msg });

  }

});



async function tempUpgrade(user) {

  try {

    let found = false;
    let map = null;

    ///see if the user has a device on build 153
    for (let i = 0; i < user.devices.length; i++) {
      if (user.devices[i].build > 152) {
        found = true;
      }
    }


    if (found == false) {

      let userCircles = await returnUserCirclesWithExpiredKeys(user._id);
      let ironCoinWallet = await IronCoinWallet.findOne({ user: user._id });

      ///check for notification
      let notificationUser;
      let sendingNotification;
      let latestNotification = await OfficialNotification.findOne({ enabled: true }).sort({ 'created': -1 });
      if (latestNotification instanceof OfficialNotification) {
        notificationUser = await NotificationUser.findOne({ user: user._id, officialNotification: latestNotification._id });
        if (notificationUser instanceof NotificationUser) {
          ///user has already dismissed notification
          sendingNotification = null;
        } else {
          sendingNotification = latestNotification;
        }
      } else {
        sendingNotification = null;
      }


      map = { user: user, ironCoinWallet: ironCoinWallet, latestBuild: 153, minimumBuild: 153, needUserKeyBackup: false, officialNotification: sendingNotification, userCircles: userCircles };
    }

    return map;

  } catch (err) {
    await logUtil.logError(err, true);
  }
}


async function newDeviceAndKyber(user, body, ip) {

  try {

    logUtil.logAlert(user.id + ' is updating their deviceID from ' + body.oldID + ' to ' + body.uuid, ip, user.id);

    ///update the device
    let deviceUpdated = await deviceLogic.updateDevice(user, body.pushtoken, body.platform, body.uuid, body.build, body.model, body.identity, body.oldID);


    //delete kyber keys for this device
    await kyberLogic.deleteDeviceKyber(body.uuid, body.oldID);

    ///calculate the new kyber thingy based on a new public key 
    let pk = await kyberLogic.postPublicKey(body.uuid);

    return [deviceUpdated, pk];

  } catch (err) {
    logUtil.logError(err, true);


  }

  return [deviceUpdated, null];

}
//Test if client stored token is still active, validate token, validateToken
router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    console.log('Autologin start: ' + req.user.id + '   ' + getIP(req) + '  uuid:' + req.body.uuid);

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let deviceUpdated = false;
    var pk;

    if (body.updateKyber != null && body.updateKyber != undefined) {
      let results = await newDeviceAndKyber(req.user, body, getIP(req));

      deviceUpdated = results[0];
      pk = results[1];

    } else {
      //did the user get a new push token?
      deviceUpdated = await deviceLogic.registerDevice(req.user.id, body.pushtoken, body.platform, body.uuid, body.build, body.model);
    }

    //set open to closed
    userCircleLogic.closeOpenHiddenPerDevice(req.user.id, body.uuid);

    var user;

    if (body.uuid != undefined) {
      //login user
      user = await setLoggedIn(true, req.user.id, body.uuid, body.build, body.identity);


    } else
      user = req.user;


    let userCircles = [];
    if (deviceUpdated == true) {
      userCircles = await returnUserCircles(user._id);
    } else {
      userCircles = await returnUserCirclesWithExpiredKeys(user._id);
    }

    //get the latest build number 
    var releases = await getBuild();

    ///check for notification
    let notificationUser;
    let sendingNotification;
    let latestNotification = await OfficialNotification.findOne({ enabled: true }).sort({ 'created': -1 });
    if (latestNotification instanceof OfficialNotification) {
      notificationUser = await NotificationUser.findOne({ user: user._id, officialNotification: latestNotification._id });
      if (notificationUser instanceof NotificationUser) {
        ///user has already dismissed notification
        sendingNotification = null;
      } else {
        sendingNotification = latestNotification;
      }
    } else {
      sendingNotification = null;
    }

    let ironCoinWallet = await IronCoinWallet.findOne({ user: user._id }); //.populate({ path: 'transactions', options: { limit: 10, sort: { created: -1 } } });
    // res.status(200).json({ user: user, ironCoinWallet: ironCoinWallet, latestBuild: releases[0].build, minimumBuild: releases[0].minimumBuild, needUserKeyBackup: false, officialNotification: sendingNotification, userCircles: userCircles });

    let payload = { user: user, ironCoinWallet: ironCoinWallet, latestBuild: releases[0].build, minimumBuild: releases[0].minimumBuild, needUserKeyBackup: false, officialNotification: sendingNotification, userCircles: userCircles, pk: pk };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {

    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ err: msg });

  }

});

router.put('/changepasswordfromtoken', passport.authenticate('jwt', { session: false }), async (req, res) => {

  var user;

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);


    if (!body.build)
      throw ('please upgrade before changing password');

    /*if (req.user.username != body.username)
      throw ('username mismatch');*/

    if (body.passwordHash) {
      await validateParamsHash(body.username, body.passwordHash, body.passwordNonce, body.apikey, body.tos);
    } else {
      //deprecated
      await validateParams(body.username, body.password, body.pin, body.apikey); //error thrown if in
    }

    user = await loadUserPlusPasswordByID(req.user.id);

    if (!(user instanceof User)) throw ("password change error, could not find user");

    if (user.passwordBeforeChange == true)
      throw ("must provide password/pin combo to change");

    if (!body.passwordHash) {
      let success = validatePasswordComplexity(user, body.password, '', body.pin);

      if (success != true) {
        user = null;  //don't increment attempts
        throw (success);

      }
    } else {
      //set the hash and nonce
      user.passwordHash = body.passwordHash;
      user.passwordNonce = body.passwordNonce;
    }

    if (user.lockedOut == true) {
      return res.status(200).json({ msg: "your account on this network has been locked" });
    } else if (user.loginAttemptsExceeded == true) {
      return res.status(200).json({ msg: "login attempts exceeded", loginAttemptsExceeded: true });
    } else if (user.loginAttempts > SLOWLOGINAFTER) {
      var tooSoonMsg = tooSoonMessage(user);
      if (tooSoonMsg)
        return res.status(200).json({ msg: tooSoonMsg, loginAttemptsExceeded: true });
    }

    if (body.newUsername != undefined && body.newUsername != null && user.username != body.newUsername) {
      var hostedID = user.hostedFurnace;
      var oldLowercase = user.lowercase;

      var lowercase = body.newUsername.toLowerCase();

      ///don't check if the username is the same as the old one except for case
      if (oldLowercase != lowercase) {

        lowercase = await checkUsername(body.newUsername, hostedID, body.authUserID);
      }
      user.username = body.newUsername;
      user.lowercase = lowercase;

      let linkedUsers = await User.find({ linkedUser: user._id, lowercase: oldLowercase });

      for (let i = 0; i < linkedUsers.length; i++) {
        let linkedUser = linkedUsers[i];
        linkedUser.username = user.username;
        linkedUser = await getUniqueUsernameForNetwork(linkedUser, linkedUser.hostedFurnace, user._id);
        await linkedUser.save();

      }


    }

    await ActionRequired.deleteMany({ user: user._id, alertType: constants.ACTION_REQUIRED.CHANGE_GENERATED });

    user.passwordExpired = false;
    user.passwordChangedOn = Date.now();
    user.tokenExpired = false;
    user.loginAttempts = 0;
    user.loginAttemptsExceeded = false;
    user.password = body.password
    user.pin = body.pin;

    let userKeyBackup = await UserKeyBackup.findOne({ user: user._id });

    if (userKeyBackup) {
      userKeyBackup.backupIndex.ratchetIndex = body.backupIndex.ratchetIndex;
      userKeyBackup.backupIndex.crank = body.backupIndex.crank;
      userKeyBackup.backupIndex.signature = body.backupIndex.signature;
      userKeyBackup.backupIndex.device = body.backupIndex.device;
      userKeyBackup.backupIndex.kdfNonce = body.backupIndex.kdfNonce;
      userKeyBackup.backupIndex.ratchetValue = body.backupIndex.ratchetValue;

      if (body.userIndex) {
        ///rare scenario where user doesn't have a backup key. Dubbed the Homer Problem
        userKeyBackup.userIndex.ratchetIndex = body.userIndex.ratchetIndex;
        userKeyBackup.userIndex.crank = body.userIndex.crank;
        userKeyBackup.userIndex.signature = body.userIndex.signature;
        userKeyBackup.userIndex.device = body.userIndex.device;
        userKeyBackup.backupIndex.kdfNonce = body.backupIndex.kdfNonce;
        userKeyBackup.userIndex.ratchetValue = body.userIndex.ratchetValue;
      }

      await userKeyBackup.save();

    } else {
      throw ('could not find user key backup');
    }



    user = await removeResetCode(user, false);

    await user.save();

    //return res.status(200).json({ user: user });

    let payload = { user: user };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, true, getIP(req));
    ///token was already validated, so don't increment attempts
    //if (user != null) await incrementLoginAttempts(user);
    return res.status(500).json({ err: msg });

  }

});

router.put('/changepassword', async (req, res) => {

  var user;

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    if (!body.build)
      throw ('please upgrade before changing password');


    if (body.password) {
      //deprecated
      await validateParams(body.username, body.password, body.pin, body.apikey);  //error thrown if invalid

      if (!body.existing || !body.existingPin) {
        await logUtil.logAlert('no existing or exisitingPin in changepassword');
        throw ('unauthorized');
      }

    } else {

      await validateParamsHash(body.username, body.passwordHash, body.passwordNonce, body.apikey);

      if (!body.existing) {
        await logUtil.logAlert('no existing in changepassword');
        throw ('unauthorized');
      }
    }

    var user;

    if (body.hostedName && body.key) {
      let hostedFurnace = await validateHostedNetwork(body.hostedName, body.key);
      user = await loadUserPlusPassword(body.username, hostedFurnace._id);
    }
    else
      user = await loadUserPlusPassword(body.username);

    if (!(user instanceof User)) throw ("Invalid username or password");

    //no token passed to this function so validate the exising password before continuing
    if (body.password) {
      await user.comparePassword(body.existing); //only vague error messages before username/password checked
      await user.comparePin(body.existingPin);

      var success = validatePasswordComplexity(user, body.password, body.existing, body.pin);

      if (success != true) {
        user = null;  //don't increment attempts
        throw (success);

      }

      user.password = body.password
      user.pin = body.pin;

    } else {
      await user.comparePasswordHash(body.existing);

      user.passwordHash = body.passwordHash;
      user.passwordNonce = body.passwordNonce;
    }

    if (user.lockedOut == true) {
      return res.status(200).json({ msg: "your account on this network has been locked" });
    } else if (user.loginAttemptsExceeded == true) {
      return res.status(200).json({ msg: "login attempts exceeded", loginAttemptsExceeded: true });
    } else if (user.loginAttempts > SLOWLOGINAFTER) {
      var tooSoonMsg = tooSoonMessage(user);
      if (tooSoonMsg)
        return res.status(200).json({ msg: tooSoonMsg, loginAttemptsExceeded: true });
    }

    user.passwordExpired = false;
    user.passwordChangedOn = Date.now();
    user.tokenExpired = false;
    user.loginAttempts = 0;
    user.loginAttemptsExceeded = false;


    let userKeyBackup = await UserKeyBackup.findOne({ user: user._id });

    if (userKeyBackup) {
      userKeyBackup.backupIndex.ratchetIndex = body.backupIndex.ratchetIndex;
      userKeyBackup.backupIndex.crank = body.backupIndex.crank;
      userKeyBackup.backupIndex.signature = body.backupIndex.signature;
      userKeyBackup.backupIndex.device = body.backupIndex.device;
      userKeyBackup.backupIndex.ratchetValue = body.backupIndex.ratchetValue;
      userKeyBackup.backupIndex.kdfNonce = body.backupIndex.kdfNonce;

      await userKeyBackup.save();

    } else
      throw ('could not find userkeys');

    user = await removeResetCode(user, false);

    await user.save();

    //return res.status(200).json({ user: user });
    let payload = { user: user };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, true, getIP(req));
    if (user != null) await incrementLoginAttempts(user);
    return res.status(500).json({ err: msg });

  }

});



async function incrementLoginAttempts(user) {

  try {
    if (user instanceof User) {

      user.loginAttempts = user.loginAttempts + 1;
      user.loginAttemptsLastFailed = Date.now();

      if (user.loginAttempts > user.securityLoginAttempts)
        user.loginAttemptsExceeded = true;
      await user.save();

      let msg = 'invalid login attempt # ' + user.loginAttempts;
      console.error('user: ' + user.username + ' invalid login attempt # ' + user.loginAttempts);

      return msg;
    }
  } catch (err) {
    logUtil.logError(err, true);
  }

}


function setLoggedInUser(loggedIn, user, deviceID, build, identity) {

  try {

    for (let i = 0; i < user.devices.length; i++) {
      if (user.devices[i].uuid == deviceID) {



        user.devices[i].loggedIn = loggedIn;
        if (build)
          user.devices[i].build = build;
        user.devices[i].lastAccessed = Date.now();

        if (user.devices[i].identity == null && identity) {
          /// only set it if there is not one already
          user.devices[i].identity = identity;
        }
      }

    }

    return user;

  } catch (err) {
    logUtil.logError(err, true);
  }

}

async function setLoggedIn(loggedIn, userID, deviceID, build, identity) {

  try {

    let user = await User.findById(userID);

    user = setLoggedInUser(loggedIn, user, deviceID, build, identity);

    metricLogic.setLastAccessed(user);

    await user.save();

    ///update build for linked users and set logged in
    let linkedUsers = await User.find({ linkedUser: user._id });
    for (let i = 0; i < linkedUsers.length; i++) {
      let linkedUser = linkedUsers[i];
      linkedUser = setLoggedInUser(loggedIn, linkedUser, deviceID, build, identity);
      await linkedUser.save();
    }

    return user;

  } catch (err) {
    logUtil.logError(err, true);
  }

}

async function incrementResetCodeAttempts(user) {

  try {
    if (user instanceof User) {

      if (user.resetCodeAttempts == undefined)
        user.resetCodeAttempts = 1;
      else {
        user.resetCodeAttempts = user.resetCodeAttempts + 1;
        user.resetCodeAttemptsLastFailed = Date.now();
      }

      if (user.resetCodeAttempts > user.securityLoginAttempts)
        user.resetCodeAttemptsExceeded = true;

      await user.save();

      let msg = 'invalid reset code attempt # ' + user.resetCodeAttempts;
      console.error('user: ' + user.username + ' ' + msg);

      return msg;

    }
  } catch (err) {
    logUtil.logError(err, true);
    return;
  }

}

async function loadUserPlusPasswordByID(userID) {
  try {

    let user = await User.findById(userID).select('_id ratchetPublicKey username lowercase accountRecovery linkedUser devices minor allowClosed role accountType avatar keyGen autoKeychainBackup lockedOut lastUpdate created securityDaysPasswordValid securityMinPassword loginAttempts loginAttemptsExceeded loginAttemptsLastFailed securityLoginAttempts securityTokenExpirationDays tokenExpired passwordChangedOn passwordExpired autoKeyBackup lastKeyBackup passwordHelpers hostedFurnace joinBeta +password +pin +resetCode +passwordHash +passwordNonce');

    return user;

  } catch (err) {
    var msg = await logUtil.logError(err, true);
  }
}


async function loadUserPlusPassword(username, hostedFurnaceID) {
  try {

    var query = User.findOne({});

    if (hostedFurnaceID != undefined && hostedFurnaceID != null)
      //query = UserCircle.findOne({ lowercase: username.toLowerCase(), hostedFurnace: hostedFurnaceID });
      query.where({ lowercase: username.toLowerCase(), hostedFurnace: hostedFurnaceID });
    else
      query.where({ lowercase: username.toLowerCase(), hostedFurnace: null });

    return await query.select('_id ratchetPublicKey username lowercase accountRecovery linkedUser devices minor allowClosed role accountType avatar keyGen autoKeychainBackup lockedOut lastUpdate created securityDaysPasswordValid securityMinPassword loginAttempts loginAttemptsExceeded loginAttemptsLastFailed securityLoginAttempts securityTokenExpirationDays tokenExpired passwordChangedOn passwordExpired autoKeyBackup lastKeyBackup passwordHelpers hostedFurnace joinBeta +password +pin +resetCode +passwordHash +passwordNonce').populate("passwordHelpers");


  } catch (err) {
    var msg = await logUtil.logError(err, true);
  }
}

async function loadUserPlusResetCode(username, hostedFurnaceID) {
  try {

    var query;

    if (hostedFurnaceID != undefined && hostedFurnaceID != null)
      query = User.findOne({ lowercase: username.toLowerCase(), hostedFurnace: hostedFurnaceID });
    else
      query = User.findOne({ lowercase: username.toLowerCase(), hostedFurnace: null });

    return await query.select('_id ratchetPublicKey username accountRecovery linkedUser lowercase devices minor joinBeta allowClosed role accountType avatar keyGen autoKeychainBackup lockedOut lastUpdate created  securityDaysPasswordValid resetCodeCreatedOn resetCodeAttempts resetCodeAttemptsLastFailed resetCodeAttemptsExceeded securityMinPassword loginAttempts loginAttemptsExceeded loginAttemptsLastFailed securityLoginAttempts securityTokenExpirationDays tokenExpired passwordChangedOn passwordExpired autoKeyBackup lastKeyBackup passwordHelpers hostedFurnace +resetCode').exec();


  } catch (err) {
    var msg = await logUtil.logError(err, true);
  }
}

function tooSoonMessage(user) {
  var lapsedTime = Math.round((Date.now() - user.loginAttemptsLastFailed) / 1000);

  if (lapsedTime < LAPSEDSECOND) {

    var msg = "need to wait " + (LAPSEDSECOND - lapsedTime) + " seconds before trying again";
    console.log(user.username + ': ' + msg);
    return msg;
  } else return null;
}

function tooSoonMessageFurnace(lastAttempt) {
  var lapsedTime = Math.round((Date.now() - lastAttempt) / 1000);

  if (lapsedTime < LAPSEDSECOND) {
    var msg = LAPSEDSECOND - lapsedTime + " ";
    return msg;
  } else return null;
}

function tooSoonResetCode(user) {
  var lapsedTime = Math.round((Date.now() - user.resetCodeAttemptsLastFailed) / 1000);

  if (lapsedTime < LAPSEDSECOND) {

    var msg = "need to wait " + (LAPSEDSECOND - lapsedTime) + " seconds before trying again";
    console.log(user.username + ': ' + msg);
    return msg;
  } else return null;
}


function daysToMilliseconds(days) {
  return days * 24 * 60 * 60 * 1000;
}

function validatePasswordComplexity(user, password, existing, pin) {

  try {

    if (!user)
      return ('invalid credentials');
    if (!password)
      return ('invalid credentials');

    if (password.length < user.securityMinPassword)
      return "password needs to be " + user.securityMinPassword + " characters in length";

    //if (existing != '') if (existing == password) return "new password must be different than old password";

    if (!pin)
      return ('invalid credentials');
    if (pin.length < 4)
      return "invalid credentials";

    return true;
  } catch (err) {
    console.err(err);
    throw new Error("invalid credentials");

  }

}

router.post('/recoverycode', async (req, res) => {

  try {
    var user;

    if (req.body.hostedName && req.body.hostedName.toLowerCase() != 'ironforge') {
      network = await validateHostedNetworkNameOnly(req.body.hostedName);

      user = await User.find({ lowercase: req.body.username.toLowerCase(), hostedFurnace: network._id });
    } else
      user = await loadUserPlusPassword(req.body.username);

    if (!(user instanceof User)) throw ("Invalid username or password");

    let recoveryIndex = await UserRecoveryIndex.find({ user: user._id, });

    return res.status(200).json({ recoveryIndex: recoveryIndex });

  } catch (err) {

    var msg = await logUtil.logError(err, false, getIP(req));
    let attempts = await incrementLoginAttempts(user);
    if (attempts) msg = attempts;
    return res.status(500).json({ err: msg });

  }

});


//Return a user's password nonce
router.post('/nonce/', async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    if (body.username == null || body.username == undefined) {
      throw ("Invalid network name or credentials");
    }

    var user;

    let network = HostedFurnace({ _id: 'IronForge', name: 'IronForge' });

    //console.log(body.hostedName);

    if (body.hostedName && body.hostedName.toLowerCase() != 'ironforge') {
      //console.log('not the forge');
      network = await validateHostedNetworkNameOnly(body.hostedName);

      user = await loadUserPlusPassword(body.username, network._id);
    } else {
      //it's the forge
      //console.log('forge');
      user = await loadUserPlusPassword(body.username);
    }

    if (!(user instanceof User)) throw ("Invalid network name or credentials");

    let passwordNonce = '';

    if (user.passwordNonce != null) passwordNonce = user.passwordNonce;

    //res.status(200).json({ passwordNonce: passwordNonce });

    let payload = { passwordNonce: passwordNonce };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, true, getIP(req));
    let attempts = await incrementLoginAttempts(user);
    if (attempts) msg = attempts;
    return res.status(500).json({ err: msg });

  }

});


router.post('/signinweb', async (req, res) => {
  try {

    var user;

    //console.log(req.body);

    if (req.body.hostedName && req.body.hostedName.toLowerCase() != 'ironforge') {
      //console.log('not the forge');
      network = await validateHostedNetworkNameOnly(req.body.hostedName);

      user = await loadUserPlusPassword(req.body.username, network._id);
    } else {
      //console.log('forge');
      user = await loadUserPlusPassword(req.body.username);
    }

    //console.log("loaded user");

    if (!(user instanceof User)) throw ("Invalid username or password");

    if (user.linkedUser != null) {

      logUtil.logAlert('user tried to login with linked account' + req.body.username, getIP(req));
      return res.status(200).json({ msg: "This is a linked account, please login with your primary account" });
    }
    if (user.lockedOut == true) {
      logUtil.logAlert('user account has been locked out: ' + req.body.username, getIP(req));
      return res.status(200).json({ msg: "your account on this network has been locked" });
    } else if (user.passwordExpired == true) {
      logUtil.logAlert('user password expired: ' + req.body.username, getIP(req));
      return res.status(200).json({ msg: "your password has expired", changePassword: true });
    } else if (user.loginAttemptsExceeded == true) {
      logUtil.logAlert('user login attempts exceeded: ' + req.body.username, getIP(req));
      return res.status(200).json({ msg: "login attempts exceeded", loginAttemptsExceeded: true });
    } else if (user.loginAttempts > SLOWLOGINAFTER) {
      var tooSoonMsg = tooSoonMessage(user);
      if (tooSoonMsg)
        return res.status(200).json({ msg: tooSoonMsg, loginAttemptsExceeded: true });
    }

    if (user.passwordHash != null) {
      try {
        console.log('hash is not null');
        await validateParamsHash(req.body.username, req.body.passwordHash, 'NA', req.body.apikey, req.body.recoveryKey);
        await user.comparePasswordHash(req.body.passwordHash);
      } catch (err) {

        throw new Error(
          "Invalid username or password"
        );
      }
    } else {
      try {

        console.log('hash is null');

        //deprecated - test the password and pin
        await user.comparePassword(req.body.password);
        console.log('password worked');
        await user.comparePin(req.body.pin);
        console.log('pin worked');
      } catch (err) {

        throw new Error(
          "Invalid username or password"
        );
      }
    }

    //blank out the password
    user.pin = "";
    user.password = "";

    //blank out uneeded fields for token
    let tokenUser = JSON.parse(JSON.stringify(user));
    delete tokenUser.devices;
    delete tokenUser.ratchetPublicKey;
    delete tokenUser.avatar;
    delete tokenUser.passwordHelpers;
    delete tokenUser.blockedList;
    delete tokenUser.allowedList;

    //add the device for the token (not a normal user field)
    tokenUser.device = req.body.uuid;

    //create the token
    const token = jwt.sign(tokenUser, secret, { expiresIn: daysToMilliseconds(user.securityTokenExpirationDays) }, user); //30 days (24 hours = 345600)

    return res.status(200).json({ token: 'JWT ' + token, });



  } catch (err) {
    var msg = await logUtil.logError(err, false, getIP(req));
    let attempts = await incrementLoginAttempts(user);
    if (attempts) msg = attempts;
    return res.status(500).json({ err: msg });

  }
});


router.post('/signin', async (req, res) => {

  var user;

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    if (!body.build) throw ("Upgrade required before logging in");

    console.log('login start: ' + body.username + '   ' + getIP(req) + '  ' + body.uuid);

    let pin = body.pin;

    let network = HostedFurnace({ _id: 'IronForge', name: 'IronForge' });

    if (body.build < 36) pin = 'NA';

    if (body.passwordHash) {
      await validateParamsHash(body.username, body.passwordHash, 'NA', body.apikey, body.recoveryKey);
    } else {

      await validateParams(body.username, body.password, pin, body.apikey, body.recoveryKey);  //error thrown if in
    }

    if (body.hostedName && body.hostedName.toLowerCase() != 'ironforge') {
      network = await validateHostedNetworkNameOnly(body.hostedName);

      user = await loadUserPlusPassword(body.username, network._id);
    } else
      user = await loadUserPlusPassword(body.username);

    if (!(user instanceof User)) throw ("Invalid username or password");

    //set open to closed
    userCircleLogic.closeOpenHiddenPerDevice(user._id, body.uuid);

    //set deviceID to loggedin
    user = setLoggedInUser(true, user, body.uuid, body.build, body.identity);

    var needRemotePublicKey = false;
    if (user.ratchetPublicKey == undefined || user.ratchetPublicKey == null) {
      needRemotePublicKey = true;
    }

    //asnyc ok 
    await checkActionRequired(user);

    if (user.linkedUser != null) {

      logUtil.logAlert('user tried to login with linked account' + body.username, getIP(req));
      return res.status(200).json({ msg: "This is a linked account, please login with your primary account" });
    }
    if (user.lockedOut == true) {
      logUtil.logAlert('user account has been locked out: ' + body.username, getIP(req));
      return res.status(200).json({ msg: "your account on this network has been locked" });
    } else if (user.passwordExpired == true) {
      logUtil.logAlert('user password expired: ' + body.username, getIP(req));
      return res.status(200).json({ msg: "your password has expired", changePassword: true });
    } else if (user.loginAttemptsExceeded == true) {
      logUtil.logAlert('user login attempts exceeded: ' + body.username, getIP(req));
      return res.status(200).json({ msg: "login attempts exceeded", loginAttemptsExceeded: true });
    } else if (user.loginAttempts > SLOWLOGINAFTER) {
      var tooSoonMsg = tooSoonMessage(user);
      if (tooSoonMsg)
        return res.status(200).json({ msg: tooSoonMsg, loginAttemptsExceeded: true });
    }

    if (body.passwordHash && body.passwordHash != '') {
      await user.comparePasswordHash(body.passwordHash);
    } else {

      //deprecated - test the password and pin
      await user.comparePassword(body.password);
      console.log('password worked');
      await user.comparePin(body.pin);
      console.log('pin worked');

      //test to see if password requirements have changed since last login
      if (body.password.length < user.securityMinPassword) {
        user.passwordExpired = true;
        await user.save();  //return message is below
      }
    }

    let deviceUpdated = false;
    //console.log('token: ' + body.pushtoken);
    deviceUpdated = deviceLogic.registerDevice(user.id, body.pushtoken, body.platform, body.uuid, body.build, body.model, body.identity);

    ///load subscription history
    let subscriptions = await Subscription.find({ user: user._id });
    user.tokenExpired = false;
    user.loginAttempts = 0;
    user.loginAttemptsExceeded = false;
    user.currentDeviceToken = body.pushtoken;

    user = await removeResetCode(user, false);

    await user.save();

    //console.log(user._id);

    //blank out the password
    user.pin = "";
    user.password = "";

    //blank out uneeded fields for token
    let tokenUser = JSON.parse(JSON.stringify(user));
    delete tokenUser.devices;
    delete tokenUser.ratchetPublicKey;
    delete tokenUser.avatar;
    delete tokenUser.passwordHelpers;
    delete tokenUser.blockedList;
    delete tokenUser.allowedList;

    //add the device for the token (not a normal user field)
    tokenUser.device = body.uuid;

    //create the token
    const token = jwt.sign(tokenUser, secret, { expiresIn: daysToMilliseconds(user.securityTokenExpirationDays) }); //30 days (24 hours = 345600)

    await addWallIfEnabled(user, network);

    let userCircles = await returnUserCircles(user._id);
    //var releases = await Release.find({}).sort({ 'build': -1 }).limit(1);
    var releases = await getBuild();

    let userKeyBackup = await UserKeyBackup.findOne({ user: user._id });

    let userIndex = null;
    let backupIndex = null;
    let ratchetPublicKey = user.ratchetPublicKey;

    if (userKeyBackup) {
      userIndex = userKeyBackup.userIndex;
      backupIndex = userKeyBackup.backupIndex;
    }

    //see if there any linked accounts to include
    let linkedUsers = await User.find({ linkedUser: user._id, removeFromCache: null, lockedOut: false, tokenExpired: false }).populate('hostedFurnace');
    let linkedUsersJson = [];

    for (let i = 0; i < linkedUsers.length; i++) {

      let token = createToken(linkedUsers[i], body.uuid);
      let userCircles = await returnUserCircles(linkedUsers[i]._id);

      let linkedUser = JSON.parse(JSON.stringify(linkedUsers[i]));

      linkedUser.token = 'JWT ' + token;
      linkedUser.userCircles = userCircles;

      let userKeyBackup = await UserKeyBackup.findOne({ user: linkedUsers[i]._id });
      linkedUser.userIndex = userKeyBackup.userIndex;
      linkedUser.backupIndex = userKeyBackup.backupIndex;
      linkedUser.ratchetPublicKey = linkedUsers[i].ratchetPublicKey;

      linkedUsersJson.push(linkedUser);
    }

    await network.populate('hostedFurnaceImage');

    ///check for notification
    let notificationUser;
    let sendingNotification;
    let latestNotification = await OfficialNotification.findOne({ enabled: true }).sort({ 'created': -1 });
    if (latestNotification instanceof OfficialNotification) {
      notificationUser = await NotificationUser.findOne({ user: user._id, officialNotification: latestNotification._id });
      if (notificationUser instanceof NotificationUser) {
        ///user has already dismissed notification
        sendingNotification = null;
      } else {
        sendingNotification = latestNotification;
      }
    } else {
      sendingNotification = null;
    }

    let payload = { token: 'JWT ' + token, user: user, userIndex: userIndex, backupIndex: backupIndex, ratchetPublicKey: ratchetPublicKey, userCircles: userCircles, latestBuild: releases[0].build, minimumBuild: releases[0].minimumBuild, needRemotePublicKey: needRemotePublicKey, subscriptions: subscriptions, linkedUsers: linkedUsersJson, network: network, officialNotification: sendingNotification, deviceUpdated: deviceUpdated };

    // return the information including token as JSON
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, false, getIP(req));
    let attempts = await incrementLoginAttempts(user);
    if (attempts) msg = attempts;
    return res.status(500).json({ err: msg });

  }

});

function createToken(user, deviceID) {
  try {
    //blank out the password
    user.pin = "";
    user.password = "";

    //blank out uneeded fields for token
    let tokenUser = JSON.parse(JSON.stringify(user));
    delete tokenUser.devices;
    delete tokenUser.ratchetPublicKey;
    delete tokenUser.avatar;
    delete tokenUser.passwordHelpers;
    delete tokenUser.blockedList;
    delete tokenUser.allowedList;

    //add the device for the token (not a normal user field)
    tokenUser.device = deviceID;

    //create the token
    const token = jwt.sign(tokenUser, secret, { expiresIn: daysToMilliseconds(user.securityTokenExpirationDays) }); //30 days (24 hours = 345600)

    return token;

  } catch (err) {
    logUtil.logError(err, false);
    throw ('could not create token');

  }
}

//link an existing account with a token to another account
// router.post('/linkaccount', passport.authenticate('jwt', { session: false }), async (req, res) => {
//   ///this authenticates the linked user's token since they are relinquishing control

//   try {


//     let linkedUser = req.user;
//     let primaryUser = await User.findOne({ _id: req.body.primaryID });

//     if (!(primaryUser instanceof User)) {
//       throw new Error("unauthorized");
//     }

//     linkedUser.linkedUser = primaryUser._id;

//     await linkedUser.save();


//     return res.status(200).json({
//       msg: 'success'

//     });

//   } catch (err) {
//     var msg = await logUtil.logError(err, true, getIP(req));
//     return res.status(500).json({ err: msg });
//   }

// });


//handle api call to users/signup
router.post('/registerlinkedaccount', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let alreadyExists = false;

    if (!body.ratchetPublicKey) {
      await logUtil.logAlert('no ratchetPublicKey in registerlinkedaccount', getIP(req));
      throw ('unauthorized');
    }

    //let existingUser = await loadUserPlusPassword(req.user.username, body.hostedName);
    let existingUser = await User.findById(req.user.id);

    if (!(existingUser instanceof User))
      throw ('linked acccount not found');

    var hostedFurnace;

    let user = new User({
      username: existingUser.username,
      //password: existingUser.password,
      //pin: existingUser.pin,
      minor: existingUser.minor,
      allowClosed: existingUser.allowClosed,
      tos: existingUser.tos,
      accountRecovery: true,
      linkedUser: req.user.id,
      avatar: existingUser.avatar,
      keyGen: true,
    });


    if (body.newNetwork == true) {

      let hostedName = body.hostedName.trim();

      if (body.createNetworkName == true) {

        //backwards compatability check
        if (hostedName == undefined || hostedName == null || hostedName == '')
          hostedName = await getUniqueHostedName();
        else
          await validateNetworkNameAvailable(hostedName);

      }

      var enableWall = false;
      if (body.enableWall == true) {
        ///uncomment to support wall
        //enableWall = true;

      }
      hostedFurnace = new HostedFurnace({
        name: hostedName,
        lowercase: hostedName.toLowerCase(),
        key: body.key.trim(),
        enableWall: enableWall,
        description: body.description,
        link: body.link,
        type: body.type,
        adultOnly: body.adultOnly,
        discoverable: body.discoverable,
        memberAutonomy: body.memberAutonomy,
      });
      await hostedFurnace.save();

      //get a unique username
      //await isNewUsernameReserved(user.username, body.authUserID); 
      user = await getUniqueUsernameForNetwork(user, hostedFurnace, body.authUserID);

      user.role = constants.ROLE.OWNER;
      user.hostedFurnace = hostedFurnace;

    } else {

      if (body.type == constants.NETWORK_TYPE.HOSTED || body.type == constants.NETWORK_TYPE.SELF_HOSTED) {
        hostedFurnace = await validateHostedNetwork(body.hostedName, body.key, req.user._id);
        user.hostedFurnace = hostedFurnace;

        //is there already an account for this user?
        let existingUser = await User.findOne({ hostedFurnace: hostedFurnace._id, linkedUser: req.user.id });

        if (existingUser instanceof User) {
          user = existingUser;
          alreadyExists = true;
        } else {
          //user.lowercase = await checkUsername(user.username, hostedFurnace._id, body.authUserID);
          user = await getUniqueUsernameForNetwork(user, hostedFurnace, body.authUserID);
        }
      } else if (body.type == constants.NETWORK_TYPE.FORGE) {
        hostedFurnace = new HostedFurnace({ _id: 'IronForge', name: 'IronForge' });

        //is there already an account for this user?
        let existingUser = await User.findOne({ hostedFurnace: null, linkedUser: req.user.id });

        if (existingUser instanceof User) {
          user = existingUser;
          alreadyExists = true;
        } else {
          //user.lowercase = await checkUsername(user.username, null, body.authUserID);
          user = await getUniqueUsernameForNetwork(user, null, body.authUserID);
        }
      }

    }

    if (!alreadyExists) { ///This is a scenario when the user removes a linked network and then links it again later

      await User.init(); // `User.init()` returns a promise that is fulfilled when all indexes are done

      //is the user blocked from having hidden circles?
      let deviceBlocks = await DeviceBlock.find({});

      for (let i = 0; i < deviceBlocks.length; i++) {

        if (body.uuid == deviceBlocks[i].deviceID || body.pushtoken == deviceBlocks[i].pushToken) {

          user.allowClosed = false;
          break;
        }

      }

      await User.create(user);

      user.ratchetPublicKey = RatchetPublicKey.new(body.ratchetPublicKey);
      user.ratchetPublicKey.user = user.id;
      await user.save();

      deleteNetworkRequest(existingUser._id, hostedFurnace);

      if (body.inviterID != undefined && body.inviterID != null) {
        createActionRequiredForInviter(user, body.inviterID, hostedFurnace.name);
      } else if (body.newNetwork == false &&
        user.role != constants.ROLE.OWNER &&
        body.hosted == true) {
        ///find owner
        let owner = await User.findOne({ role: constants.ROLE.OWNER, hostedFurnace: hostedFurnace._id });
        createActionRequiredForInviter(user, owner._id, hostedFurnace.name);
      }

      let userKeyBackup = await UserKeyBackup.new(body); // ({ crank: body.ratchetIndex.crank, signature: body.ratchetIndex.signature, backup: body.ratchetIndex.ratchetValue });
      userKeyBackup.user = user.id;
      userKeyBackup.userIndex.user = user.id;
      userKeyBackup.backupIndex.user = user.id;
      await userKeyBackup.save();

      //await createPrivateVault(user);
      // await createFirstCircle(user);

      if (body.magicLink != undefined && body.magicLink != null) {
        await connectMembers(user, body.inviterID);
        await createDM(user, body.inviterID, RatchetPublicKey.new(body.ratchetPublicKey), body.magicLink, body.authServer);
      }
    } else {
      ///the user is adding a newtork that was once removed
      ///verify the user is not locked out of then network
      if (user.lockedOut == true) {
        throw ('your account on this network has been locked');
      }
    }

    metricLogic.setLastAccessed(user);

    const token = jwt.sign(user.toObject(), secret, { expiresIn: daysToMilliseconds(user.securityTokenExpirationDays) }); //30 days (24 hours = 345600)

    await addWallIfEnabled(user, hostedFurnace);

    let userCircles = await returnUserCircles(user._id);

    if (body.pushtoken != null && body.pushtoken != undefined)
      deviceLogic.registerDevice(user._id, body.pushtoken, body.platform, body.uuid, body.build, body.model);

    ///check for notification
    let notificationUser;
    let sendingNotification;
    let latestNotification = await OfficialNotification.findOne({ enabled: true }).sort({ 'created': -1 });
    if (latestNotification instanceof OfficialNotification) {
      notificationUser = await NotificationUser.findOne({ user: user._id, officialNotification: latestNotification._id });
      if (notificationUser instanceof NotificationUser) {
        ///user has already dismissed notification
        sendingNotification = null;
      } else {
        sendingNotification = latestNotification;
      }
    } else {
      sendingNotification = null;
    }

    // return res.status(200).json({
    //   user: user, userCircles: userCircles, hostedFurnace: hostedFurnace,
    //   token: 'JWT ' + token, officialNotification: sendingNotification
    // });

    let payload = {
      user: user, userCircles: userCircles, hostedFurnace: hostedFurnace,
      token: 'JWT ' + token, officialNotification: sendingNotification
    };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ err: msg });
  }


});

async function deleteNetworkRequest(userID, hostedFurnace) {

  let networkRequest = await NetworkRequest.findOne({ user: userID, hostedFurnace: hostedFurnace._id });

  if (networkRequest instanceof NetworkRequest) {

    await ActionRequired.deleteMany({ user: userID, alertType: constants.ACTION_REQUIRED.NETWORK_REQUEST_APPROVED, networkRequest: networkRequest._id });
    await ActionRequired.deleteMany({ user: userID, alertType: constants.ACTION_REQUIRED.USER_JOINED_NETWORK, networkRequest: networkRequest._id });
    await NetworkRequest.deleteMany({ user: userID, hostedFurnace: hostedFurnace._id });

  }



}

async function createActionRequiredForInviter(member, inviter, networkName) {
  try {

    let actionRequired = new ActionRequired({ alertType: constants.ACTION_REQUIRED.USER_JOINED_NETWORK, alert: member.username + ' has joined ' + networkName + '. Tap to invite them to a Circle', user: inviter, member: member });
    await actionRequired.save();

    deviceLogic.sendActionNeededNotification(inviter, member.username + ' has joined your network');

  } catch (err) {
    await logUtil.logError(err, true);
    throw err;
    //return res.status(500).json({ err: msg });
  }

}

async function createPrivateVault(user, authServer, createNetworkName, privateVaultName) {
  try {
    let dateNow = new Date();

    let name = "Private Vault";

    if (privateVaultName != undefined)
      name = privateVaultName;

    //Create the me circle
    let circle = new Circle({
      name: name,
      type: constants.CIRCLE_TYPE.VAULT,
      ownershipModel: constants.CIRCLE_OWNERSHIP.OWNER,
      owner: user._id,
      created: dateNow,
      privacyShareImage: true,
      lastUpdate: dateNow,
    });

    await circle.save();

    if (authServer == true) {

      var releases = await Release.find({}).sort({ 'build': -1 }).limit(1);

      if (releases.length > 0)
        latestBuild = releases[0].build;

      //circleObject = await systemMessageLogic.sendMessage(circle._id, "This is your private vault. You can safely stash things like images, videos and credentials here.");

      if (createNetworkName == true)
        await checkActionRequired(user, true);
      else
        await checkActionRequired(user, false);

    }


    //Tie to a corresponding usercircle
    let usercircle = new UserCircle({
      user: user._id,
      circle: circle._id,
      prefName: "Private Vault",
      hidden: false,
      lastItemUpdate: Date.now(),
      pinnedOrder: 1,
      newItems: 0,
    });

    //Couldn't be part of new statement above for backwards compatability
    if (authServer == true) {
      usercircle.showBadge = authServer;
      usercircle.newItems = 1;
    }

    await usercircle.save();
  } catch (err) {
    await logUtil.logError(err, true);
    throw err;
    //return res.status(500).json({ err: msg });
  }

}

router.put('/updateblockstatus', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await User.findById(body.userID).populate('blockedList');
    var member = await User.findById(body.memberID);

    var blockedUser;

    for (let i = 0; i < user.blockedList.length; i++) {
      if (user.blockedList[i]._id.equals(body.memberID)) {
        blockedUser = user.blockedList[i];
      }
    }

    if (blockedUser != null) {
      if (body.status == true) {
        ///already blocked
        //return res.status(500).json({ msg: "block failed" });
        return res.status(200).json({ msg: "already blocked" });
      } else {
        ///unblock
        user.blockedList.remove(member);
      }
    } else {
      if (body.status == true) {
        ///block
        user.blockedList.push(member);
      } else {
        ///already unblocked
        //return res.status(500).json({ msg: "unblock failed" });
        return res.status(200).json({ msg: "already unblocked" });
      }
    }

    await user.save();
    //return res.status(200).send({ success: true });
    let payload = { success: true };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    console.log(err);
  }
});



async function createFirstCircle(user, authServer, createNetworkName) {
  try {
    let dateNow = new Date();

    let name = "Circle";

    //Create the me circle
    let circle = new Circle({
      name: name,
      type: constants.CIRCLE_TYPE.STANDARD,
      ownershipModel: constants.CIRCLE_OWNERSHIP.MEMBERS,
      owner: user._id,
      created: dateNow,
      privacyShareImage: true,
      lastUpdate: dateNow,
    });

    await circle.save();

    //Tie to a corresponding usercircle
    let usercircle = new UserCircle({
      user: user._id,
      circle: circle._id,
      prefName: name,
      hidden: false,
      lastItemUpdate: Date.now(),
      pinnedOrder: 1,
      newItems: 0,
    });

    //Couldn't be part of new statement above for backwards compatability
    if (authServer == true) {
      usercircle.showBadge = true;
      usercircle.newItems = 1;
    }

    await usercircle.save();
  } catch (err) {
    await logUtil.logError(err, true);
    throw err;
    //return res.status(500).json({ err: msg });
  }

}

async function connectMembers(user, memberID) {

  let userConnection = await UserConnection.findOne({ user: user._id }).populate('connections').exec();
  if (!(userConnection instanceof UserConnection)) {
    userConnection = new UserConnection({ user: user._id, connections: [] });
  }

  ///connect the user 
  let alreadyConnected = false;

  for (let i = 0; i < userConnection.connections.length; i++) {
    if (userConnection.connections[i]._id.equals(memberID)) {
      alreadyConnected = true;
      continue;
    }
  }

  if (!alreadyConnected) {
    userConnection.connections.push(memberID);
    await userConnection.save();
  }

  ///connect the member
  alreadyConnected = false;

  let memberConnection = await UserConnection.findOne({ user: memberID }).populate('connections').exec();

  if (!(memberConnection instanceof UserConnection)) {
    memberConnection = new UserConnection({ user: memberID, connections: [] });
  }

  for (let i = 0; i < memberConnection.connections.length; i++) {
    if (memberConnection.connections[i]._id.equals(user._id)) {
      alreadyConnected = true;
      continue;
    }
  }

  if (!alreadyConnected) {
    memberConnection.connections.push(user._id);
    await memberConnection.save();
  }

}

async function createDM(user, inviterID, userRachetPublicKey, magicLink, authServer) {
  try {

    let dateNow = new Date();

    let magicNetworkLink = await MagicNetworkLink.findOne({ link: magicLink, inviter: inviterID, active: true });

    if (!(magicNetworkLink instanceof MagicNetworkLink)) throw ('network not found');

    ///test to see if magic link has a ratchetPublicKey
    if (magicNetworkLink.ratchetPublicKey == undefined || magicNetworkLink.ratchetPublicKey == null) {
      return;
    }


    if (magicNetworkLink.dm == false) {
      return; //Don't create a DM if the inviter didn't want one
    }

    let inviter = await User.findById(inviterID);

    //Create the DM
    let circle = new Circle({
      //name: name,
      type: constants.CIRCLE_TYPE.STANDARD,
      ownershipModel: constants.CIRCLE_OWNERSHIP.MEMBERS,
      owner: user._id,
      dm: true,
      created: dateNow,
      privacyShareImage: true,
      lastUpdate: dateNow,
    });

    await circle.save();


    //Tie to a corresponding usercircle
    let userCircle = new UserCircle({
      user: user._id,
      circle: circle._id,
      prefName: inviter.username,
      hidden: false,
      dm: inviter._id,  //This is the user that the DM is with,
      dmConnected: true,
      lastItemUpdate: Date.now(),
      pinnedOrder: 1,
      newItems: 0,
    });

    //Couldn't be part of new statement above for backwards compatability
    if (authServer == true) {
      userCircle.showBadge = true;
      userCircle.newItems = 1;
    }

    userRachetPublicKey.user = user._id;
    userCircle.ratchetPublicKeys.push(userRachetPublicKey);


    await userCircle.save();


    //create the inviter UserCircle
    //Tie to a corresponding usercircle
    let inviterCircle = new UserCircle({
      user: inviter._id,
      circle: circle._id,
      prefName: user.username,
      hidden: false,
      dm: user._id,  //This is the user that the DM is with
      dmConnected: true,
      lastItemUpdate: Date.now(),
      pinnedOrder: 1,
      newItems: 0,
    });

    //Couldn't be part of new statement above for backwards compatability
    if (authServer == true) {
      inviterCircle.showBadge = true;
      inviterCircle.newItems = 1;
    }

    inviterCircle.ratchetPublicKeys.push(magicNetworkLink.ratchetPublicKey);

    await inviterCircle.save();


    systemMessageLogic.sendMessage(circle,
      inviter.username + " has joined!");

    systemMessageLogic.sendMessage(circle,
      user.username + " has joined!");



  } catch (err) {
    await logUtil.logError(err, true);
    throw err;
    //return res.status(500).json({ err: msg });
  }

}


//handle api call to users/signup
router.post('/reserved', async (req, res) => {
  try {

    /*if (process.env.NODE_ENV !== 'production')
      require('dotenv').load();

    if (req.body.apikey != process.env.apikey) {
      await logUtil.logAlert('no apikey doesnt match in reserved', getIP(req));
      return reject('unauthorized');
    }

    let reserved = await isNewUsernameReserved(req.body.username);
    */

    logUtil.logAlert('/user/reserved called from somewhere', getIP(req));

    return res.status(200).json({
      msg: 'deprecated',
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ err: msg });
  }

});


async function addWallIfEnabled(user, network) {

  try {

    if (network.enableWall == true) {

      var wall;

      if (network.wallCircleID == undefined || network.wallCircleID == null) {
        ///Will only happen with a new network registration
        //the wall doesn't exist so create it

        wall = new Circle({
          ownershipModel: constants.CIRCLE_OWNERSHIP.OWNER,
          votingModel: constants.VOTE_MODEL.UNANIMOUS,
          owner: user,
          type: constants.CIRCLE_TYPE.WALL,
          privacyShareImage: true,
        });

        // save the circle
        await wall.save();

        ///add the circle to the newtork
        network.wallCircleID = wall._id;
        await network.save();
      } else {

        ///load the wall circle 
        wall = await Circle.findById(network.wallCircleID);
      }

      //does the usercircle already exist?
      let userCircle = await UserCircle.findOne({ user: user._id, circle: wall._id });

      if (!(userCircle instanceof UserCircle)) {
        userCircle = new UserCircle({
          prefName: 'Network Feed',
          user: user._id,
          circle: wall.id,
          hidden: false,
          lastItemUpdate: Date.now(),
          wall: true,
          ratchetPublicKeys: [user.ratchetPublicKey],
          newItems: 0,
          showBadge: false,
        });
      } else {
        //is the ratchet key already there?
        let ratchetKey = userCircle.ratchetPublicKeys.find(x => x.ratchetIndex == user.ratchetPublicKey.ratchetIndex);

        if (!(ratchetKey instanceof RatchetPublicKey)) {
          userCircle.ratchetPublicKeys.push(user.ratchetPublicKey);
        }
      }

      //check to see if this user is using multiple devices
      for (let k = 0; k < user.devices.length; k++) {
        let device = user.devices[k];

        if (device.uuid == '' || device.pushToken == null)
          continue;

        user.ratchetPublicKey.device = device.uuid;
        userCircle.ratchetPublicKeys.push(user.ratchetPublicKey);

      }

      // save the usercircle
      await userCircle.save();

    }

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    throw new Error(msg);
  }

}

//handle api call to users/signup
router.post('/register', async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    if (!body.build) throw ("register - access denied");
    if (!body.ratchetPublicKey) throw ('register - access denied');

    ///check newer params to verify the user is on a support version
    if (body.passwordHash == null || body.type == null) {
      throw new Error("upgrade required");

    }

    if (body.newNetwork == false && body.type == constants.NETWORK_TYPE.SELF_HOSTED) {
      ///the network and accesscode will be validated below
    } else {
      await validateParamsHash(body.username, body.passwordHash, body.passwordNonce, body.apikey, body.tos);
    }


    if (!body.tos) {
      throw new Error('Terms of Service not agreed to');
    }

    var hostedFurnace;

    let minor = body.minor;

    if (!minor) minor = false;

    let user = new User({
      username: body.username,
      //password: body.password, //deprecated
      //pin: body.pin, //deprecated
      passwordHash: body.passwordHash,
      passwordNonce: body.passwordNonce,
      minor: minor,
      allowClosed: true,
      tos: Date.now(),
    });

    if (!body.passwordHash) {
      let success = validatePasswordComplexity(user, body.password, '', body.pin);

      if (success != true) {
        user = null;  //don't increment attempts
        throw (success);

      }
    }

    if (body.newNetwork == true || body.type == constants.NETWORK_TYPE.SELF_HOSTED) {

      let hostedName = body.hostedName;

      if (body.createNetworkName == true) {

        //backwards compatability check
        if (hostedName == undefined || hostedName == null || hostedName == '')
          hostedName = await getUniqueHostedName();
        else
          await validateNetworkNameAvailable(hostedName);

      }

      await isNewUsernameReserved(user.username); //it's a new furnace, only check guaranteed uniqueness

      hostedFurnace = new HostedFurnace({
        name: hostedName,
        lowercase: hostedName.toLowerCase(),
        key: body.key,
        enableWall: false, ///Used to turn feed on/off
        description: body.description,
        link: body.link,
        adultOnly: body.adultOnly,
        discoverable: body.discoverable
      });

      if (body.newStandalone) {
        hostedFurnace.approved = true;
      }

      await hostedFurnace.save();

      user.role = constants.ROLE.OWNER;
      user.hostedFurnace = hostedFurnace;
      user.lowercase = user.username.toLowerCase();



    } else {

      if (body.type == constants.NETWORK_TYPE.FORGE) {
        ///is it the Forge?
        if (body.hostedName == null || body.hostedName == undefined || body.hostedName == "IronForge") {
          hostedFurnace = HostedFurnace({ _id: 'IronForge', name: 'IronForge' });
          user.lowercase = await checkUsername(user.username, null, body.authUserID);
        } else {
          user.lowercase = await checkUsername(user.username, null, body.authUserID);
          ///it's a self hosted server
          hostedFurnace = await validateHostedNetworkFromLanding(body.hostedName, body.key, body.uuid);
          user.hostedFurnace = hostedFurnace;
        }
      } else if (body.type == constants.NETWORK_TYPE.HOSTED) {
        user.lowercase = await checkUsername(user.username, null, body.authUserID);
        ///have to check username before furnace so that they don't lose furnace attempts through duplicate username
        hostedFurnace = await validateHostedNetworkFromLanding(body.hostedName, body.key, body.uuid);
        user.hostedFurnace = hostedFurnace;
      } else {
        throw new Error("access denied");
      }

    }

    await User.init(); // `User.init()` returns a promise that is fulfilled when all indexes are done


    let deviceBlocks = await DeviceBlock.find({});

    for (let i = 0; i < deviceBlocks.length; i++) {

      if (body.uuid == deviceBlocks[i].deviceID || body.pushtoken == deviceBlocks[i].pushToken) {

        user.allowClosed = false;
        break;
      }

    }

    if (body.fromNetworkManager != true) {
      await createPrivateVault(user, body.authServer, body.createNetworkName);
      await createFirstCircle(user, body.authServer, body.createNetworkName);
    }

    user.ratchetPublicKey = RatchetPublicKey.new(body.ratchetPublicKey);
    user.ratchetPublicKey.user = user.id;
    await user.save();

    let currency = new IronCurrency();

    //save the wallet
    let balance = 0;
    if (body.authServer == true) {

      ///has this device been givin coins already?
      let users = await User.find({ _id: { $ne: user._id }, 'devices.uuid': body.uuid + "s" });
      if (users.length == 0) {
        let users = await User.find({ _id: { $ne: user._id }, 'devices.pushToken': body.pushtoken });
        if (users.length == 0) {
          balance = currency.newUserCoins;
        }
      }

    }
    let ironCoinWallet = IronCoinWallet({ user: user._id, balance: balance });
    await ironCoinWallet.save();

    deleteNetworkRequest(body.authUserID, hostedFurnace);

    // let userKeyBackup = new UserKeyBackup({ crank: body.ratchetIndex.crank, signature: body.ratchetIndex.signature, backup: body.ratchetIndex.ratchetValue });
    //userKeyBackup.user = user.id;

    let userKeyBackup = await UserKeyBackup.new(body); // ({ crank: body.ratchetIndex.crank, signature: body.ratchetIndex.signature, backup: body.ratchetIndex.ratchetValue });
    userKeyBackup.user = user.id;
    userKeyBackup.userIndex.user = user.id;
    userKeyBackup.backupIndex.user = user.id;
    await userKeyBackup.save();


    if (body.inviterID != undefined && body.inviterID != null) {
      createActionRequiredForInviter(user, body.inviterID, hostedFurnace.name);

      if (body.magicLink != undefined && body.magicLink != null) {
        await connectMembers(user, body.inviterID);
        await createDM(user, body.inviterID, body.ratchetPublicKey, body.magicLink, body.authServer);
      }
    }

    //blank out the password before creating the token
    user.pin = "";
    user.password = "";
    const token = jwt.sign(user.toObject(), secret, { expiresIn: daysToMilliseconds(user.securityTokenExpirationDays) }); //30 days (24 hours = 345600)

    await addWallIfEnabled(user, hostedFurnace);

    let userCircles = await returnUserCircles(user._id);

    var latestBuild;
    if (body.authServer == true) {

      var releases = await Release.find({}).sort({ 'build': -1 }).limit(1);

      if (releases.length > 0)
        latestBuild = releases[0].build;
    }

    //if (body.pushtoken != null && body.pushtoken != undefined)
    deviceLogic.registerDevice(user._id, body.pushtoken, body.platform, body.uuid, body.build, body.model);

    metricLogic.setLastAccessed(user);

    await hostedFurnace.populate('hostedFurnaceImage');

    ///check for notification
    let notificationUser;
    let sendingNotification;
    let latestNotification = await OfficialNotification.findOne({ enabled: true }).sort({ 'created': -1 });
    if (latestNotification instanceof OfficialNotification) {
      notificationUser = await NotificationUser.findOne({ user: user._id, officialNotification: latestNotification._id });
      if (notificationUser instanceof NotificationUser) {
        ///user has already dismissed notification
        sendingNotification = null;
      } else {
        sendingNotification = latestNotification;
      }
    } else {
      sendingNotification = null;
    }

    // return res.status(200).json({
    //   user: user, ironCoinWallet: ironCoinWallet, userCircles: userCircles, latestBuild: latestBuild, hostedFurnace: hostedFurnace,
    //   token: 'JWT ' + token, officialNotification: sendingNotification
    // });

    let payload = {
      user: user, ironCoinWallet: ironCoinWallet, userCircles: userCircles, latestBuild: latestBuild, hostedFurnace: hostedFurnace,
      token: 'JWT ' + token, officialNotification: sendingNotification
    };

    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ err: msg });
  }


});


//create a central user record for externally registered users
router.post('/registerstandalone', async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    if (!body.build) throw ("register - access denied");
    if (!body.ratchetPublicKey) throw ('register - access denied');

    validateUsernameAndApikey(body.username, body.apikey);
    var hostedFurnace;

    let minor = body.minor;
    ///hosted name is passed in as the external networks id (not the name)
    let hostedName = body.hostedName;

    if (!minor) minor = false;

    let user = new User({
      username: body.username,
      // passwordHash: body.passwordHash,
      // passwordNonce: body.passwordNonce,
      minor: minor,
      allowClosed: true,
      tos: Date.now(),
    });

    //await isNewUsernameReserved(user.username);

    if (body.newNetwork == true) {

      hostedFurnace = new HostedFurnace({
        name: hostedName,
        type: body.type,
        lowercase: hostedName.toLowerCase(),
        key: hostedName.toLowerCase(), ///don't store actual key
        enableWall: false, ///Used to turn feed on/off
        description: '',
        link: '',
        adultOnly: body.adultOnly,
        discoverable: body.discoverable,
        approved: true,
      });

      await hostedFurnace.save();

      user.role = constants.ROLE.OWNER;
      user.hostedFurnace = hostedFurnace;
      user.lowercase = user.username.toLowerCase();

    } else {
      ///this doesn't give the user access to the network, no need to validate the accessCode (we don't want to store selfHosted access codes)
      hostedFurnace = await HostedFurnace.findOne({ 'lowercase': hostedName.toLowerCase() });
      if (!(hostedFurnace instanceof HostedFurnace)) throw new error("access denied");
      user.hostedFurnace = hostedFurnace;

    }

    await User.init(); // `User.init()` returns a promise that is fulfilled when all indexes are done

    user.ratchetPublicKey = RatchetPublicKey.new(body.ratchetPublicKey);
    user.ratchetPublicKey.user = user.id;
    await user.save();

    let currency = new IronCurrency();

    //save the wallet
    let balance = 0;
    if (body.authServer == true) {

      ///has this device been givin coins already?
      let users = await User.find({ _id: { $ne: user._id }, 'devices.uuid': body.uuid + "s" });
      if (users.length == 0) {
        let users = await User.find({ _id: { $ne: user._id }, 'devices.pushToken': body.pushtoken });
        if (users.length == 0) {
          balance = currency.newUserCoins;
        }
      }

    }
    let ironCoinWallet = IronCoinWallet({ user: user._id, balance: balance });
    await ironCoinWallet.save();

    //blank out the password before creating the token
    user.pin = "";
    user.password = "";
    const token = jwt.sign(user.toObject(), secret, { expiresIn: daysToMilliseconds(user.securityTokenExpirationDays) }); //30 days (24 hours = 345600)

    var latestBuild;
    if (body.authServer == true) {

      var releases = await Release.find({}).sort({ 'build': -1 }).limit(1);

      if (releases.length > 0)
        latestBuild = releases[0].build;
    }

    deviceLogic.registerDevice(user._id, body.pushtoken, body.platform, body.uuid, body.build, body.model);

    metricLogic.setLastAccessed(user);

    ///check for notification
    let notificationUser;
    let sendingNotification;
    let latestNotification = await OfficialNotification.findOne({ enabled: true }).sort({ 'created': -1 });
    if (latestNotification instanceof OfficialNotification) {
      notificationUser = await NotificationUser.findOne({ user: user._id, officialNotification: latestNotification._id });
      if (notificationUser instanceof NotificationUser) {
        ///user has already dismissed notification
        sendingNotification = null;
      } else {
        sendingNotification = latestNotification;
      }
    } else {
      sendingNotification = null;
    }

    // return res.status(200).json({
    //   user: user, ironCoinWallet: ironCoinWallet, latestBuild: latestBuild,
    //   token: 'JWT ' + token, officialNotification: sendingNotification
    // });

    let payload = {
      user: user, ironCoinWallet: ironCoinWallet, latestBuild: latestBuild,
      token: 'JWT ' + token, officialNotification: sendingNotification
    };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ err: msg });
  }


});



//handle api call to users/signup
router.post('/backupuserkey', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    if (!req.body.userIndex || !req.body.backupIndex || !req.body.password || !req.body.pin) {
      await logUtil.logAlert('invalid params to backupuserkey', getIP(req));
      throw ('unauthorized');
    }


    let user = await User.findOne({ _id: req.user.id });

    let success = validatePasswordComplexity(user, req.body.password, '', req.body.pin);

    if (success != true) {
      user = null;  //don't increment attempts
      throw (success);

    }

    user.password = req.body.password;
    user.pin = req.body.pin;
    await user.save();

    let userKeyBackup = await UserKeyBackup.new(req.body); // ({ crank: req.body.ratchetIndex.crank, signature: req.body.ratchetIndex.signature, backup: req.body.ratchetIndex.ratchetValue });
    //userKeyBackup.user = user.id;
    userKeyBackup.save();


    //blank out the password before creating the token
    user.password = "";
    const token = jwt.sign(user.toObject(), secret, { expiresIn: daysToMilliseconds(user.securityTokenExpirationDays) }); //30 days (24 hours = 345600)

    return res.status(200).json({
      user: user, msg: 'success', token: 'JWT ' + token
    });
  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ err: msg });
  }


});

router.put('/dismissnotification', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //let user = await User.findById(body.userID);
    //let userNotification = await NotificationUser.findOne({ user: req.body.user.id, officialNotification: req.body.officialNotification.id });

    let userID = req.user._id;

    if (req.user.linkedUser != null) {
      userID = req.user.linkedUser;
    }

    let userNotification = new NotificationUser({
      user: userID,
      officialNotification: body.notification,
    });
    userNotification.save();


    // return res.status(200).json({ msg: 'success' });

    let payload = { msg: 'success' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});

async function checkActionRequired(user, changeGenerated) {

  try {

    /*
    let backupNeeded = false;

    if (user.autoKeychainBackup != true) {

      if (user.lastKeyBackup == null)
        backupNeeded = true;
      else {

        let difference = Date.now() - user.lastKeyBackup;
        let days = Math.ceil(difference / (1000 * 3600 * 24))

        if (days >= 90) backupNeeded = true;

      }
    }


    if (backupNeeded == true) {

      let actionRequired = await ActionRequired.findOne({ user: user._id, alertType: constants.ACTION_REQUIRED.EXPORT_KEYS });

      if (!(actionRequired instanceof ActionRequired)) {

        actionRequired = new ActionRequired({
          user: user._id,
          alert: "Important: Export or enable autobackup for your encryption keys.",
          alertType: constants.ACTION_REQUIRED.EXPORT_KEYS
        });

        await actionRequired.save();
      }

    }
    */

    if (changeGenerated != undefined && changeGenerated != null) {

      let actionRequired = await ActionRequired.findOne({ user: user._id, alertType: constants.ACTION_REQUIRED.CHANGE_GENERATED });

      if (!(actionRequired instanceof ActionRequired)) {
        actionRequired = new ActionRequired({
          user: user._id,
          alert: "Create a password and a pin",
          alertType: constants.ACTION_REQUIRED.CHANGE_GENERATED
        });

        await actionRequired.save();

      }

    }

    /* if (!user.accountRecovery) {
 
       await user.populate('passwordHelpers');
 
       let actionRequired = await ActionRequired.findOne({ user: user._id, alertType: constants.ACTION_REQUIRED.SETUP_PASSWORD_ASSIST });
 
       if (!(actionRequired instanceof ActionRequired)) {
         actionRequired = new ActionRequired({
           user: user._id,
           alert: "Important: Setup account recovery. without this you will not be able to access an account if you forget your password or pin.",
           alertType: constants.ACTION_REQUIRED.SETUP_PASSWORD_ASSIST
         });
 
         await actionRequired.save();
 
       }
 
     }*/

  } catch (err) {

    var msg = await logUtil.logError(err, true);
  }


}

async function validateNetworkNameAvailable(hostedName) {
  try {
    let hostedFurnace = await HostedFurnace.findOne({ lowercase: hostedName.trim().toLowerCase() });
    if (hostedFurnace instanceof HostedFurnace) throw ('The network name you selected is already in use. Please choose a different name.');

    return;

  } catch (err) {
    logUtil.logError(err, true);
    throw ('The network name you selected is already in use. Please choose a different name.');
  }
}

async function getUniqueHostedName() {
  try {
    let hostedName = 'Private Network ' + String(Math.random()).substring(2, 7);

    for (let i = 0; i < 50; i++) {

      let hostedFurnace = await HostedFurnace.findOne({ lowercase: hostedName.toLowerCase() });

      if (!(hostedFurnace && hostedFurnace instanceof HostedFurnace)) {
        //its unique so quit
        break;
      }

      else {
        //add another number and try again
        hostedName = hostedName + String(Math.random()).substring(2, 3);

        if (i == 49)
          throw new Error('Could not find a name for network');
      }
    }

    return hostedName;

  } catch (err) {
    logUtil.logError(err, true);
    throw ('Could not find a name for network');
  }
}

async function getUniqueUsernameForNetwork(user, hostedFurnace, authUserID) {

  try {

    ///first check to see if the name is reserved
    for (let i = 0; i < 500; i++) {

      let existing = await User.findOne({ lowercase: user.username.toLowerCase(), reservedUsername: true, _id: { $ne: authUserID } });

      if (!(existing && existing instanceof User)) {
        //its unique so quit
        break;
      }

      else {
        //add another number and try again
        user.username = user.username + String(Math.random()).substring(2, 3);

        if (i == 499)
          throw new Error('could not find a name for network');
      }
    }

    //second, check to see if the name is used on the network (null for IronForge)
    for (let i = 0; i < 500; i++) {

      let existing = await User.findOne({ lowercase: user.username.toLowerCase(), hostedFurnace: hostedFurnace, _id: { $ne: authUserID } });

      if (!(existing && existing instanceof User)) {
        //its unique so quit
        break;
      }

      else {
        //add another number and try again
        user.username = user.username + String(Math.random()).substring(2, 3);

        if (i == 499)
          throw new Error('Could not find a name for network');
      }
    }

    user.lowercase = user.username.toLowerCase();

    return user;
  } catch (err) {
    logUtil.logError(err, true);
    throw ('could not create username');
  }

}
/*
async function getUniqueUsername(username) {

  try {

    for (let i = 0; i < 50; i++) {

      let user = await User.findOne({ lowercase: username.toLowerCase(), reservedUsername: true });

      if (!(user && user instanceof User)) {
        //its unique so quit
        break;
      }

      else {
        //add another number and try again
        username = username + String(Math.random()).substring(2, 3);

        if (i == 49)
          throw new Error('could not find a name for network');
      }
    }

    return username;
  } catch (err) {
    logUtil.logError(err, true);
    throw ('could not reserve username');
  }

}*/

async function isNewUsernameReserved(username, authUserID) {
  try {
    var lowercase = username.toLowerCase();

    let duplicate = await User.findOne({ lowercase: lowercase, reservedUsername: true });

    if (duplicate instanceof User) {

      if (authUserID == undefined) {
        throw ('this username has been reserved');
      } else if (!duplicate._id.equals(ObjectID(authUserID))) {
        throw ('this username has been reserved');
      }
    }

    return false;

  } catch (err) {
    throw ('this username has been reserved');
  }

}


async function checkUsername(username, hostedFurnace, authUserID) {

  let lowercase = username.trim().toLowerCase();
  //lowercase = lowercase.toLowerCase();

  await isNewUsernameReserved(lowercase, authUserID);

  var duplicate;

  if (hostedFurnace != undefined && hostedFurnace != null) {
    duplicate = await User.findOne({ lowercase: lowercase, hostedFurnace: hostedFurnace });
  } else {
    duplicate = await User.findOne({ lowercase: lowercase, hostedFurnace: null });
  }

  if (duplicate instanceof User) {
    console.log('username: ' + username + ', network: ' + hostedFurnace);
    throw ('username is already taken');

  }

  return lowercase;

}

async function validateHostedNetworkNameOnly(hostedName) {


  let hostedFurnace = await HostedFurnace.findOne({ lowercase: hostedName.toLowerCase() });

  if (hostedFurnace && hostedFurnace instanceof HostedFurnace)
    return hostedFurnace;
  else
    throw new Error("invalid credentials for this network");
}

async function validateHostedNetwork(hostedName, hostedKey, userID) { ///VALIDATION


  let hostedFurnace = await HostedFurnace.findOne({ lowercase: hostedName.toLowerCase().trim(), key: hostedKey.trim() });

  if (hostedFurnace && hostedFurnace instanceof HostedFurnace)
    return hostedFurnace;
  else {

    if (userID != undefined && userID != null) {
      let hostedFurnace = await HostedFurnace.findOne({ lowercase: hostedName.toLowerCase() });
      if (hostedFurnace && hostedFurnace instanceof HostedFurnace) {
        let networkRequest = await NetworkRequest.findOne({ user: userID, hostedFurnace: hostedFurnace._id, status: constants.NETWORK_REQUEST_STATUS.APPROVED });

        if (networkRequest instanceof NetworkRequest) {
          return hostedFurnace;
        }
      }
    }

    await logUtil.logAlert('invalid hosted network');
    throw ("unauthorized");

  }
}

async function validateHostedNetworkFromLanding(hostedName, hostedKey, deviceId) {

  let message = 'invalid';

  let hostedFurnaceReference = await HostedFurnace.findOne({
    lowercase: hostedName.toLowerCase().trim(),
  });
  if (!hostedFurnaceReference) {
    await logUtil.logAlert('invalid hosted network');
    throw ("unauthorized");
  }
  let hostedFurnace = await HostedFurnace.findOne({
    lowercase: hostedName.toLowerCase().trim(),
    key: hostedKey.trim(),
  });
  if (hostedFurnace && hostedFurnace instanceof HostedFurnace) {
    message = 'valid';
  }

  let attempts = 0;
  let deviceNetworkAttempts = await DeviceNetworkAttempts.findOne({
    device: deviceId,
    network: hostedFurnaceReference._id,
  });
  if (deviceNetworkAttempts && deviceNetworkAttempts instanceof DeviceNetworkAttempts) {
    attempts = deviceNetworkAttempts.attempts;
  }

  if (attempts == 0) {
    deviceNetworkAttempts = new DeviceNetworkAttempts({
      device: deviceId,
      network: hostedFurnaceReference._id,
      lastAttempt: Date.now(),
    });
  } else if (attempts < 5) {

  } else if (attempts < 10) {
    var tooSoonMsg = tooSoonMessageFurnace(deviceNetworkAttempts.lastAttempt);
    if (tooSoonMsg) {
      message = "wait" + tooSoonMsg;
    } else if (attempts == 9 && message == 'invalid') {
      message = "failed";
    }
  } else {
    message = 'exceeded';
  }

  if (message != 'valid' && !tooSoonMsg) {
    deviceNetworkAttempts.attempts = attempts + 1;
    deviceNetworkAttempts.lastAttempt = Date.now();
    await deviceNetworkAttempts.save();
  }

  if (message == 'valid') {
    return hostedFurnace;
  } else if (message == 'invalid') {
    await logUtil.logAlert('invalid hosted network');
    throw ("unauthorized");
  } else if (message == 'failed') {
    await logUtil.logAlert('failed last attempt');
    throw ("failed");
  } else if (message == 'exceeded') {
    await logUtil.logAlert('exceeded attempts');
    throw ("exceeded");
  } else {
    await logUtil.logAlert('wait before trying again');
    throw (message);
  }
}



router.put('/profile/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //AUTHORIZATION CHECK NOT NEEDED, TOKEN IS ENOUGH

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = req.user; //await User.findById(req.user.id);
    var oldLowercase = user.lowercase;

    if (body.username != undefined && body.username != null) {

      var hostedID = user.hostedFurnace;

      var lowercase = body.username.toLowerCase();

      ///don't worry about case only changes
      if (lowercase != user.lowercase) {
        lowercase = await checkUsername(body.username, hostedID, body.authUserID);
      }
      user.username = body.username;
      user.lowercase = lowercase;

      //await systemMessageLogic.sendMessageAllCircles(user._id, req.user.username + ' changed their username to ' + user.username);
    }

    if (body.passwordBeforeChange != undefined) {
      user.passwordBeforeChange = body.passwordBeforeChange;

    }

    await user.save();


    let linkedUsers = await User.find({ linkedUser: user._id, lowercase: oldLowercase });

    //If the username change, also change linked accounts
    if (body.username != undefined && body.username != null) {

      for (let i = 0; i < linkedUsers.length; i++) {
        let linkedUser = linkedUsers[i];
        linkedUser.username = user.username;
        linkedUser = await getUniqueUsernameForNetwork(linkedUser, linkedUser.hostedFurnace, user._id);
        await linkedUser.save();

      }
    }

    //return res.status(200).json({ msg: 'profile updates complete', username: user.username, linkedUsers: linkedUsers });

    let payload = { msg: 'profile updates complete', username: user.username, linkedUsers: linkedUsers };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);




  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

//Generate reset code
router.post('/generateresetcode/', async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);


    if (process.env.NODE_ENV !== 'production')
      require('dotenv').load();

    if (body.apikey != process.env.apikey) {
      await logUtil.logAlert('missing apikey in generateresetcode', getIP(req));
      throw new Error('Unauthorized');
    }

    let resetCode = crypto.randomBytes(6).toString('hex');
    //console.log("RESET CODE");
    //console.log(resetCode);

    var user;

    var lowercase = body.username.toLowerCase();

    if (body.hostedName != undefined && body.hostedName.toLowerCase() != 'ironforge') {

      var hostedFurnace;

      if (body.hostedKey != undefined || body.hostedKey != null) {
        hostedFurnace = await validateHostedNetwork(body.hostedName, body.key);
      } else {
        hostedFurnace = await validateHostedNetworkNameOnly(body.hostedName);
      }
      user = await User.findOne({ lowercase: lowercase, hostedFurnace: hostedFurnace._id }).populate('passwordHelpers');
    } else {
      user = await User.findOne({ lowercase: lowercase, hostedFurnace: null }).populate('passwordHelpers');
    }



    if (!user || !(user instanceof User)) throw ('user not found');

    if (user.passwordHelpers.length == 0) {
      throw "No password assist members identified.\n\nPassword cannot be reset";
    }

    user.resetCode = resetCode;
    user.resetCodeCreatedOn = Date.now();


    let chunkSize = resetCode.length / user.passwordHelpers.length;
    let chunks = resetCode.match(new RegExp('.{1,' + chunkSize + '}', 'g'));

    //remove any prior password reset requests for this user
    await ActionRequired.deleteMany({ 'resetUser': user._id });

    for (let i = 0; i < user.passwordHelpers.length; i++) {

      let helper = user.passwordHelpers[i];

      let actionRequired = new ActionRequired({
        user: helper,
        alert: 'User needs help reseting their password',
        alertType: constants.ACTION_REQUIRED.HELP_WITH_RESET,
        resetFragment: "Reset code fragment #" + (i + 1) + ":    " + chunks[i],

        ratchetPublicKey: RatchetPublicKey.new(body.ratchetPublicKey),
        resetUser: user,
      });

      await user.save();
      await actionRequired.save();


      deviceLogic.sendActionNeededNotification(helper._id, user.username + ' needs your help with a password reset');

    }

    //res.status(200).send({ msg: 'Reset code fragments send to password assist members.\n\nThis code will expire in 48 hours' });

    let payload = { msg: 'Reset code fragments send to password assist members.\n\nThis code will expire in 48 hours' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);


  } catch (err) {
    let msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});


///remove POSTKYBER
router.get('/passcodeforpasscodereset/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    //AUTHORIZATION - Ensure there is an active password reset request
    let actionRequired = await ActionRequired.findOne({ user: req.user.id, resetUser: req.params.id });
    if (!actionRequired) {
      await logUtil.logAlert('could not find action required for passcodeforpasscodereset', getIP(req));
      throw ('unauthorized');
    }
    if (!(actionRequired instanceof ActionRequired)) {
      await logUtil.logAlert('could not find action required for passcodeforpasscodereset', getIP(req));
      throw ('unauthorized');
    }

    //Only return the RatchetIndex that was created for the authentication user
    let userKeyBackup = await UserKeyBackup.findOne({ user: req.params.id });
    var ratchetIndex = null;

    for (let i = 0; i < userKeyBackup.assistants.length; i++) {

      if (userKeyBackup.assistants[i].user.equals(req.user.id)) {
        ratchetIndex = userKeyBackup.assistants[i];
        break;
      }
    }

    if (ratchetIndex == null) {
      await logUtil.logAlert('could not find ratchetIndex for passcodeforpasscodereset', getIP(req));
      throw ('unauthorized');
    }


    res.status(200).send({ ratchetIndex: ratchetIndex });

  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ err: msg });
  }
});

router.post('/passcodeforpasscodereset/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION - Ensure there is an active password reset request
    let actionRequired = await ActionRequired.findOne({ user: req.user.id, resetUser: body.resetUserID });
    if (!actionRequired) {
      await logUtil.logAlert('could not find action required for passcodeforpasscodereset', getIP(req));
      throw ('unauthorized');
    }
    if (!(actionRequired instanceof ActionRequired)) {
      await logUtil.logAlert('could not find action required for passcodeforpasscodereset', getIP(req));
      throw ('unauthorized');
    }

    //Only return the RatchetIndex that was created for the authentication user
    let userKeyBackup = await UserKeyBackup.findOne({ user: body.resetUserID });
    var ratchetIndex = null;

    for (let i = 0; i < userKeyBackup.assistants.length; i++) {

      if (userKeyBackup.assistants[i].user.equals(req.user.id)) {
        ratchetIndex = userKeyBackup.assistants[i];
        break;
      }
    }

    if (ratchetIndex == null) {
      await logUtil.logAlert('could not find ratchetIndex for passcodeforpasscodereset', getIP(req));
      throw ('unauthorized');
    }


    //res.status(200).send({ ratchetIndex: ratchetIndex });

    let payload = { ratchetIndex: ratchetIndex };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ err: msg });
  }
});



//Updates the UserKeyBackup recoveryIndex with the supplied index (which encrypted a fragment of the user's backup code)

router.post('/encryptedfragforpasscodereset/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION - Ensure there is an active password reset request
    let actionRequired = await ActionRequired.findOne({ user: req.user.id, resetUser: body.resetUserID });
    if (!actionRequired) {
      await logUtil.logAlert('could not find actionRequired for encryptedfragforpasscodereset', getIP(req));
      throw ('unauthorized');
    }
    if (!(actionRequired instanceof ActionRequired)) {
      await logUtil.logAlert('could not find actionRequired for encryptedfragforpasscodereset', getIP(req));
      throw ('unauthorized');
    }
    if (!body.returnIndex || !body.resetUserID) {
      await logUtil.logAlert('could not find returnIndex or resetUserID for encryptedfragforpasscodereset', getIP(req));
      throw ('unauthorized');
    }

    //load the UserKeyBackup
    let userKeyBackup = await UserKeyBackup.findOne({ user: body.resetUserID });

    let returnIndex = RatchetIndex.new(body.returnIndex);
    returnIndex.user = req.user.id;

    //pull any existing RachetIndex for this user
    await UserKeyBackup.updateOne({ '_id': userKeyBackup._id }, { $pull: { 'recoveryIndexes': { user: req.user.id, } } });

    //push the newly supplied one
    await UserKeyBackup.updateOne({ '_id': userKeyBackup._id }, { $push: { 'recoveryIndexes': returnIndex } }); //,'keyIndex': {$ne: ratchetPublicKey.keyIndex} } });

    //res.status(200).send({ msg: 'success' });

    let payload = { msg: 'success' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ err: msg });
  }
});


router.post('/resetcodeavailable', async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    await validateParams(body.username, 'NA', 'NA', body.apikey);  //error thrown if invalid

    var user;

    if (body.hostedName != undefined && body.hostedName.toLowerCase() != 'ironforge') {

      var hostedFurnace;

      if (body.key != undefined && body.key != null) {
        hostedFurnace = await validateHostedNetwork(body.hostedName, body.key);
      } else {
        hostedFurnace = await validateHostedNetworkNameOnly(body.hostedName);
      }
      user = await loadUserPlusResetCode(body.username, hostedFurnace._id);
    }
    else {
      user = await loadUserPlusResetCode(body.username);
    }

    if (!(user instanceof User)) throw new Error("Could not find an account matching network and username");

    let msg = await isResetCodeValid(user, true);

    // res.status(200).send({ 'resetcodeavailable': msg });
    let payload = { 'resetcodeavailable': msg };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    let msg = await logUtil.logError(err, true, getIP(req));
    msg = "Could not find an account matching network and username";
    return res.status(500).json({ msg: msg });
  }

});



//get recoveryIndexes before actually resetting the password, to make sure backup key is valid
router.post('/resetcoderatchetindexes/', async (req, res) => {

  var user;

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    if (!body.username || !body.resetcode) throw ('reset: invalid code');

    var user;

    if (body.hostedName != undefined && body.hostedName.toLowerCase() != 'ironforge') {

      var hostedFurnace;

      if (body.key != undefined || body.key != null) {
        hostedFurnace = await validateHostedNetwork(body.hostedName, body.key);
      } else {
        hostedFurnace = await validateHostedNetworkNameOnly(body.hostedName);
      }

      user = await loadUserPlusResetCode(body.username, hostedFurnace._id);
    }
    else
      user = await loadUserPlusResetCode(body.username);


    if (!(user instanceof User)) throw new Error("reset: could not find user");

    if (user.resetCodeAttemptsExceeded == true) {
      let payload = { msg: "reset code attempts exceeded", resetAttemptsExceeded: true };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);


      //return res.status(200).json({ msg: "reset code attempts exceeded", resetAttemptsExceeded: true });
    } else if (user.resetCodeAttempts > SLOWLOGINAFTER) {
      var tooSoonMsg = tooSoonResetCode(user);
      if (tooSoonMsg) {
        let payload = { msg: tooSoonMsg, resetAttemptsExceeded: true };
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);

        //return res.status(200).json(payload = { msg: tooSoonMsg, resetAttemptsExceeded: true });
      }
    }


    let valid = await isResetCodeValid(user, true);

    if (!valid) {
      user = null;
      throw new Error("Reset code expired");
    }

    await user.compareResetCode(body.resetcode);

    let userKeyBackup = await UserKeyBackup.findOne({ user: user._id });

    let recoveryIndexes = [];

    for (let i = 0; i < userKeyBackup.assistants.length; i++) {


      for (let j = 0; j < userKeyBackup.recoveryIndexes.length; j++) {

        if (userKeyBackup.assistants[i].user._id.equals(userKeyBackup.recoveryIndexes[j].user._id)) {
          recoveryIndexes.push(userKeyBackup.recoveryIndexes[j]);
          break;
        }
      }

    }



    // return the information 
    //return res.status(200).json({ ratchetIndexes: recoveryIndexes, /*userIndex: userKeyBackup.userIndex*/ });



    let payload = { ratchetIndexes: recoveryIndexes, /*userIndex: userKeyBackup.userIndex*/ };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {

    let msg = await logUtil.logError(err, true, getIP(req));
    let attempts = await incrementResetCodeAttempts(user);
    if (attempts) msg = attempts;
    return res.status(500).json({ err: msg });

  }

});



//reset password from code
router.put('/resetcode/', async (req, res) => {

  var user;

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    if (body.passwordHash) {
      await validateParamsHash(body.username, body.passwordHash, body.passwordNonce, body.apikey, body.tos);
    } else {
      //deprecated
      await validateParams(body.username, body.resetcode, 'NA', body.apikey);  //error thrown if invalid
    }

    if (!body.backupIndex) throw ('backupIndex not found');

    var user;

    if (body.hostedName != undefined && body.hostedName.toLowerCase() != 'ironforge') {

      var hostedFurnace;

      if (body.key != undefined || body.key != null) {
        hostedFurnace = await validateHostedNetwork(body.hostedName, body.key);
      } else {
        hostedFurnace = await validateHostedNetworkNameOnly(body.hostedName);
      }

      user = await loadUserPlusResetCode(body.username, hostedFurnace._id);
    }
    else
      user = await loadUserPlusResetCode(body.username);


    if (!(user instanceof User)) throw new Error("Invalid username or password");


    if (user.resetCodeAttemptsExceeded == true) {
      return res.status(200).json({ msg: "reset code attempts exceeded", resetAttemptsExceeded: true });
    } else if (user.resetCodeAttempts > SLOWLOGINAFTER) {
      var tooSoonMsg = tooSoonResetCode(user);
      if (tooSoonMsg)
        return res.status(200).json({ msg: tooSoonMsg, resetAttemptsExceeded: true });
    }



    let valid = await isResetCodeValid(user, true);

    if (!valid) {
      user = null;
      throw new Error("Reset code expired");
    }

    await user.compareResetCode(body.resetcode);

    if (!body.passwordHash) {
      let success = validatePasswordComplexity(user, body.password, '', body.pin);

      if (success != true) {
        user = null;  //don't increment attempts
        throw (success);

      }

      user.password = body.password;
      user.pin = body.pin;

    } else {
      //set the hash and nonce
      user.passwordHash = body.passwordHash;
      user.passwordNonce = body.passwordNonce;
    }

    user.loginAttempts = 0;
    user.loginAttemptsExceeded = false;
    user.passwordChangedOn = Date.now();
    user.passwordExpired = false;

    user = await removeResetCode(user, false);

    await user.save();

    let userKeyBackup = await UserKeyBackup.findOne({ user: user._id });
    userKeyBackup.backupIndex = RatchetIndex.new(body.backupIndex);
    userKeyBackup.backupIndex.user = user._id;

    if (userKeyBackup)
      await userKeyBackup.save();

    // return the information 
    //return res.status(200).json({ user: user });


    let payload = { user: user };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {

    let msg = await logUtil.logError(err, true, getIP(req));
    let attempts = await incrementResetCodeAttempts(user);
    if (attempts) msg = attempts;
    return res.status(500).json({ err: msg });

  }

});

function getIP(request) {

  try {
    let ipAddr = request.connection.remoteAddress;

    if (request.headers && request.headers['x-forwarded-for']) {
      [ipAddr] = request.headers['x-forwarded-for'].split(',');
    }

    return ipAddr;
  } catch (err) {
    logUtil.logError(err, true);
    return '';
  }
}


async function removeResetCode(user, save) {
  try {
    user.resetCodeCreatedOn = undefined;
    user.resetCode = undefined;
    user.resetCodeAttempts = undefined;
    user.resetCodeAttemptsExceeded = undefined;
    user.resetCodeAttemptsLastFailed = undefined;

    if (save) await user.save();

    await ActionRequired.deleteMany({ resetUser: user._id, alertType: constants.ACTION_REQUIRED.HELP_WITH_RESET });

  } catch (err) {
    let msg = await logUtil.logError(err, true);
  }

  return user;

}




async function isResetCodeValid(user) {

  let retValue = false;

  try {

    if (user) {
      if (user.resetCode) {

        //test the date 
        if ((Date.now() - user.resetCodeCreatedOn) < HOURS_48)
          retValue = true;
        else {
          user = await removeResetCode(user, true);
        }
      }
    }

  } catch (err) {
    let msg = await logUtil.logError(err, true);

  }

  return retValue;
}



///deprecated POSTKYBER
router.get('/passwordhelpers/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var user = await User.findOne({ "_id": req.user.id }).populate('passwordHelpers');

    var response = await userCircleLogic.getUserCirclesParam(req.user.id, null, null, true);
    var userCircles = response[0];

    var circles = [];
    for (var i = 0; i < userCircles.length; i++) {
      if (userCircles[i].circle != null) {
        //console.log(userCircles[i]._id.toString());
        circles.push(userCircles[i].circle._id);
      }
    }

    var memberCircles = await UserCircle.find({ 'circle': { $in: circles } }).populate('user').exec();

    var members = [];
    //only return the members, not their UserCircle details
    for (let i = 0; i < memberCircles.length; i++) {
      var member = memberCircles[i].user;

      //console.log(memberCircles[i]);
      // console.log(memberCircles[i].user);

      if (member == null) {
        //console.log(memberCircles[i]);
        continue;
      }
      if (member._id == req.user.id) continue; //make user isn't in list already
      if (members.includes(member)) continue; //don't add duplicates

      members.push(member);
    }


    res.status(200).send({ members: members, passwordhelpers: user.passwordHelpers });
  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});


router.post('/getpasswordhelpers/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await User.findOne({ "_id": req.user.id }).populate('passwordHelpers');

    var response = await userCircleLogic.getUserCirclesParam(req.user.id, null, null, true);
    var userCircles = response[0];

    var circles = [];
    for (var i = 0; i < userCircles.length; i++) {
      if (userCircles[i].circle != null) {
        //console.log(userCircles[i]._id.toString());
        circles.push(userCircles[i].circle._id);
      }
    }

    var memberCircles = await UserCircle.find({ 'circle': { $in: circles } }).populate('user').exec();

    var members = [];
    //only return the members, not their UserCircle details
    for (let i = 0; i < memberCircles.length; i++) {
      var member = memberCircles[i].user;

      //console.log(memberCircles[i]);
      // console.log(memberCircles[i].user);

      if (member == null) {
        //console.log(memberCircles[i]);
        continue;
      }
      if (member._id == req.user.id) continue; //make user isn't in list already
      if (members.includes(member)) continue; //don't add duplicates

      members.push(member);
    }


    //res.status(200).send({ members: members, passwordhelpers: user.passwordHelpers });

    let payload = { members: members, passwordhelpers: user.passwordHelpers };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});


//Post password helpers
// router.post('/passwordhelpers/', passport.authenticate('jwt', { session: false }), async (req, res) => {

//   try {
//     //var test = req.body.test;

//     if (!req.body.build) throw ("Upgrade required before proceeding");
//     if (req.body.build < 35) throw ("Upgrade required before proceeding");


//     var passwordHelpers = req.body.passwordHelpers;

//     var user = await User.findOne({ '_id': req.user.id });

//     if (passwordHelpers.length > 0) {
//       user.passwordHelpers = [];

//       for (let i = 0; i < passwordHelpers.length; i++) {
//         user.passwordHelpers.push(passwordHelpers[i]._id);
//       }

//       await ActionRequired.deleteOne({ user: user._id, alertType: constants.ACTION_REQUIRED.SETUP_PASSWORD_ASSIST });
//       var actionRequired = await ActionRequired.find({ user: req.user.id }).populate('user').populate('resetUser').populate('member').populate({ path: 'networkRequest', populate: [{ path: 'hostedFurnace' }, { path: 'user' }] }).exec();


//       if (req.body.ratchetIndexes != undefined) {

//         let userKeyBackup = await UserKeyBackup.findOne({ user: req.user.id });

//         userKeyBackup.assistants = [];

//         //save the UserKeyBackup
//         for (let j = 0; j < req.body.ratchetIndexes.length; j++) {
//           let ratchetIndex = RatchetIndex.new(req.body.ratchetIndexes[j]);
//           userKeyBackup.assistants.push(ratchetIndex);
//         }

//         await userKeyBackup.save();
//       }

//       user.accountRecovery = true;
//       await user.save();

//     } else throw new Error("Invalid parameter");

//     res.status(200).send({ success: true, actionrequired: actionRequired });
//   } catch (err) {
//     var msg = await logUtil.logError(err, true, getIP(req));
//     return res.status(500).json({ msg: msg });
//   }

// });



//Post password helpers, POSTKYBER
router.post('/passwordhelpers/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //var test = req.body.test;

    if (!req.body.build) throw ("Upgrade required before setting password helpers");
    if (req.body.build < 35) throw ("Upgrade required before setting password helpers");


    var passwordHelpers = req.body.passwordHelpers;

    var user = await User.findOne({ '_id': req.user.id });

    if (passwordHelpers.length > 0) {
      user.passwordHelpers = [];

      for (let i = 0; i < passwordHelpers.length; i++) {
        user.passwordHelpers.push(passwordHelpers[i]._id);
      }

      await ActionRequired.deleteOne({ user: user._id, alertType: constants.ACTION_REQUIRED.SETUP_PASSWORD_ASSIST });
      var actionRequired = await ActionRequired.find({ user: req.user.id }).populate('user').populate('resetUser').populate('member').populate({ path: 'networkRequest', populate: [{ path: 'hostedFurnace' }, { path: 'user' }] }).exec();


      if (req.body.ratchetIndexes != undefined) {

        let userKeyBackup = await UserKeyBackup.findOne({ user: req.user.id });

        userKeyBackup.assistants = [];

        //save the UserKeyBackup
        for (let j = 0; j < req.body.ratchetIndexes.length; j++) {
          let ratchetIndex = RatchetIndex.new(req.body.ratchetIndexes[j]);
          userKeyBackup.assistants.push(ratchetIndex);
        }
        user.accountRecovery = true;
        await userKeyBackup.save();
      }

      await user.save();

    } else throw new Error("Invalid parameter");

    res.status(200).send({ success: true, actionrequired: actionRequired });
  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});






//post password helpers
router.post('/setpasswordhelpers/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var passwordHelpers = body.passwordHelpers;

    var user = req.user; //await User.findOne({ '_id': req.user.id });

    if (passwordHelpers.length > 0) {
      user.passwordHelpers = [];

      for (let i = 0; i < passwordHelpers.length; i++) {
        user.passwordHelpers.push(passwordHelpers[i]._id);
      }

      await ActionRequired.deleteOne({ user: user._id, alertType: constants.ACTION_REQUIRED.SETUP_PASSWORD_ASSIST });
      var actionRequired = await ActionRequired.find({ user: req.user.id }).populate('user').populate('resetUser').populate('member').populate({ path: 'networkRequest', populate: [{ path: 'hostedFurnace' }, { path: 'user' }] }).exec();


      if (body.ratchetIndexes != undefined) {

        let userKeyBackup = await UserKeyBackup.findOne({ user: req.user.id });

        userKeyBackup.assistants = [];

        //save the UserKeyBackup
        for (let j = 0; j < body.ratchetIndexes.length; j++) {
          let ratchetIndex = RatchetIndex.new(body.ratchetIndexes[j]);
          userKeyBackup.assistants.push(ratchetIndex);
        }

        await userKeyBackup.save();
      }
      user.accountRecovery = true;
      await user.save();

    } else throw new Error("Invalid parameter");

    //res.status(200).send({ success: true, actionrequired: actionRequired });
    let payload = { success: true, actionrequired: actionRequired };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});


//Return remotewipe helpers
router.post('/getremotewipehelpers', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var user = await User.findOne({ "_id": req.user.id });
    let helpers = await UserHelper.find({ user: user._id }).populate("helpers");

    var response = await userCircleLogic.getUserCirclesParam(req.user.id, null, null, true);
    var userCircles = response[0];

    var circles = [];
    for (var i = 0; i < userCircles.length; i++) {
      if (userCircles[i].circle != null) {
        circles.push(userCircles[i].circle._id);
      }
    }

    var memberCircles = await UserCircle.find({ 'circle': { $in: circles } }).populate('user').exec();

    var members = [];
    //only return the members, not their UserCircle details
    for (var i = 0; i < memberCircles.length; i++) {
      var member = memberCircles[i].user

      if (member == null) {
        continue;
      }
      if (member._id == req.user.id) continue; //make user isn't in list already
      if (members.includes(member)) continue; //don't add duplicates

      members.push(member);
    }


    // res.status(200).send({ members: members, helpers: helpers });
    let payload = { members: members, helpers: helpers };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});


//Post remote wipe helpers
router.post('/updateremotewipehelpers', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await User.findOne({ '_id': req.user.id });

    var helpers = body.helpers;

    let userHelper = new UserHelper({ user: user._id });

    if (helpers.length > 0) {


      for (let i = 0; i < helpers.length; i++) {
        userHelper.helpers.push(helpers[i]._id);
      }

      await UserHelper.deleteMany({ user: user._id });

      await userHelper.save();

      //res.status(200).send({ success: true });
      let payload = { success: true };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

      return res.status(200).json(payload);

    } else {

      await logUtil.logAlert('could not find helpers for updateremotewipehelpers', getIP(req));
      throw new Error("Unauthorized");
    }

  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

//save recovery index
router.post('/recoveryindex', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    if (body.ratchetIndex == null || body.ratchetIndex == undefined)
      throw ('Access denied');

    let ratchetIndex = RatchetIndex.new(body.ratchetIndex);
    var user = await User.findOne({ '_id': req.user.id });
    let userRecoveryIndex = new UserRecoveryIndex({ user: user, ratchetIndex: ratchetIndex });

    await ActionRequired.deleteOne({ user: user._id, alertType: constants.ACTION_REQUIRED.SETUP_PASSWORD_ASSIST });
    var actionRequired = await ActionRequired.find({ user: req.user.id }).populate('user').populate('resetUser').populate('member').populate({ path: 'networkRequest', populate: [{ path: 'hostedFurnace' }, { path: 'user' }] }).exec();

    await userRecoveryIndex.save();

    user.accountRecovery = true;
    await user.save();

    //res.status(200).send({ success: true, actionrequired: actionRequired });

    let payload = { success: true, actionrequired: actionRequired };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});


//Keys exported
router.post('/keysexported/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    var user = await User.findOne({ '_id': req.user.id });
    user.lastKeyBackup = Date.now();
    await user.save();

    await ActionRequired.deleteOne({ user: user._id, alertType: constants.ACTION_REQUIRED.EXPORT_KEYS });
    var actionRequired = await ActionRequired.find({ user: req.user.id }).populate('user').populate('resetUser').populate('member').populate({ path: 'networkRequest', populate: [{ path: 'hostedFurnace' }, { path: 'user' }] }).exec();

    //res.status(200).send({ success: true, actionrequired: actionRequired });
    let payload = { success: true, actionrequired: actionRequired };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});



async function validateParamsHash(username, passwordHash, passwordNonce, apikey, recoveryKey) {

  try {

    if (!apikey) {
      await logUtil.logAlert('no apikey in validateParamsHash');
      throw new Error('Unauthorized');
    } else if (username == null || passwordHash == null || passwordNonce == null) {
      await logUtil.logAlert('no username or password or pin in validateParamsHash');
      throw new Error('Unauthorized');
    } else {

      if (process.env.NODE_ENV !== 'production')
        require('dotenv').load();

      if (apikey != process.env.apikey) {
        await logUtil.logAlert('passed in apikey does not match process.enc');
        throw new Error('Unauthorized');
      } else {

        if (username.length > 25)
          throw new Error('Username cannot be longer than 25 chars');
        else
          return true;


      }
    }


  } catch (err) {
    console.error(err);
    throw (err);
  }

}

async function validateUsernameAndApikey(username, apikey) {

  try {

    if (!apikey) {
      await logUtil.logAlert('no apikey in validateParams');
      throw new Error('Unauthorized');
    } else {

      if (process.env.NODE_ENV !== 'production')
        require('dotenv').load();

      if (apikey != process.env.apikey) {
        await logUtil.logAlert('passed in apikey does not match process.enc');
        throw new Error('Unauthorized');
      } else {

        if (username.length > 25)
          throw new Error('Username cannot be longer than 25 chars');
        else
          return true;


      }
    }


  } catch (err) {
    console.error(err);
    throw (err);
  }

}

async function validateParams(username, password, pin, apikey, recoveryKey) {

  try {

    if (!apikey) {
      await logUtil.logAlert('no apikey in validateParams');
      throw new Error('Unauthorized');
    } else if (!username || !password || !pin) {
      await logUtil.logAlert('no username or password or pin in validateParams');
      throw new Error('Unauthorized');
    } else {

      if (process.env.NODE_ENV !== 'production')
        require('dotenv').load();

      if (apikey != process.env.apikey) {
        await logUtil.logAlert('passed in apikey does not match process.enc');
        throw new Error('Unauthorized');
      } else {

        if (username.length > 25)
          throw new Error('Username cannot be longer than 25 chars');
        else
          return true;


      }
    }


  } catch (err) {
    console.error(err);
    throw (err);
  }

}


router.put('/tos/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var user = req.user; //await User.findById(req.user.id);

    user.tos = Date.now();

    await user.save();
    //return res.status(200).json({ msg: 'Profile updates complete' });

    let payload = { msg: 'Profile updates complete' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});






// async function returnUserCirclesandCircleObjects(userID, circleLastUpdates) {

//   try {

//     let results = [];
//     let circleObjects = [];
//     let userCircles = await UserCircle.find({ user: userID, removeFromCache: null }).populate("user").populate("circle").exec();

//     for (let i = 0; i < userCircles.length; i++) {

//       if (userCircles[i].showBadge) {

//         //find the corresponding lastItemDate
//         for (let j = 0; j < circleLastUpdates.length; j++) {

//           if (userCircles[i].circle._id.equals(circleLastUpdates[j].circleID) == true) {
//             let partialResults = await circleObjectLogic.returnNewObjects(userID, circleLastUpdates[j].circleID, circleLastUpdates[j].lastFetched);

//             if (partialResults) {
//               circleObjects.push(partialResults);
//             }

//           }
//         }
//       }
//     }

//     results[0] = userCircles;
//     results[1] = circleObjects;

//     return results;

//   } catch (err) {
//     let msg = await logUtil.logError(err, true);
//     return null;
//   }

// }

async function getBuild() {
  try {
    var releases = await Release.find({}).sort({ 'build': -1 }).limit(1);

    if (!releases || releases.length == 0) {
      releases = [];
      releases.push(new Release({ build: 0 }));
      console.log('build number not detected');
    }

    return releases;

  } catch (err) {

    await logUtil.logError(err, true);
    throw (err);
  }


}


async function returnUserCircles(userID) {

  try {

    let userCircles = await UserCircle.find({ user: userID, removeFromCache: null }).populate({ path: "user", select: userFieldsToPopulate }).populate("circle").exec();

    return userCircles;

  } catch (err) {
    let msg = await logUtil.logError(err, true);
    return null;
  }

}

async function returnUserCirclesWithExpiredKeys(userID) {

  try {

    //let expiredKeys = [];

    let expiredKeys = await UserCircle.find({ user: userID, removeFromCache: null, ratchetPublicKeys: { $size: 0 } }).populate({ path: "user", select: userFieldsToPopulate }).populate("circle").exec();;

    // for (let i = 0; i < userCircles.length; i++) {

    //   let userCircle = userCircles[i];

    //   if (userCircle.ratchedPublicKeys.length == 0) {

    //     expiredKeys.push(userCircle);
    //   }
    // }

    return expiredKeys;

  } catch (err) {
    let msg = await logUtil.logError(err, true);
    return null;
  }

}


router.put('/reserveusername/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK not needed, token is enough

    var user = await User.findById(req.user.id);

    if (user.accountType == constants.ACCOUNT_TYPE.FREE) {

      throw new Error('Free user tried to reserve username');
    }

    let existingUsers = [];

    if (req.body.reserved == true) {
      await isNewUsernameReserved(user.username, user.id);  //tosses an exception if reserved
    }

    user.reservedUsername = req.body.reserved;
    await user.save();
    //return res.status(200).json({ msg: 'username reservation preference set', username: user.username });

    let payload = { msg: 'username reservation preference set', username: user.username };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

router.post('/deleteprep/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  //let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

  var user = await User.findById(req.user.id);

  if (user.hostedFurnace != null) {
    if (user.role == constants.ROLE.OWNER) {
      let members = await User.find({ _id: { $ne: user._id }, hostedFurnace: user.hostedFurnace });

      if (members.length == 0)
        return res.status(200).json({ user: user, canDelete: true });
      else

        return res.status(200).json({ user: user, canDelete: false, members: members });
    }
  }

  // return res.status(200).json({ user: user, canDelete: true });
  let payload = { user: user, canDelete: true };
  payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

  return res.status(200).json(payload);

});

router.post('/deleteaccount/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {


    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK not needed, token is enough
    var user = await User.findById(req.user.id).populate('hostedFurnace');
    let networkTransferred = false;

    if (body.override == null || body.override == undefined || body.override == false) {
      //see if the network needs to be transferred
      if (user.hostedFurnace != null) {

        if (user.role == constants.ROLE.OWNER) {
          if (body.transferUserID == null || body.transferUserID == undefined) {
            //see if there is anyone else on the network
            let members = await User.find({ _id: { $ne: user._id }, hostedFurnace: user.hostedFurnace });

            if (members.length > 0)
              throw new Error('Network must be transferred before deletion');

          } else {
            //transfer the network
            let member = await User.findById(body.transferUserID).populate('hostedFurnace');

            //validate the member is on the network
            if (member.hostedFurnace._id.equals(user.hostedFurnace._id) == false)
              throw new Error('Transferee is not on the network');

            member.role = constants.ROLE.OWNER;
            await member.save();
            networkTransferred = true;
          }
        }

      }
    } else {
      networkTransferred = true;
    }

    try {
      if (user.avatar != null && user.linkedUser == null) //don't delete a linked account avatar
        ///delete the avatar blob
        s3Util.deleteBlob(constants.BUCKET_TYPE.AVATAR, user.avatar.name);
    } catch (err) {
      console.log(err);
    }

    await Metric.updateOne({ user: user._id }, { $set: { accountDeleted: true } });

    //leave all Circles, delete all backgrounds
    userCircleLogic.deleteAllForUser(user);

    //delete all Posts (including blobs)
    circleObjectLogic.deleteAllForUser(user);

    //delete all invitations
    invitationLogic.deleteAllForUser({ 'passwordHelpers': user._id }, { $pull: { 'passwordHelpers': user._id } });

    //delete all backup keys
    keychainBackupLogic.deleteKeychainBackups(user);

    //delete from remoteWipeHelpers
    await UserHelper.updateMany({ 'helpers': user._id }, { $pull: { 'helpers': user._id } });

    //delete from passwordHelpers
    await User.updateMany({ 'passwordHelpers': user._id }, { $pull: { 'passwordHelpers': user._id } });

    //delete from connections
    await UserConnection.updateMany({ 'connections': user._id }, { $pull: { 'connections': user._id } });

    //mark the account as deleted so other users pick up the change
    user.devices = undefined;
    user.lowercase = undefined;
    user.password = '';
    user.pin = '';
    user.passwordHelpers = undefined;
    user.removeFromCache = true;
    user.linkedUser = undefined;
    user.lockedOut = true;

    //determine whether to delete the network
    if (user.hostedFurnace != null && user.role == constants.ROLE.OWNER && networkTransferred == false) {
      await HostedFurnace.deleteOne({ _id: user.hostedFurnace._id });

      /*
      //set the user's network to the deleted network default (since the IronForge is null)
      let deletedNetwork = await HostedFurnace.findOne({ lowercase: 'deleted network' });

      if (!(deletedNetwork instanceof HostedFurnace)) {
        deletedNetwork = new HostedFurnace({ name: 'Deleted Network', lowercase: 'deleted network', key: 'AS;DL*(%$%&%*KFJASDFPO;S' });
        await deletedNetwork.save();
      }
      user.hostedFurnace = deletedNetwork._id;
      */
    }

    await user.save();
    //return res.status(200).json({ msg: 'account deleted' });
    let payload = { msg: 'account deleted' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

router.post('/validatelinkedaccount/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await User.findById(body.userID);

    if (!(user instanceof User) || user.linkedUser != req.user.id || (user.lockedOut == true))
      throw new Error('Access denied');

    let token = createToken(user, body.uuid);

    let userCircles = await returnUserCircles(user._id);

    // return res.status(200).json({ msg: 'valid', token: 'JWT ' + token, userCircles: userCircles, user: user });
    let payload = { msg: 'valid', token: 'JWT ' + token, userCircles: userCircles, user: user };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});


///this function isn't needed after everyone is on 1.1.14
router.post('/identity/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    if (req.user.id != body.userID)
      return res.status(400).json({ msg: 'Access denied' });

    var user = await User.findById(req.user.id);

    var device;

    for (let i = 0; i < user.devices.length; i++) {
      if (user.devices[i].uuid == body.uuid) {

        device = user.devices[i];
        break;
      }
    }

    if (device == null)
      throw new Error('device not found to set identity');

    let payload = { msg: 'identity already set', };

    //only insert the identity for a device that doesn't have one
    if (device.identity == null || device.identity == undefined) {

      //let linkedUsers = await User.find({ linkedUser: user._id });

      device.identity = body.signatureKey;
      await user.save();

      //return res.status(200).json({ msg: 'identity update complete', });
      payload = { msg: 'identity update complete', };


    } else if (device.identity != body.signatureKey) {

      logUtil.logError('device identity mismatch: ' + device.identity + ' vs ' + body.signatureKey + ' for user ' + user._id + ' device ' + device.uuid, true, getIP(req));

      payload = { msg: 'device identity mismatch', };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(400).json(payload);
      //return res.status(400).json({ msg: 'device identity mismatch' });
    }

    // return res.status(200).json({ msg: 'identity already set', });
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});




///this function isn't needed after everyone is on 1.1.14
router.post('/clearpatternflag/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    req.user.clearPattern = false;

    await req.user.save();

    return res.status(200).json({ msg: 'reset', });


  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

///add or remove a member from the Friends list
router.put('/connected/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    if (body.connected == null || body.memberID == null) throw new Error('access denied');

    ///find the member and verify their are on the same network
    let member = await User.findOne({ _id: body.memberID, hostedFurnace: req.user.hostedFurnace });

    if (!(member instanceof User)) throw new Error('access denied');

    let userConnection = await UserConnection.findOne({ user: req.user._id });
    if (!(userConnection instanceof UserConnection)) {
      userConnection = new UserConnection({ user: req.user._id });

    }


    if (body.connected == true) {
      if (userConnection.connections.includes(member._id) == false) {
        userConnection.connections.push(member._id);
        await userConnection.save();
      }
    } else {
      if (userConnection.connections.includes(member._id) == true) {
        userConnection.connections.pull(member._id);
        await userConnection.save();
      }
    }

    //return res.status(200).json({ msg: 'done', });


    let payload = { msg: 'done', };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);



  } catch (err) {
    var msg = await logUtil.logError(err, true, getIP(req));
    return res.status(500).json({ msg: msg });
  }

});


module.exports = router;