/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Control avatars.  
 * 
 * Implements post/put/get for users to control their own avatars.  
 * 
 * Delete user is not a feature yet, so there is no delete. Create one already.
 * 
 *  
 ***************************************************************************/
const kyberLogic = require('../logic/kyberlogic');
const express = require('express');
const router = express.Router();
const passport = require('passport');
const User = require('../models/user');
const Avatar = require('../models/avatar');
const securityLogic = require('../logic/securitylogic');
const ObjectID = require('mongodb').ObjectID;
const logUtil = require('../util/logutil');
const mongoose = require('mongoose');
const constants = require('../util/constants');
const gridFS = require('../util/gridfsutil');
const s3Util = require('../util/s3util');
let Grid = require('gridfs-stream');
Grid.mongo = mongoose.mongo;

const bodyParser = require('body-parser');
router.use(bodyParser.json({ limit: '50mb' }));
router.use(bodyParser.urlencoded({ limit: '50mb', extended: true, parameterLimit: 50000 }));

/*
router.post('/', passport.authenticate('jwt', { session: false}), function(req, res) {

   //SECURITY CHECK
   if (req.user.id != req.headers.userid)
      return res.status(400).json({msg: 'Access denied'});

    var avatarID;

    gridFS.saveBlob(req, res, "avatar", "avatars", req.user.id)
    .then((id) => {   
      if (!id) throw("Failed to save avatar"); 

      avatarID = id;
      //load the user
      return User.findOne({"_id": req.user.id});
    })
    .then((user) => { 
      if (!user) throw("Failed to save avatar"); 
      
      user.avatar = avatarID;
      return user.save();
    })
    .then((user) => {
      if (!user) throw("Failed to save avatar"); 

      return res.status(200).json({avatar: user.avatar});
    })
    .catch((err) => {
      console.error(err);
      return res.status(500).json({msg: err.message});
    });

});
*/


router.put('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    //token check is enough

    let avatar = new Avatar();

    avatar.name = body.name;
    avatar.size = body.size;
    avatar.location = body.location;

    let user = await User.findOne({ "_id": req.user.id });

    /*  shouldn't have to delete, filename is the same
    if (user.avatar != undefined){
        //delete the blob
        s3Util.deleteBlob(constants.BUCKET_TYPE.AVATAR, user.avatar.name);
    }*/
    let oldAvatar = user.avatar;

    user.avatar = avatar;
    await user.save();


    if (oldAvatar != null) {
      //update any linkedAccounts
      await User.updateMany({ linkedUser: user._id, 'avatar.name': oldAvatar.name }, { avatar: avatar });

    }

    //return res.status(200).json({ avatar: user.avatar });

    let payload = { avatar: user.avatar };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});


router.get('/:id', passport.authenticate('jwt', { session: false }), (req, res) => {

  //SECURITY CHECK - Userid passed in won't always matched logged in user.  Have to get fancy.
  securityLogic.canUserAccessAvatar(req.user.id, req.params.id, req.headers.circleid, (success) => {

    if (!success)
      return res.status(400).json({ msg: 'Access denied' });


    try {
      var userID = new ObjectID(req.params.id);
    } catch (err) {
      console.error(err);
      return res.status(400).json({ msg: 'Invalid parameter' });
    }

    //load the user
    User.findOne({ "_id": userID })
      .then((user) => {
        if (!user) throw ("Could not find user");

        if (user.avatar)
          return gridFS.loadBlob(res, "avatars", user.avatar);
        else
          return res.status(200).json({ msg: 'No avatar' });
      })
      .catch((err) => {
        console.error(err);
        return res.status(500).json({ msg: err.message });
      });

  });

});


module.exports = router;