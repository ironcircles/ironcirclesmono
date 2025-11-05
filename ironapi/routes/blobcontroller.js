const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const CircleImage = require('../models/circleimage');
const UserCircle = require('../models/usercircle');
const User = require('../models/user');
const passport = require('passport');
const securityLogicAsync = require('../logic/securitylogicasync');
const deviceLogic = require('../logic/devicelogic');
const imageLogic = require('../logic/imagelogic');
const logUtil = require('../util/logutil');
const s3Util = require('../util/s3util');
const constants = require('../util/constants');
var randomstring = require("randomstring");
const HostedFurnace = require('../models/hostedfurnace');
const kyberLogic = require('../logic/kyberlogic');
const LogDetail = require('../models/logdetail');

const gridFS = require('../util/gridfsutil');
let Grid = require('gridfs-stream');
Grid.mongo = mongoose.mongo;

const bodyParser = require('body-parser');
router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

const ObjectID = require('mongodb').ObjectID;

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

async function getDualUploadLinks(blobtype, filename, thumbnail, hostedFurnaceStorage) {
  try {

    var urls;

    let location = process.env.blobLocation;

    if (hostedFurnaceStorage != null && hostedFurnaceStorage != undefined)
      location = hostedFurnaceStorage.location;

    if (location == constants.BLOB_LOCATION.S3 || location == constants.BLOB_LOCATION.PRIVATE_S3 || location == constants.BLOB_LOCATION.PRIVATE_WASABI)
      urls = await s3Util.getUploadLinks(blobtype, filename, thumbnail, hostedFurnaceStorage);
    else
      urls = {};

    urls.location = location;

    return urls;

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    throw (err);
  }
}

async function getDualDownloadLinks(blobtype, filename, thumbnail, hostedFurnaceStorage) {
  try {

    let urls = await s3Util.getDownloadLinks(blobtype, filename, thumbnail, hostedFurnaceStorage);

    return urls;

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    throw (err);
  }
}

