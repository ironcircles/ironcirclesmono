const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
mongoose.Promise = require('bluebird');
const logUtil = require('../util/logutil');
const HostedFurnace = require('../models/hostedfurnace');
const HostedFurnaceStorage = require('../models/hostedfurnacestorage');
const HostedInvitation = require('../models/hostedinvitation');
const HostedFurnaceImage = require('../models/hostedfurnaceimage');
const RatchetPublicKey = require('../models/ratchetpublickey');
const UserConnection = require('../models/userconnection');
const NetworkRequest = require('../models/networkrequest');
const UserCircle = require('../models/usercircle');
const Circle = require('../models/circle');
const User = require('../models/user');
const passport = require('passport');
const securityLogic = require('../logic/securitylogic');
const MemberCircle = require('../models/membercircle');
const securityLogicAsync = require('../logic/securitylogicasync');
const deviceLogic = require('../logic/devicelogic');
const gridFS = require('../util/gridfsutil');
const ObjectId = require('mongodb').ObjectId;
const constants = require('../util/constants');
var randomstring = require("randomstring");
const s3Util = require('../util/s3util');
const UserNetworkAttempts = require('../models/usernetworkattempts');
const Device = require('../models/device');
const DeviceNetworkAttempts = require('../models/devicenetworkattempts');
const Violation = require('../models/violation');
const kyberLogic = require('../logic/kyberlogic');
const LAPSEDSECOND = 20;
const mongodb = require('mongodb');
let conn = mongoose.connection;
let Grid = require('gridfs-stream');
const user = require('../models/user');
Grid.mongo = mongoose.mongo;


if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());


router.post('/invitation', async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, null);

    //validate apikey
    if (process.env.NODE_ENV !== 'production')
      require('dotenv').load();

    if (body.apikey != process.env.apikey)
      return reject('unauthorized');

    let hostedInvitation = await HostedInvitation.findOne({ token: body.token, active: true }).populate('hostedFurnace').populate('inviter').populate('circle');

    if (!hostedInvitation) throw ('invitation not found or has expired');


    if (hostedInvitation.hostedFurnace == null) { //then it's the forge

      let key = randomstring.generate({
        length: 25,
        charset: 'alphanumeric'
      });

      let hostedFurnace = new HostedFurnace({ name: "IronForge", key: key, _id: key })

      hostedInvitation.hostedFurnace = hostedFurnace;

    }

    // return res.status(200).send({
    //   hostedInvitation: hostedInvitation,
    // });

    let payload = { hostedInvitation: hostedInvitation };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

router.post('/reportprofile', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let violation = await Violation.new(body.violation);
    violation.reporter = req.user.id;

    await violation.save();

    //return res.status(200).json({ msg: 'violation reported' });

    let payload = { msg: 'violation reported' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});

router.post('/reportnetwork', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let violation = await Violation.new(body.violation);
    violation.reporter = req.user.id;

    await violation.save();

    // return res.status(200).json({ msg: 'violation reported' });

    let payload = { msg: 'violation reported' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});

