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
const TutorialLineItem = require('./tutoriallineitem');

var TutorialSchema = new mongoose.Schema({
  title: { type: String },
  lineItems: [mongoose.model('TutorialLineItem').schema],
  video: { type: String },
  requireHidden: { type: Boolean, default: false },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'tutorial' });


TutorialSchema.statics.new = async function (json) {

  let object = this(json);
  return object;
}

mongoose.model('Tutorial', TutorialSchema);

module.exports = mongoose.model('Tutorial');