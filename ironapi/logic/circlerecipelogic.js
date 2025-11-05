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
const CircleRecipe = require('../models/circlerecipe');
const CircleRecipeIngredient = require('../models/circlerecipeingredient');
const CircleRecipeInstruction = require('../models/circlerecipeinstruction');
const mongoose = require('mongoose');

const ObjectID = require('mongodb').ObjectID;
const mongodb = require('mongodb');
const circle = require('../models/circle');
const e = require('express');
const logUtil = require('../util/logutil');

const constants = require('../util/constants');
const awsLogic = require('./awslogic');
const gridFS = require('../util/gridfsutil');


module.exports.deleteAllCircleRecipes = async function (circle) {
  try {

    let circleRecipes = await CircleRecipe.find({ "circle": circle._id });

    for (let i = 0; i < circleRecipes.length; i++) {
      _delete(circleRecipes[i]);
    }

  } catch (err) {
    logUtil.logError(err, true);
  }

}


async function deleteGridFS(circleRecipe) {

  try {

    await gridFS.deleteBlob("circlerecipeFull", circleRecipe.image.thumbnail);

    //await CircleVideo.deleteOne({ _id: circleVideo._id });

    return true;

  } catch (err) {
    console.error(err);
    return false;
  }

}


module.exports.deleteCircleRecipe = async function (id) {
  try {

    var circleRecipe = await CircleRecipe.findOne({ _id: id });

    if (!circleRecipe) throw new Error(('Could not find recipe'));

    await _delete(circleRecipe);


  } catch (err) {
    console.error(err);
    return false;

  }
}

async function _delete(circleRecipe) {

  try {

    if (circleRecipe.image == undefined || circleRecipe.image == null || circleRecipe.image.thumbnail == undefined) return;

    if (process.env.blobLocation == constants.BLOB_LOCATION.S3) {

      awsLogic.deleteObject(process.env.s3_images_bucket, circleRecipe.image.thumbnail);  //don't wait
      //awsLogic.deleteObject(process.env.s3_images_bucket, circleImage.fullImage);
    } else {
      deleteGridFS(circleRecipe);  //don't wait
    }

    //return await deleteCircleImage(circleImage);

    await CircleRecipe.deleteOne({ _id: circleRecipe._id });

  } catch (err) {
    console.error(err);
    throw (err);

  }

}


module.exports.updateInstructions = function (circleRecipe, newList) {
  try {

    circleRecipe.instructions = [];

    for (i = 0; i < newList.length; i++) {
      var circleRecipeInstruction = new CircleRecipeInstruction({ seed: newList[i].seed, order: newList[i].order });
      circleRecipe.instructions.push(circleRecipeInstruction);

    }

    return circleRecipe.instructions;

  } catch (err) {
    console.error(err);
  }
}

module.exports.updateIngredients = function (circleRecipe, newList) {
  try {

    circleRecipe.ingredients = [];

    for (i = 0; i < newList.length; i++) {
      var circleRecipeIngredient = new CircleRecipeIngredient({ order: newList[i].order, seed: newList[i].seed });
      circleRecipe.ingredients.push(circleRecipeIngredient);

    }

    return circleRecipe.ingredients;

  } catch (err) {
    console.error(err);
  }
}