router.post('/magiclinktonetwork', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await User.findById(req.user.id).populate('hostedFurnace');

    var hostedFurnace = undefined;

    if (user.hostedFurnace != null && user.hostedFurnace != undefined) {

      if (user.hostedFurnace.name != body.hostedName || user.hostedFurnace.key != body.key) {

        throw new Error('Access denied');
      }

      hostedFurnace = user.hostedFurnace;
    }

    let token = 'MGC' + randomstring.generate({
      length: 37,
      charset: 'alphanumeric'
    });

    let hostedInvitation = new HostedInvitation({ inviter: req.user.id, token: token, hostedFurnace: hostedFurnace });
    await hostedInvitation.save();


    //for the return only, don't save
    if (hostedFurnace == undefined) {

      let key = 'MGC' + randomstring.generate({
        length: 37,
        charset: 'alphanumeric'
      });

      hostedFurnace = new HostedFurnace({ name: "IronForge", key: key });

    }
    let url = 'This is a magic code to join an IronCircles social network.\n\nCopy this entire message, open the app (install and register if needed) and you will be prompted to join the new network.\n\nMagic Code: ' + token;

    // return res.status(200).send({
    //   url: url,
    // });

    let payload = { url: url, };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

router.post('/magiclinktocircle', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, body.circleID);

    if (!userCircle)
      throw new Error('Access denied');

    var hostedFurnace;


    await userCircle.user.populate('hostedFurnace');

    hostedFurnace = userCircle.user.hostedFurnace;

    let token = randomstring.generate({
      length: 40,
      charset: 'alphanumeric'
    });

    let hostedInvitation = new HostedInvitation({ circle: userCircle.circle, inviter: req.user.id, token: token, hostedFurnace: hostedFurnace });
    await hostedInvitation.save();


    //for the return only, don't save
    if (hostedFurnace == undefined) {

      let key = randomstring.generate({
        length: 25,
        charset: 'alphanumeric'
      });

      hostedFurnace = new HostedFurnace({ name: "IronForge", key: key })

    }

    //let url = "https://ironcircles.com/applink/" + token;

    //let url = 'com.ironcircles.ironclient:tokenid?token="' + token + '"';

    //let url = 'ironcirclesapp://ironcircles.com/' + token;

    //let url = 'Here is a magic link to join an IronCircles social network.\n\nOn iOS, tap: ironcirclesapp://ironcircles.com/' + token + '\n\nOn Android, tap: https://ironcircles.com/applink/' + token;

    //let url = 'Here is a magic code to join an IronCircles social network.\n\nOn iOS, tap: ironcirclesapp://ironcircles.com/' + token + '\n\nOn Android, tap: https://ironcircles.com/applink/' + token;

    let url = 'This is a magic code to join an IronCircles social network. Copy this entire message, open the app (install if needed) and you will asked to join the new network.\n\nMagic Code: ' + token;

    // return res.status(200).send({
    //   url: url,
    // });

    let payload = {  url: url, };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

router.post('/requestapproved/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let valid = false;

    let hostedFurnace = await HostedFurnace.findOne({ lowercase: body.hostedName.toLowerCase() });

    if (hostedFurnace instanceof HostedFurnace) {

      let networkRequest = await NetworkRequest.findOne({ user: req.user._id, hostedFurnace: hostedFurnace._id, status: constants.NETWORK_REQUEST_STATUS.APPROVED });

      if (networkRequest instanceof NetworkRequest) {
        valid = true;
      }
    }

    // return res.status(200).send({
    //   valid: valid,
    // });

    let payload = {
      valid: valid,
    };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

function tooSoonMessage(lastAttempt) {
  var lapsedTime = Math.round((Date.now() - lastAttempt) / 1000);

  if (lapsedTime < LAPSEDSECOND) {
    var msg = LAPSEDSECOND - lapsedTime + " ";
    return msg;
  } else return null;
}

///validate network from network manager
router.post('/valid/', async (req, res) => {

  try {
    // let user;
    // if (req.user != null) {
    //   user = await User.findById(req.user.id);
    // } else {
    //   ///for older versions that haven't yet updated
    //   user = await User.findById(req.body.user._id);
    // }

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, null);

    let message = 'invalid';
    await validateAPIKey(body.apikey);

    ///check the network exists
    let network = await HostedFurnace.findOne({
      lowercase: body.hostedName.toLowerCase(),
    });
    if (!network) {
      return res.status(200).json({ valid: message });
    }

    ///check passcode is correct
    let hostedFurnace = await HostedFurnace.findOne({
      lowercase: body.hostedName.toLowerCase(),
      key: body.key
    });
    if (hostedFurnace && hostedFurnace instanceof HostedFurnace) {
      message = 'valid';
      if (body.fromPublic == false) {
        return res.status(200).json({ valid: message });
      }
    }

    /* if (body.user != null) {
       let user = await User.findById(body.user._id);
 
       ///check if tried before
       let tries = 0;
       let userNetworkAttempts = await UserNetworkAttempts.findOne({
         user: user._id,
         network: network._id
       });
     } else if (tries < 5) {
 
     } else if (tries < 10) {
       var tooSoonMsg = tooSoonMessage(userNetworkAttempts.lastAttempt);
       if (tooSoonMsg) {
         message = " " + tooSoonMsg;
       } else if (tries == 9 && message == 'invalid') {
         message = "failed";
 
       }
       console.log(tries);
 
       if (tries == 0) {
         userNetworkAttempts = new UserNetworkAttempts({
           user: user._id,
           network: network._id,
           lastAttempt: Date.now()
         });
       } else if (tries < 5) {
         // console.log("middling");
       } else if (tries < 10) {
         var tooSoonMsg = tooSoonMessage(userNetworkAttempts);
         if (tooSoonMsg) {
           message = " " + tooSoonMsg;
         } else if (tries == 9 && message == 'invalid') {
           message = "failed";
         }
       } else {
         message = 'exceeded';
       }
   
       if (!tooSoonMsg) {
         userNetworkAttempts.attempts = tries + 1;
         userNetworkAttempts.lastAttempt = Date.now();
         await userNetworkAttempts.save();
       }
     }*/


    //return res.status(200).json({ valid: message });

    let payload = { valid: message };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});

router.post('/checkname/', async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let nameAvailable = false;
    let lowercase = body.hostedName.trim().toLowerCase();

    if (lowercase.includes('ironforge') || lowercase.includes('iron forge') || lowercase.includes('iron  forge')) {
      nameAvailable = false;
    } else {

      await validateAPIKey(req.headers.apikey);


      let hostedFurnace = await HostedFurnace.findOne({ lowercase: lowercase });

      if (hostedFurnace && hostedFurnace instanceof HostedFurnace)
        nameAvailable = false;
      else
        nameAvailable = true;

    }

    let payload = {
      nameAvailable: nameAvailable,
    };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

    // return res.status(200).send({
    //   nameAvailable: nameAvailable,
    // });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});


//Deprecated. Delete after everyone is on 81, POSTKYBER
router.get('/valid/:name', async (req, res) => {

  try {

    let valid = false;

    await validateAPIKey(req.headers.apikey);


    let hostedFurnace = await HostedFurnace.findOne({ lowercase: req.params.name.toLowerCase(), key: req.headers.key });

    if (hostedFurnace && hostedFurnace instanceof HostedFurnace)
      valid = true;


    return res.status(200).send({
      valid: valid,
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});



//Deprecated. Delete after everyone is on 81
router.get('/checkname/:name', async (req, res) => {

  try {

    let nameAvailable = false;
    let lowercase = req.params.name.toLowerCase();

    await validateAPIKey(req.headers.apikey);


    let hostedFurnace = await HostedFurnace.findOne({ lowercase: lowercase });

    if (hostedFurnace && hostedFurnace instanceof HostedFurnace)
      nameAvailable = false;
    else
      nameAvailable = true;

    return res.status(200).send({
      nameAvailable: nameAvailable,
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

///this is really a get
router.put('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    if (body.hostedName == null || body.key == null) {
      throw new Error('access denied');
    }

    ///ok to return the key, user has it anyways
    let hostedNetwork = await HostedFurnace.findOne({ lowercase: body.hostedName.toLowerCase(), key: body.key }).populate('hostedFurnaceImage');

    // return res.status(200).send({
    //   hostedNetwork: hostedNetwork,
    // });

    let payload = { hostedNetwork: hostedNetwork, };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});


///update network settings
router.put('/config/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    await req.user.populate('hostedFurnace');

    let user = req.user; //await User.findById(req.user.id).populate('hostedFurnace');
    let hostedNetwork = user.hostedFurnace;

    //if the user is on the forge, then they can't change the discoverable setting
    if (hostedNetwork == null || hostedNetwork == undefined) throw new Error('access denied');

    //verify the user owns the hosted network
    if (user.role != constants.ROLE.OWNER && user.role != constants.ROLE.ADMIN && user.role != constants.ROLE.IC_ADMIN)
      throw new Error('access denied');

    let changed = false;

    if (body.newName != undefined && body.newName != null) {
      //verify the network name isn't already in used
      let lowercase = body.newName.trim().toLowerCase();

      ///don't let the user name it the forge
      if (lowercase.includes('ironforge') || lowercase.includes('iron forge') || lowercase.includes('iron  forge')) {
        throw new Error('Network name is already in use');
      } else {
        ///see if there is already a network with this name
        let hostedNetworkNameCheck = await HostedFurnace.findOne({ _id: { $ne: hostedNetwork._id }, lowercase: lowercase }).populate('hostedFurnaceImage');;

        if (hostedNetworkNameCheck && hostedNetworkNameCheck instanceof HostedFurnace)
          throw new Error('Network name is already in use');


        if (hostedNetwork.discoverable == true && hostedNetwork.lowercase != lowercase) {
          hostedNetwork.approved = false;  ///must be approved again
        }

        hostedNetwork.name = body.newName.trim();
        hostedNetwork.lowercase = lowercase;

        await HostedFurnace.updateOne({ '_id': hostedNetwork._id }, { $set: { name: hostedNetwork.name, lowercase: hostedNetwork.lowercase, approved: hostedNetwork.approved } });

        changed = true;

      }
    }

    if (body.discoverable != null) {

      if (body.discoverable == true) {
        ///see if discoverablity was turned off
        if (hostedNetwork.override == true) throw new Error("Cannot set to discoverable. Network name, description, or image contains content that is not appropriate for general audiences.");
      }
      ///auto approved networks in pre production
      if (process.env.NODE_ENV !== 'production') {
        hostedNetwork.approved = true;
      } else {
        hostedNetwork.approved = false;  ///must be approved again
      }
      hostedNetwork.discoverable = body.discoverable;

      await HostedFurnace.updateOne({ '_id': hostedNetwork._id }, { $set: { discoverable: hostedNetwork.discoverable, approved: hostedNetwork.approved } });
      changed = true;
    }

    if (body.adultOnly != undefined || body.adultOnly != null) {
      hostedNetwork.adultOnly = body.adultOnly;
      await HostedFurnace.updateOne({ '_id': hostedNetwork._id }, { $set: { adultOnly: hostedNetwork.adultOnly } });
      changed = true;
    }

    if (body.accessCode != undefined || body.accessCode != null) {
      hostedNetwork.key = body.accessCode;
      await HostedFurnace.updateOne({ '_id': hostedNetwork._id }, { $set: { key: hostedNetwork.key } });
      changed = true;
    }

    if (body.description != undefined || body.description != null) {
      ///auto approved networks in pre production
      if (process.env.NODE_ENV !== 'production') {
        hostedNetwork.approved = true;
      } else {
        hostedNetwork.approved = false;  ///must be approved again
      }
      hostedNetwork.description = body.description;
      await HostedFurnace.updateOne({ '_id': hostedNetwork._id }, { $set: { description: hostedNetwork.description, approved: hostedNetwork.approved } });
      changed = true;
    }

    if (body.link != undefined || body.link != null) {
      hostedNetwork.link = body.link;
      await HostedFurnace.updateOne({ '_id': hostedNetwork._id }, { $set: { link: hostedNetwork.link } });
      changed = true;
    }

    if (body.memberAutonomy != undefined || body.memberAutonomy != null) {
      hostedNetwork.memberAutonomy = body.memberAutonomy;
      await HostedFurnace.updateOne({ '_id': hostedNetwork._id }, { $set: { memberAutonomy: hostedNetwork.memberAutonomy } });
      changed = true;
    }

    var wallCircle = null;

    if (body.enableWall != undefined || body.enableWall != null) {

      hostedNetwork.enableWall = body.enableWall;
      await HostedFurnace.updateOne({ '_id': hostedNetwork._id }, { $set: { enableWall: hostedNetwork.enableWall } });
      changed = true;

      if (hostedNetwork.enableWall == true) {
        wallCircle = await createWall(req.user);
      }
    }

    if (changed == true) {

      //commented out to support concurrency
      //await hostedNetwork.save();

      // return res.status(200).send({
      //   msg: 'success',
      // });

      let payload = { msg: 'success', };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);

    } else {
      throw new Error('nothing changed');
    }

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});


router.post('/setrole/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await User.findById(req.user.id).populate('hostedFurnace');


    if (body.hostedName.trim().toLowerCase().includes('ironforge')) {

      /// don't allow role changes through the API for the IronForge
      throw new Error("Unauthorized");

      /*
      //verify the user is an IC admin
      if (user.role != constants.ROLE.IC_ADMIN)
        throw new Error("unauthorized");

      let member = await User.findById(body.memberID);
      member.role = body.role;
      await member.save();

      return res.status(200).send({
        msg: 'success',
      });
      */

    } else {
      //verify the user is on the network
      if (user.hostedFurnace.name != body.hostedName || user.hostedFurnace.key != body.key)
        throw new Error("Unauthorized");

      //verify the user is a network admin
      if (user.role != constants.ROLE.ADMIN && user.role != constants.ROLE.OWNER)
        throw new Error("Unauthorized");

      let member = await User.findById(body.memberID);

      if (user.role == constants.ROLE.OWNER && body.role == constants.ROLE.OWNER) {
        ///owner is transferring ownership
        user.role = constants.ROLE.ADMIN;
        await user.save();
      } else if (member.role == constants.ROLE.OWNER) {
        ///admin is trying to change owner role
        throw new Error("Only the owner of a network can transfer ownership");
      }

      member.role = body.role;
      await member.save();

      // return res.status(200).send({
      //   msg: 'success',
      // });

      let payload = { msg: 'success' };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);

    }



  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

router.post('/nameandaccesscode/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await User.findById(req.user.id).populate('hostedFurnace');

    if (body.hostedName.trim().toLowerCase().includes('ironforge')) {

      throw new Error("Unauthorized");

    } else {
      //verify the user is on the network
      //if (user.hostedFurnace.name != body.hostedName /*|| user.hostedFurnace.key != body.key*/)
      // throw new Error("unauthorized");

      //verify the user is a network admin
      if (user.role != constants.ROLE.ADMIN && user.role != constants.ROLE.OWNER)
        throw new Error("Unauthorized");


      let lowercase = body.newName.trim().toLowerCase();

      if (lowercase.includes('ironforge') || lowercase.includes('iron forge') || lowercase.includes('iron  forge')) {
        throw new Error('Network name is already in use');
      } else {
        let hostedFurnace = await HostedFurnace.findOne({ _id: { $ne: user.hostedFurnace._id }, lowercase: lowercase });

        if (hostedFurnace && hostedFurnace instanceof HostedFurnace)
          throw new Error('Network name is already in use');

      }

      if (user.hostedFurnace.discoverable == true && user.hostedFurnace.lowercase != lowercase) {
        user.hostedFurnace.approved = false; ///name must be checked again
      }

      user.hostedFurnace.name = body.newName.trim();
      user.hostedFurnace.lowercase = lowercase;
      user.hostedFurnace.key = body.accessCode;


      await user.hostedFurnace.save();

      // return res.status(200).send({
      //   msg: 'success',
      // });
      
      let payload = {  msg: 'success', };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);
    }



  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

//Deprecated; delete after everyone is on 91+
router.post('/accesscode/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    var user = await User.findById(req.user.id).populate('hostedFurnace');

    if (req.body.hostedName.trim().toLowerCase().includes('ironforge')) {

      throw new Error("Unauthorized");

    } else {
      //verify the user is on the network
      if (user.hostedFurnace.name != req.body.hostedName /*|| user.hostedFurnace.key != req.body.key*/)
        throw new Error("Unauthorized");

      //verify the user is a network admin
      if (user.role != constants.ROLE.ADMIN && user.role != constants.ROLE.OWNER)
        throw new Error("Unauthorized");

      user.hostedFurnace.key = req.body.accessCode;
      await user.hostedFurnace.save();

      return res.status(200).send({
        msg: 'success',
      });

    }



  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

router.post('/lockout/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await User.findById(req.user.id).populate('hostedFurnace');
    let member = await User.findById(body.memberID);

    if (body.hostedName.trim().toLowerCase().includes('ironforge')) {

      //verify the user is an IC admin
      if (user.role != constants.ROLE.IC_ADMIN)
        throw new Error("Unauthorized");

      member.lockedOut = body.lockedOut;
      await member.save();


    } else {
      //verify the user is on the network
      if (user.hostedFurnace.name != body.hostedName || user.hostedFurnace.key != body.key)
        throw new Error("Unauthorized");

      //verify the user is a network admin
      if (user.role != constants.ROLE.ADMIN && user.role != constants.ROLE.OWNER)
        throw new Error("Unauthorized");

      if (member.role == constants.ROLE.OWNER)
        throw new Error("The owner of a network cannot be locked out");

      member.lockedOut = body.lockedOut;
      await member.save();

    }

    ///remove any usercircle ratchet keys to the user won't get messages while they are locked out
    if (body.lockedOut == true) {
      try {
        await UserCircle.updateMany({ 'user': member._id, removeFromCache: null }, { $pull: { 'ratchetPublicKeys': { user: member._id } } });
      } catch (err) {
        logUtil.logError(err, true);
      }

    }

    // return res.status(200).send({
    //   msg: 'success',
    // });

    let payload = { msg: 'success' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

router.post('/members', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {


    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await User.findById(req.user.id).populate('hostedFurnace');

    var members = [];

    if (body.hostedName.trim().toLowerCase().includes('ironforge')) {

      ///verify the user is on the ironforge
      if (user.hostedFurnace != null && user.hostedFurnace != undefined)
        throw new Error("unauthorized");

      members = await User.find({ hostedFurnace: null, keyGen: true }).sort({ lowercase: 1 });


    } else {
      //verify the user is on the network
      //if (user.hostedFurnace.lowercase != body.hostedName.toLowerCase())
      //  throw new Error("unauthorized");

      //the check above is unnecessary because the function only returns the uer's network members

      members = await User.find({ hostedFurnace: user.hostedFurnace._id }).sort({ lowercase: 1 });
    }

    let connections = [];

    let userConnection = await UserConnection.findOne({ user: req.user.id }).populate('connections').exec();

    if (userConnection instanceof UserConnection) {
      connections = userConnection.connections;
    }


    let memberCircles = [];

    if (body.includeMemberCircles != null && body.includeMemberCircles != undefined) {



      let results = await UserCircle.find({ circle: ObjectId(body.includeMemberCircles), user: { $ne: ObjectId(user._id) } }).populate('user').populate('circle').populate('dm');

      for (let i = 0; i < results.length; i++) {
        memberCircles.push(new MemberCircle({ userID: user._id, memberID: results[i].user._id, circleID: results[i].circle._id, dm: results[i].circle.dm, }));
      }
    }

    // return res.status(200).send({
    //   user: user, members: members, userConnections: connections, memberCircles: memberCircles,
    // });

    let payload = { user: user, members: members, userConnections: connections, memberCircles: memberCircles, };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});



router.post('/getstorage', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await User.findById(req.user.id).populate('hostedFurnace');


    if (body.hostedName.trim().toLowerCase().includes('ironforge')) {
      throw new Error("Unauthorized");

    } else {
      //verify the user is on the network
      if (user.hostedFurnace.name != body.hostedName || user.hostedFurnace.key != body.key)
        throw new Error("Unauthorized");

      //verify the user is a network admin
      if (user.role != constants.ROLE.ADMIN && user.role != constants.ROLE.OWNER)
        throw new Error("Unauthorized");

      var hostedFurnaceStorage;

      if (user.hostedFurnace.storage.length == 0)
        hostedFurnaceStorage = new HostedFurnaceStorage({ location: '' });
      else
        hostedFurnaceStorage = user.hostedFurnace.storage[user.hostedFurnace.storage.length - 1];

      // return res.status(200).send({
      //   hostedFurnaceStorage: hostedFurnaceStorage,
      // });

      let payload = { hostedFurnaceStorage: hostedFurnaceStorage };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);

    }



  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

async function testLink(hostedFurnaceStorage) {
  try {

    let location = hostedFurnaceStorage.location;

    if (location == constants.BLOB_LOCATION.PRIVATE_S3 || location == constants.BLOB_LOCATION.PRIVATE_WASABI) {
      await s3Util.bucketTest(constants.BUCKET_TYPE.AVATAR, hostedFurnaceStorage);
      await s3Util.bucketTest(constants.BUCKET_TYPE.IMAGE, hostedFurnaceStorage);
    } else
      throw new Error("Could not connect");

    return true;

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    throw new Error('Could not connect to storage');
  }
}

router.post('/setstorage', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await User.findById(req.user.id).populate('hostedFurnace');

    if (body.hostedName.trim().toLowerCase().includes('ironforge')) {
      throw new Error("Unauthorized");

    } else {
      //verify the user is on the network
      if (user.hostedFurnace.name != body.hostedName || user.hostedFurnace.key != body.key)
        throw new Error("Unauthorized");

      //verify the user is a network admin
      if (user.role != constants.ROLE.ADMIN && user.role != constants.ROLE.OWNER)
        throw new Error("Unauthorized");

      let hostedFurnaceStorage = HostedFurnaceStorage({ location: body.location, accessKey: body.accessKey, secretKey: body.secretKey, region: body.region, mediaBucket: body.mediaBucket });

      let urls = await testLink(hostedFurnaceStorage);

      if (urls == undefined)
        throw new Error("Could not connect");

      user.hostedFurnace.storage.push(hostedFurnaceStorage);

      await user.hostedFurnace.save();

      // return res.status(200).send({
      //  msg: 'success',
      // }); 

      let payload = { msg: 'success', };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);

    }



  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});


function validateAPIKey(apikey) {

  try {
    return new Promise(function (resolve, reject) {
      if (!apikey) {
        return reject('Unauthorized');
      } else {

        if (process.env.NODE_ENV !== 'production')
          require('dotenv').load();

        if (apikey != process.env.apikey)
          return reject('Unauthorized');
        else
          return resolve('valid');
      }
    });

  } catch (err) {
    console.error(err);
    return reject(err);
  }

}

///used to pull all discoverable networks, POSTKYBER
router.get('/discoverable/:ageRestrict', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    ///don't return the key (passcode)
    let selectFields = '_id name lowercase override discoverable enableWall wallCircleID adultOnly description hostedFurnaceImage';

    var hostedNetworks;

    if (req.user.lowercase == 'google32395' || req.user.lowercase == 'apple27895') {
      hostedNetworks = await HostedFurnace.find({ discoverable: true, storeApproved: true, }).select(selectFields).populate('hostedFurnaceImage');
    } else if (req.user.role == constants.ROLE.IC_ADMIN) {

      hostedNetworks = await HostedFurnace.find({ discoverable: true, override: false }).select(selectFields).populate('hostedFurnaceImage');
    } else if (req.user.minor == true) {

      hostedNetworks = await HostedFurnace.find({ discoverable: true, approved: true, adultOnly: false, override: false }).select(selectFields).populate('hostedFurnaceImage');
    } else {
      hostedNetworks = await HostedFurnace.find({ discoverable: true, approved: true, override: false }).select(selectFields).populate('hostedFurnaceImage');
    }
    return res.status(200).send({
      hostedNetworks: hostedNetworks,
    });


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

router.post('/getdiscoverable/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    //let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    ///don't return the key (passcode)
    let selectFields = '_id name lowercase override discoverable enableWall wallCircleID adultOnly description hostedFurnaceImage';

    var hostedNetworks;

    if (req.user.lowercase == 'google32395' || req.user.lowercase == 'apple27895') {
      hostedNetworks = await HostedFurnace.find({ discoverable: true, storeApproved: true, }).select(selectFields).populate('hostedFurnaceImage');
    } else if (req.user.role == constants.ROLE.IC_ADMIN) {

      hostedNetworks = await HostedFurnace.find({ discoverable: true, override: false }).select(selectFields).populate('hostedFurnaceImage');
    } else if (req.user.minor == true || req.user.allowClosed == false) {

      hostedNetworks = await HostedFurnace.find({ discoverable: true, approved: true, adultOnly: false, override: false }).select(selectFields).populate('hostedFurnaceImage');
    } else {
      hostedNetworks = await HostedFurnace.find({ discoverable: true, approved: true, override: false }).select(selectFields).populate('hostedFurnaceImage');
    }
    // return res.status(200).send({
    //   hostedNetworks: hostedNetworks,
    // });

    let payload = { hostedNetworks: hostedNetworks, };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

//used to pull discoverable networks from the landing page, POSTKYBER
router.get('/alldiscoverable', async (req, res) => {
  try {

    ///don't return the key (passcode)
    let selectFields = '_id name lowercase override discoverable enableWall wallCircleID adultOnly description hostedFurnaceImage';

    var hostedNetworks;
    //hostedNetworks = await HostedFurnace.find({ discoverable: true, storeApproved: true, }).select(selectFields).populate('hostedFurnaceImage');
    hostedNetworks = await HostedFurnace.find({ discoverable: true, approved: true, override: false }).select(selectFields).populate('hostedFurnaceImage');

    return res.status(200).send({
      hostedNetworks: hostedNetworks
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});

router.post('/getalldiscoverable', async (req, res) => {
  try {

    ///don't return the key (passcode)
    let selectFields = '_id name lowercase override discoverable enableWall wallCircleID adultOnly description hostedFurnaceImage';

    var hostedNetworks;
    //hostedNetworks = await HostedFurnace.find({ discoverable: true, storeApproved: true, }).select(selectFields).populate('hostedFurnaceImage');
    hostedNetworks = await HostedFurnace.find({ discoverable: true, approved: true, override: false }).select(selectFields).populate('hostedFurnaceImage');

    // return res.status(200).send({
    //   hostedNetworks: hostedNetworks
    // });

    let payload = { hostedNetworks: hostedNetworks };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});

//used to pull discoverable networks for IC admins
router.get('/pendingdiscoverable', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    let user = await User.findById(req.user.id);
    ///don't return the key (passcode)
    let selectFields = '_id name lowercase discoverable override approved enableWall wallCircleID adultOnly description hostedFurnaceImage storage lastUpdate';

    ///verify user is ic admin
    if (user.role != constants.ROLE.IC_ADMIN) throw new Error('access denied');

    var hostedNetworks = await HostedFurnace.find({ discoverable: true, $or: [{ approved: false }, { approved: undefined }, { override: true }] }).sort({ lastUpdate: -1 }).select(selectFields).populate('hostedFurnaceImage');

    return res.status(200).send({
      hostedNetworks: hostedNetworks,
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});

//used to pull discoverable networks for IC admins
router.post('/getpendingdiscoverable', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    let user = req.user; //await User.findById(req.user.id);
    ///don't return the key (passcode)
    let selectFields = '_id name lowercase discoverable override approved enableWall wallCircleID adultOnly description hostedFurnaceImage storage lastUpdate';

    ///verify user is ic admin
    if (user.role != constants.ROLE.IC_ADMIN) throw new Error('access denied');

    var hostedNetworks = await HostedFurnace.find({ discoverable: true, $or: [{ approved: false }, { approved: undefined }, { override: true }] }).sort({ lastUpdate: -1 }).select(selectFields).populate('hostedFurnaceImage');

    // return res.status(200).send({
    //   hostedNetworks: hostedNetworks,
    // });

    let payload = { hostedNetworks: hostedNetworks, };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});

router.put('/setapproved', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let user = await User.findById(req.user.id);
    ///don't return the key (passcode)
    let selectFields = '_id name lowercase discoverable override approved enableWall wallCircleID adultOnly description hostedFurnaceImage storage';

    let hostedFurnace = await HostedFurnace.findById(body.furnaceID).select(selectFields).populate('hostedFurnaceImage');

    ///verify user is ic admin
    if (user.role != constants.ROLE.IC_ADMIN) throw new Error('access denied');

    hostedFurnace.approved = body.approved;
    await hostedFurnace.save();

    // return res.status(200).send({
    //   hostedFurnace: hostedFurnace,
    // });

    let payload = { hostedFurnace: hostedFurnace, };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});

router.put('/setoverride', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let user = await User.findById(req.user.id);
    ///don't return the key (passcode)
    let selectFields = '_id name lowercase discoverable override approved enableWall wallCircleID adultOnly description hostedFurnaceImage storage';

    var hostedFurnace = await HostedFurnace.findById(body.furnaceID).select(selectFields).populate('hostedFurnaceImage');

    ///verify user is ic admin
    if (user.role != constants.ROLE.IC_ADMIN) throw new Error('access denied');

    hostedFurnace.override = body.override;
    await hostedFurnace.save();

    // return res.status(200).send({
    //   hostedFurnace: hostedFurnace,
    // });

    let payload = { hostedFurnace: hostedFurnace, };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});


///allows an owner to toggle whether a network is discoverable or not
router.put('/discoverable', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {


    //if (hostedNetwork.owner != req.user.id) throw new Error('access denied');
    let user = await User.findById(req.user.id).populate('hostedFurnace');
    let hostedNetwork = user.hostedFurnace;

    //if the user is on the forge, then they can't change the discoverable setting
    if (hostedNetwork == null || hostedNetwork == undefined) throw new Error('access denied');

    //verify the user owns the hosted network
    if (user.role != constants.ROLE.OWNER) throw new Error('access denied');

    //validate the parameters
    if (req.body.discoverable == undefined || req.body.discoverable == null) throw new Error('access denied');


    if (req.body.discoverable == true) {
      ///see if discoverablity was turned off
      if (hostedNetwork.override == true) throw new Error("Network name or image contains inappropriate content.");
      else
        hostedNetwork.approved = false;
    }

    //set the discoverable variable
    hostedNetwork.discoverable = req.body.discoverable;
    if (process.env.NODE_ENV !== 'production') {
      hostedNetwork.approved = true;
    }
    await hostedNetwork.save();

    return res.status(200).send({
      msg: 'success',
    });




  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});





///allows an owner to toggle whether a network is adult only or not



///used for owner to change the network image
router.put('/networkimage', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    let user = await User.findOne({ "_id": req.user.id }).populate('hostedFurnace');

    //verify the user is on the network
    if (user.hostedFurnace.name != body.hostedName || user.hostedFurnace.key != body.key) {

      throw new Error("Access denied");
    }

    //also check if the user is the owner
    if (user.role != constants.ROLE.OWNER) {
      throw new Error("Access denied");
    }

    let hostedFurnaceImage = new HostedFurnaceImage();

    hostedFurnaceImage.name = body.name;
    hostedFurnaceImage.size = body.size;
    hostedFurnaceImage.location = body.location;


    await hostedFurnaceImage.save();

    user.hostedFurnace.hostedFurnaceImage = hostedFurnaceImage;
    user.hostedFurnace.approved = false; ///must be approved again
    await user.hostedFurnace.save();

    // return res.status(200).json({ hostedFurnaceImage: hostedFurnaceImage });

    let payload = { hostedFurnaceImage: hostedFurnaceImage };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

///only used for a logged in user to get a modified network image
router.get('/networkimage:id', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    //AUTHORIZATION CHECK
    let user = await User.findOne({ "_id": req.user.id }).populate('hostedFurnace');

    //verify the user is on the network
    if (user.hostedFurnace.name != req.body.hostedName || user.hostedFurnace.key != req.body.key) {

      throw new Error("Access denied");
    }

    let hostedFurnaceImage = await HostedFurnaceImage.findOne({ "_id": req.params.id });

    return res.status(200).json({ hostedFurnaceImage: hostedFurnaceImage });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});



//generate wall circle
async function createWall(user) {

  try {

    let owner = await User.findById(user._id).populate('hostedFurnace');
    if (owner.role != constants.ROLE.IC_ADMIN && owner.role != constants.ROLE.OWNER && owner.role != constants.ROLE.ADMIN) throw new Error('access denied');

    let network = owner.hostedFurnace;

    ///does the wall already exist?
    let circle = await Circle.findOne({ type: constants.CIRCLE_TYPE.WALL, owner: owner._id });

    if (circle instanceof Circle) {
      //add the users ratchets
      let networkUsers = await User.find({ hostedFurnace: network._id });

      for (let j = 0; j < networkUsers.length; j++) {
        let networkUser = networkUsers[j];

        //does the usercircle already exist?
        let userCircle = await UserCircle.findOne({ user: networkUser._id, circle: circle._id });

        if (!(userCircle instanceof UserCircle)) {
          userCircle = new UserCircle({
            user: networkUser._id,
            circle: circle.id,
            hidden: false,
            prefName: 'Network Feed',
            lastItemUpdate: Date.now(),
            wall: true,
            ratchetPublicKeys: [networkUser.ratchetPublicKey],
            newItems: 0,
            showBadge: false,
          });
        } else {
          //is the ratchet key already there?
          let ratchetKey = userCircle.ratchetPublicKeys.find(x => x.ratchetIndex == networkUser.ratchetPublicKey.ratchetIndex);

          if (!(ratchetKey instanceof RatchetPublicKey)) {
            userCircle.ratchetPublicKeys.push(networkUser.ratchetPublicKey);
          }
        }

        //check to see if this user is using multiple devices
        for (let k = 0; k < networkUser.devices.length; k++) {
          let device = networkUser.devices[k];

          if (device.uuid == '' || device.pushToken == null)
            continue;

          networkUser.ratchetPublicKey.device = device.uuid;
          userCircle.ratchetPublicKeys.push(networkUser.ratchetPublicKey);

        }

        let mute = true;

        for (let k = 0; k < networkUser.devices.length; k++) {

          let device = networkUser.devices[k];

          if (device.build > 127) {
            mute = false;
            break;
          }

        }

        userCircle.mute = mute;
        // save the usercircle
        await userCircle.save();

      }

    } else {
      ///the wall doesn't exist so create it

      ///create the circle for the network
      circle = new Circle({
        ownershipModel: constants.CIRCLE_OWNERSHIP.OWNER,
        votingModel: constants.VOTE_MODEL.UNANIMOUS,
        owner: owner,
        type: constants.CIRCLE_TYPE.WALL,
        privacyShareImage: true,
      });

      // save the circle
      await circle.save();

      ///add the circle to the newtork
      network.wallCircleID = circle._id;
      await network.save();

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
          prefName: 'Network Feed',
          //ratchetIndex: RatchetIndex.new(req.body.ratchetIndex),
          ratchetPublicKeys: [networkUser.ratchetPublicKey],
          newItems: 0,
          showBadge: false,
        });

        //check to see if this user is using multiple devices
        for (let k = 0; k < networkUser.devices.length; k++) {
          let device = networkUser.devices[k];

          if (device.uuid == '' || device.pushToken == null)
            continue;

          networkUser.ratchetPublicKey.device = device.uuid;
          usercircle.ratchetPublicKeys.push(networkUser.ratchetPublicKey);

        }

        // save the usercircle
        await usercircle.save();

      }
    }

    ///RBR
    //network.wallCircleID = circle._id;
    //await network.save();


    let ownerUserCircle = await UserCircle.findOne({ user: owner, circle: circle._id }).populate('circle').populate('user');


    return ownerUserCircle;

  } catch (err) {
    var msg = await logUtil.logError(err, true);
  }

}

module.exports = router;
