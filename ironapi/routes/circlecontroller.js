const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const usercircleLogic = require('../logic/usercirclelogic');
const systemmessageLogic = require('../logic/systemmessagelogic');
const securityLogic = require('../logic/securitylogic');
const securityLogicAsync = require('../logic/securitylogicasync');
const circleLogic = require('../logic/circlelogic');
const circleSettingLogic = require('../logic/circlesettinglogic');
const deviceLogicSingle = require('../logic/devicelogicsingle');
const passport = require('passport');
const Circle = require('../models/circle');
const User = require('../models/user');
const CircleObject = require('../models/circleobject');
const UserCircle = require('../models/usercircle');
const Invitation = require('../models/invitation');
const constants = require('../util/constants');
const logUtil = require('../util/logutil');
const mongoose = require('mongoose');
const gridFS = require('../util/gridfsutil');
let Grid = require('gridfs-stream');
const RatchetPublicKey = require('../models/ratchetpublickey');
const RatchetIndex = require('../models/ratchetindex');
const { ObjectId } = require('mongodb');
const invitation = require('../models/invitation');
const circlerecipe = require('../models/circlerecipe');
const kyberLogic = require('../logic/kyberlogic');
const ratchetKeyLogic = require('../logic/ratchetkeylogic');

Grid.mongo = mongoose.mongo;

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());


///REMOVE POSTKYBER
router.get('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.params.id);

    if (!userCircle) throw ("Access denied");

    let circle = await Circle.findById(req.params.id); //.populate("owner").exec();

    if (!(circle instanceof Circle)) throw new Error("Could not find circle");

    let memberCount = await circleLogic.memberCount(circle);

    let ratchetPublicKeys = await ratchetKeyLogic.getPublicKeys(req.user.id, req.params.circleid);

    return res.status(200).json({ circle: circle, memberCount: memberCount, ratchetPublicKeys: ratchetPublicKeys });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });

  }

});

router.post('/getcircle', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleID);

    if (!userCircle) throw ("Access denied");

    let circle = await Circle.findById(body.circleID); //.populate("owner").exec();

    if (!(circle instanceof Circle)) throw new Error("Could not find circle");

    let memberCount = await circleLogic.memberCount(circle);

    let ratchetPublicKeys = await ratchetKeyLogic.getPublicKeys(req.user.id, body.circleID);

    //return res.status(200).json({ circle: circle, memberCount: memberCount });

    if (body.lastAccessed != null && body.lastAccessed != undefined) {

      if (userCircle.lastAccessed < body.lastAccessed) {
        userCircle.lastAccessed = body.lastAccessed;
        await userCircle.save();
      }
    }

    let payload = { circle: circle, memberCount: memberCount, ratchetPublicKeys: ratchetPublicKeys };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });

  }

});


// router.put('/:id', passport.authenticate('jwt', { session: false }), function (req, res) {

//   securityLogic.canUserAccessCircle(req.user.id, req.params.id, function (valid) {

//     if (!valid) {
//       console.log('Access denied');
//       return res.json({ success: false, msg: 'Access denied' });
//     }

//     Circle.findById(req.params.id)
//       .then(function (circle) {
//         if (circle) {

//           if (circle.ownershipModel == constants.CIRCLE_OWNERSHIP.OWNER) {
//             if (circle.owner != req.user.id)
//               return res.json({ success: false, msg: "Only the owner can change the ownership model" });

//             if (req.body.ownershipModel == constants.CIRCLE_OWNERSHIP.MEMBERS) {
//               circle.ownershipModel = constants.CIRCLE_OWNERSHIP.MEMBERS;
//               circle.votingModel = constants.VOTE_MODEL.UNANIMOUS;
//               circle.owner = null;
//               circle.lastUpdate = Date.now();

//               circle.save(function (error, circle) {
//                 if (error || !circle)
//                   return res.json({ success: false, msg: "Failed to save" });
//                 else
//                   return res.json({ success: true, circle: circle });
//               });

//             }

//           } else {
//             return res.json({ success: false, msg: "Nothing was changed" });
//           }

//         }
//         else
//           return res.json({ success: false, msg: "Could not find circle" });
//       })
//       .catch(function (err) {
//         console.error(err);
//         return res.json({ success: false, msg: err });
//       });


//   });

// });


