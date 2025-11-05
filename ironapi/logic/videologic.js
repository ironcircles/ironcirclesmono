//const mongoose = require('mongoose');
const logUtil = require('../util/logutil');
const gridFS = require('../util/gridfsutil');//
const awsLogic = require('./awslogic');
const CircleVideo = require('../models/circlevideo');
const constants = require('../util/constants');
const User = require('../models/user');
const s3Util = require('../util/s3util');

if (process.env.NODE_ENV !== 'production') {
    require('dotenv').load();
}

async function getHostedFurnaceStorage(userID) {
    let user = await User.findById(userID).populate("hostedFurnace");

    if (user.hostedFurnace != null) {
        if (user.hostedFurnace.storage != null)
            if (user.hostedFurnace.storage.length > 0)
                return user.hostedFurnace.storage[user.hostedFurnace.storage.length - 1];

    }

    return null;
}

module.exports.deleteAllCircleVideos = async function (userID, circle) {
    try {

        let circleVideos = await CircleVideo.find({ "circle": circle._id });

        let hostedFurnaceStorage = await getHostedFurnaceStorage(userID);

        for (let i = 0; i < circleVideos.length; i++) {
            _delete(circleVideos[i], hostedFurnaceStorage);
        }

    } catch (err) {
        logUtil.logError(err, true);
    }

}

module.exports.deleteCircleVideo = async function (userID, videoID) {

    try {

        let circleVideo = await CircleVideo.findOne({ '_id': videoID });
        if (!circleVideo) throw ('Could not find video');

        let hostedFurnaceStorage = await getHostedFurnaceStorage(userID);

        await _delete(circleVideo, hostedFurnaceStorage);

        return true;

    } catch (err) {
        logUtil.logError(err, true);
        return false;
    }

}



async function _delete(circleVideo, hostedFurnaceStorage) {

    try {

        ///RBR
        if (circleVideo.streamable == true) {
            return true;
        }

        if (circleVideo.location == constants.BLOB_LOCATION.S3) {

            awsLogic.deleteObject(process.env.s3_videos_bucket, circleVideo.preview);  //don't wait
            awsLogic.deleteObject(process.env.s3_videos_bucket, circleVideo.video);
        } else if (circleVideo.location == constants.BLOB_LOCATION.PRIVATE_S3 || circleVideo.location == constants.BLOB_LOCATION.PRIVATE_WASABI) {

            s3Util.deleteBlobPrivateStorage(hostedFurnaceStorage, constants.BUCKET_TYPE.VIDEO, circleVideo.preview);  //don't wait
            s3Util.deleteBlobPrivateStorage(hostedFurnaceStorage, constants.BUCKET_TYPE.VIDEO, circleVideo.video);
        } else {
            // deleteGridFS(circleVideo);  //don't wait
        }


        await CircleVideo.deleteOne({ '_id': circleVideo._id });

        return true;

    } catch (err) {
        logUtil.logError(err, true);
        throw (err);
    }

}

async function deleteGridFS(circleVideo) {

    try {

        await gridFS.deleteBlob("circlevideoFull", circleVideo.video);
        await gridFS.deleteBlob("circlevideoThumbnail", circleVideo.preview);
        //await CircleVideo.deleteOne({ _id: circleVideo._id });

        return true;

    } catch (err) {
        console.error(err);
        return false;
    }

}