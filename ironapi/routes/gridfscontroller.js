/*const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const CircleImage = require('../models/circleimage');
const CircleObject = require('../models/circleobject');
const passport = require('passport');
const securityLogic = require('../logic/securitylogic');
const securityLogicAsync = require('../logic/securitylogicasync');
const deviceLogic = require('../logic/devicelogic');
const imageLogic = require('../logic/imagelogic');
const circleObjectLogic = require('../logic/circleobjectlogic');
const logUtil = require('../util/logutil');
const s3Util = require('../util/s3util');
var multer = require('multer');
const authUtil = require('../util/authutil');
//var upload = multer();
let GridFSStorage = require('multer-gridfs-storage');

const gridFS = require('../util/gridfsutil');
let Grid = require('gridfs-stream');
Grid.mongo = mongoose.mongo;
let conn = mongoose.connection;

const bodyParser = require('body-parser');
router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

const ObjectID = require('mongodb').ObjectID;
const { db } = require('../models/circleimage');
const { DataSync } = require('aws-sdk');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}


function getBuckets(type) {

  var buckets = new Buckets();

  buckets.thumbnail = 'thumbnails';
  buckets.full = 'fullimages';

  if (type) {
    if (type != 'circleimage') {

      buckets.thumbnail = type + "Thumbnail";
      buckets.full = type + "Full";

    }
  }

  return buckets;
}


router.post('/dual', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var buckets = getBuckets(req.headers.type);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.headers.authid);

    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });


    let results = await gridFS.saveDual(buckets.thumbnail, buckets.full, req, res, req.headers.authid);

    return res.status(200).json({ "full": results.full, "thumbnail": results.thumbnail });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }
});

router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var buckets = getBuckets(req.headers.type);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.headers.authid);

    if (!usercircle)
      return res.status(400).json({ err: 'Access denied' });

    let results = await gridFS.saveBlob(req, res, "full", buckets.full, req.headers.authid);

    return res.status(200).json({ "full": results });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }
});

router.put('/populatecircle', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let circleImages = await CircleImage.find({ circle: undefined });  //.populate('image').exec();

    console.log(circleImages.length);

    for (let i = 0; i < circleImages.length; i++) {

      console.log(i);

      let circleObject = await CircleObject.find({ image: circleImages[i]._id });

      if (!circleObject) {

        circleImages[i].circle = circleObject.circle;

        await circleImages[i].save();

      } else {
        console.log(circleImages[i]._id);
      }
    }

    return res.status(200).json({ "done": "done" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }
});

router.get('/circleobjectthumbnail/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //AUTHORIZATION CHECK
    await securityLogicAsync.canUserAccessCircleObject(req.user.id, req.headers.authid);

    //does the item exist?


    var buckets = getBuckets(req.headers.type);

    await gridFS.loadBlob(res, buckets.thumbnail, req.params.id);

  } catch (err) {
    console.error(err + ' gridfs_controller');
    return res.status(500).json({ msg: err });
  }
});

router.get('/circleobjectfull/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //AUTHORIZATION CHECK
    await securityLogicAsync.canUserAccessCircleObject(req.user.id, req.headers.authid);

    var buckets = getBuckets(req.headers.type);

    await gridFS.loadBlob(res, buckets.full, req.params.id);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }
});





class Buckets {
  constructor() {
  }

  set thumbnail(thumbnail) {
    this._thumbnail = thumbnail;
  }
  get thumbnail() {
    return this._thumbnail;
  }

  set full(full) {
    this._full = full;
  }
  get full() {
    return this._full;
  }
}

module.exports = router;
*/