/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates logic to deal with push notifications.  
 *  
 * TODO: Remove none *cp version and cleanup devicelogic (remove old procedures)
 * 
 *  
 ***************************************************************************/

const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const passport = require('passport');
const deviceLogic = require('../logic/devicelogic');
const logUtil = require('../util/logutil');
const kyberLogic = require('../logic/kyberlogic');

if (process.env.NODE_ENV !== 'production') {
    require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());


router.post('/registerdevice', passport.authenticate('jwt', { session: false }), async (req, res) => {


    try {

        let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        //console.log('token registration: ' + body.pushtoken);

        await deviceLogic.registerDevice(req.user.id, body.pushtoken, body.platform, body.uuid);

        let payload = { msg: "fire token updated" };
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);


        // deviceLogic.registerDevice(req.user.id, req.body.pushtoken, req.body.platform, req.body.uuid)
        //     .then(() => {

        //         //deviceLogic.deleteDevicesByToken(req.body.oldToken);

        //         return res.status(200).send({msg: "fire token updated" });
        //     })
        //     .catch((err) => {
        //         console.error(err);
        //         return res.status(500).send({msg: "There was a problem registering the device." });
        //     });
    } catch (err) {
        console.error(err);
        return res.status(500).send({ msg: "There was a problem registering the device." });
    }
});

/*
router.delete('/removedevice/:token', passport.authenticate('jwt', { session: false }), function (req, res) {

    //TODO This should only be called if a user removes a furnace
    deviceLogic.deleteDevicesByToken(req.user.id, req.params.token);

    // if (!success) return res.status(500).send("There was a problem registering the device.");

    return res.status(200).send({ success: true });

});
*/



module.exports = router;