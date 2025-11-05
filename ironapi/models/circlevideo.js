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

var CircleVideoSchema = new mongoose.Schema({
  circleobject: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObject' },
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
  preview: { type: String }, //link to gridfs bitmap preview of movie
  video: { type: String }, //link to gridfs movie
  //s3Video: { type: String },
  //s3Preview: { type: String },
  streamable: { type: Boolean, default: false },
  previewSize: { type: Number },
  location: { type: String },
  videoSize: { type: Number },
  extension: { type: String },
 // fullImageSize: { type: Number },
  thumbSignature: { type: String },
  fullSignature: { type: String },
  thumbCrank: { type: String },
  fullCrank: { type: String },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circlevideo' });


CircleVideoSchema.statics.new = async function (json) {

  let circleVideo = this(json);
  return circleVideo;
}

mongoose.model('CircleVideo', CircleVideoSchema);

module.exports = mongoose.model('CircleVideo');