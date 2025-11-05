const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
mongoose.Promise = require('bluebird');
const logUtil = require('../util/logutil');
const UserConnection = require('../models/userconnection');
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


router.put('/add', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let member = await User.findOne({ _id: req.body.memberID, hostedFurnace: req.user.hostedFurnace });

    if (!(member instanceof User)) {
      throw new Error('connection not found');
    }

    await UserConnection.updateOne({ 'user': req.user._id }, { $push: { 'connections': member } });

    return res.status(200).send({
      success: 'true',
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

router.put('/remove', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let member = await User.findOne({ _id: req.body.memberID, hostedFurnace: req.user.hostedFurnace });

    if (!(member instanceof User)) {
      throw new Error('connection not found');
    }

    await UserConnection.updateOne({ '_id': req.user._id }, { $pull: { 'connections': member } });

    return res.status(200).send({
      success: 'true',
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

module.exports = router;
