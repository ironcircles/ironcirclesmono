const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const passport = require('passport');
const NetworkRequest = require('../models/networkrequest');
const logUtil = require('../util/logutil');
const User = require('../models/user');
const ActionRequired = require('../models/actionrequired');
const HostedFurnace = require('../models/hostedfurnace');
const DeviceLogicSingle = require('../logic/devicelogicsingle');
const constants = require('../util/constants');
const deviceLogic = require('../logic/devicelogic');
const ObjectId = require('mongodb').ObjectId;
const kyberLogic = require('../logic/kyberlogic');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());


router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {


    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);


    //console.log(body);

    //load the hostedfurnace
    let hostedFurnace = await HostedFurnace.findById(body.hostedFurnaceID);

    if (!(hostedFurnace instanceof HostedFurnace)) {
      throw new Error('access denied');
    }

    //make sure the user wasn't denied already
    let existingRequest = await NetworkRequest.findOne({ user: req.user._id, hostedFurnace: hostedFurnace._id });

    if (existingRequest instanceof NetworkRequest) {

      if (existingRequest.status == constants.NETWORK_REQUEST_STATUS.CANCELED_AFTER_DECLINED) {
        throw ('user can no longer request to join this network');
      } else if (existingRequest.status != constants.NETWORK_REQUEST_STATUS.CANCELED) {
        throw ('a request to join this network already exists');
      } else {
        await NetworkRequest.deleteOne(existingRequest);
      }
    }

    let networkRequest = await NetworkRequest.new(body.networkRequest);

    //console.log(networkRequest.status + ' ' + networkRequest.description);

    networkRequest.hostedFurnace = hostedFurnace;
    networkRequest.user = req.user;
    networkRequest.status = constants.NETWORK_REQUEST_STATUS.PENDING;
    await networkRequest.save();

    //find network owner
    let owner = await User.findOne({ hostedFurnace: hostedFurnace._id, role: constants.ROLE.OWNER }).populate('devices');
    let request = await NetworkRequest.findOne({ hostedFurnace: hostedFurnace, user: req.user, status: constants.NETWORK_REQUEST_STATUS.PENDING });

    ///check for existing action required
    let action = await ActionRequired.findOne({
      alertType: constants.ACTION_REQUIRED.USER_REQUESTED_JOIN_NETWORK,
      user: owner._id,
      requestHostedFurnace: hostedFurnace._id,
    });
    ///check for empty one
    if (!action) {
      let altAction = await ActionRequired.findOne({
        alertType: constants.ACTION_REQUIRED.USER_REQUESTED_EMPTY,
        user: owner._id,
        requestHostedFurnace: hostedFurnace._id
      });
      if (!altAction) {
        ///check recipient user's devices
        ///if any device on build < 128, don't make action required
        let sendActionRequired = true;
        for (let i = 0; i < owner.devices.length; i++) {
          let device = owner.devices[i];
          if (device.build < 128) {
            sendActionRequired = false;
          }
        }
        if (sendActionRequired == true) {
          ///make one
          let actionReq = new ActionRequired({
            alertType: constants.ACTION_REQUIRED.USER_REQUESTED_JOIN_NETWORK,
            user: owner._id,
            requestHostedFurnace: hostedFurnace._id,
          });
          await actionReq.save();
        }
      } else {
        ///update alertType of existing
        altAction.alertType = constants.ACTION_REQUIRED.USER_REQUESTED_JOIN_NETWORK;
        await altAction.save();
      }
    }

    deviceLogic.sendActionNeededNotification(owner, req.user.username + 'has requested to join your network');
    //res.status(200).json({ networkRequest: networkRequest });

    let payload = { networkRequest: networkRequest };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});

