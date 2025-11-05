const User = require('../models/user');
const KeychainBackup = require('../models/keychainbackup');
const constants = require('../util/constants');
const logUtil = require('../util/logutil');
const s3Util = require('../util/s3util');
const gridFS = require('../util/gridfsutil');

module.exports.deleteKeychainBackups = async function (user) {
    try {

        let keychains = await KeychainBackup.find({ user: user._id });

        for (let i = 0; i < keychains.length; i++) {
            let keychain = keychains[i];

            if (keychain.location == constants.BLOB_LOCATION.S3) {

                s3Util.deleteBlob(constants.BUCKET_TYPE.KEYCHAIN_BACKUP, keychain.keychain);

            } else {
                gridFS.deleteBlob('keychainBlob', keychain.keychain);

            }

        }

        await KeychainBackup.deleteMany({ user: user._id });


    } catch (err) {
        console.error(err);
    }
}