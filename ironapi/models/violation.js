/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Report a Term of Service Violation  
 * 
 *  
 ***************************************************************************/
const mongoose = require('mongoose');

var ViolationSchema = new mongoose.Schema({
  violatedTerms: { type: String },
  comments: { type: String },
  violator: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  reporter: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  hostedFurnace: { type: mongoose.Schema.Types.ObjectId, ref: "HostedFurnace" },
  circleObjectID: { type: String },
  circleObjectType: { type: String },
  replyObjectID: { type: String },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'violation' });


ViolationSchema.statics.new = async function (json) {

  let object = this(json);
  return object;
}

mongoose.model('Violation', ViolationSchema);

module.exports = mongoose.model('Violation');