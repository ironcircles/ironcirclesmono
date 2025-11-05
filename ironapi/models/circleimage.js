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

var CircleImageSchema = new mongoose.Schema({
  circleobject: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObject' },
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
  location: { type: String },
  thumbnail: { type: String },
  fullImage: { type: String },
  height: { type: Number },
  width: { type: Number },
  thumbnailSize: { type: Number },
  fullImageSize: { type: Number },
  thumbSignature: { type: String },
  fullSignature: { type: String },
  thumbCrank: { type: String },
  fullCrank: { type: String },
  album: { type: String },  //used for photo albums
  //imageType: { type: String },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circleimages' });


CircleImageSchema.statics.new = async function (json) {

  json._id = undefined;
  //in v25 going forward these come over as null, so remove them
  if (json.height == null) json.height = undefined;
  if (json.width == null) json.width = undefined;
  if (json.thumbnailSize == null) json.thumbnailSize = undefined;
  if (json.fullImageSize == null) json.fullImageSize = undefined;


  let circleImage = this(json);
  return circleImage;
}


CircleImageSchema.methods.update = async function (json) {

  this.circle = json["circle"];
  this.location = json["location"];
  this.thumbnail = json["thumbnail"];
  this.fullImage = json["fullImage"];
  this.height = json["height"];
  this.width = json["width"];
  this.thumbnailSize = json["thumbnailSize"];
  this.fullImageSize = json["fullImageSize"];
  this.thumbSignature = json["thumbSignature"];
  this.fullSignature = json["fullSignature"];
  this.thumbCrank = json["thumbCrank"];
  this.fullCrank = json["fullCrank"];
  this.album = json["album"];

}

mongoose.model('CircleImage', CircleImageSchema);

module.exports = mongoose.model('CircleImage');