/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for events.  Child of CircleObject.
 * 
 * Contains an property of type circle to avoid lack of joins in MongoDB
 * 
 *  
 ***************************************************************************/
const mongoose = require('mongoose');
const RatchetIndex = require('../models/ratchetindex');

var CircleObjectLineItemSchema = new mongoose.Schema({
  ratchetIndex: mongoose.model('RatchetIndex').schema,
  version: { type: Number }

}, { timestamps: false }, { collection: 'circleobjectlineitem' });

CircleObjectLineItemSchema.statics.new = async function (json, userID) {

  delete json._id;
  
  let circleObjectLineItem = this(json);  //will pickup version

  if (json["ratchetIndex"]) {

    circleObjectLineItem.rachetIndex = await RatchetIndex.new(json["ratchetIndex"]);
    circleObjectLineItem.rachetIndex.user = userID;
  }

  return circleObjectLineItem;

}



CircleObjectLineItemSchema.methods.update = async function (json) {

  //if (json["ratchetIndex"].user == userID) {  //security check

    this.version = this.version + 1;
    this.ratchetIndex = await RatchetIndex.new(json.ratchetIndex);

    return this;

 // }


}


mongoose.model('CircleObjectLineItem', CircleObjectLineItemSchema);

module.exports = mongoose.model('CircleObjectLineItem');