router.post('/removemember/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    const userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleid);

    if (!(userCircle instanceof UserCircle)) throw new Error("Access denied");

    if (userCircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }


    let msg = await circleLogic.requestToRemoveMember(req.user.id, body.circleid, body.memberid);
    let payload = {};

    if (msg == "") {
      payload = { msg: "" };
    } else {
      payload = { msg: msg };
    }

    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });

  }

});


router.delete('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);
    let userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.params.id);

    if (!(userCircle instanceof UserCircle)) throw ("Access denied");

    if (userCircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    var something = await circleLogic.requestToDeleteCircle(req.user.id, req.params.id);

    let payload = {};
    if (something instanceof CircleObject)
      payload = { msg: "Vote to delete " + something.circle.chatType() + " created", circleobject: something };
    else if (something.toLowerCase() == "circle deleted" || something.toLowerCase() == "dm deleted")
      payload = { msg: something };
    else
      return res.status(500).json({ msg: something });


    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});


async function addUserKeyForOtherDevices(user, userCircle, ratchetPublicKey) {
  for (let i = 0; i < user.devices.length; i++) {

    if (user.devices[i].uuid == '' || user.devices[i].pushToken == null)
      continue;

    if (ratchetPublicKey.device != user.devices[i].uuid) {
      user.ratchetPublicKey.device = user.devices[i].uuid;
      userCircle.ratchetPublicKeys.push(user.ratchetPublicKey);
    }

  }

  return userCircle;

}

