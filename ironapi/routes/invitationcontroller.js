const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const passport = require('passport');
var Invitation = require('../models/invitation');
const User = require('../models/user');
const UserCircle = require('../models/usercircle');
const CircleObject = require('../models/circleobject');
const Circle = require('../models/circle');
const securityLogic = require('../logic/securitylogic');
const circleLogic = require('../logic/circlelogic');
const userCircleLogic = require('../logic/usercirclelogic');
const securityLogicAsync = require('../logic/securitylogicasync');
const systemmessageLogic = require('../logic/systemmessagelogic');
var invitationLogic = require('../logic/invitationlogic');
const deviceLogicSingle = require('../logic/devicelogicsingle');
const circleObjectLogic = require('../logic/circleobjectlogic');
const constants = require('../util/constants');
const logUtil = require('../util/logutil');
const RatchetPublicKey = require('../models/ratchetpublickey');
const RatchetIndex = require('../models/ratchetindex');
const kyberLogic = require('../logic/kyberlogic');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());


router.delete('/decline/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {


  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let invitationID = req.params.id;
    if (invitationID == 'undefined') {
      invitationID = body.invitationID;
    }

    var invitation = await Invitation.findById({ _id: invitationID }).populate("invitee").populate('circle');

    if (!invitation) return res.status(500).json({ msg: "There was a problem finding the invitation." });

    //AUTHORIZATION CHECK
    if (invitation.invitee.id != req.user.id) {
      console.log("Access Denied");
      return res.status(400).json({ msg: 'unauthorized' });
    }


    if (invitation.vote != null) {
      circleObjectLogic.deleteByVoteID(invitation.vote);
    } else if (invitation.dm == true) {
      ///also deletes the invitation
      await circleLogic.deleteCircle(req.user.id, invitation.circle);
    } else
      await invitationLogic.delete(invitation);

    if (invitation.dm != true) {
      systemmessageLogic.sendMessage(invitation.circle,
        invitation.invitee.username + " has declined the invitation");
    }

    var newInvitationCount = await invitationLogic.getUserInvitationCount(req.user.id);

    //console.log('Invitation count: ' + newInvitationCount);

    //return res.status(200).json({ msg: 'Successfully deleted invitation', invitationcount: newInvitationCount });

    let payload = { msg: 'Successfully deleted invitation', invitationcount: newInvitationCount };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }


});

//Called if inviter cancels the invite
router.delete('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {


  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let invitationID = req.params.id;
    if (invitationID == 'undefined') {
      invitationID = body.invitationID;
    }


    var invitation = await Invitation.findById({ _id: invitationID }).populate("invitee").populate("vote").populate("inviter").populate('circle').exec();
    if (!(invitation instanceof Invitation)) return res.status(500).json({ msg: "Invitation not found" });

    //AUTHORIZATION CHECK
    if (invitation.inviter.id != req.user.id) {      //only the poster can delete the invitation (owner of circle or post)
      console.log("Access Denied");
      return res.status(400).json({ msg: 'Access denied' });
    }

    var sysMessage = "Invitation to " + invitation.invitee.username + " was canceled";

    if (invitation.vote) {
      var circleObject = await CircleObject.findOne({ vote: invitation.vote });
      if (!(circleObject instanceof CircleObject)) throw ("Could not find CircleObject");
      var success = await circleObjectLogic.deleteCircleObject(circleObject, req, null, invitation.inviter.username + ' canceled an invitation to ' + invitation.invitee.username);
      if (!success) throw ("Could not delete invitation");
    }
    else {
      invitationLogic.delete(invitation);
    }

    await systemmessageLogic.sendMessage(invitation.circle, sysMessage);
    //return res.status(200).json({ msg: 'Successfully deleted invitation', invitation: invitation }); //

    let payload = { msg: 'Successfully deleted invitation', invitation: invitation };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }

});

