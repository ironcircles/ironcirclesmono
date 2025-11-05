const { Kyber1024 } = require("crystals-kyber-js");
const kyber = require('crystals-kyber');
const log = require("../models/log");
const User = require("../models/user");
const logUtil = require('../util/logutil');
const aesCipher = require('./aesencryption');
const Device = require('../models/device');
const DeviceKyber = require('../models/devicekyber');


module.exports.postPublicKey = async function (uuid) {

    try {

        if (uuid == null || uuid == undefined) {
            throw new Error('unauthorized');
        }

        const sender = new Kyber1024();
        const [pk, sk] = await sender.generateKeyPair();


        let deviceKyber = await DeviceKyber.findOne({ deviceID: uuid });

        if (deviceKyber instanceof DeviceKyber) {

            logUtil.logAlert('kyber device already exists: ' + uuid);
            //TODO POSTKYBER this should only work for an authenticated user

            //throw new Error('unauthorized - device already exists: ' + uuid);
            deviceKyber.pk = Buffer.from(pk);
            deviceKyber.sk = Buffer.from(sk);


        } else {
            deviceKyber = new DeviceKyber({ deviceID: uuid, sk: Buffer.from(sk), pk: Buffer.from(pk) });

        }

        await deviceKyber.save();

        return pk;

    } catch (err) {
        await logUtil.logError(err, true);
        throw err;
    }
}

module.exports.postSharedSecret = async function (uuid, ct) {

    try {
        ///Remember, this isn't Perfect Forward Secrecy, just api traffic
        ///So it's ok to store the shared secret, doesn't impact user generated content which is PFS encrypted

        let deviceKyber = await DeviceKyber.findOne({ deviceID: uuid, pk: { $ne: null }, sk: { $ne: null }, ss: null });

        if (!(deviceKyber instanceof DeviceKyber)) {
            throw new Error('unauthorized');
        }

        ///calculate the shared secret to store
        const sender = new Kyber1024();
        const ss = await sender.decap(new Uint8Array(ct), new Uint8Array(deviceKyber.sk));

        deviceKyber.ss = Buffer.from(ss);
        await deviceKyber.save();
    } catch (err) {
        await logUtil.logError(err, true);
        throw err;
    }
}



module.exports.putPublicKey = async function (userID, uuid) {

    try {

        //only use this function for an authenticated user
        let user = await User.findOne({ _id: userID, 'devices.uuid': uuid });

        if (!(user instanceof User)) {
            throw new Error('unauthorized');
        }

        const sender = new Kyber1024();
        const [pk, sk] = await sender.generateKeyPair();


        let deviceKyber = await DeviceKyber.findOne({ deviceID: uuid });

        if (deviceKyber instanceof DeviceKyber) {
            deviceKyber.pk = Buffer.from(pk);
            deviceKyber.sk = Buffer.from(sk);
        } else {
            //deviceKyber = new DeviceKyber({ deviceID: uuid, sk: Buffer.from(sk), pk: Buffer.from(pk) });
            throw new Error('unauthorized');
        }

        await deviceKyber.save();

        return pk;

    } catch (err) {
        await logUtil.logError(err, true);
        throw err;
    }
}


module.exports.putSharedSecret = async function (userID, uuid, ct) {

    try {
        ///Remember, this isn't Perfect Forward Secrecy, just api traffic
        ///So it's ok to store the shared secret, doesn't impact user generated content which is PFS encrypted

        //only use this function for an authenticated user
        let user = await User.findOne({ _id: userID, 'devices.uuid': uuid });

        if (!(user instanceof User)) {
            throw new Error('unauthorized');
        }

        let deviceKyber = await DeviceKyber.findOne({ deviceID: uuid, pk: { $ne: null }, sk: { $ne: null } });

        if (!(deviceKyber instanceof DeviceKyber)) {
            throw new Error('unauthorized - device not found to store ss ' + uuid);
        }

        ///calculate the shared secret to store
        const sender = new Kyber1024();
        const ss = await sender.decap(new Uint8Array(ct), new Uint8Array(deviceKyber.sk));

        deviceKyber.ss = Buffer.from(ss);
        await deviceKyber.save();
    } catch (err) {
        await logUtil.logError(err, true);
        throw err;
    }
}




module.exports.encryptPayload = async function (enc, uuid, payload) {
    try {


        if (enc == null || enc == undefined) {

            ///TODO remove this line when everyone is on the api encrypted version
            //throw new Error('unauthorized');

            return payload;

        }

        if (uuid == null || uuid == undefined) {
            throw new Error('unauthorized');
        }

        let deviceKyber = await DeviceKyber.findOne({ deviceID: uuid });

        if (!(deviceKyber instanceof DeviceKyber)) {
            throw new Error('unauthorized');
        }

        ///turn the payload into a string
        let textPayload = JSON.stringify(payload);

        //let textPayload = "fake payload 55";

        let ciper = aesCipher.encrypt(deviceKyber.ss, textPayload);
        //console.log(ciper);
        return ciper;

    } catch (err) {
        await logUtil.logError(err, true);
        throw err;
    }
}

module.exports.decryptBody = async function (body, uuid, iv, mac, enc, user) {

    try {
        if (enc == null || enc == undefined || iv == null || iv == undefined || mac == null || mac == undefined) {

            return body;
            ///TODO remove this line when everyone is on the api encrypted version
            //throw new Error('unauthorized');
        }

        if (user != null && user != undefined) {
            ///this is an authenticated call, ensure the user has this device
            let found = false;

            for (let i = 0; i < user.devices.length; i++) {
                if (user.devices[i].uuid == uuid) {
                    found = true;
                    break;
                }

            }

            if (!found) {
                throw new Error('unauthorized');
            }
        }


        ///Make sure a public private keypair was stored for this device
        //let deviceKyber = await DeviceKyber.findOne({ deviceID: uuid, pk: { $ne: null }, sk: { $ne: null } });
        let deviceKyber = await DeviceKyber.findOne({ deviceID: uuid });

        if (!(deviceKyber instanceof DeviceKyber)) {
            throw new Error('unauthorized');
        }

        const ivBuffer = Buffer.from(iv, 'utf8');
        const macBuffer = Buffer.from(mac, 'utf8');
        const encBuffer = Buffer.from(enc, 'utf8');

        const decrypted = aesCipher.decrypt(deviceKyber.ss, encBuffer, ivBuffer, macBuffer);

        return JSON.parse(decrypted);


    }
    catch (err) {
        await logUtil.logError(err, true);
        throw err;
    }




}


module.exports.deleteDeviceKyber = async function (uuid, oldID) {

    try {

        await DeviceKyber.deleteOne({ deviceID: uuid });
        await DeviceKyber.deleteOne({ deviceID: oldID });


    }
    catch (err) {
        await logUtil.logError(err, true);
        throw err;
    }
}