//create new circle
router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let circle = new Circle({
      ownershipModel: body.ownershipModel,
      votingModel: body.votingModel,
      owner: req.user.id
    });

    if (body.backgroundColor != null && body.backgroundColor != undefined) {

      circle.backgroundColor = body.backgroundColor;
    }

    if (body.circle != null && body.circle != undefined) {

      //it will default to standard unless something is passed in
      if (body.circle.type != null && body.circle.type != undefined)
        circle.type = body.circle.type;

      circle.privacyVotingModel = body.circle.privacyVotingModel;

      if (body.circle.privacyDisappearingTimer != null) {
        circle.privacyDisappearingTimer = body.circle.privacyDisappearingTimer;
        circle.privacyDisappearingTimerSeconds = body.circle.privacyDisappearingTimer * 60 * 60;
      }

      if (body.circle.privacyShareImage != null)
        circle.privacyShareImage = body.circle.privacyShareImage;

      if (body.circle.privacyShareURL != null)
        circle.privacyShareURL = body.circle.privacyShareURL;

      if (body.circle.privacyCopyText != null)
        circle.privacyCopyText = body.circle.privacyCopyText;

      if (body.circle.privacyShareGif != null)
        circle.privacyShareGif = body.circle.privacyShareGif;

      if (body.circle.toggleEntryVote != null)
        circle.toggleEntryVote = body.circle.toggleEntryVote;

      if (body.circle.toggleMemberPosting != null)
        circle.toggleMemberPosting = body.circle.toggleMemberPosting;

      if (body.circle.toggleMemberReacting != null)
        circle.toggleMemberReacting = body.circle.toggleMemberReacting;

      if (body.circle.type == constants.CIRCLE_TYPE.TEMPORARY) {
        circle.expiration = body.circle.expiration;
      }

    }

    var alreadyLeft;
    var memberDidNotLeave;
    var invitationExists;

    if (body.dm != null && body.dm != undefined) {
      //double check there isn't an dm already created

      memberDidNotLeave = await UserCircle.findOne({ user: ObjectId(body.memberID), dm: ObjectId(req.user.id), removeFromCache: { $exists: false } }).populate('circle');
      alreadyLeft = await UserCircle.findOne({ user: req.user.id, dm: ObjectId(body.memberID), removeFromCache: { $exists: true } }).populate('circle');
      //if (alreadyExists instanceof UserCircle) throw new Error("DM already exists");

      let alreadyExists = await UserCircle.findOne({ user: req.user.id, dm: ObjectId(body.memberID), circle: { $ne: null } }).populate('circle');
      if (alreadyExists instanceof UserCircle) {
        if (alreadyExists.hidden == true)
          throw new Error("Could not create DM");
        else
          throw new Error("DM already exists");
      }

      //also need to check invitations
      invitationExists = await Invitation.findOne({ invitee: req.user.id, inviter: ObjectId(body.memberID), dm: true }).populate('circle').populate('invitee').populate('inviter');
      /*if (invitationExists instanceof Invitation) {

        throw new Error("You are already invited to this DM");
      }
      */

      //if the alreadyLeft is populated, the user was part of the DM but left at some point
      //if (alreadyLeft instanceof UserCircle) throw new Error("You previously left this DM." + body.memberName + ' can delete the DM and then reinvite you');


      circle.dm = body.dm;
    }

    if (invitationExists != null || (alreadyLeft instanceof UserCircle && memberDidNotLeave instanceof UserCircle)) {


      var circleObject;
      var userCircle;

      if (invitationExists != null) {
        let invitation = invitationExists;

        userCircle = new UserCircle({
          user: invitation.invitee,
          circle: invitation.circle,
          backgroundColor: invitation.circle.backgroundColor,
          //prefName: invitation.circle.name,
          dm: invitation.inviter,
          dmConnected: true,
          hidden: false,
          hiddenPassphrase: '',
          newItems: 0,
          lastItemUpdate: Date.now(),
          ratchetIndex: JSON.parse(JSON.stringify(invitation.ratchetIndex)),
          ratchetPublicKeys: [RatchetPublicKey.new(body.ratchetPublicKey)],
        });

        ///also set connected with the usercircle
        var inviterCircle = await UserCircle.findOne({ user: invitation.inviter, circle: invitation.circle });
        inviterCircle.dmConnected = true;
        await inviterCircle.save();

        userCircle.ratchetIndex._id = undefined;

        //delete the invitation
        await Invitation.findByIdAndDelete(invitation._id);

        circleObject = await systemmessageLogic.sendMessage(invitation.circle,
          invitation.invitee.username + " has joined!");


      } else {

        userCircle = alreadyLeft;
        if (userCircle.circle == null) {

          circle = memberDidNotLeave.circle;
        } else {
          circle = userCircle.circle;
        }


        ///user left the DM but wants back in
        userCircle = alreadyLeft;
        userCircle.dmConnected = true;
        userCircle.removeFromCache = undefined;
        userCircle.user = req.user.id;
        userCircle.circle = circle;
        userCircle.hidden = false;
        //userCircle.lastItemUpdate = Date.now();
        userCircle.ratchetIndex = RatchetIndex.new(body.ratchetIndex);
        userCircle.ratchetPublicKeys = [RatchetPublicKey.new(body.ratchetPublicKey)];
        circleObject = await systemmessageLogic.sendMessage(circle, req.user.username + " has rejoined the DM");

      }

      //use the userkey until the user logs into the other device, will timeout after 90 days of inactivity
      userCircle = await addUserKeyForOtherDevices(req.user, userCircle, body.ratchetPublicKey);

      userCircle.lastItemUpdate = circleObject.created;
      await userCircle.save();
      await userCircle.populate(['circle', 'user']);

      //return res.status(200).json({ usercircle: userCircle, circle: circle, circleObject: circleObject, lastItemUpdate: userCircle.lastItemUpdate, msg: 'joined' });

      let payload = { usercircle: userCircle, circle: circle, circleObject: circleObject, lastItemUpdate: userCircle.lastItemUpdate, msg: 'joined' };
      payload = await kyberLogic.encryptPayload(body.enc, body.uuid, payload);
      return res.status(200).json(payload);


    } else {

      // save the circle
      await circle.save();

      let usercircle = new UserCircle({
        user: req.user.id,
        circle: circle.id,
        hidden: body.hidden,
        lastItemUpdate: Date.now(),
        ratchetIndex: RatchetIndex.new(body.ratchetIndex),
        ratchetPublicKeys: [RatchetPublicKey.new(body.ratchetPublicKey)],
        newItems: 1,
        showBadge: false,
      });

      if (body.backgroundColor != null && body.backgroundColor != undefined) {
        usercircle.backgroundColor = body.backgroundColor;
      }

      if (body.dm != null && body.dm != undefined) {
        usercircle.dm = body.memberID;
      }

      if (body.dmConnected != null && body.dmConnected != undefined) {
        usercircle.dmConnected = body.dmConnected;
        usercircle.newItems = 0;
        usercircle.showBadge = false;
      }
      //check to see if this user is using multiple devices
      let user = await User.findById(req.user.id);

      //use the userkey until the user logs into the other device, will timeout after 90 days of inactivity
      usercircle = await addUserKeyForOtherDevices(req.user, usercircle, body.ratchetPublicKey);

      if (usercircle.hidden == true) usercircle.hiddenPassphrase = body.hiddenPassphrase;  //don't bcrypt on an empty string

      var circleObject;
      let lastItemUpdate = Date.now();

      if (body.dmConnected != null && body.dmConnected != undefined) {
        circleObject = await systemmessageLogic.sendMessage(circle, "Welcome!");
        lastItemUpdate = circleObject.created;
      }

      usercircle.lastItemUpdate = lastItemUpdate;
      // save the usercircle
      await usercircle.save();

      await usercircle.populate(['circle', 'user']);

      //return res.status(200).json({ usercircle: usercircle, circle: circle, circleObject: circleObject, lastItemUpdate: lastItemUpdate, msg: 'successfully created new circle' });

      let payload = { usercircle: usercircle, circle: circle, circleObject: circleObject, lastItemUpdate: lastItemUpdate, msg: 'successfully created new circle' };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);

    }
  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});


