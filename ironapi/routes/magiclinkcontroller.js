const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
mongoose.Promise = require('bluebird');
const logUtil = require('../util/logutil');
const HostedFurnace = require('../models/hostedfurnace');
const MagicNetworkLink = require('../models/magicnetworklink');
const User = require('../models/user');
const RatchetPublicKey = require('../models/ratchetpublickey');
const passport = require('passport');
const securityLogicAsync = require('../logic/securitylogicasync');
const constants = require('../util/constants');
const kyberLogic = require('../logic/kyberlogic');

var randomstring = require("randomstring");


if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());


router.post('/magiclinktonetworkvalidate', async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, null);

    //validate apikey
    validateAPIKey(body.apikey);

    //console.log(body.link);

    let magicNetworkLink = await MagicNetworkLink.findOne({ link: body.link, active: true }).populate('hostedFurnace').populate('inviter').populate('circle');

    if (!magicNetworkLink) {

      //If the link was clicked on in IronCircles, the url will be the firebase url
      magicNetworkLink = await MagicNetworkLink.findOne({ firebaseLink: body.link, active: true }).populate('hostedFurnace').populate('inviter').populate('circle');

      if (!magicNetworkLink)
        throw ('invitation not found or has expired');
    }


    if (magicNetworkLink.hostedFurnace == null) { //then it's the forge

      let key = randomstring.generate({
        length: 25,
        charset: 'alphanumeric'
      });

      let hostedFurnace = new HostedFurnace({ name: "IronForge", key: key, _id: key })

      magicNetworkLink.hostedFurnace = hostedFurnace;

    }

    // return res.status(200).send({
    //   magicNetworkLink: magicNetworkLink,
    // });

    let payload = { magicNetworkLink: magicNetworkLink };
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

      /*if (user.hostedFurnace.name != body.hostedName || user.hostedFurnace.key != body.key) {

        throw new Error('access denied');
      }*/

      hostedFurnace = user.hostedFurnace;
    }

    let magicNetworkLink = new MagicNetworkLink({ inviter: req.user.id, link: body.link, firebaseLink: body.firebaseLink, hostedFurnace: hostedFurnace });

    magicNetworkLink.dm = false;
    if (body.dm != undefined && body.dm != null) {
      magicNetworkLink.dm = body.dm;
    }

    if (body.ratchetPublicKey != null) {
      let ratchetPublicKey = RatchetPublicKey({ user: req.user._id, device: body.ratchetPublicKey.device, public: body.ratchetPublicKey.public, keyIndex: body.ratchetPublicKey.keyIndex });
      magicNetworkLink.ratchetPublicKey = ratchetPublicKey;
    }

    await magicNetworkLink.save();

    // return res.status(200).send({
    //   success: true,
    // });

    let payload = {  success: true };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

/*router.post('/magiclinktocircle', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    var userCircle = await securityLogicAsync.canUserAccessCircle(req.user.id, req.body.circleID);

    if (!userCircle)
      throw new Error('access denied');

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

    return res.status(200).send({
      url: url,
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});
*/



function validateAPIKey(apikey) {

  try {
    return new Promise(function (resolve, reject) {
      if (!apikey) {
        return reject('unauthorized');
      } else {

        if (process.env.NODE_ENV !== 'production')
          require('dotenv').load();

        if (apikey != process.env.apikey)
          return reject('unauthorized');
        else
          return resolve('valid');
      }
    });

  } catch (err) {
    console.error(err);
    return reject(err);
  }

}




module.exports = router;
