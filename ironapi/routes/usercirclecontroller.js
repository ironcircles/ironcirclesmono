const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const passport = require('passport');
const UserCircle = require('../models/usercircle');
const User = require('../models/user');
const CircleObject = require('../models/circleobject');
const usercircleLogic = require('../logic/usercirclelogic');
const securityLogic = require('../logic/securitylogic');
const securityLogicAsync = require('../logic/securitylogicasync');
const logUtil = require('../util/logutil');
const actionrequired = require('../models/actionrequired');
const Release = require('../models/release');
const RatchetPublicKey = require('../models/ratchetpublickey');
const RatchetIndex = require('../models/ratchetindex');
const metricLogic = require('../logic/metriclogic');
const SwipePatternAttempt = require('../models/swipepatternattempt');
const IronCoinWallet = require('../models/ironcoinwallet');
const kyberLogic = require('../logic/kyberlogic');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

let userFieldsToPopulate = '_id username lowercase avatar accountType';

//find by circleid
router.delete('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //Authorization Check
    var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.params.id);

    if (!userCircle) return res.status(400).json({ msg: 'Access denied' });

    var success = await usercircleLogic.deactivateUserCircle(userCircle);

    return res.status(200).json({ msg: success });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).send({ msg: msg });
  }

});

///DEPRECATED, USE POST BELOW, REMOVE POSTKYBER
router.get('/:id', passport.authenticate('jwt', { session: false }), function (req, res) {

  try {
    //Authorization Check
    securityLogic.canUserAccessCircle(req.user.id, req.params.id, function (valid) {
      if (!valid)
        return res.status(400).json({ msg: 'Access denied' });

      UserCircle.findOne({ circle: req.params.id, user: req.user.id }, function (err, usercircle) {
        if (err)
          return res.status(400).send({ msg: "There was a problem finding the usercircle." });


        res.status(200).json({
          usercircle: usercircle,
          msg: 'Successful loaded usercircle.'
        });

      }).populate("circle").populate({ path: "user", select: userFieldsToPopulate }).populate({ path: "dm", select: userFieldsToPopulate });

    });
  } catch (err) {
    console.error(err);
    return res.status(500).send({ msg: err });
  }

});

//find by circleID
router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);
    //Authorization Check
    var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleID);

    if (!userCircle) return res.status(400).json({ msg: 'Access denied' });

    // res.status(200).json({
    //   usercircle: userCircle,
    //   msg: 'Successful loaded usercircle.'
    // });

    let payload = {
      usercircle: userCircle,
      msg: 'Successful loaded usercircle.'
    };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);


  } catch (err) {
    console.error(err);
    return res.status(500).send({ msg: err });
  }

});


//update usercircle
router.post('/setlastaccessed/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //Authorization Check
    var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleID);
    if (!userCircle) return res.status(400).json({ msg: 'Access denied' });

    if (body.lastAccessed == null || body.lastAccessed == undefined) {
      throw new Error('access denied');
    }

    //if (req.body.lastAccessed > userCircle.lastAccessed) {  //weird timing thing with reacting and leaving a circle too soon
    userCircle.lastAccessed = body.lastAccessed;

    userCircle.showBadge = false;

    await userCircle.save();

    userCircle = await getLastAccess(userCircle);
    //}


    let payload = { usercircle: userCircle, msg: 'Successful updated circle settings.' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    //return res.status(200).json({ usercircle: userCircle, msg: 'Successful updated circle settings.' });
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).send({ msg: msg });
  }

});

//update usercircle
router.put('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let id = req.params.id;

    if (req.params.id == 'undefined') {
      id = body.id;
    }

    //Authorization Check
    var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, id);
    if (!userCircle) return res.status(400).json({ msg: 'Access denied' });

    if (body.setPrefName != undefined) {
      userCircle.ratchetIndex = RatchetIndex.new(body.ratchetIndex);
      userCircle.prefName = undefined;
    }

    if (body.hidden != undefined)
      userCircle.hidden = body.hidden;

    if (body.guarded != undefined) {
      userCircle.guarded = body.guarded;

      if (body.guarded == false) {
        userCircle.guardedOpen = undefined;
        userCircle.guardedPin = undefined;
      } else {
        if (body.guardedPin != undefined)
          userCircle.guardedPin = body.guardedPin;
      }

    }

    if (body.hiddenOpen == false)
      userCircle.hiddenOpen = undefined;

    if (body.pinnedOrder != undefined)
      userCircle.pinnedOrder = body.pinnedOrder;

    if (body.hiddenPassphrase != undefined)
      userCircle.hiddenPassphrase = body.hiddenPassphrase;

    if (body.lastAccessed != undefined) {
      if (body.lastAccessed > userCircle.lastAccessed)  //weird timing thing with reacting and leaving a circle too soon
        userCircle.lastAccessed = body.lastAccessed;

    } else
      userCircle.lastAccessed = Date.now();

    await userCircle.save();

    userCircle = await getLastAccess(userCircle);

    //return res.status(200).json({ usercircle: userCircle, msg: 'Successful updated circle settings.' });

    let payload = { usercircle: userCircle, msg: 'Successful updated circle settings.' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).send({ msg: msg });
  }

});

