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

var BacklogSchema = new mongoose.Schema({
  creator: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  summary: { type: String },
  description: { type: String },
  type: { type: String },  //"defect", "feature"
  hideReply: { type: Boolean, default: false },
  replies: [{ type: mongoose.Schema.Types.ObjectId, ref: 'BacklogReply' }],
  //priority: { type: Number, default: 2000 },
  //version: { type: String },
  upVotes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  upVotesCount: { type: Number },  //calculated, not stored
  //location: { type: String },
  //thumbnail: { type: String },
  //thumbnailSize: { type: Number },
  status: { type: String, default: "in review" } //"open", "closed", "resolved"

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'backlog' });


BacklogSchema.statics.new = async function (json) {

  let object = this(json);
  return object;
}

mongoose.model('Backlog', BacklogSchema);

module.exports = mongoose.model('Backlog');