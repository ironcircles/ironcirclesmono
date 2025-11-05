/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: NOT IN USE YET
 * 
 *  
 ***************************************************************************/const mongoose = require('mongoose');  

var CircleBlobSchema = new mongoose.Schema({  
  circleobject: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObject' },
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
  blob: String

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}}, { collection: 'circleblobs' });

mongoose.model('CircleBlob', CircleBlobSchema);

module.exports = mongoose.model('CircleBlob');