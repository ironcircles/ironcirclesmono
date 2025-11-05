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
const kyberLogic = require('../logic/kyberlogic');
const bodyParser = require('body-parser');
router.use(bodyParser.json({ limit: '50mb' }));
router.use(bodyParser.urlencoded({ limit: '50mb', extended: true, parameterLimit: 50000 }));

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

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


router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //AUTHORIZATION CHECK

    let dezgoToken = process.env.DEZGO_TOKEN;


    return res.status(200).json({ dezgoToken: dezgoToken });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});


module.exports = router;