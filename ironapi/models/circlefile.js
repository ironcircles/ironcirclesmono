/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for photos/images/pictures within a circle
 * 
 * Should not be used for videos or gifs.
 * 
 * Decentralized to include circleobject and circle property to avoid MongoDB join hell
 * 
 *  
 ***************************************************************************/
const mongoose = require('mongoose');

var CircleFileSchema = new mongoose.Schema({
  circleobject: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObject' },
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
  location: { type: String },
  file: { type: String },
  fileSignature: { type: String },
  fileCrank: { type: String },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circlefiles' });


CircleFileSchema.statics.new = async function (json) {

  json._id = undefined;

  let circleFile = this(json);
  return circleFile;
}


CircleFileSchema.methods.update = async function (json) {

  this.circle = json["circle"];
  this.location = json["location"];
  this.file = json["file"];
  this.fileSignature = json["fileSignature"];
  this.fileCrank = json["fileCrank"];
}

mongoose.model('CircleFile', CircleFileSchema);

module.exports = mongoose.model('CircleFile');