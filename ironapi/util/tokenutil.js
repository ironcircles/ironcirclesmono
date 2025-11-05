//const passport = require('passport');
//require('../config/passport')(passport);
//var jwt = require('jsonwebtoken');
 
  function getToken(headers) {
    if (headers && headers.authorization) {
      var parted = headers.authorization.split(' ');
      if (parted.length === 2) {
        return parted[1];
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

//module.exports.getToken = getToken;
