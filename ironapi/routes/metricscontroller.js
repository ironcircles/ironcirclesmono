const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const CircleImage = require('../models/circleimage');
const CircleObject = require('../models/circleobject');
const Circle = require('../models/circle');
const User = require('../models/user');
const Metrics = require('../models/metric');
const Subscription = require('../models/subscription');
var ActionRequired = require('../models/actionrequired');
const passport = require('passport');
const securityLogic = require('../logic/securitylogic');
const deviceLogic = require('../logic/devicelogic');
const constants = require('../util/constants');
const logUtil = require('../util/logutil');
var randomstring = require("randomstring");
const kyberLogic = require('../logic/kyberlogic');

const gridFS = require('../util/gridfsutil');
let Grid = require('gridfs-stream');
Grid.mongo = mongoose.mongo;


//const bodyParser =  require('body-parser');
const ObjectID = require('mongodb').ObjectId;
const UserCircle = require('../models/usercircle');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

const day = 1000 * 60 * 60 * 24;

/*
class Metric {
  constructor({username, lastAccessed, recentMessageCount }) {
  
    this.username = username;
    this.lastAccessed = lastAccessed;
    this.recentMessageCount = recentMessageCount;
  }

}
*/


router.get('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let ninety = new Date(Date.now() - day * 90);
    let fourteen = new Date(Date.now() - day * 14);
    let seven = new Date(Date.now() - day * 7);

    let validUser = await User.findById(req.user.id);


    if (validUser.role != constants.ROLE.IC_ADMIN)
      throw ("Unauthorized");

    /*let excludeArray = [
      '63e58df8660eaa190f97dc7c',
      '63e5811809d5c6121a565cc0',
    ];*/

    let accountsDeleted = await User.countDocuments({ removeFromCache: { $ne: null } });
    let subscriptionCount = await Subscription.countDocuments({ status: 1 });

    let metrics = await Metrics.find({ lastAccessed: { $gte: ninety, }, accountDeleted: { $ne: true }/*, user: { $nin: excludeArray }*/ }).sort({ lastAccessed: -1 }).populate({ path: 'user', populate: { path: 'hostedFurnace' } });
    let metricsLastFourteen = await Metrics.countDocuments({ lastAccessed: { $gte: fourteen, }, created: { $lte: seven }, accountDeleted: { $ne: true } }).sort({ lastAccessed: -1 }).populate({ path: 'user', populate: { path: 'hostedFurnace' } });

    return res.status(200).json({ metrics: metrics, metricsLastFourteen: metricsLastFourteen, subscriptionCount: subscriptionCount, accountsDeleted: accountsDeleted });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }

});


module.exports = router;