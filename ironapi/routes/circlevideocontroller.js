const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
mongoose.Promise = require('bluebird');
const logUtil = require('../util/logutil');
const CircleVideo = require('../models/circlevideo');
const CircleObject = require('../models/circleobject');
const passport = require('passport');
const securityLogic = require('../logic/securitylogic');
const securityLogicAsync = require('../logic/securitylogicasync');
const deviceLogic = require('../logic/devicelogic');
const gridFS = require('../util/gridfsutil');
const ObjectID = require('mongodb').ObjectID;
const constants = require('../util/constants');
const kyberLogic = require('../logic/kyberlogic');

const mongodb = require('mongodb');
let conn = mongoose.connection;
let Grid = require('gridfs-stream');
Grid.mongo = mongoose.mongo;


router.post('/movie', passport.authenticate('jwt', { session: false }), function (req, res) {

  //AUTHORIZATION CHECK
  securityLogic.canUserAccessCircleReturnUserCircle(req.user.id, req.headers.circleid, function (valid) {
    if (!valid)
      return res.status(400).json({ success: false, msg: 'Access denied' });

    //console.log("made it to post movie payload");

    var returnCircleObject;

    gridFS.saveBlob(req, res, "file", "movie")
      .then(function () {
        return CircleObject.findById({ _id: req.headers.circleobjectid }).populate("movie").populate("circle").populate("creator");
      })
      .then(function (circleObject) {

        circleObject.movie.movie = req.file.id;
        circleObject.movie.save();  //Async is ok, IDs have already been populated
        return circleObject;
      })
      .then(function (circleObject) {
        circleObject.lastUpdate = Date.now();
        return circleObject.save();  //this should update the date;

      })
      .then(function (circleObject) {

        returnCircleObject = circleObject;

        return deviceLogic.sendNotificationToCircle(req.headers.circleid, req.user.id, null);

      })
      .then(function () {
        return res.json({ success: "true", id: req.file.id, circleObject: returnCircleObject });
      })
      .catch(function (err) {
        console.error(err);
        //next(err);
        return res.json({ success: false, msg: "Failed to upload movie" });
      });
  });
});


router.post('/preview', passport.authenticate('jwt', { session: false }), function (req, res) {

  //AUTHORIZATION CHECK
  securityLogic.canUserAccessCircleReturnUserCircle(req.user.id, req.headers.circleid, function (valid) {
    if (!valid)
      return res.status(400).json({ success: false, msg: 'Access denied' });

    //make sure the parameters were passed in
    try {
      var circleID = new ObjectID(req.headers.circleid);
      var userID = new ObjectID(req.headers.userid);

    } catch (err) {
      return res.status(400).json({ success: false, msg: "Need to send parameters" });
    }

    //create the circlemovie object
    var circlemovie = new CircleMovie();

    //create the circleobject
    var circleobject = new CircleObject({
      circle: circleID,
      creator: userID,
      type: "circlemovie", 
      created: Date.now(),
    });

    gridFS.saveBlob(req, res, "image", "moviepreview")
      .then(function (id) {
        //save the circlemovie
        circlemovie.preview = id;
        circlemovie.circle = circleID;

        return circlemovie.save();
      })
      .then(function () {
        //save the circleobject
        circleobject.movie = circlemovie;
        circleobject.body = req.headers.body;
        circleobject.lastUpdate = Date.now();
        return circleobject.save();
      })
      .then(function () {
        //populate the creator for the client side cache
        return CircleObject.populate(circleobject, { path: "creator" });
      })
      .then(function () {
        //populate the creator for the client side cache
        return CircleObject.populate(circleobject, { path: "circle" });
      })
      .then(function () {
        //send a notification to the circle and return
        return deviceLogic.sendNotificationToCircle(req.headers.circleid, req.user.id, req.headers.devicetoken);
      })
      .then(function () {
        return res.status(201).json({ success: true, circleobject: circleobject, circlemovie: circlemovie });
      })
      .catch(function (err) {
        console.error(err);
        //next(err);
        return res.json({ success: false, msg: "Failed to upload preview" });
      });
  });
});

router.get('/preview/:id', passport.authenticate('jwt', { session: false }), function (req, res) {

  //AUTHORIZATION CHECK
  securityLogic.canUserAccessCircleReturnUserCircle(req.user.id, req.headers.circleid, function (valid) {
    if (!valid)
      return res.json({ success: false, msg: 'Access denied' });

    try {

      gridFS.loadBlob(res, "moviepreview", req.params.id)
        .catch(function (err) {
          console.error(err);
          //next(err);
          return res.json({ success: false, msg: "Failed to load preview" });
        });

    } catch (err) {
      return res.status(400).json({ success: false, message: "Invalid id" });
    }
  });
});

router.get('/movie/:id', passport.authenticate('jwt', { session: false }), function (req, res) {

  //console.log("download movie reached");

  //AUTHORIZATION CHECK
  securityLogic.canUserAccessCircleReturnUserCircle(req.user.id, req.headers.circleid, function (valid, usercircle) {
    if (!valid)
      return res.json({ success: false, msg: 'Access denied' });

    gridFS.loadBlob(res, "movie", req.params.id)
      .catch(function (err) {
        console.error(err);
        return res.json({ success: false, msg: "Failed to load movie" });
      });

  });
});


module.exports = router;
