const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const passport = require('passport');
const AWS = require("aws-sdk");
const uuid = require("uuid");
const logUtil = require('./logutil');
const constants = require('./constants');
const securityLogicAsync = require('../logic/securitylogicasync');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}



module.exports.authorizationCheck = async function (type, userID, id) {
  try {
    //AUTHORIZATION CHECK
    if (type == constants.BLOB_AUTH_TYPE.CIRCLE) {

      var usercircle = await securityLogicAsync.canUserAccessCircle(userID, id);
      if (!usercircle)
        throw new Error('Access denied');
    } else if (type == constants.BLOB_AUTH_TYPE.USER) {
      if (userID != id)  //this is unnecessary, user has been authenticated through token
        throw new Error('Access denied');
    } else {
      throw new Error('Access denied');
    }

    return;

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    throw (err);
  }
}

