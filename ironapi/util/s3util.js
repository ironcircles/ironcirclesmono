const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const passport = require('passport');
const AWS = require("aws-sdk");
const uuid = require("uuid");
const logUtil = require('./logutil');
const constants = require('./constants');
const hostedfurnace = require('../models/hostedfurnace');

if (process.env.NODE_ENV !== 'production') {
    require('dotenv').load();
}


AWS.config.update({ region: process.env.s3region });

const S3_IMAGES_BUCKET = process.env.s3_images_bucket;
const S3_FILES_BUCKET = process.env.s3_files_bucket;
const S3_VIDEOS_BUCKET = process.env.s3_videos_bucket;
const S3_KEYCHAIN_BACKUPS_BUCKET = process.env.s3_keychain_backups_bucket;
const S3_BACKGROUNDS_BUCKET = process.env.s3_backgrounds_bucket;
const S3_AVATARS_BUCKET = process.env.s3_avatars_bucket;
const S3_LOG_DETAIL_BUCKET = process.env.s3_log_detail_bucket;

const s3 = new AWS.S3({
    accessKeyId: process.env.s3one,
    secretAccessKey: process.env.s3key,
    region: AWS.config.region,
    signatureVersion: "v4",
    endpoint: "s3-accelerate.amazonaws.com",
});

function getBucket(bucketType, hostedFurnaceStorage) {

    if (hostedFurnaceStorage == null || hostedFurnaceStorage == undefined) {

        if (bucketType == constants.BUCKET_TYPE.IMAGE)
            return S3_IMAGES_BUCKET;
        else if (bucketType == constants.BUCKET_TYPE.VIDEO)
            return S3_VIDEOS_BUCKET;
        else if (bucketType == constants.BUCKET_TYPE.FILE)
            return S3_FILES_BUCKET;
        else if (bucketType == constants.BUCKET_TYPE.KEYCHAIN_BACKUP)
            return S3_KEYCHAIN_BACKUPS_BUCKET;
        else if (bucketType == constants.BUCKET_TYPE.AVATAR)
            return S3_AVATARS_BUCKET;
        else if (bucketType == constants.BUCKET_TYPE.BACKGROUND)
            return S3_BACKGROUNDS_BUCKET;
        else if (bucketType == constants.BUCKET_TYPE.LOG_DETAIL)
            return S3_LOG_DETAIL_BUCKET;
    } else {
        /*if (bucketType == constants.BUCKET_TYPE.IMAGE)
            return hostedFurnaceStorage.mediaBucket;
        else if (bucketType == constants.BUCKET_TYPE.VIDEO)
            return hostedFurnaceStorage.mediaBucket;
        else if (bucketType == constants.BUCKET_TYPE.FILE)
            return hostedFurnaceStorage.mediaBucket;
        else if (bucketType == constants.BUCKET_TYPE.AVATAR)
            return hostedFurnaceStorage.avatarBucket;
        else if (bucketType == constants.BUCKET_TYPE.BACKGROUND)
            return hostedFurnaceStorage.mediaBucket;*/

        return hostedFurnaceStorage.mediaBucket;
    }
}

function getConnection(hostedFurnaceStorage) {

    if (hostedFurnaceStorage == undefined || hostedFurnaceStorage == null) {
        AWS.config.update({ region: process.env.s3region });
        return s3;
    } else {
        AWS.config.update({ region: hostedFurnaceStorage.region });

        if (hostedFurnaceStorage.location == constants.BLOB_LOCATION.PRIVATE_S3) {

            return new AWS.S3({
                accessKeyId: hostedFurnaceStorage.accessKey,
                secretAccessKey: hostedFurnaceStorage.secretKey,
                region: AWS.config.region,
                signatureVersion: "v4",
                endpoint: "s3." + hostedFurnaceStorage.region + ".amazonaws.com",
            });

        } else if (hostedFurnaceStorage.location == constants.BLOB_LOCATION.PRIVATE_WASABI) {

            return new AWS.S3({
                accessKeyId: hostedFurnaceStorage.accessKey,
                secretAccessKey: hostedFurnaceStorage.secretKey,
                region: AWS.config.region,
                signatureVersion: "v4",
                endpoint: "s3." + hostedFurnaceStorage.region + ".wasabisys.com",
            });

        }

    }
}
module.exports.bucketTest = async function (bucketType, hostedFurnaceStorage) {
    try {
        let connection = getConnection(hostedFurnaceStorage);
        let bucket = getBucket(bucketType, hostedFurnaceStorage);

        return new Promise((resolve, reject) => {

            connection.headBucket({ Bucket: bucket }, (err, data) => {
                if (err) {
                    console.log(err);
                    reject(err);
                }
                resolve(true);

            });
        });

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        throw err;
    }
}


module.exports.getUploadLink = async function (bucketType, fileName, hostedFurnaceStorage) {

    try {
        let connection = getConnection(hostedFurnaceStorage);

        let bucket = getBucket(bucketType, hostedFurnaceStorage);

        const blobParams = {
            Bucket: bucket,
            Key: fileName,  //uuid
            Expires: 60 * 60,
            ContentType: "application/octet-stream",
        };

        return new Promise((resolve, reject) => {
            connection.getSignedUrl("putObject", blobParams, (err, data) => {
                if (err) {
                    console.log(err);
                    reject(err);
                }

                const presignedURls = {
                    message: "Urls generated",
                    fileUrl: data,
                    fileName: fileName,
                };

                resolve(presignedURls);

            });
        });

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        throw err;
    }

}

