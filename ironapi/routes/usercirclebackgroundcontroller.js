const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const bodyParser =  require('body-parser');
const UserCircle = require('../models/usercircle');
const passport = require('passport');
const securityLogic = require('../logic/securitylogicasync');
const kyberLogic = require('../logic/kyberlogic');
const ObjectID = require('mongodb').ObjectID;
const RatchetIndex = require('../models/ratchetindex');
const logUtil = require('../util/logutil');
router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());
const constants = require('../util/constants');
const awsLogic = require('../logic/awslogic');

/*
const { Readable } = require('stream');
const mongodb = require('mongodb');
const multer = require('multer');
const gridFS = require('../util/gridfsutil');
let Grid = require('gridfs-stream');
Grid.mongo = mongoose.mongo;
*/

router.put('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

  //AUTHORIZATION CHECK
  var usercircle = await securityLogic.canUserAccessCircle(req.user.id, body.circleid);
  if (!usercircle) return res.status(400).json({ msg: 'Access denied' });

  try {

    if (body.oldBackground != null && body.oldBackground != undefined) {

      if (usercircle.backgroundLocation == constants.BLOB_LOCATION.GRIDFS) {
          //gridFS.deleteBlob("circlebackgrounds", body.oldBackground);
      } else {
          awsLogic.deleteObject(process.env.s3_backgrounds_bucket, body.oldBackground);
      }

  }

    //update the usercircle record
    usercircle.background = body.background;
    usercircle.backgroundSize = body.backgroundSize;
    usercircle.backgroundLocation = body.backgroundLocation;
    usercircle.backgroundColor = null;

    if (body.ratchetIndex != null && body.ratchetIndex != undefined)
      usercircle.ratchetIndex= RatchetIndex.new(body.ratchetIndex);

    await usercircle.save();


    //return res.json({ success: "true"});

    let payload = { success: "true"};
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    console.error(err);
    return res.json({ success: false, msg: err });
  }

});

/*
router.get('/:id&:circleid', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //Authorization Check
    var usercircle = securityLogic.canUserAccessCircle(req.user.id, req.params.circleid);
    if (!usercircle) return res.status(400).json({ msg: 'Access denied' });

    gridFS.loadBlob(res, "usercirclebackgrounds", req.params.id)
      .catch(function (err) {
        console.error(err);
        return res.status(500).json({ msg: "Failed to load image" });
      });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: "Failed to load image" });
  }
});*/

  module.exports = router;