const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
mongoose.Promise = require('bluebird');
const logUtil = require('../util/logutil');
const Release = require('../models/release');
const passport = require('passport');
const constants = require('../util/constants');


const mongodb = require('mongodb');
let conn = mongoose.connection;
let Grid = require('gridfs-stream');
Grid.mongo = mongoose.mongo;


if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

router.get('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var releases = await Release.find({ ready: true }).sort({ 'build': -1 });

    return res.status(200).send({
      releases: releases,
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});


router.put('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    if (req.user.role != constants.ROLE.IC_ADMIN)
      throw ("unauthorized");

    let notes = [];

    notes.push("a");
    notes.push("b");

    var release = new Release({
      version: '1.0.1+23',
      build: 23,
      notes: notes,
    });

    await release.save();


    return res.status(200).send({
      success: 'true',
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});



module.exports = router;