//videos and images, deprecated, POSTKYBER
router.get('/uploadduallinks/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.params.id);
    if (!(usercircle instanceof UserCircle))
      throw new Error('Access denied');

    if (usercircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    let hostedFurnaceStorage = await getHostedFurnaceStorage(req.user.id);

    let urls = await getDualUploadLinks(req.headers.blobtype, req.headers.filename, req.headers.thumbnail, hostedFurnaceStorage);

    return res.status(201).json({ urls: urls });

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

router.post('/getuploadlinks/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleID);
    if (!(usercircle instanceof UserCircle))
      throw new Error('Access denied');

    if (usercircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    let hostedFurnaceStorage = await getHostedFurnaceStorage(req.user.id);

    let urls = await getDualUploadLinks(body.blobtype, body.filename, body.thumbnail, hostedFurnaceStorage);

    //return res.status(201).json({ urls: urls });

    let payload = { urls: urls };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

//videos and images, deprecated, POSTKYBER
router.get('/downloadduallinks/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircleObject(req.user.id, req.params.id);
    if (!usercircle)
      throw new Error('Access denied');

    let hostedFurnaceStorage = await getHostedFurnaceStorage(req.user.id);

    let urls = await getDualDownloadLinks(req.headers.blobtype, req.headers.filename, req.headers.thumbnail, hostedFurnaceStorage);

    return res.status(201).json({ urls: urls });

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

router.post('/getdownloadlinks/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircleObject(req.user.id, body.circleID);
    if (!usercircle)
      throw new Error('Access denied');

    let hostedFurnaceStorage = await getHostedFurnaceStorage(req.user.id);

    let urls = await getDualDownloadLinks(body.blobtype, body.filename, body.thumbnail, hostedFurnaceStorage);

    //return res.status(201).json({ urls: urls });

    let payload = { urls: urls };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});



//recipes, files, POSTKYBER
router.get('/circleobjectuploadlink/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.params.id);
    if (!(usercircle instanceof UserCircle))
      throw new Error('Access denied');

    if (usercircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    let hostedFurnaceStorage = await getHostedFurnaceStorage(req.user.id);

    let urls = await getUploadLink(req.headers.blobtype, req.headers.filename, hostedFurnaceStorage);

    return res.status(201).json({ urls: urls });

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

router.post('/getcircleobjectuploadlink/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleID);
    if (!(usercircle instanceof UserCircle))
      throw new Error('Access denied');

    if (usercircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    let hostedFurnaceStorage = await getHostedFurnaceStorage(req.user.id);

    let urls = await getUploadLink(body.blobtype, body.filename, hostedFurnaceStorage);

    //return res.status(201).json({ urls: urls });

    let payload = { urls: urls };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

//recipes, files, POSTKYBER
router.get('/circleobjectdownloadlink/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircleObject(req.user.id, req.params.id);
    if (!usercircle)
      throw new Error('Access denied');

    let hostedFurnaceStorage = await getHostedFurnaceStorage(req.user.id);
    let urls = await getDownloadLink(req.headers.blobtype, req.headers.filename, hostedFurnaceStorage);

    return res.status(201).json({ urls: urls });

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

router.post('/getcircleobjectdownloadlink/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircleObject(req.user.id, body.circleID);
    if (!usercircle)
      throw new Error('Access denied');

    let hostedFurnaceStorage = await getHostedFurnaceStorage(req.user.id);
    let urls = await getDownloadLink(body.blobtype, body.filename, hostedFurnaceStorage);

    //return res.status(201).json({ urls: urls });

    let payload = { urls: urls };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

///public network avatar from landing, POSTKYBER
router.get('/networkavatardownloadlink/', async (req, res) => {
  try {

    ///get network, check discoverable
    var network = await HostedFurnace.findById(req.headers.networkid);
    if (!(network instanceof HostedFurnace)) {
      throw new Error(("Could not find HostedFurnace"));
    }

    if (network.discoverable == true &&
      network.override == false &&
      network.approved == true) {

      let urls = await getDownloadLink(req.headers.blobtype, req.headers.filename, null);
      return res.status(201).json({ urls: urls });
    }
    return res.status(500);

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

router.get('/getnetworkavatardownloadlink/', async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    ///get network, check discoverable
    var network = await HostedFurnace.findById(body.networkid);
    if (!(network instanceof HostedFurnace)) {
      throw new Error(("Could not find HostedFurnace"));
    }

    if (network.discoverable == true &&
      network.override == false &&
      network.approved == true) {

      let urls = await getDownloadLink(body.blobtype, body.filename, null);
      //return res.status(201).json({ urls: urls });

      let payload = { urls: urls };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);

    }
    return res.status(500);

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

//keychain backups, avatars, circle backgrounds, POSTKYBER
router.get('/userdownloadlink/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    var hostedFurnaceStorage;

    //keychain storage is always on the forge
    if (req.headers.blobtype != constants.BUCKET_TYPE.KEYCHAIN_BACKUP)
      hostedFurnaceStorage = await getHostedFurnaceStorage(req.user.id);

    let urls = await getDownloadLink(req.headers.blobtype, req.headers.filename, hostedFurnaceStorage);
    return res.status(201).json({ urls: urls });

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

//keychain backups, avatars, circle backgrounds
router.post('/getuserdownloadlink/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var hostedFurnaceStorage;

    //keychain storage is always on the forge
    if (body.blobtype != constants.BUCKET_TYPE.KEYCHAIN_BACKUP)
      hostedFurnaceStorage = await getHostedFurnaceStorage(req.user.id);


    if ((body.filename == null || body.filename == undefined) && body.blobtype == constants.BUCKET_TYPE.DETAILEDLOG) {

      let detailedLog = await LogDetail.findOne({ user: req.user.id }).sort({ createdAt: -1 }).limit(1);
      if (detailedLog != null) {
        body.filename = detailedLog.blob;
      }

    }

    let urls = await getDownloadLink(body.blobtype, body.filename, hostedFurnaceStorage);
    //return res.status(201).json({ urls: urls });

    let payload = { urls: urls };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

//keychain backups, avatars, circle backgrounds, POSTKYBER
router.get('/useruploadlink/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    var hostedFurnaceStorage;

    //keychain storage is always on the forge
    if (req.headers.blobtype != constants.BUCKET_TYPE.KEYCHAIN_BACKUP && req.headers.blobtype != constants.BUCKET_TYPE.DETAILEDLOG)
      hostedFurnaceStorage = await getHostedFurnaceStorage(req.user.id);

    let urls = await getUploadLink(req.headers.blobtype, req.headers.filename, hostedFurnaceStorage);

    return res.status(201).json({ urls: urls });

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

router.post('/getuseruploadlink/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var hostedFurnaceStorage;

    //keychain storage is always on the forge
    if (body.blobtype != constants.BUCKET_TYPE.KEYCHAIN_BACKUP && body.blobtype != constants.BUCKET_TYPE.DETAILEDLOG)
      hostedFurnaceStorage = await getHostedFurnaceStorage(req.user.id);

    let urls = await getUploadLink(body.blobtype, body.filename, hostedFurnaceStorage);

    //return res.status(201).json({ urls: urls });

    let payload = { urls: urls };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true, logUtil.getIP(req));
    return res.status(500).json({ msg: msg });
  }

});

async function getHostedFurnaceStorage(userID) {
  let user = await User.findById(userID).populate("hostedFurnace");

  if (user.hostedFurnace != null) {
    if (user.hostedFurnace.storage != null)
      if (user.hostedFurnace.storage.length > 0)
        return user.hostedFurnace.storage[user.hostedFurnace.storage.length - 1];

  }

  return null;
}

async function getUploadLink(blobtype, filename, hostedFurnaceStorage) {
  try {

    var urls;

    let location = process.env.blobLocation;

    if (hostedFurnaceStorage != null && hostedFurnaceStorage != undefined)
      location = hostedFurnaceStorage.location;

    if (location == constants.BLOB_LOCATION.S3 || location == constants.BLOB_LOCATION.PRIVATE_S3 || location == constants.BLOB_LOCATION.PRIVATE_WASABI)
      urls = await s3Util.getUploadLink(blobtype, filename, hostedFurnaceStorage);
    else
      urls = {};

    urls.location = location;

    return urls;

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    throw (err);
  }
}

async function getDownloadLink(blobtype, filename, hostedFurnaceStorage) {
  try {

    //only called to get S3, not GRIDFS
    let urls = await s3Util.getDownloadLink(blobtype, filename, hostedFurnaceStorage);

    return urls;

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    throw (err);
  }
}


module.exports = router;


/*
async function authorizationCheck(type, userID, id) {
  try {
    //AUTHORIZATION CHECK
    if (type == constants.BLOB_TYPE.CIRCLE) {

      var usercircle = await securityLogicAsync.canUserAccessCircle(userID, id);
      if (!usercircle)
        throw new Error('access denied');
    } else if (type == constants.BLOB_TYPE.USER) {
      if (userID != id)  //this is unnecessary, user has been authenticated through token
        throw new Error('access denied');
    } else {
      throw new Error('access denied');
    }

    return;

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    throw (err);
  }
}*/