//Find members for a circle POSTKYBER
router.get('/members/:id', passport.authenticate('jwt', { session: false }), async function (req, res) {

  try {

    //AUTHORIZATION CHECK
    let userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.params.id);

    let userCirles = await UserCircle.find({ "circle": req.params.id })
      //.populate({path: 'user', match: { locketOut: { $ne: true } },})
      .populate('user')
      .populate('circle');

    res.status(200).send({ usercircles: userCirles });


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});


//Find members for a circle
router.post('/getmembers/', passport.authenticate('jwt', { session: false }), async function (req, res) {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    let userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleID);

    let userCirles = await UserCircle.find({ "circle": body.circleID })
      //.populate({path: 'user', match: { locketOut: { $ne: true } },})
      .populate('user')
      .populate('circle');

    //res.status(200).send({ usercircles: userCirles });

    let payload = { usercircles: userCirles };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});


router.put('/settingvotingmodel/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);


    let circleID = req.params.id;
    if (circleID == 'undefined') {
      circleID = body.circleID;
    }

    //authorization check
    let userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, circleID);

    //param check
    if (!(userCircle instanceof UserCircle)) throw ("Access denied");

    if (userCircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    if (!body.modelchange) throw ("Access denied");
    var circle = await Circle.findById(circleID);
    if (!(circle instanceof Circle)) throw ("Could not find circle");

    //ownership check
    if (circle.ownershipModel == constants.CIRCLE_OWNERSHIP.OWNER)
      //if (req.user.id != circle.owner)
      throw ("No need to change voting model for owners");

    let circleObject = await circleSettingLogic.createModelVote(circle, body.modelchange, req.user.id, body.settingchangetype, body.description);


    //return res.status(200).json({ circle: circle, msg: 'vote created', circleObject: circleObject });
    let payload = { circle: circle, msg: 'vote created', circleObject: circleObject };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);



  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });

  }

});

router.put('/setting/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let circleID = req.params.id;
    if (circleID == 'undefined') {
      circleID = body.circleID;
    }

    //authorization check
    let userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, circleID);

    //param check
    if (!(userCircle instanceof UserCircle)) throw ("Access denied");

    if (userCircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    if (!body.settingvalues) throw ("Access denied");
    var circle = await Circle.findById(circleID);
    if (!(circle instanceof Circle)) throw ("Could not find circle");

    //ownership check
    if (circle.ownershipModel == constants.CIRCLE_OWNERSHIP.OWNER)
      if (req.user.id != circle.owner)
        throw ("Only owners can change settings for owned circles");


    //is a vote needed?
    let voteNeeded = await circleSettingLogic.votedNeeded(circle);
    let proposedChanges = circleSettingLogic.getSettings(circle, body.settingvalues);

    if (voteNeeded) {
      await proposedChanges.save();
      let circleObject = await circleSettingLogic.createVote(circle, proposedChanges, req.user.id, body.settingchangetype, body.description);


      deviceLogicSingle.sendMessageNotificationToCircle(circleObject, circle._id, req.user.id, body.pushtoken, circleObject.lastUpdate);  //async ok

      //return res.status(200).json({ circle: circle, msg: 'vote created', circleObject: circleObject });

      let payload = { circle: circle, msg: 'vote created', circleObject: circleObject };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);


    } else {
      await circleSettingLogic.setSettings(circle, proposedChanges.proposedCircle);
      await systemmessageLogic.sendMessage(circle, 'Circle settings updated, no vote required');
      return res.status(200).json({ circle: circle, msg: 'Settings changed' });
    }

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });

  }

});

