const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const passport = require('passport');
const Log = require('../models/log');
const LogDetail = require('../models/logdetail');
const Device = require('../models/device');
const logUtil = require('../util/logutil');
const User = require('../models/user');
const kyberLogic = require('../logic/kyberlogic');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

//router.use(bodyParser.urlencoded({ extended: true }));
//router.use(bodyParser.json());

router.use(bodyParser.json({ limit: '100mb' }));
router.use(bodyParser.urlencoded({ limit: '100mb', extended: true, parameterLimit: 50000 }));


//toggle keychain backup
router.post('/detail/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let logDetail = new LogDetail({user: req.user.id, blob: body.blob, blobSize: body.blobSize, dbKey: body.dbKey, backupKey: body.backupKey});

    await logDetail.save();

    ///res.status(200).json({ success: true });
    let payload = { success: true };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});



//toggle keychain backup
router.post('/toggle/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let user = await User.findById(req.user._id);

    user.submitLogs = body.submitLogs;
    await user.save();

    if (user.submitLogs == false) {
      await Log.deleteMany({ user: user._id });
    }

    //res.status(200).json({ success: true });
    let payload = { success: true };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});

router.put('/removenoise/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {



    let validUser = await User.findById(req.user.id);


    if (validUser.username != 'lexluthor' && validUser.username != 'nitro')
      return res.status(400).json({ message: "Unauthorized" });


    await Log.deleteMany({ message: 'Invalid argument(s): Seed must be 32 bytes' });
    await Log.deleteMany({ message: 'Exception: Invalid argument(s): Seed must be 32 bytes' });
    await Log.deleteMany({ message: 'no match' });
    await Log.deleteMany({ message: 'last full is null' });
    await Log.deleteMany({ message: { $regex: 'backup key is empty for' } });


  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});

router.post('/iclog/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let logs = [];

    for (let i = 0; i < body.logs.length; i++) {
      let log = await Log.new(body.logs[i]);

      if (logUtil.skipLog(log)) continue;

      log.serverSide = false;
      log.user = req.user.id;
      log.source = getIP(req);
      logs.push(log);

      //await log.save();

    }

    await Log.insertMany(logs);

    //res.status(200).json({ msg: 'Successful uploaded logs' });

    let payload = { msg: 'Successful uploaded logs' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});


function getIP(request) {

  try {
    let ipAddr = request.connection.remoteAddress;

    if (request.headers && request.headers['x-forwarded-for']) {
      [ipAddr] = request.headers['x-forwarded-for'].split(',');
    }

    return ipAddr;
  } catch (err) {
    logUtil.logError(err, true);
    return '';
  }
}


router.post('/forge/', async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);


    if (process.env.NODE_ENV !== 'production')
      require('dotenv').load();

    if (body.apikey != process.env.apikey)
      throw new Error('Unauthorized');

    let logs = [];

    for (let i = 0; i < body.logs.length; i++) {
      let log = await Log.new(body.logs[i]);
      if (logUtil.skipLog(log)) continue;
      log.serverSide = false;
      log.source = getIP(req);
      logs.push(log);
    }

    await Log.insertMany(logs);

   
    let payload =  { msg: 'Successful uploaded logs' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    return res.status(200).json(payload);

   // res.status(200).json({ msg: 'Successful uploaded logs' });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});


/*async function addDeviceInstall(log){

  try{

    if (log.type == 'log' && log.message.toLowerCase().contains('new installation')){

      var device;

      if (log.message.toLowerCase().contains('android'))
        device = new Device({});
      else 
        device = new Device({});

        await device.save();
    }
  } catch (err) {
     logUtil.logError(err, true);
    
  }

}*/

router.post('/ironcirclesweb', async (req, res) => {

  try {


    let logs = [];

    for (let i = 0; i < req.body.logs.length; i++) {
      let log = await Log.new(req.body.logs[i]);

      if (logUtil.skipLog(log)) continue;

      log.serverSide = false;
      log.user = req.user.id;
      log.source = getIP(req);
      logs.push(log);
      //await log.save();

    }

    await Log.insertMany(logs);

    res.status(200).json({ msg: 'Successful uploaded logs' });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});

router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {


    let logs = [];

    for (let i = 0; i < req.body.logs.length; i++) {
      let log = await Log.new(req.body.logs[i]);

      if (logUtil.skipLog(log)) continue;

      log.serverSide = false;
      log.user = req.user.id;
      log.source = getIP(req);
      logs.push(log);
      //await log.save();

    }

    await Log.insertMany(logs);

    res.status(200).json({ msg: 'Successful uploaded logs' });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
});

/*
//TODO get by data range

//find by logid
router.get('/:id', passport.authenticate('jwt', { session: false }), function (req, res) {

  Log.find({ "_id": req.params.id })
    .then((log) => {
      res.status(200).send(log);
    })
    .catch((err) => {
      return res.status(500).json({ msg: err });
    });

});
*/


module.exports = router;