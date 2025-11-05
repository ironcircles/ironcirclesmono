const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const CircleImage = require('../models/circleimage');
const CircleObject = require('../models/circleobject');
const Circle = require('../models/circle');
const DeviceRemoteWipe = require('../models/deviceremotewipe');
const User = require('../models/user');
var ActionRequired = require('../models/actionrequired');
var UserConnection = require('../models/userconnection');
const passport = require('passport');
const securityLogic = require('../logic/securitylogic');
const deviceLogic = require('../logic/devicelogic');
const constants = require('../util/constants');
const logUtil = require('../util/logutil');
var randomstring = require("randomstring");
const kyberLogic = require('../logic/kyberlogic');
const gridFS = require('../util/gridfsutil');
let Grid = require('gridfs-stream');
Grid.mongo = mongoose.mongo;


//const bodyParser =  require('body-parser');
const ObjectId = require('mongodb').ObjectId;
const UserCircle = require('../models/usercircle');
const circle = require('../models/circle');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

async function reserveAccount(username, device, hostedNetworkName) {
  try {
    let user = new User({ username: username, lockedOut: true, password: '$2a$10$nl5rxohzpQNoZ3wDmmxDYO/yuMkY5L6siRzuivNj1KU4TYvOA2O/q' });
    await user.save();
  } catch (err) {
    console.log(err);
  }

}


async function seedconnected(username) {

  try {

    let users = await User.find({ keyGen: true, tos: { $ne: null }, removeFromCache: null });


    for (i = 0; i < users.length; i++) {


      let user = users[i];

      let userConnection = new UserConnection({ user: user._id, connections: [] });
      let allConnections = [];


      let userCircles = await UserCircle.find({ user: user._id, removeFromCache: null }).populate('circle').populate('user');

      for (j = 0; j < userCircles.length; j++) {

        let userCircle = userCircles[j];

        if (userCircle.circle == null) continue;
        if (userCircle.circle._id.equals(ObjectId('621e6fd26673b8001559e701'))) continue; //beta
        if (userCircle.circle._id.equals(ObjectId('618b0b0bff07430015e599ad'))) continue; //product advisor
        if (userCircle.circle._id.equals(ObjectId('60f1ef59273ac50014b0e726'))) continue; //alpha


        //grab the usercircles that are not the current user
        let memberCircles = await UserCircle.find({ user: { $ne: user._id }, circle: userCircle.circle, removeFromCache: null }).populate('user');

        for (k = 0; k < memberCircles.length; k++) {

          let memberCircle = memberCircles[k];
          //use a string so the remove duplicates works
          allConnections.push(memberCircle.user._id.toString());

        }

      }

      if (allConnections.length > 0) {
        //Node.js syntax for removing duplicates
        let uniqueConnections = Array.from(new Set(allConnections));

        userConnection.connections = uniqueConnections;
        await userConnection.save();
      }

    }

    //console.log('dozo');
  } catch (err) {
    console.log(err);
  }


}


router.post('/seedconnected/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    if (req.user.role != constants.ROLE.IC_ADMIN)
      throw ('Unauthorized');

    seedconnected();

    res.status(200).json({ kickedOff: true });

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});

async function connectdm() {

  try {

    let userCircles = await UserCircle.find({ dm: { $ne: null } }).populate('circle').populate('user').populate('dm');;

    for (j = 0; j < userCircles.length; j++) {

      let userCircle = userCircles[j];

      //skip bad data
      if (!(userCircle.dm instanceof User)) continue;
      if (!(userCircle.circle instanceof Circle)) continue;


      ///see if the other user has a dm with this user (meaning no pending invitation)
      let otherUserCircle = await UserCircle.findOne({ user: userCircle.dm, circle: userCircle.circle, dm: userCircle.user, removeFromCache: null }).populate('circle').populate('user').populate('dm');;

      if (otherUserCircle instanceof UserCircle) {
        await UserCircle.updateOne({ _id: userCircle._id }, { $set: { dmConnected: true } });
        // await UserCircle.updateOne({ _id: otherUserCircle._id }, { $set: { dmConnected: true } });
        ///log the everything before running
        //console.log('start:' + j);
        /*console.log('userCircle.user: ' + userCircle.user._id);
        console.log('otherUserCircle.user: ' + otherUserCircle.user._id);
        console.log('userCircle.circle: ' + userCircle.circle._id);
        console.log('otherUserCircle.circle: ' + otherUserCircle.circle._id);
        console.log('userCircle.dm: ' + userCircle.dm._id);
        console.log('otherUserCircle.dm: ' + otherUserCircle.dm._id);
        console.log('userCircle: ' + userCircle._id);
        console.log('otherUserCircle: ' + otherUserCircle._id);
        console.log('end');*/

      }
    }



    //console.log('donzo');
  } catch (err) {
    console.log(err);
  }


}

