const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
//const securityLogic = require('../logic/securitylogic');
const securityLogic = require('../logic/securitylogicasync');
const passport = require('passport');
const Circle = require('../models/circle');
const logUtil = require('../util/logutil');
const ObjectID = require('mongodb').ObjectID;
const mongoose = require('mongoose');
const gridFS = require('../util/gridfsutil');
const kyberLogic = require('../logic/kyberlogic');
let Grid = require('gridfs-stream');
Grid.mongo = mongoose.mongo;


router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());


if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.put('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var userCircle = await securityLogic.canUserAccessCircle(req.user.id, body.circleid);
    if (!userCircle) throw new Error('access denied');

    /*
    var blob = await gridFS.saveBlobReturnBlob(req, res, "image", "circlebackgrounds", req.headers.circleid);

    //let results = await gridFS.saveBlobReturnArray(req, res, "image", "circlebackgrounds", req.headers.circleid);
    

    console.log('New circlebackground: ' + blob.id);

    //delete the old image
    if (userCircle.circle.background != null) {
      var deleteID = new ObjectID(userCircle.circle.background);

      try {
        await gridFS.deleteBlob("circlebackgrounds", deleteID);
      } catch (err) {
        console.error(err);
      }
    }
    */

    userCircle.circle.background = body.background;
    userCircle.circle.backgroundSize = body.backgroundSize;
    userCircle.circle.backgroundLocation = body.backgroundLocation;

    await userCircle.circle.save();

    // return res.status(200).json({ circle: userCircle.circle });

    let payload = { circle: userCircle.circle };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }



});



router.get('/:id&:circleid', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    //AUTHORIZATION CHECK
    var userCircle = await securityLogic.canUserAccessCircle(req.user.id, req.params.circleid);
    if (!userCircle) throw new Error('access denied');

    gridFS.loadBlob(res, "circlebackgrounds", req.params.id)
      .catch((err) => {
        console.error(err);
        return res.status(500).json({ msg: "Failed to load image" });
      });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});


module.exports = router;