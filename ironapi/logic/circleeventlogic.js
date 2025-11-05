/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates logic for dealing with CircleImages.   
 * 
 * TODO: Replace GridFSBucket logic with /util/gridfsutil deleteblob
 * 
 *  
 ***************************************************************************/
const CircleEvent = require('../models/circleevent');
const CircleObjectLineItem = require('../models/circleobjectlineitem');
const mongoose = require('mongoose');

const ObjectID = require('mongodb').ObjectID;
const mongodb = require('mongodb');
const circle = require('../models/circle');
const e = require('express');
const logUtil = require('../util/logutil');

const constants = require('../util/constants');
const awsLogic = require('./awslogic');
const gridFS = require('../util/gridfsutil');


module.exports.deleteAllCircleEvents = async function (circle) {
  try {
    CircleEvent.deleteMany({ "circle": circle._id });

  } catch (err) {
    logUtil.logError(err, true);
  }

}


module.exports.deleteCircleEvent = async function (id) {
  try {


    let circleEvent = await CircleEvent.findById(id);

    for (let i = 0; i < circleEvent.encryptedLineItems.length; i++) {

      await CircleObjectLineItem.deleteOne({ _id: circleEvent.encryptedLineItems[i] });
    }
    await CircleEvent.deleteOne({ _id: id });


  } catch (err) {
    console.error(err);
    return false;

  }
}