router.put('/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let user = await User.findById(req.user._id).populate('hostedFurnace');
    let hostedFurnace = await HostedFurnace.findById(body.hostedFurnaceID);
    let networkRequest = await NetworkRequest.findById(body.networkRequestID).populate(["hostedFurnace", { path: "user", populate: [{ path: 'devices' }] }]);

    if (!(hostedFurnace instanceof HostedFurnace)) {
      throw new Error('access denied');
    }
    if (!(user instanceof User)) {
      throw new Error('access denied');
    }
    if (!(networkRequest instanceof NetworkRequest)) {
      throw ('request not found');
    }

    let owner = false;

    //is this the requestor?
    if (user._id.equals(networkRequest.user._id)) {

      if (body.networkRequest.status == constants.NETWORK_REQUEST_STATUS.CANCELED) {
        if (networkRequest.status == constants.NETWORK_REQUEST_STATUS.DECLINED) {
          networkRequest.status = constants.NETWORK_REQUEST_STATUS.CANCELED_AFTER_DECLINED;
        } else {
          networkRequest.status = constants.NETWORK_REQUEST_STATUS.CANCELED;
        }

        let action = await ActionRequired.findOne({
          hostedFurnace: hostedFurnace._id,
          alertType: constants.ACTION_REQUIRED.USER_REQUESTED_JOIN_NETWORK
        });
        let requests = await NetworkRequest.find({ hostedFurnace: hostedFurnace._id, status: constants.NETWORK_REQUEST_STATUS.PENDING });
        if (action) {
          if (requests.length <= 1) {
            action.alertType = constants.ACTION_REQUIRED.USER_REQUESTED_EMPTY;
            await action.save();
          }
        }

      } else {
        throw ('invalid status');
      }

    } else {

      //verify it is the owner
      if (user.hostedFurnace._id.equals(hostedFurnace._id)) {
        if (user.role != constants.ROLE.OWNER && user.role != constants.ROLE.ADMIN && user.role != constants.ROLE.IC_ADMIN) {
          throw ('only the owner or admin can approve requests');
        }

        owner = true;
        if (body.networkRequest.status == constants.NETWORK_REQUEST_STATUS.APPROVED) {
          networkRequest.status = constants.NETWORK_REQUEST_STATUS.APPROVED;

          ///check recipient user's devices
          ///if any device on build < 128, don't make action required
          let sendActionRequired = true;
          for (let i = 0; i < networkRequest.user.devices.length; i++) {
            let device = networkRequest.user.devices[i];
            if (device.build < 128) {
              sendActionRequired = false;
            }
          }
          if (sendActionRequired == true) {
            let actionRequired = new ActionRequired({ alertType: constants.ACTION_REQUIRED.NETWORK_REQUEST_APPROVED, alert: 'Your request to join the ' + user.hostedFurnace.name + ' network has been approved', user: networkRequest.user, networkRequest: networkRequest._id });
            await actionRequired.save();
          }

          let ownerReq = await ActionRequired.findOne({
            alertType: constants.ACTION_REQUIRED.USER_REQUESTED_JOIN_NETWORK,
            user: user._id,
            hostedFurnace: hostedFurnace._id
          });
          let requests = await NetworkRequest.find({ hostedFurnace: hostedFurnace._id, status: constants.NETWORK_REQUEST_STATUS.PENDING });
          if (ownerReq) {
            if (requests.length < 2) {
              ownerReq.alertType = constants.ACTION_REQUIRED.USER_REQUESTED_EMPTY;
              await ownerReq.save();
            }
          }

          //DeviceLogicSingle.sendNotificationToIndividual();
          deviceLogic.sendActionNeededNotification(networkRequest.user, 'Your request to join the ' + networkRequest.hostedFurnace.name + ' network has been approved');

        } else if (body.networkRequest.status == constants.NETWORK_REQUEST_STATUS.DECLINED) {
          networkRequest.status = constants.NETWORK_REQUEST_STATUS.DECLINED;
          let ownerReq = await ActionRequired.findOne({ alertType: constants.ACTION_REQUIRED.USER_REQUESTED_JOIN_NETWORK, user: user._id, hostedFurnace: hostedFurnace._id });

          if (ownerReq != null) {
            let requests = await NetworkRequest.find({ hostedFurnace: hostedFurnace._id, status: constants.NETWORK_REQUEST_STATUS.PENDING });
            if (requests.length < 2) {
              ownerReq.alertType = constants.ACTION_REQUIRED.USER_REQUESTED_EMPTY;
              await ownerReq.save();
            }
          }
        }
        else {
          throw ('invalid status');
        }

      } else {
        throw ('invalid request');

      }
    }

    await networkRequest.save();
    await networkRequest.populate([{ path: 'user', select: constants.POPULATE_REDUCED_FIELDS.USER }, { path: 'hostedFurnace', select: constants.POPULATE_REDUCED_FIELDS.HOSTED_FURNACE }]);

    var updatedRequests = [];

    if (owner) {
      updatedRequests = await NetworkRequest.find({ hostedFurnace: user.hostedFurnace._id, $or: [{ status: constants.NETWORK_REQUEST_STATUS.PENDING }, { status: constants.NETWORK_REQUEST_STATUS.DECLINED }] })
        .populate('user').populate('hostedFurnace');
    }

    //res.status(200).json({ networkRequest: networkRequest, updatedRequests: updatedRequests });

    let payload = { networkRequest: networkRequest, updatedRequests: updatedRequests };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});

router.post('/getforowner/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    //let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //returns all pending requests if you are the owner
    let user = await User.findById(req.user._id).populate('hostedFurnace');

    //verify it is a valid user
    if (!(user instanceof User)) {
      throw new Error('access denied');
    }

    //verify it is the owner
    if (user.role != constants.ROLE.OWNER && user.role != constants.ROLE.ADMIN && user.role != constants.ROLE.IC_ADMIN) {
      throw new Error('access denied');
    }

    let hostedFurnace = user.hostedFurnace;
    let networkRequests = await NetworkRequest.find({ hostedFurnace: hostedFurnace._id, $or: [{ status: constants.NETWORK_REQUEST_STATUS.PENDING }, { status: constants.NETWORK_REQUEST_STATUS.DECLINED }] }).sort({ created: -1 })
      .populate('user').populate('hostedFurnace');

    //res.status(200).json({ networkRequests: networkRequests });

    let payload = { networkRequests: networkRequests };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});

router.post('/getmyrequests/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    //let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //find only pending, accepted, or declined requests. Canceled requests are not shown. 
    let networkRequests = await NetworkRequest.find({ user: req.user._id, $or: [{ status: constants.NETWORK_REQUEST_STATUS.PENDING }, { status: constants.NETWORK_REQUEST_STATUS.DECLINED }, { status: constants.NETWORK_REQUEST_STATUS.APPROVED }] })
      .populate({ path: 'user', select: constants.POPULATE_REDUCED_FIELDS.USER }).populate({ path: 'hostedFurnace', select: constants.POPULATE_REDUCED_FIELDS.HOSTED_FURNACE });

    //res.status(200).json({ networkRequests: networkRequests });

    let payload = { networkRequests: networkRequests };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});



module.exports = router;