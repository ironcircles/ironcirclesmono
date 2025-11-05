/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for mapping a required Agora user ID to a User object
 * 
 * 
 *  
 ***************************************************************************/
const mongoose = require('mongoose');

var AgoraUserSchema = new mongoose.Schema({
  agoraID: { type: Number, default: 0 },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'agorauser' });


mongoose.model('AgoraUser', AgoraUserSchema);
  
module.exports = mongoose.model('AgoraUser');