router.post('/connectdm/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  //router.post('/connectdm/', async (req, res) => {
  try {

    if (req.user.role != constants.ROLE.IC_ADMIN)
      throw ('Unauthorized');

    connectdm();

    res.status(200).json({ kickedOff: true });

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});



router.post('/cleanupdeleted/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    if (req.user.role != constants.ROLE.IC_ADMIN)
      throw ('Unauthorized');

    let deletedUsers = await User.find({ removeFromCache: { $ne: null } });

    for (let i = 0; i < deletedUsers.length; i++) {

      let deletedUser = deletedUsers[i];

      await UserCircle.deleteMany({ user: deletedUser._id });

    }

    res.status(200).json({ kickedOff: true });

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});


router.post('/deactivatedevice/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    if (req.user.role != constants.ROLE.IC_ADMIN)
      throw ('Unauthorized');

    let device = await deviceLogic.deactivateDevice(req.body.userID, req.body.uuid);

    res.status(200).json({ deactivateDevice: device });

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});


router.post('/initremotewipe/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    if (req.user.role != constants.ROLE.IC_ADMIN)
      throw ('Unauthorized');


    let users = await User.find({ keyGen: true, tos: { $ne: null }, });

    for (let u = 0; u < users.length; u++) {
      let user = users[u];

      for (let d = 0; d < user.devices.length; d++) {

        let device = user.devices[d];

        let deviceRemoteWipe = DeviceRemoteWipe({
          users: [user], deviceOwner: user, uuid: device.uuid, code: randomstring.generate({
            length: 80,
            charset: 'alphabetic'
          })
        });

        await deviceRemoteWipe.save();
      }



    }

    res.status(200).json({ msg: 'complete' });

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});



router.put('/keycleanup/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {


    let validUser = await User.findById(req.user.id);


    if (validUser.role != constants.ROLE.IC_ADMIN) {
      await logUtil.logError('unauthorized access to keycleanup', true);
      throw ('Unauthorized');
    }

    let counter = 0;

    //FIRST CHECK
    //Remove any devices who's push token have expired or whose device has been deactivated
    let users = await User.find({ _id: req.body.id, 'devices.expiredToken': { $ne: null }, 'devices.pushToken': null });
    for (let i = 0; i < users.length; i++) {
      let user = users[i];

      let devices = user.devices;

      for (let d = 0; d < devices.length; d++) {

        let device = devices[d];

        //sanity check
        if (device.pushToken == null) {

          //console.log('pulled: ' + device.uuid);

          try {

            counter = counter + 1;
            await UserCircle.updateMany({ 'user': req.body.id, 'ratchetPublicKeys': { $ne: null } }, { $pull: { 'ratchetPublicKeys': { user: req.body.id, device: device.uuid, } } });
          } catch (err) {

            logUtil.logError(err, true);
          }
        }

      }

    }

    console.log('COUNTER FIRST: ' + counter);

    //SECOND check
    counter = 0;
    //TODO Remove any keys that are older than 90 days
    console.log('COUNTER SECOND: ' + counter);

    //THIRD CHECK (should go away after running a few times, replaced by FIRST above)
    counter = 0;
    let userCircles = await UserCircle.find({ _id: req.body.id, removeFromCache: null, ratchetPublicKeys: { $ne: null }, user: { $ne: null } }).populate('user');



    for (let i = 0; i < userCircles.length; i++) {

      let userCircle = userCircles[i];
      let user = userCircle.user;


      for (let r = 0; r < userCircle.ratchetPublicKeys.length; r++) {

        let ratchetPublicKey = userCircle.ratchetPublicKeys[r];
        //loop through and remove any keys that don't match a device

        let found = false;

        if (user == null || user.devices == null) {
          continue;
        }

        for (let d = 0; d < user.devices.length; d++) {

          let device = user.devices[d];

          if (device.uuid == ratchetPublicKey.device) {
            found = true;
            break;
          }

        }

        if (!found) {

          counter = counter + 1;
          //console.log('pulled ratchetPublicKey:' + ratchetPublicKey);
          //console.log(ratchetPublicKey);

          await UserCircle.updateMany({ 'user': req.body.id, _id: userCircle._id, ratchetPublicKeys: { $ne: null } }, { $pull: { 'ratchetPublicKeys': { '_id': ratchetPublicKey._id } } });
        }
      }
    }

    console.log('COUNTER THREE: ' + counter);

    return res.status(200).json({ message: "success" });

  } catch (err) {
    logUtil.logError(err, true);
    return res.status(500).json({ err: err });
  }
});