module.exports.getDownloadLink = async function (bucketType, fileName, hostedFurnaceStorage) {

    try {

        let connection = getConnection(hostedFurnaceStorage);

        let bucket = getBucket(bucketType, hostedFurnaceStorage);

        const blobParams = {
            Bucket: bucket,
            Key: fileName,
            Expires: 60 * 60,
            //ContentType: "video/" + extension,
        };

        return new Promise((resolve, reject) => {

            connection.getSignedUrl("getObject", blobParams, (err, data) => {
                if (err) {
                    console.log(err);
                    reject(err);
                }

                const presignedURls = {
                    fileUrl: data,
                    fileName: fileName,
                    message: "Urls generated",
                };;

                resolve(presignedURls);
            });
        });


    } catch (err) {
        var msg = await logUtil.logError(err, true);
        throw err;
    }
}


module.exports.initiateMultipartUpload = async function (bucketType, fileName) {

    let bucket = getBucket(bucketType);

    const blobParams = {
        Bucket: bucket,
        Key: fileName,  //uuid
        Expires: 60 * 60,
        //ContentType: "application/octet-stream",
        ContentType: 'multipart/form-data'
    };

    const res = await s3.createMultipartUpload(blobParams).promise()

    return res.UploadId;
}


module.exports.getUploadLinks = async function (bucketType, fileName, thumbnail, hostedFurnaceStorage) {

    try {

        let connection = getConnection(hostedFurnaceStorage);

        let bucket = getBucket(bucketType, hostedFurnaceStorage);

        const blobParams = {
            Bucket: bucket,
            Key: fileName,  //uuid
            Expires: 60 * 60,
            //ContentType: "application/octet-stream",
            ContentType: 'multipart/form-data'
        };

        return new Promise((resolve, reject) => {

            let data = connection.getSignedUrl("putObject", blobParams, (err, data) => {
                if (err) {
                    console.log(err);
                    reject(err);
                }

                let fileUrl = data;

                const thumbnailParams = {
                    Bucket: bucket,
                    Key: thumbnail,
                    Expires: 60 * 60,
                    ContentType: 'multipart/form-data'
                };

                connection.getSignedUrl("putObject", thumbnailParams, (err, data) => {
                    if (err) {
                        console.log(err);
                        reject(err);
                    }
                    const presignedURls = {
                        message: "Urls generated",
                        fileUrl: fileUrl,
                        thumbnailUrl: data,
                        fileName: fileName,
                        thumbnail: thumbnail,
                    };

                    resolve(presignedURls);
                });

            });
        });

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        throw err;
    }

}

module.exports.getDownloadLinks = async function (bucketType, fileName, thumbnail, hostedFurnaceStorage) {

    try {

        let connection = getConnection(hostedFurnaceStorage);

        let bucket = getBucket(bucketType, hostedFurnaceStorage);

        const blobParams = {
            Bucket: bucket,
            Key: fileName,
            Expires: 60 * 60,
            //ContentType: "video/" + extension,
        };

        return new Promise((resolve, reject) => {

            connection.getSignedUrl("getObject", blobParams, (err, data) => {
                if (err) {
                    console.log(err);
                    reject(err);
                }

                let fileUrl = data;

                const thumbnailParams = {
                    Bucket: bucket,
                    Key: thumbnail,
                    Expires: 60 * 60,
                };

                connection.getSignedUrl("getObject", thumbnailParams, (err, data) => {
                    if (err) {
                        console.log(err);
                        reject(err);
                    }
                    const presignedURls = {
                        fileUrl: fileUrl,
                        thumbnailUrl: data,
                        fileName: fileName,
                        thumbnail: thumbnail,
                        message: "Urls generated",
                    };;

                    resolve(presignedURls);
                });

            });
        });


    } catch (err) {
        var msg = await logUtil.logError(err, true);
        throw err;
    }
}


module.exports.deleteBlobPrivateStorage = async function (hostedFurnaceStorage, bucketType, fileName) {

    try {

        let connection = getConnection(hostedFurnaceStorage);

        let bucket = getBucket(bucketType, hostedFurnaceStorage);

        const params = {
            Bucket: bucket,
            Key: fileName
        };

        return new Promise((resolve, reject) => {

            connection.deleteObject(params, function (err, data) {
                if (err) console.log(err);
                else
                    console.log(
                        "Successfully deleted file from bucket"
                    );
            });

        });

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        throw err;
    }
}

module.exports.deleteBlob = async function (bucketType, fileName) {

    try {

        let bucket = getBucket(bucketType);

        const params = {
            Bucket: bucket,
            Key: fileName
        };

        return new Promise((resolve, reject) => {

            s3.deleteObject(params, function (err, data) {
                if (err) console.log(err);
                else
                    console.log(
                        "Successfully deleted file from bucket"
                    );
            });

        });

    } catch (err) {
        var msg = await logUtil.logError(err, true);
        throw err;
    }
}