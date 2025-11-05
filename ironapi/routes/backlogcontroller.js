const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
mongoose.Promise = require('bluebird');
const logUtil = require('../util/logutil');
const Backlog = require('../models/backlog');
const DeviceLogic = require('../logic/devicelogic');
const BacklogReply = require('../models/backlogreply');
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

var userFieldsToPopulate = '_id username role';

router.get('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var backlog;

    if (req.user.role == constants.ROLE.IC_ADMIN) {
      backlog = await Backlog.find({ $or: [{ status: 'open' }, { status: 'resolved' }, { status: 'in review' }, { status: 'in progress' }, { $and: [{ status: { $ne: 'closed' } }, { creator: req.user.id }] }] }).sort({ 'created': -1 })
        .populate('creator').populate('upVotes').populate({ path: "replies", populate: { path: 'user', select: userFieldsToPopulate } });

    } else {

      backlog = await Backlog.find({ $or: [{ status: 'open' }, { status: 'resolved' },  { status: 'in progress' }, { $and: [{ status: { $ne: 'closed' } }, { creator: req.user.id }] }] }).sort({ 'created': -1 })
        .populate('creator').populate('upVotes').populate({ path: "replies", populate: { path: 'user', select: userFieldsToPopulate } });
      //var backlog = await Backlog.find({ $and: [{ $and: [{ status: { $ne: 'closed' }, status: { $ne: 'in review' } }] }, { $and: [{ status: { $ne: 'closed' } }, { creator: req.user.id }] }] }).sort({ 'created': -1 }).populate('creator').populate('upVotes');
    }

    for (let i = 0; i < backlog.length; i++) {
      backlog[i].upVotesCount = backlog[i].upVotes.length;
    }

    return res.status(200).send({
      backlog: backlog,
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});


router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let backlog = await Backlog.new(req.body.backlog);

    backlog.status = "in review"; //don't trust the message body
    backlog.creator = req.user.id;
    backlog.upVotes.push(req.user.id);

    await backlog.save();

    await backlog.populate(['creator', 'upVotes', 'replies']);

    if (req.user.role != constants.ROLE.IC_ADMIN) {
      ///send a notification to the IronCircles admins
      let icAdmins = await User.find({ role: constants.ROLE.IC_ADMIN });
      for (let i = 0; i < icAdmins.length; i++) {
        let icAdmin = icAdmins[i];
        DeviceLogic.sendNotification(icAdmin, 'New Backlog Item', constants.NOTIFICATION_TYPE.BACKLOG_ITEM);
      }
    }

    return res.status(200).send({
      backlog: backlog,
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});


router.put('/reply/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    ///load the backlog
    let backlog = await Backlog.findById(req.body.backlogID).populate('creator').populate('upVotes').populate('replies');

    if (!(backlog instanceof Backlog)) {
      throw new Error('Unauthorized');
    }

    if (backlog.creator._id.equals(req.user.id) == false && req.user.role != constants.ROLE.IC_ADMIN) {
      throw new Error('Unauthorized');
    }

    let backlogReply = new BacklogReply({ reply: req.body.reply, user: req.user });
    await backlogReply.save();

    backlog.replies.push(backlogReply);

    await backlog.save();

    await backlog.populate(['creator', 'upVotes', { path: "replies", populate: { path: 'user', select: userFieldsToPopulate } }]);

    if (req.user.role != constants.ROLE.IC_ADMIN) {
      ///send a notification to the IronCircles admins
      let icAdmins = await User.find({ role: constants.ROLE.IC_ADMIN });
      for (let i = 0; i < icAdmins.length; i++) {
        let icAdmin = icAdmins[i];
        DeviceLogic.sendNotification(icAdmin, 'New reply to backlog item', constants.NOTIFICATION_TYPE.BACKLOG_REPLY);
      }
    } else {

      //only send a notification to the creator if the creator is on build 119
      let devices = backlog.creator.devices;

      let found = false;

      for (let i = 0; i < devices.length; i++) {
        let device = devices[i];
        if (device.build >= 119) {
          found = true;
          break;
        }
      }

      if (found) {
        DeviceLogic.sendNotification(backlog.creator, 'IronCircles has replied to your request', constants.NOTIFICATION_TYPE.BACKLOG_REPLY);
      }
    }


    return res.status(200).send({
      backlog: backlog, reply: backlogReply
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});


//up or down vote
router.put('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {


    let backlog = await Backlog.findById(req.params.id).populate('creator').populate('upVotes').populate('replies');

    if (backlog.creator._id.equals(req.user.id)) {
      throw new Error('Creator cannot modify vote');
    }


    let found = false;
    for (let i = 0; i < backlog.upVotes.length; i++) {
      if (backlog.upVotes[i]._id.equals(req.user.id)) {
        found = true;
        break;
      }

    }

    if (found)
      backlog.upVotes.pull({ _id: req.user.id });
    else
      backlog.upVotes.push(req.user.id);

    await backlog.save();

    // await backlog.populate('creator').populate('upVotes').execPopulate();

    return res.status(200).send({
      msg: 'success',
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});


module.exports = router;
