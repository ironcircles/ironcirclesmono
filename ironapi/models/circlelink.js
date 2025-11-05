/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for links within a circle
 * 
 * 
 * Decentralized to include circleobject and circle property to avoid MongoDB join hell
 * 
 *  
 ***************************************************************************/

/*
DEPRECATED

const mongoose = require('mongoose');  

var CircleLinkSchema = new mongoose.Schema({  
  circleobject: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObject' },
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
  title: String,
  description: String,
  image: String,
  url: String,

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}},  { collection: 'circlelink' });

mongoose.model('CircleLink', CircleLinkSchema);

module.exports = mongoose.model('CircleLink');
*/