//update usercircle
router.put('/muted/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let id = req.params.id;

    if (req.params.id == 'undefined') {
      id = body.id;
    }

    //Authorization Check
    var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, id);
    if (!userCircle) return res.status(400).json({ msg: 'Access denied' });

    userCircle.muted = body.muted;

    await UserCircle.updateOne({ _id: userCircle._id }, { muted: body.muted });

    userCircle = await getLastAccess(userCircle);

    // return res.status(200).json({ usercircle: userCircle, msg: 'Successful updated circle settings.' });

    let payload = { usercircle: userCircle, msg: 'Successful updated circle settings.' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).send({ msg: msg });
  }

});

//update usercircle
router.put('/backgroundcolor/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let id = req.params.id;

    if (req.params.id == 'undefined') {
      id = body.id;
    }

    //Authorization Check
    var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, id);
    if (!userCircle) return res.status(400).json({ msg: 'Access denied' });

    userCircle.backgroundColor = req.body.backgroundColor;
    userCircle.background = null;
    userCircle.backgroundLocation = null;
    userCircle.backgroundSize = null;
    await UserCircle.updateOne({ _id: userCircle._id }, { backgroundColor: body.backgroundColor });

    userCircle = await getLastAccess(userCircle);

    //return res.status(200).json({ usercircle: userCircle, msg: 'Successful updated circle color.' });

    let payload = { usercircle: userCircle, msg: 'Successful updated circle settings.' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).send({ msg: msg });
  }

});

//update usercircle
router.put('/closed/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let id = req.params.id;

    if (req.params.id == 'undefined') {
      id = body.id;
    }

    //Authorization Check
    var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, id);
    if (!userCircle) return res.status(400).json({ msg: 'Access denied' });

    await UserCircle.updateOne({ _id: userCircle._id }, { muted: body.closed, closed: body.closed });

    userCircle = await getLastAccess(userCircle);
    userCircle.muted = body.closed;
    userCircle.closed = body.closed;


    //return res.status(200).json({ usercircle: userCircle, msg: 'Successful updated circle settings.' });
    let payload = { usercircle: userCircle, msg: 'Successful updated circle settings.' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).send({ msg: msg });
  }

});

async function getLastAccess(usercircle) {
  try {

    let circleObject = await CircleObject.findOne({ circle: usercircle.circle, type: { $ne: 'deleted' } }).sort({ lastUpdate: -1 }).limit(1);

    if (usercircle.lastItemUpdate == null || usercircle.lastItemUpdate == undefined) {
      ///beginning of IC time
      usercircle.lastItemUpdate = "2018-01-01T00:00:00.000Z";
    }

    if (circleObject instanceof CircleObject) {
      usercircle.lastItemUpdate = circleObject.lastUpdate;
    }

    return usercircle;

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).send({ msg: msg });
  }

}

/*
function getLastAccess(usercircle) {
  return new Promise(function (resolve, reject) {


    CircleObject.findOne({ circle: usercircle.circle, type: { $ne: 'deleted' } }, function (err, circleobject) {

      if (err) {
        console.error(err);
        return reject();
      }

      //console.log('circleobject: ' + circleobject);
      usercircle.lastItemUpdate = "2018-01-01T00:00:00.000Z";
      //usercircle.showBadge = false;

      if (circleobject) {
        usercircle.lastItemUpdate = circleobject.lastUpdate;

        //if (circleobject.creator != usercircle.user) {//if the user did not create the last post
        //usercircle.showBadge = (usercircle.lastItemUpdate > usercircle.lastAccessed);
        //}
      }


      return resolve(usercircle);

    }).sort({ lastUpdate: -1 }).limit(1);
  });

}*/



