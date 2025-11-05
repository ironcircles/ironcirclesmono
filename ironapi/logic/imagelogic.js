/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates logic for dealing with CircleImages.   
 * 
 * 
 *  
 ***************************************************************************/
const CircleImage = require('../models/circleimage');
const User = require('../models/user');
const mongoose = require('mongoose');

const ObjectID = require('mongodb').ObjectId;
const mongodb = require('mongodb');
const logUtil = require('../util/logutil');
const awsLogic = require('./awslogic');
const s3Util = require('../util/s3util');
const constants = require('../util/constants');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

module.exports.deleteAllCircleImages = async function (userID, circle) {
  try {

    let circleImage = await CircleImage.find({ "circle": circle._id });

    let hostedFurnaceStorage = await getHostedFurnaceStorage(userID);

    for (let i = 0; i < circleImage.length; i++) {
      _delete(circleImage[i], hostedFurnaceStorage);
    }

  } catch (err) {
    logUtil.logError(err, true);
  }

}


/*
async function deleteBlobs(circleImage) {

  try {

    var imageID = new ObjectID(circleImage.fullImage);

    //delete the chunks and files
    let bucket = new mongodb.GridFSBucket(mongoose.connection.db, {
      bucketName: "fullimages"
    });

    bucket.delete(imageID, function (err) {
      if (err) console.error('FullImage not deleted: ' + err);
    });
  } catch (err) {
    console.err(err);
  }

  try {

    var thumbnailID = new ObjectID(circleImage.thumbnail);

    let bucket2 = new mongodb.GridFSBucket(mongoose.connection.db, {
      bucketName: "thumbnails"
    });

    bucket2.delete(thumbnailID, function (err) {
      if (err) console.error('Thumbnail not deleted: ' + err);
    });

  } catch (err) {
    console.err(err);
  }

  console.log('imagelogic.deleteImage : ' + circleImage.id + ' deleted');
  return;


}

async function deleteCircleImage(circleImage) {

  try {

    var imageID = new ObjectID(circleImage.fullImage);
    var thumbnailID = new ObjectID(circleImage.thumbnail);

    CircleImage.deleteOne({ _id: circleImage._id }, function (err) {
      if (err) {
        console.error(err);
        return false;// reject();
      }
    });

    try {
      //delete the chunks and files
      let bucket = new mongodb.GridFSBucket(mongoose.connection.db, {
        bucketName: "fullimages"
      });

      bucket.delete(imageID, function (err) {
        if (err) console.error('FullImage not deleted: ' + err);
      });
    } catch (err) {
      console.err(err);
    }

    try {
      let bucket2 = new mongodb.GridFSBucket(mongoose.connection.db, {
        bucketName: "thumbnails"
      });

      bucket2.delete(thumbnailID, function (err) {
        if (err) console.error('Thumbnail not deleted: ' + err);
      });

    } catch (err) {
      console.err(err);
    }

    console.log('imagelogic.deleteImage : ' + circleImage.id + ' deleted');
    return true;
    //return resolve();

  } catch (err) {
    console.error(err);
    return false;
  }

}
*/


/*
async function deleteGridFS(circleImage) {

  try {

    await gridFS.deleteBlob("thumbnails", circleImage.thumbnail);
  } catch (err) {
    console.error(err);

  }

  try {
    await gridFS.deleteBlob("fullimages", circleImage.fullImage);

  } catch (err) {
    console.error(err);

  }

}
*/


module.exports.deleteCircleImage = async function (userID, imageID) {
  try {

    var circleImage = await CircleImage.findOne({ _id: imageID });

    if (!circleImage) throw new Error(('Could not find image'));

    let hostedFurnaceStorage = await getHostedFurnaceStorage(userID);

    await _delete(circleImage, hostedFurnaceStorage);


  } catch (err) {
    console.error(err);
    return false;

  }
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

async function _delete(circleImage, hostedFurnaceStorage) {

  try {

    //if (process.env.blobLocation == constants.BLOB_LOCATION.S3) {
    if (circleImage.location == constants.BLOB_LOCATION.S3) {

      awsLogic.deleteObject(process.env.s3_images_bucket, circleImage.thumbnail);  //don't wait
      awsLogic.deleteObject(process.env.s3_images_bucket, circleImage.fullImage);
    } else if (circleImage.location == constants.BLOB_LOCATION.PRIVATE_S3 || circleImage.location == constants.BLOB_LOCATION.PRIVATE_WASABI) {

      s3Util.deleteBlobPrivateStorage(hostedFurnaceStorage, constants.BUCKET_TYPE.IMAGE, circleImage.thumbnail);  //don't wait
      s3Util.deleteBlobPrivateStorage(hostedFurnaceStorage, constants.BUCKET_TYPE.IMAGE, circleImage.fullImage);
    }

    //return await deleteCircleImage(circleImage);

    await CircleImage.deleteOne({ _id: circleImage._id });

  } catch (err) {
    console.error(err);
    throw (err);

  }

}

//module.exports.deleteImage = deleteImage;
//module.exports.deleteBlobs = deleteBlobs;