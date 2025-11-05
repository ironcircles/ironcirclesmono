/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for user avatar information
 * 
 * 
 *  
 ***************************************************************************/
const mongoose = require('mongoose');

var AvatarSchema = new mongoose.Schema({
  name: { type: String },
  size: { type: Number },
  location: { type: String },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'avatars' });



mongoose.model('Avatar', AvatarSchema);

module.exports = mongoose.model('Avatar');