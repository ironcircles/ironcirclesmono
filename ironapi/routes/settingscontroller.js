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

///this is a get
router.post('/dezgokey', passport.authenticate('jwt', { session: false }), async (req, res) => {

    try {
        let key = process.env.dezgo_ai;

        //return res.status(200).json({ key: key });

        let payload = { key: key };
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

        return res.status(200).json(payload);

    } catch (err) {
        var msg = await logUtil.logError(err, true, getIP(req));
        return res.status(500).json({ err: msg });
    }
});


///this is a get
router.post('/dezgoregistration', async (req, res) => {

    try {
        let key = process.env.dezgo_ai_registration;

        let payload = { key: key };
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

        return res.status(200).json(payload);

    } catch (err) {
        var msg = await logUtil.logError(err, true, getIP(req));
        return res.status(500).json({ err: msg });
    }
});

module.exports = router;