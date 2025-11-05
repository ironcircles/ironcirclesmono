/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose:
 * 
 *  
 ***************************************************************************/
const mongoose = require('mongoose');

var ReleaseSchema = new mongoose.Schema({
  version: { type: String },
  notes: [{ type: String }],
  released: { type: Date },
  ready: { type: Boolean },
  build: { type: Number },
  minimumBuild: { type: Number }

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'release' });


ReleaseSchema.statics.new = async function (json) {

  let object = this(json);
  return object;
}

mongoose.model('Release', ReleaseSchema);

module.exports = mongoose.model('Release');