//This is really a get, needed a body
router.post('/history', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {


    //let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let start = new Date(Date.now()).toLocaleTimeString();

    await req.user.populate(['blockedList', 'hostedFurnace']);

    var arrayResponse = await usercircleLogic.getUserCirclesHistory(req.user);


    //console.log('Fetch usercircles history start: '  + start + ' and end: ' + new Date(Date.now()).toLocaleTimeString() + ' for user: ' + req.user.id);

    if (arrayResponse != null) {

      // return res.status(200).send({
      //   usercircles: arrayResponse[0],
      //   members: arrayResponse[1],
      //   memberCircles: arrayResponse[2],
      //   userConnections: arrayResponse[3],
      //   user: req.user,
      // });

      let payload = {
        usercircles: arrayResponse[0],
        members: arrayResponse[1],
        memberCircles: arrayResponse[2],
        userConnections: arrayResponse[3],
        user: req.user,
      };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

      return res.status(200).json(payload);

    } else {
      throw new Error('No history found');

    }
  } catch (err) {
    var msg = await logUtil.logError(err);
    return res.status(500).json({ msg: msg });
  }

});

//This is really a get, needed a body
router.post('/byuser', passport.authenticate('jwt', { session: false }), async (req, res) => {


  try {


    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);
    //let start = new Date(Date.now());
    //console.log('Fetch usercircles start: ' + start.toLocaleTimeString() + ' for user: ' + req.user.id);

    await req.user.populate(['blockedList', 'hostedFurnace']);

    var arrayResponse = await usercircleLogic.getUserCircles(req.user, body.deviceid, body.openguarded);

    if (arrayResponse != null) {

      if (arrayResponse[0].length > 0) {
        let user = arrayResponse[0][0].user;
        metricLogic.setLastAccessed(user);
      }

      var releases = await Release.find({}).sort({ 'build': -1 }).limit(1);

      if (!releases || releases.length == 0) {
        releases = [];
        releases.push(new Release({ build: 0 }));
        console.log('build number not detected');
      }

      var payload;

      if (req.user.linkedUser == null || req.user.linkedUser == undefined) {
        let wallet = await IronCoinWallet.findOne({ user: req.user.id });

        payload = {
          usercircles: arrayResponse[0],
          invitations: arrayResponse[1],
          actionrequired: arrayResponse[2],
          members: arrayResponse[3],
          memberCircles: arrayResponse[4],
          latestBuild: releases[0].build,
          circleobjects: arrayResponse[5],
          userConnections: arrayResponse[7],
          user: req.user,
          coins: wallet.balance,
        };

      } else {

        payload = {
          usercircles: arrayResponse[0],
          invitations: arrayResponse[1],
          actionrequired: arrayResponse[2],
          members: arrayResponse[3],
          memberCircles: arrayResponse[4],
          latestBuild: releases[0].build,
          circleobjects: arrayResponse[5],
          userConnections: arrayResponse[7],
          user: req.user,
        };
      }


      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

      return res.status(200).send(payload);

    } else {
      throw new Error('No usercircles found');

    }
  } catch (err) {
    var msg = await logUtil.logError(err);
    return res.status(500).json({ msg: msg });
  }

});

// /* Deprecated in 1.0.1+31 */
// router.post('/user', passport.authenticate('jwt', { session: false }), async (req, res) => {

//   try {

//     let start = new Date(Date.now());
//     console.log('Fetch usercircles start: ' + start.toLocaleTimeString());

//     var arrayResponse = await usercircleLogic.getUserCirclesAndObjects_deprecated(req.user._id, req.body.openguarded, req.body.circlelastupdates);

//     if (arrayResponse != null) {

//       let end = new Date(Date.now());
//       console.log('Fetch usercircles end: ' + end.toLocaleTimeString());
//       var releases = await Release.find({}).sort({ 'build': -1 }).limit(1);

//       return res.status(200).send({
//         usercircles: arrayResponse[0],
//         invitationcount: arrayResponse[1],
//         actionrequired: arrayResponse[2],
//         circleobjects: arrayResponse[3], latestBuild: releases[0].build
//       });



//     } else {
//       throw new Error('No usercircles found');

//     }
//   } catch (err) {
//     var msg = await logUtil.logError(err);
//     return res.status(500).json({ msg: msg });
//   }

// });


// Sets hiddenOpen for a UserCircle (passcode was validated on the device)
router.post('/tempopen/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //SECURITY CHECK
    if (!body.usercircles)
      return res.status(400).json({ msg: 'Access denied' });

    for (let i = 0; i < body.usercircles.length; i++) {

      let userCircle = await UserCircle.findOne({ _id: body.usercircles[i], user: req.user.id });

      if (!userCircle) continue;  //Authorization check
      if (!userCircle instanceof UserCircle) continue;

      if (userCircle.hiddenOpen == undefined)
        userCircle.hiddenOpen = new Array();

      userCircle.hiddenOpen.push(body.device);
      await userCircle.save();

    }

    //return res.status(200).json({ found: true });

    let payload = { found: true };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);



  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});