//Called if inviter cancels the invite
router.put('/canceldm/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    ///find the usercircle
    var userCircle = await UserCircle.findOne({ user: req.user.id, _id: body.userCircleCacheID }).populate('circle');
    if (!(userCircle instanceof UserCircle)) throw ("access denied");

    if (userCircle.circle != null) {
      //validate this is a dm and the users haven't already connected
      if (userCircle.circle.dm != true || userCircle.dmConnected == true) throw new Error("user already accepted invitation");

      /*
      var invitation = await Invitation.findOne({ inviter: req.user.id, invitee: userCircle.dm }).populate("invitee").populate("vote").populate("inviter").populate('circle').exec();
      if (!(invitation instanceof Invitation)) return res.status(500).json({ msg: "Invitation not found" });
      */

      ///also deletes the invitation
      await circleLogic.deleteCircle(req.user.id, userCircle.circle);
    }

    // return res.status(200).json({ msg: 'Successfully deleted invitation' }); //

    let payload = { msg: 'Successfully deleted invitation' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);



  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }

});

//finds a user by username, returns user and ratchetpublickey
router.post('/finduser/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {


    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let user = req.user; //await User.findById(req.user.id);

    var invitee;

    if (!body.inviteeID || body.inviteeID == '') {

      var inviteeUsername = body.inviteeUsername.toLowerCase();

      if (user.hostedFurnace) {
        invitee = await User.findOne({ lowercase: inviteeUsername, hostedFurnace: user.hostedFurnace }).populate('blockedList').populate('allowedList').exec();
      } else {
        invitee = await User.findOne({ lowercase: inviteeUsername, hostedFurnace: null }).populate('blockedList').populate('allowedList').exec();
      }

    } else {
      invitee = await User.findOne({ _id: body.inviteeID }).populate('blockedList').populate('allowedList').exec();

    }

    if (!(invitee instanceof User))
      throw new Error("user not found");

    if (invitee.lockedOut)
      throw ("user is locked out and cannot be invited");

    if (body.circleID && body.circleID != '') {

      var alreadyMember = await UserCircle.findOne({ user: invitee._id, circle: body.circleID });
      if (alreadyMember instanceof UserCircle)
        throw ("user is already a member");

      //Did someone already send an invitation?
      var invitations = await Invitation.find({ "invitee": invitee._id, "circle": body.circleID });

      if (invitations)
        if (invitations.length != 0)
          throw ("user was already invited");
    }


    //return res.status(200).json({ user: invitee, ratchetPublicKey: invitee.ratchetPublicKey });

    let payload = { user: invitee, ratchetPublicKey: invitee.ratchetPublicKey };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err);
    return res.status(500).json({ msg: msg });
  }

});



router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {


  try {


    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let user = await User.findById(req.user.id);

    //AUTHORIZATION CHECK
    var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleID);
    if (!(userCircle instanceof UserCircle)) throw ("could not load UserCircle");

    if (userCircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }


    if (!body.ratchetIndex) {
      return res.status(400).json({ msg: 'Need to upgrade to version 27 before you can send an invite' });
    }

    var circle = await Circle.findOne({ _id: body.circleID });

    if (circle.type == constants.CIRCLE_TYPE.VAULT)
      throw "cannot send invites to private vaults";

    if (circle.ownershipModel == constants.CIRCLE_OWNERSHIP.OWNER && circle.owner != req.user.id)
      throw "only the owner of this circle can send an invite"

    var invitee;
    if (!body.inviteeID || body.inviteeID == '') {
      var inviteeUsername = body.inviteeUsername.toLowerCase();

      if (user.hostedFurnace) {
        invitee = await User.findOne({ lowercase: inviteeUsername, hostedFurnace: user.hostedFurnace }).populate('blockedList').populate('allowedList').exec();
      } else {
        invitee = await User.findOne({ lowercase: inviteeUsername, hostedFurnace: null }).populate('blockedList').populate('allowedList').exec();
      }

    } else {
      invitee = await User.findOne({ _id: body.inviteeID }).populate('blockedList').populate('allowedList').exec();
    }

    if (!(invitee instanceof User)) throw new Error("User not found");

    var alreadyMember = await UserCircle.findOne({ user: invitee._id, circle: body.circleID });
    if (alreadyMember instanceof UserCircle)
      throw ("user already a member");

    //Did someone already send an invitation?
    var invitations = await Invitation.find({ "invitee": invitee._id, "circle": body.circleID });

    if (invitations instanceof Invitation) {
      if (invitations.length != 0)
        throw ("User was already invited");
    }


    var invitation = new Invitation({
      circle: body.circleID,
      invitee: invitee,
      inviter: req.user.id,
      dm: circle.dm,
      ratchetIndex: RatchetIndex.new(body.ratchetIndex)
    });

    var voteNeeded = false;

    if (circle.ownershipModel == constants.CIRCLE_OWNERSHIP.MEMBERS && circle.toggleEntryVote == true) {

      voteNeeded = true;

      var count = await UserCircle.countDocuments({ "circle": circle._id });

      if (circle.privacyVotingModel == constants.VOTE_MODEL.MAJORITY) {
        ///if it is a simple majority vote, the user's vote would default to yes and the vote would close automatically anyway
        if (count < 3) {
          voteNeeded = false;
        }
      } else if (count == 1) {
        voteNeeded = false;
      }


    }

    var circleObject;
    //should we send the invite or create a vote for a new member?
    if (voteNeeded) {
      let result = await invitationLogic.kickOffMemberVote(invitation, circle, invitee, req.user.id, body.seed);

      circleObject = result[0];
      invitation = result[1];
    } else {
      invitation = await invitationLogic.inviteUser(invitation);
    }

    if (!(invitation instanceof Invitation))
      throw ("Failed to send invitation");

    var message;

    if (circle.ownershipModel == constants.CIRCLE_OWNERSHIP.MEMBERS && circle.toggleEntryVote == true) {
      message = "Successfully created vote for invite";

      //deviceLogic.sendNotificationToCircle(body.circleID, req.user.id, req.headers.devicetoken, null, 'Vote to add ' + invitee.username + ' is open');

      var notification = 'Vote to add ' + invitee.username + ' is open';
      var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
      let oldNotification = "New ironclad message";

      let lastUpdate = null;

      if (circleObject != undefined && circleObject != null)
        lastUpdate = circleObject.lastUpdate;

      deviceLogicSingle.sendMessageNotificationToCircle(circleObject, userCircle.circle._id, req.user.id, body.pushtoken, lastUpdate, notification, notificationType, oldNotification);  //async ok
    } else
      message = 'Successfully created invitation';

    //return res.status(200).json({ msg: message, invitation: invitation });

    let payload = { msg: message, invitation: invitation };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err);
    return res.status(500).json({ msg: msg });
  }

});





