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

var BacklogReplySchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  reply: { type: String },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'backlogreply' });


BacklogReplySchema.statics.new = async function (json) {

  let object = this(json);
  return object;
}

mongoose.model('BacklogReply', BacklogReplySchema);

module.exports = mongoose.model('BacklogReply');