/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Used for trouble shooting restore issues for beta users
 *  
 ***************************************************************************/
const mongoose = require('mongoose');

var LogDetailSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  blob: { type: String }, 
  blobSize: { type: Number },
  dbKey: { type: String },
  backupKey: { type: String },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'logdetail' });


LogDetailSchema.statics.new = async function (json) {

  let logDetail = this(json);
  return logDetail;
}

mongoose.model('LogDetail', LogDetailSchema);

module.exports = mongoose.model('LogDetail');