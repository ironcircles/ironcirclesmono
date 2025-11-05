/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for movies/videos within a circle.  
 * 
 * Decentralized to include circleobject and circle property to avoid MongoDB join hell
 * 
 *  
 ***************************************************************************/
const mongoose = require('mongoose');


var TutorialLineItemSchema = new mongoose.Schema({
  item: { type: String },
  subTitle: { type: Boolean, default: false },
  video: { type: String },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'tutoriallineitem' });


TutorialLineItemSchema.statics.new = async function (json) {

  let object = this(json);
  return object;
}

mongoose.model('TutorialLineItem', TutorialLineItemSchema);

module.exports = mongoose.model('TutorialLineItem');