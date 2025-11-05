/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for gifs within a circle
 * 
 * 
 * Decentralized to include circleobject and circle property to avoid MongoDB join hell
 * 
 *  
 ***************************************************************************/

/*
DEPRECATED
const mongoose = require('mongoose');  

var CircleGifSchema = new mongoose.Schema({  
  circleobject: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObject' },
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
  gif: String,
  giphy: String

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}},  { collection: 'circlegif' });

mongoose.model('CircleGif', CircleGifSchema);

module.exports = mongoose.model('CircleGif');
*/