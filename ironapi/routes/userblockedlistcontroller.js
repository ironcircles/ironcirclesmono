const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const passport = require('passport');
const User = require('../models/user');
var Invitation = require('../models/invitation');
const logUtil = require('../util/logutil');
//var UserBlocks = require('../models/userblocks');
const constants = require('../util/constants');
const kyberLogic = require('../logic/kyberlogic');

if (process.env.NODE_ENV !== 'production') {
    require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

// Returns user with lists populated for this user and furnace, POSTKYBER
router.get('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

    try {
        //SECURITY CHECK
        if (req.user.id != req.params.id)
            return res.status(400).json({ msg: 'Access denied' });

        //load the list of users
        var user = await User.findById(req.user.id).populate('blockedList').populate('allowedList').exec();

        return res.status(200).send({ user: user });

    } catch (err) {

        var msg = await logUtil.logError(err);
        return res.status(500).json({ msg: msg });
    }

});

router.post('/get/', passport.authenticate('jwt', { session: false }), async (req, res) => {

    try {
        //let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        //load the list of users
        var user = await User.findById(req.user.id).populate('blockedList').populate('allowedList').exec();

        //return res.status(200).send({ user: user });

        let payload = { user: user };
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);

    } catch (err) {

        var msg = await logUtil.logError(err);
        return res.status(500).json({ msg: msg });
    }

});

//add a user to the active list
router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

    try {

        let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

        //load the user
        var user = await User.findById(req.user.id).populate('blockedList').populate('allowedList').exec();

        var found = false;

        if (user.blockedEnabled) {
            for (let index = 0; index < user.blockedList; index++) {

                let user = user.blockedList[index];

                if (user.id = body.userid) {

                    found = true;
                    break;
                }

            }

            if (!found)
                user.blockedList.push(body.userid);

        } else {

            for (let index = 0; index < user.allowedList; index++) {

                let user = user.allowedList[index];

                if (user.id = body.userid) {

                    found = true;
                    break;
                }
            }

            if (!found)
                user.allowedList.push(body.userid);

        }

        await user.save();

        //change any invitation status to blocked
        await Invitation.updateMany({ invitee: req.user.id, inviter: body.userid }, {status: constants.INVITATION_STATUS.BLOCKED});

        //return res.status(200).send({ success: true });

        let payload = { success: true };
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);

    } catch (err) {

        var msg = await logUtil.logError(err);
        return res.status(500).json({ msg: msg });
    }

});

// Remove a user from the active list
router.delete('/:userid', passport.authenticate('jwt', { session: false }), async (req, res) => {

    try {

        let userID = req.params.userid;
        if (userID == 'undefined'){
            userID = req.body.userID;
        }

        //load the user
        var user = await User.findById(req.user.id).populate('blockedList').populate('allowedList').exec();

        if (user.blockedEnabled)
            await user.updateOne({ $pull: { blockedList: userID} });
        else
            await user.updateOne({ $pull: { allowedList: userID } });

        //change any invitation status to unblocked
        await Invitation.updateMany({ invitee: req.user.id, inviter: userID }, {status: constants.INVITATION_STATUS.PENDING});

        //return res.status(200).send({ user: user });

        let payload = { user: user };
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);


    } catch (err) {

        var msg = await logUtil.logError(err);
        return res.status(500).json({ msg: msg });
    }

});

module.exports = router;