const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
mongoose.Promise = require('bluebird');
const logUtil = require('../util/logutil');
const ActionRequired = require('../models/actionrequired');
const User = require('../models/user');
const passport = require('passport');
const constants = require('../util/constants');
const kyberLogic = require('../logic/kyberlogic');
const mongodb = require('mongodb');
let conn = mongoose.connection;
let Grid = require('gridfs-stream');
Grid.mongo = mongoose.mongo;


if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

router.post('/dismiss/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    if (body.id == undefined || body.id == null)
      throw new Error('Access denied');

    await ActionRequired.deleteOne({ user: req.user.id, _id: body.id });

    // return res.status(200).send({
    //   success: true
    // });

    let payload = {
      success: true
    };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});



module.exports = router;
