const mongoose = require('mongoose');
const constants = require('../util/constants');

//Needs to be a generic object
//meta data and tags will be stored outside of body
//everything else needs to be pulled and decrypted clientside
//so the contects are not visible
/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: 
 *  
 ***************************************************************************/

var CircleObjectReactionSchema = new mongoose.Schema({
  users: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  index: { type: Number },
  emoji: { type: String },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circleobjectreaction' });


mongoose.model('CircleObjectReaction', CircleObjectReactionSchema);
module.exports = mongoose.model('CircleObjectReaction');