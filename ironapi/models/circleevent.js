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
const CircleObjectLineItem = require('../models/circleobjectlineitem');
const ObjectID = require('mongodb').ObjectID;

var CircleEventSchema = new mongoose.Schema({
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
  startDate: { type: Date },
  lastEdited: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  encryptedLineItems: [{ type: mongoose.Schema.Types.ObjectId, ref: 'CircleObjectLineItem' }],
}, /*{ timestamps: false },*/ { collection: 'circleevents' });


CircleEventSchema.statics.new = async function (json, userID) {

  let circleEvent = this(json); //will pickup startDate and circle
  circleEvent.encryptedLineItems = [];

  if (json["encryptedLineItems"]) {

    for (let i = 0; i < json["encryptedLineItems"].length; i++) {


      let circleObjectLineItem = await CircleObjectLineItem.new(json["encryptedLineItems"][i], userID);

      //await ratchetIndex.save();
      circleEvent.encryptedLineItems.push(circleObjectLineItem);

    }

    circleEvent.markModified('encryptedLineItems');

  }



  return circleEvent;
}

CircleEventSchema.methods.updateReply = async function (encryptedLineItem, userID) {

  //find the item
  for (let j = 0; j < this.encryptedLineItems.length; j++) {

    // console.log(this.encryptedLineItems[j].ratchetIndex.user);
    // console.log(encryptedLineItem.ratchetIndex.user);

    if (this.encryptedLineItems[j].ratchetIndex.user.equals(ObjectID(encryptedLineItem.ratchetIndex.user))) {

      return await this.encryptedLineItems[j].update(encryptedLineItem);
    }
  }

  //Didn't find a match so it is a new reply
  return await CircleObjectLineItem.new(encryptedLineItem, userID);

}





CircleEventSchema.methods.update = async function (json) {

  this.startDate = json["startDate"];

}





mongoose.model('CircleEvent', CircleEventSchema);

module.exports = mongoose.model('CircleEvent');