router.put('/settingexpiration/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let circleID = req.params.id;
    if (circleID == 'undefined') {
      circleID = body.circleID;
    }

    //authorization check
    let userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, circleID);

    //param check
    if (!(userCircle instanceof UserCircle)) throw ("Access denied");

    if (userCircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    var circle = await Circle.findById(circleID);
    if (!(circle instanceof Circle)) throw ("Could not find circle");

    //ownership check
    if (req.user.id != circle.owner) {
      throw ("Only creators can change the expiration date for temporary circles");
    }

    circle.expiration = new Date(body.expiration);
    circle.lastUpdate = Date.now();
    await circle.save();
    await systemmessageLogic.sendMessage(circle, 'Circle expiration updated, no vote required');

    //return res.status(200).json({ circle: circle, msg: "Expiration changed" });

    let payload = { circle: circle, msg: "Expiration changed" };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

})

/*
//generate wall circles for all networks
router.post('/createwalls/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let user = await User.findById(req.user.id).populate('hostedFurnace');
    if (user.role != constants.ROLE.IC_ADMIN) throw new Error('access denied');

    let networks = await HostedFurnace.find({ enabledWall: false });

    for (let i = 0; i < networks.length; i++) {

      let network = networks[i];

      let owner = await User.find({ hostedFurnace: network._id, role: constants.ROLE.OWNER });

      ///create the circle for the network
      let circle = new Circle({
        ownershipModel: constants.CIRCLE_OWNERSHIP.OWNER,
        votingModel: constants.VOTE_MODEL.UNANIMOUS,
        owner: owner,
        type: constants.CIRCLE_TYPE.WALL,
      });

      // save the circle
      await circle.save();

      //create the usercircles for each user
      let networkUsers = await User.find({ hostedFurnace: network._id });

      for (let j = 0; j < networkUsers.length; j++) {
        let networkUser = networkUsers[j];

        let usercircle = new UserCircle({
          user: networkUser._id,
          circle: circle.id,
          hidden: false,
          lastItemUpdate: Date.now(),
          wall: true,
          //ratchetIndex: RatchetIndex.new(req.body.ratchetIndex),
          ratchetPublicKeys: [user.ratchetPublicKey],
          newItems: 0,
          showBadge: false,
        });

        //check to see if this user is using multiple devices
        for (let k = 0; k < user.devices.length; k++) {
          let device = user.devices[k];

          if (device.uuid == '' || device.pushToken == null)
            continue;

          user.ratchetPublicKey.device = user.devices[i].uuid;
          usercircle.ratchetPublicKeys.push(user.ratchetPublicKey);

        }

        // save the usercircle
        await usercircle.save();

      }
    }

    return res.status(200).json({ msg: 'successfully created walls' });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});
*/


/*
router.put('/setting/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //authorization check
    var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.params.id);

    //param check
    if (!userCircle) throw ("Access denied");
    if (!req.body.settingvalues) throw ("Access denied");
    var circle = await Circle.findById(req.params.id);
    if (!(circle instanceof Circle)) throw ("Could not find circle");

    //ownership check
    if (circle.ownershipModel == constants.CIRCLE_OWNERSHIP.OWNER)
      if (req.user.id != circle.owner)
        throw ("Only owners can change settings for owned circles");

    var response = [];
    var changed = false;

    //update the settings
    for (i = 0; i < req.body.settingvalues.length; i++) {
      var setting = req.body.settingvalues[i].setting;
      var settingValue = req.body.settingvalues[i].settingValue;

      if (!circleSettingLogic.settingValid(setting, settingValue))
        response.push(setting + ": invalid value");
      else if (!circleSettingLogic.settingChanged(circle, setting, settingValue))
        response.push(setting + ": value has not changed");
      else {

        if (await circleSettingLogic.settingVotedNeeded(circle, setting, settingValue) == false) {
          changed = true;
          await systemmessageLogic.sendMessage(circle._id, "Setting for " + circleSettingLogic.settingToEnglish(setting) + " has changed to " + settingValue);
          circle.set({ [setting]: settingValue });
        } else {
          response.push(circleSettingLogic.settingCreateVote(circle, setting, settingValue));
          
        }
      }
    }

    if (changed){
      await circle.save();
      response.push("updated successfully");
    }

    console.log(response);
    return res.status(200).json({ circle: circle, response: response });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });

  }

});*/


//count = await Circle.updateOne({ "_id": req.params.id }, { [req.body.setting]: req.body.settingvalue });
//if (count.n == 1) {}


module.exports = router;