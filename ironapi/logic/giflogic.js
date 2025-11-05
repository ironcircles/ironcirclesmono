/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates logic for dealing with CircleGifs   
 * 
 * TODO: Replace GridFSBucket logic with /util/gridfsutil deleteblob
 * 
 *  
 ***************************************************************************/
const CircleGif = require('../models/circlegif');
const mongoose = require('mongoose');

const ObjectID = require('mongodb').ObjectID;
const mongodb = require('mongodb');
const logUtil = require('../util/logutil');


module.exports.deleteAllCircleGifs = function deleteAllCircleGifs(circle) {
  return new Promise(function (resolve, reject) {

    CircleGif.find({ "circle": circle._id })
      .then(function (circleGifs) {

        circleGifs.forEach(function (circlegif) {
          deleteCircleImage(circlegif)
            .catch(function (err) {
              console.error(err);
            });
        });

        return resolve();
      })
      .catch(function (err) {
        console.error(err);
        return reject(err);
      });

  });
}

/*
function deleteCircleGif(circlegif) {

  
  try {

    return new Promise(function(resolve, reject){

      CircleGif.deleteOne({_id:circlegif._id}, function (err) {
        if (err){
          console.log(err);
          return reject();
        } 
      
        var id = new ObjectID(circlegif.gif);
     
        //delete the chunks and files
        let bucket = new mongodb.GridFSBucket(mongoose.connection.db, {
          bucketName: "gifs"
        });

        bucket.delete(id, function (err) {
          if (err) console.log('FullImage not deleted: ' + err);
        });

        console.log ('giflogic.deletegif : ' + circlegif.id + ' deleted');
        return resolve();
      });

    });
  } catch (err) {
      console.error(err);
      callback(false);
  }

}*/



async function deleteGif(circleobject, callback) {

  try {
    //load the image to find the chunk and file reference
    await CircleGif.deleteOne({ _id: circleobject.gif });

    return true;

  } catch (err) {
    console.error(err);
    return false;
  }
}


module.exports.deleteGif = deleteGif;