//find by user, deprecated, POSTKYBER
router.get('/user/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //AUTHORIZATION CHECK
    if (!req.user.id == req.params.id)
      return res.status(400).json({ msg: 'Access denied' });

    var invitations = await Invitation.find({ "invitee": req.user.id, status: "pending" }).populate('invitee').populate('circle').populate('inviter');

    if (!invitations) return res.status(500).send("There was a problem finding the invitation");

    var cleanInvitations = [];

    for (i = 0; i < invitations.length; i++) {

      if (invitations[i].circle == null) {  //make sure the circle wasn't deleted

        //console.log('delete invitation: ' + invitations[i]._id);
        await Invitation.findByIdAndDelete(invitations[i]._id);
      } else
        cleanInvitations.push(invitations[i]);
    }
    res.status(200).json({ invitations: cleanInvitations });

  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: err });
  }
});

router.post('/foruser/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var invitations = await Invitation.find({ "invitee": req.user.id, status: "pending" }).populate('invitee').populate('circle').populate('inviter');

    if (!invitations) return res.status(500).send("There was a problem finding the invitation");

    var cleanInvitations = [];

    for (i = 0; i < invitations.length; i++) {

      if (invitations[i].circle == null) {  //make sure the circle wasn't deleted

        //console.log('delete invitation: ' + invitations[i]._id);
        await Invitation.findByIdAndDelete(invitations[i]._id);
      } else
        cleanInvitations.push(invitations[i]);
    }
    //res.status(200).json({ invitations: cleanInvitations });

    let payload = { invitations: cleanInvitations };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: err });
  }
});

//Find all for a circle, deprecated, POSTKYBER
router.get('/circle/:id', passport.authenticate('jwt', { session: false }), function (req, res) {

  //AUTHORIZATION CHECK
  securityLogic.canUserAccessCircle(req.user.id, req.params.id, function (valid) {
    if (!valid)
      return res.status(400).json({ msg: 'Access denied' });

    Invitation.find({ "circle": req.params.id }, function (err, invitations) {
      if (err)
        return res.status(500).json({ msg: "There was a problem finding the invitation" });

      res.status(200).json({ invitations: invitations });

      //return res.json({success: true, invitations:invitations});  
      //res.status(200).send(invitations);
    }).populate('invitee').populate('inviter').populate("circle");

  });
});