///DEPRECATED, USE POST BELOW, REMOVE POSTKYBER
router.get('/hiddencircle/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //SECURITY CHECK
    if (req.user.id != req.params.id)
      return res.status(400).json({ msg: 'Access denied' });

    var usercircles = await usercircleLogic.getCirclesFromPassphrase(req.user.id, req.headers.passphrase);

    if (usercircles.length > 0) {
      usercircles = await populateLastAccess(usercircles, req.user.id, true);

      for (let index = 0; index < usercircles.length; index++) {

        //usercircles[index].hiddenOpen = undefined;

        if (usercircles[index].hiddenOpen == undefined)
          usercircles[index].hiddenOpen = new Array();

        usercircles[index].hiddenOpen.push(req.headers.device);
        await usercircles[index].save();

      }


      return res.status(200).json({ found: true, usercircles: usercircles });
    } else {
      return res.status(200).json({ found: false });
    }


  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});

// Returns hidden circles by passphrase
router.post('/hiddencircle/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var usercircles = await usercircleLogic.getCirclesFromPassphrase(req.user.id, body.passphrase);

    let payload = { found: false }

    if (usercircles.length > 0) {
      usercircles = await populateLastAccess(usercircles, req.user.id, true);

      for (let index = 0; index < usercircles.length; index++) {

        //usercircles[index].hiddenOpen = undefined;

        if (usercircles[index].hiddenOpen == undefined)
          usercircles[index].hiddenOpen = new Array();

        usercircles[index].hiddenOpen.push(body.device);
        await usercircles[index].save();

      }

      payload = { found: true, usercircles: usercircles };
    } 


    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);



  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});


async function populateLastAccess(usercircles, userid) {

  try {

    //return the activity for the circle since the user last visited
    for (let index = 0; index < usercircles.length; index++) {
      // await usercircles.forEach(async function (usercircle) {

      let usercircle = usercircles[index];

      var circleobject = await CircleObject.findOne({ "circle": usercircle.circle, type: { $ne: 'deleted' } }).sort({ lastUpdate: -1 }).limit(1).exec(); //, function (err, circleobject) {

      usercircle.lastItemUpdate = "2018-01-01T00:00:00.000Z";
      //usercircle.showBadge = false;

      if (circleobject) {
        usercircle.lastItemUpdate = circleobject.lastUpdate;

        //if (circleobject.creator != userid) {
        //usercircle.showBadge = (usercircle.lastItemUpdate > usercircle.lastAccessed);
        //}
      }

    }//);//.sort({ lastUpdate: -1 }).limit(1);

    return usercircles;


  } catch (err) {

    logUtil.logError(err, true);
    return usercircles;
  }




}



// /******* Deprecated after 1.0.1+16 ***/
// // Close any open closed circles
// router.put('/closeopenguarded/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

//   try {

//     //only close open hidden for the authenticated user
//     await UserCircle.updateMany({ user: req.user.id }, { hiddenOpen: undefined });

//     return res.status(200).json({ msg: "success" });

//   } catch (err) {

//     var msg = await logUtil.logError(err, true);
//     return res.status(500).json({ msg: msg });
//   }
// });

// Close any open closed circles
router.put('/closeopenhidden/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);


    if (body.device == undefined || body.device == null) {
      await UserCircle.updateMany({ user: req.user.id }, { hiddenOpen: null });

    } else {

      await usercircleLogic.closeOpenHiddenPerDevice(req.user.id, body.device);
    }

    // return res.status(200).json({ msg: "success" });


    let payload = { msg: "success" };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});

router.post('/swipe-attempt/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let swipePatternAttempt = new SwipePatternAttempt();
    swipePatternAttempt.circle = body.circle;
    swipePatternAttempt.user = body.user;
    swipePatternAttempt.device = body.device;
    swipePatternAttempt.attemptDate = body.attemptDate;

    await swipePatternAttempt.save();

    //    return res.status(200).json({ msg: "success" })
    let payload = { msg: "success" };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);
  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
}
);

///DEPRECATED, USE POST BELOW, REMOVE POSTKYBER
router.get('/swipe-attempts/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var today = new Date();
    var minDate = new Date(new Date().setDate(today.getDate() - 30));

    let swipePatternAttempts = await SwipePatternAttempt.find({ user: req.user.id, attemptDate: { $gte: minDate } }).populate('circle');

    res.status(200).send({ swipePatternAttempts: swipePatternAttempts });


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});


router.post('/swipe-attempts/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    //let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);
    var today = new Date();
    var minDate = new Date(new Date().setDate(today.getDate() - 30));

    let swipePatternAttempts = await SwipePatternAttempt.find({ user: req.user.id, attemptDate: { $gte: minDate } }).populate('circle');


    let payload = { swipePatternAttempts: swipePatternAttempts };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});

module.exports = router;