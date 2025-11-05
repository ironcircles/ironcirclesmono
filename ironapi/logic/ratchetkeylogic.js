const securityLogicAsync = require('../logic/securitylogicasync');
const UserCircle = require('../models/usercircle');

module.exports.getPublicKeys = async function (userID, circleID) {

    try {
  
    //Authorization Check
    var userCircle = await securityLogicAsync.canUserAccessCircle(userID, circleID);
    if (!userCircle instanceof UserCircle) {
      console.log("RatchetController access denied userid: " + userID + " circleid: " + circleID);

      throw Error("access denied");
    }

    if (userCircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }


    //include the current members; will need to create ratchet for self in case of reinstall or clearing cache
    let memberCircles = await UserCircle.find({ circle: userCircle.circle, removeFromCache: undefined, ratchetPublicKeys: { $ne: null }, beingVotedOut: { $ne: true } });


    let ratchetPublicKeys = [];

    for (let i = 0; i < memberCircles.length; i++) {
      for (let j = 0; j < memberCircles[i].ratchetPublicKeys.length; j++) {
        ratchetPublicKeys.push(memberCircles[i].ratchetPublicKeys[j]);
      }
    }

    return ratchetPublicKeys;

    } catch (err) {
      console.log(err)
    }
  
  }
  