//Find all for a circle
router.post('/bycircle/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    const userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleID);

    if (userCircle instanceof UserCircle) {
      throw new Error("unauthorized");
    }

    let invitations = await Invitation.find({ "circle": req.params.id }).populate('invitee').populate('inviter').populate("circle");

    // res.status(200).json({ invitations: invitations });

    let payload = { invitations: invitations };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {

    console.error(err);
    res.status(500).json({ msg: err });
  }
});


router.put('/accept/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {


    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let invitationID = req.params.id;
    if (invitationID == 'undefined') {
      invitationID = body.invitationID;
    }

    var invitation = await Invitation.findById({ _id: invitationID }).populate('invitee').populate('inviter').populate('circle');
    if (!invitation) return res.status(400).json({ msg: "There was a problem finding the invitation" });

    //AUTHORIZATION CHECK
    if (invitation.invitee.id != req.user.id)
      return res.status(500).json({ msg: 'Access denied' });

    let userid = invitation.invitee.id;
    let circle = invitation.circle;
    let backgroundColor = invitation.circle.backgroundColor;
    let ratchetIndex = invitation.ratchetIndex;
    let inviter = invitation.inviter;

    //delete the invitation
    await Invitation.findByIdAndDelete(invitationID);

    let circleObject = await systemmessageLogic.sendMessage(invitation.circle,
      invitation.invitee.username + " has joined!", invitation.invitee.id);

    var newInvitationCount = await invitationLogic.getUserInvitationCount(req.user.id);

    var usercircle = new UserCircle({
      user: userid,
      circle: circle.id,
      backgroundColor: backgroundColor,
      hidden: false,
      hiddenPassphrase: '',
      newItems: 0,
      lastItemUpdate: Date.now(),
      ratchetIndex: JSON.parse(JSON.stringify(ratchetIndex)),
      ratchetPublicKeys: [RatchetPublicKey.new(body.ratchetPublicKey)],
    });


    if (invitation.dm) {
      usercircle.dm = inviter;
      usercircle.dmConnected = true;

      ///also set connected with the usercircle
      var inviterCircle = await UserCircle.findOne({ user: inviter, circle: circle });
      inviterCircle.dmConnected = true;
      await inviterCircle.save();
    }

    usercircle.ratchetIndex._id = undefined;

    //check to see if this user is using multiple devices
    let user = await User.findById(req.user.id);

    //use the userkey until the user logs into the other device
    //will timeout after 90 days of inactivity

    for (let i = 0; i < user.devices.length; i++) {
      //if (user.devices.length > 0){

      if (user.devices[i].uuid == '' || user.devices[i].pushToken == null)
        continue;

      if (body.ratchetPublicKey.device != user.devices[i].uuid) {
        user.ratchetPublicKey.device = user.devices[i].uuid;
        usercircle.ratchetPublicKeys.push(user.ratchetPublicKey);
      }

    }

    // save the usercircle
    await usercircle.save();
    await usercircle.populate(['user', 'circle']);

    await userCircleLogic.setConnections(usercircle);

    //console.log('Invitation count: ' + newInvitationCount);

    //res.status(200).json({ id: usercircle._id, msg: 'invitation accepted', invitationcount: newInvitationCount, usercircle: usercircle });

    let payload = { id: usercircle._id, msg: 'invitation accepted', invitationcount: newInvitationCount, usercircle: usercircle };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {

    console.error(err);
    res.status(500).json({ msg: err });
  }

});


///deprecated, POSTKYBER
router.get('/updatecount/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    //console.log('updateinvycount calle');

    //AUTHORIZATION CHECK
    if (req.params.id != req.user.id)
      return res.status(500).json({ msg: 'Access denied' });

    var newInvitationCount = await invitationLogic.getUserInvitationCount(req.user.id);

    res.status(200).json({ invitationcount: newInvitationCount });

  } catch (err) {

    console.error(err);
    res.status(500).json({ msg: err });
  }

});

router.post('/getcount/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    //let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //console.log('updateinvycount calle');

    //AUTHORIZATION CHECK
    if (req.params.id != req.user.id)
      return res.status(500).json({ msg: 'Access denied' });

    var newInvitationCount = await invitationLogic.getUserInvitationCount(req.user.id);

    //res.status(200).json({ invitationcount: newInvitationCount });

    let payload = { invitationcount: newInvitationCount };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {

    console.error(err);
    res.status(500).json({ msg: err });
  }

});

module.exports = router;