router.put('/upgradeic/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {


    let validUser = await User.findById(req.user.id);


    if (validUser.role != constants.ROLE.IC_ADMIN) {
      await logUtil.logError('unauthorized access to upgradeic', true);
      throw ('Unauthorized');
    }



    var count = await CircleObject.updateMany({},
      {
        $unset: {
          'album': null,

        }
      }, { strict: false }


    );

    var count = await CircleObject.updateMany({},
      {
        $unset: {
          'album': undefined,

        }
      }, { strict: false }


    );

    console.log(count);

    /* let users = await User.find({});
 
     for (i=0; i<users.length; i++){
 
       users[i].lowercase = users[i].username;
       await users[i].save();
     }
     */


    /*
        await User.updateMany({ keyGen: true },
          {
            'accountType': 0,
          });
          */


    /*
         reserveAccount('TheSilentBang'.toLowerCase());
         */

    //await CircleObject.deleteMany({type: 'circleimage', crank: undefined});
    //await CircleImage.deleteMany({location: 'GRIDFS'});

    /*
    let circleObjects = await CircleObject.find({seed: 'rdQvClAiHzLM'});

    for (let i = 0; i<circleObjects.length; i++){
        circleObjects[i].seed = circleObjects[i]._id;
        await circleObjects[i].save();
    }*/

    /*
  await Circle.updateMany({},
    {
      "privacyShareImage": false,
      'privacyVotingModel': "unanimous",
      "privacyShareURL": false,
      "privacyShareGif": true,
      "privacyCopyText": false,
      'security2FA': false,
      'securityMinPassword': 8,
      'securityDaysPasswordValid': 90,
      'securityTokenExpirationDays': 7,
      'securityLoginAttempts': 9,
      'securityVotingModel': "majority",

    });
    */

    /*await CircleObject.updateMany({ type: 'circlelist' },
      {
        "checkable": true,
      });
*/

    /*
        let imageUpdate = await CircleImage.updateMany({ location: null },
          {
            "location": 'GRIDFS',
          });
        
    
        console.log('Updated imageUpdate count: ' + imageUpdate);
        */

    /*
    var count = await Circle.updateMany({},
      {
        $unset: {
          'copyText': undefined,
          'settingSharePhotos': undefined,
          'settingSharePhotosModel': undefined,
          'votingModelSharePhotos': undefined,
          'votingModelShareURL': undefined,
          'votingModelCopyText': undefined,
          'votingModelShareGif': undefined,
          'sharePhotos': undefined,
          'shareURL': undefined,
          'votingModelMinPassword': undefined,
          'votingModelDaysPasswordValid': undefined,
          'shareGif': undefined,
          'sharePhotosVotingModel': undefined,
          'securityPasswordAttempts': undefined,
          'securityPasswordAttemptsModel': undefined,

        }
      }, { strict: false }


    );
    */

    /*
    await User.updateMany({},
      {
        'autoKeyBackup': false, 'keyGen': false, 'security2FA': false, "loginAttempts": 0, "loginAttemptsExceeded": false, "loginAttemptsLastFailed": null,
        "tokenExpired": false, "passwordExpired": false, 'lockedOut': false, 'securityMinPassword': 8, 'securityDaysPasswordValid': 90,
        "securityTokenExpirationDays": 7, 'securityLoginAttempts': 9, 'passwordChangedOn': null, 'blockedEnabled': true, 'keysExported': false,
      });
      */

    /*
  var count = await User.updateMany({},
    {
      $unset: {
        // 'passwordExpired': undefined, 
        "loginAttemptLastFailed": undefined,
        'securityPasswordAttempts': undefined,
        'tempPasscode': undefined,
        'devices': undefined, 'blacklist': undefined, 'whitelist': undefined,
      }
    }, { strict: false }


  );
  */


    /*var users = await User.find().populate("passwordHelpers").exec();

    for (var i = 0; i < users.length; i++) {

      let user = users[i];
      if (user.passwordHelpers.length == 0) {

        let actionRequired = await ActionRequired.findOne({ user: user._id, alertType: constants.ACTION_REQUIRED.SETUP_PASSWORD_ASSIST });

        if (!(actionRequired instanceof ActionRequired)) {
          actionRequired = new ActionRequired({
            user: user._id,
            alert: "Important: Setup password assistance.  Without this you will not be able to reset a forgotton password.",
            alertType: constants.ACTION_REQUIRED.SETUP_PASSWORD_ASSIST
          });

          await actionRequired.save();
        } else {

          actionRequired.alert = "Important: Setup password assistance.  Without this you will not be able to reset a forgotton password.";
          await actionRequired.save();
        }

      }

    }*/


    /*
        for (var i = 0; i < users.length; i++) {
          let user = users[i];
    
          if (!user.keysExported) {
    
            let actionRequired = await ActionRequired.findOne({ user: user._id, alertType: constants.ACTION_REQUIRED.EXPORT_KEYS });
    
            if (!(actionRequired instanceof ActionRequired)) {
    
              actionRequired = new ActionRequired({
                user: user._id,
                alert: "Important: You need to export your encryption keys.  This is required to port IronCircles to a different device later.",
                alertType: constants.ACTION_REQUIRED.EXPORT_KEYS
              });
    
              await actionRequired.save();
            }
    
          }
    
        }*/


    return res.status(200).json({ msg: "updated" });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }
});


module.exports = router;