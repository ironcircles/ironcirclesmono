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
const Tutorial = require('./tutorial');

var TopicSchema = new mongoose.Schema({
  topic: { type: String },
  tutorials: [mongoose.model('Tutorial').schema],
  requireHidden: { type: Boolean, default: false },
  order: { type: Number },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'topicschema' });


TopicSchema.statics.new = async function (json) {

  let object = this(json);
  return object;
}

mongoose.model('Topic', TopicSchema);

module.exports = mongoose.model('Topic');